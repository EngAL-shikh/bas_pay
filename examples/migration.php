<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
    /**
     * Run the migrations.
     */
    public function up(): void
    {
        Schema::create('payment_transactions', function (Blueprint $table) {
            $table->id();
            
            // معلومات المعاملة الأساسية
            $table->string('order_id')->unique();
            $table->string('trx_id')->unique();
            $table->text('trx_token');
            
            // معلومات المبلغ والعملة
            $table->decimal('amount', 10, 2);
            $table->string('currency', 3)->default('YER');
            
            // معلومات العميل
            $table->string('customer_id');
            $table->string('customer_name')->nullable();
            $table->string('customer_phone')->nullable();
            $table->string('customer_email')->nullable();
            
            // حالة المعاملة
            $table->enum('status', [
                'pending',      // في الانتظار
                'processing',   // قيد المعالجة
                'paid',         // مدفوعة
                'failed',       // فشلت
                'cancelled',    // ملغية
                'refunded',     // مستردة
                'unknown'       // غير معروفة
            ])->default('pending');
            
            // معلومات الدفع
            $table->string('payment_method')->nullable();
            $table->string('payment_gateway')->default('BAS');
            $table->string('gateway_transaction_id')->nullable();
            
            // بيانات الاستجابة من BAS
            $table->json('bas_response')->nullable();
            $table->json('bas_callback_data')->nullable();
            
            // معلومات إضافية
            $table->text('description')->nullable();
            $table->json('metadata')->nullable(); // بيانات إضافية حسب الحاجة
            
            // تواريخ مهمة
            $table->timestamp('initiated_at')->nullable();
            $table->timestamp('processed_at')->nullable();
            $table->timestamp('completed_at')->nullable();
            $table->timestamp('failed_at')->nullable();
            
            // معلومات التتبع
            $table->string('ip_address')->nullable();
            $table->text('user_agent')->nullable();
            
            // معلومات الإلغاء والاسترداد
            $table->timestamp('cancelled_at')->nullable();
            $table->string('cancellation_reason')->nullable();
            $table->timestamp('refunded_at')->nullable();
            $table->decimal('refund_amount', 10, 2)->nullable();
            $table->string('refund_reason')->nullable();
            
            $table->timestamps();
            
            // فهارس لتحسين الأداء
            $table->index(['customer_id', 'status']);
            $table->index(['trx_id', 'order_id']);
            $table->index(['status', 'created_at']);
            $table->index(['payment_gateway', 'status']);
            $table->index('initiated_at');
            $table->index('processed_at');
        });
    }

    /**
     * Reverse the migrations.
     */
    public function down(): void
    {
        Schema::dropIfExists('payment_transactions');
    }
};
