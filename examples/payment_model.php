<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Factories\HasFactory;
use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\Eloquent\Relations\BelongsTo;

class PaymentTransaction extends Model
{
    use HasFactory;

    protected $fillable = [
        'order_id',
        'trx_id',
        'trx_token',
        'amount',
        'currency',
        'customer_id',
        'customer_name',
        'customer_phone',
        'customer_email',
        'status',
        'payment_method',
        'payment_gateway',
        'gateway_transaction_id',
        'bas_response',
        'bas_callback_data',
        'description',
        'metadata',
        'initiated_at',
        'processed_at',
        'completed_at',
        'failed_at',
        'ip_address',
        'user_agent',
        'cancelled_at',
        'cancellation_reason',
        'refunded_at',
        'refund_amount',
        'refund_reason',
    ];

    protected $casts = [
        'amount' => 'decimal:2',
        'refund_amount' => 'decimal:2',
        'bas_response' => 'array',
        'bas_callback_data' => 'array',
        'metadata' => 'array',
        'initiated_at' => 'datetime',
        'processed_at' => 'datetime',
        'completed_at' => 'datetime',
        'failed_at' => 'datetime',
        'cancelled_at' => 'datetime',
        'refunded_at' => 'datetime',
    ];

    /**
     * العلاقة مع المستخدم
     */
    public function user(): BelongsTo
    {
        return $this->belongsTo(User::class, 'customer_id', 'id');
    }

    /**
     * التحقق من أن المعاملة مدفوعة
     */
    public function isPaid(): bool
    {
        return $this->status === 'paid';
    }

    /**
     * التحقق من أن المعاملة فشلت
     */
    public function isFailed(): bool
    {
        return in_array($this->status, ['failed', 'cancelled']);
    }

    /**
     * التحقق من أن المعاملة معلقة
     */
    public function isPending(): bool
    {
        return in_array($this->status, ['pending', 'processing']);
    }

    /**
     * التحقق من أن المعاملة مستردة
     */
    public function isRefunded(): bool
    {
        return $this->status === 'refunded';
    }

    /**
     * الحصول على حالة المعاملة باللغة العربية
     */
    public function getStatusInArabic(): string
    {
        return match($this->status) {
            'pending' => 'في الانتظار',
            'processing' => 'قيد المعالجة',
            'paid' => 'مدفوعة',
            'failed' => 'فشلت',
            'cancelled' => 'ملغية',
            'refunded' => 'مستردة',
            'unknown' => 'غير معروفة',
            default => 'غير محدد'
        };
    }

    /**
     * الحصول على لون الحالة
     */
    public function getStatusColor(): string
    {
        return match($this->status) {
            'pending' => 'warning',
            'processing' => 'info',
            'paid' => 'success',
            'failed' => 'danger',
            'cancelled' => 'secondary',
            'refunded' => 'warning',
            'unknown' => 'dark',
            default => 'light'
        };
    }

    /**
     * تحديث حالة المعاملة
     */
    public function updateStatus(string $status, array $additionalData = []): bool
    {
        $updateData = array_merge(['status' => $status], $additionalData);
        
        // إضافة timestamp حسب الحالة
        switch ($status) {
            case 'processing':
                $updateData['processed_at'] = now();
                break;
            case 'paid':
                $updateData['completed_at'] = now();
                break;
            case 'failed':
                $updateData['failed_at'] = now();
                break;
            case 'cancelled':
                $updateData['cancelled_at'] = now();
                break;
            case 'refunded':
                $updateData['refunded_at'] = now();
                break;
        }
        
        return $this->update($updateData);
    }

    /**
     * إلغاء المعاملة
     */
    public function cancel(string $reason = null): bool
    {
        return $this->updateStatus('cancelled', [
            'cancellation_reason' => $reason
        ]);
    }

    /**
     * استرداد المعاملة
     */
    public function refund(float $amount = null, string $reason = null): bool
    {
        $refundAmount = $amount ?? $this->amount;
        
        return $this->updateStatus('refunded', [
            'refund_amount' => $refundAmount,
            'refund_reason' => $reason
        ]);
    }

    /**
     * الحصول على مدة المعاملة
     */
    public function getDuration(): ?int
    {
        if (!$this->initiated_at) {
            return null;
        }
        
        $endTime = $this->completed_at ?? $this->failed_at ?? $this->cancelled_at ?? now();
        
        return $this->initiated_at->diffInSeconds($endTime);
    }

    /**
     * الحصول على مدة المعاملة بصيغة مقروءة
     */
    public function getDurationFormatted(): string
    {
        $duration = $this->getDuration();
        
        if (!$duration) {
            return 'غير محدد';
        }
        
        if ($duration < 60) {
            return "{$duration} ثانية";
        } elseif ($duration < 3600) {
            $minutes = floor($duration / 60);
            $seconds = $duration % 60;
            return "{$minutes} دقيقة و {$seconds} ثانية";
        } else {
            $hours = floor($duration / 3600);
            $minutes = floor(($duration % 3600) / 60);
            return "{$hours} ساعة و {$minutes} دقيقة";
        }
    }

    /**
     * Scope للمعاملات المدفوعة
     */
    public function scopePaid($query)
    {
        return $query->where('status', 'paid');
    }

    /**
     * Scope للمعاملات الفاشلة
     */
    public function scopeFailed($query)
    {
        return $query->whereIn('status', ['failed', 'cancelled']);
    }

    /**
     * Scope للمعاملات المعلقة
     */
    public function scopePending($query)
    {
        return $query->whereIn('status', ['pending', 'processing']);
    }

    /**
     * Scope للمعاملات في فترة زمنية معينة
     */
    public function scopeInPeriod($query, $startDate, $endDate)
    {
        return $query->whereBetween('created_at', [$startDate, $endDate]);
    }

    /**
     * Scope لعميل معين
     */
    public function scopeForCustomer($query, $customerId)
    {
        return $query->where('customer_id', $customerId);
    }

    /**
     * الحصول على إحصائيات المعاملات
     */
    public static function getStats($customerId = null, $startDate = null, $endDate = null)
    {
        $query = static::query();
        
        if ($customerId) {
            $query->forCustomer($customerId);
        }
        
        if ($startDate && $endDate) {
            $query->inPeriod($startDate, $endDate);
        }
        
        return [
            'total_transactions' => $query->count(),
            'paid_transactions' => $query->paid()->count(),
            'failed_transactions' => $query->failed()->count(),
            'pending_transactions' => $query->pending()->count(),
            'total_amount' => $query->paid()->sum('amount'),
            'average_amount' => $query->paid()->avg('amount'),
            'success_rate' => $query->count() > 0 ? 
                round(($query->paid()->count() / $query->count()) * 100, 2) : 0,
        ];
    }
}
