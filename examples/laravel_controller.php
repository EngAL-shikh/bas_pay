<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\Validator;
use Illuminate\Support\Facades\Log;
use Bas\LaravelSdk\Facades\BasFacade;
use App\Models\PaymentTransaction;
use Illuminate\Support\Str;

class BasPaymentController extends Controller
{
    /**
     * إنشاء معاملة دفع جديدة
     */
    public function initiatePayment(Request $request)
    {
        try {
            Log::info('🔵 [DEBUG] بدء إنشاء طلب الدفع في الباك اند');
            Log::info('🔵 [DEBUG] بيانات الطلب: ' . json_encode($request->all()));

            // التحقق من صحة البيانات
            $validator = Validator::make($request->all(), [
                'amount' => 'required|numeric|min:0.01',
                'order_id' => 'required|string|max:255',
                'customer_id' => 'required|string|max:255',
                'customer_name' => 'required|string|max:255',
                'customer_phone' => 'required|string|max:20',
            ]);

            if ($validator->fails()) {
                Log::error('🔴 [DEBUG] فشل في التحقق من البيانات: ' . json_encode($validator->errors()));
                return response()->json([
                    'success' => false,
                    'message' => 'بيانات غير صحيحة',
                    'errors' => $validator->errors()
                ], 422);
            }

            $amount = $request->amount;
            $orderId = $request->order_id;
            $customerId = $request->customer_id;
            $customerName = $request->customer_name;
            $customerPhone = $request->customer_phone;

            Log::info('🔵 [DEBUG] بيانات المعاملة المستخرجة:');
            Log::info('🔵 [DEBUG] المبلغ: ' . $amount);
            Log::info('🔵 [DEBUG] معرف الطلب: ' . $orderId);
            Log::info('🔵 [DEBUG] معرف العميل: ' . $customerId);

            // إنشاء معرف فريد للمعاملة
            $trxId = 'TRX_' . time() . '_' . Str::random(8);
            Log::info('🔵 [DEBUG] معرف المعاملة: ' . $trxId);

            // استدعاء BAS SDK لإنشاء المعاملة
            Log::info('🔵 [DEBUG] بدء استدعاء BAS SDK...');
            $basResponse = BasFacade::initiateTransaction($orderId, $amount, 'YER');
            Log::info('🔵 [DEBUG] استجابة BAS SDK: ' . json_encode($basResponse));

            if ($basResponse['status'] == 1 && $basResponse['code'] == '1111') {
                Log::info('🔵 [DEBUG] نجح استدعاء BAS SDK');
                
                // حفظ المعاملة في قاعدة البيانات
                Log::info('🔵 [DEBUG] بدء حفظ المعاملة في قاعدة البيانات...');
                $transaction = PaymentTransaction::create([
                    'order_id' => $orderId,
                    'trx_id' => $trxId,
                    'trx_token' => $basResponse['body']['trxToken'],
                    'amount' => $amount,
                    'customer_id' => $customerId,
                    'customer_name' => $customerName,
                    'customer_phone' => $customerPhone,
                    'status' => 'pending',
                    'bas_response' => $basResponse,
                ]);
                Log::info('🔵 [DEBUG] تم حفظ المعاملة في قاعدة البيانات بنجاح');

                $responseData = [
                    'success' => true,
                    'message' => 'تم إنشاء طلب الدفع بنجاح',
                    'data' => [
                        'trx_id' => $trxId,
                        'trx_token' => $basResponse['body']['trxToken'],
                        'order_id' => $orderId,
                        'amount' => $amount,
                        'status' => 'pending',
                    ]
                ];
                
                Log::info('🔵 [DEBUG] الاستجابة النهائية: ' . json_encode($responseData));
                return response()->json($responseData);
            } else {
                Log::error('🔴 [DEBUG] فشل استدعاء BAS SDK');
                Log::error('🔴 [DEBUG] استجابة BAS: ' . json_encode($basResponse));

                return response()->json([
                    'success' => false,
                    'message' => 'فشل في إنشاء طلب الدفع',
                    'error' => $basResponse['message'] ?? 'خطأ غير معروف'
                ], 500);
            }

        } catch (\Exception $e) {
            Log::error('🔴 [DEBUG] خطأ في إنشاء طلب الدفع: ' . $e->getMessage());
            Log::error('🔴 [DEBUG] Stack trace: ' . $e->getTraceAsString());

            return response()->json([
                'success' => false,
                'message' => 'حدث خطأ في الخادم',
                'error' => $e->getMessage()
            ], 500);
        }
    }

    /**
     * التحقق من حالة المعاملة
     */
    public function checkTransactionStatus(Request $request)
    {
        try {
            $validator = Validator::make($request->all(), [
                'trx_id' => 'required|string',
                'order_id' => 'required|string',
            ]);

            if ($validator->fails()) {
                return response()->json([
                    'success' => false,
                    'message' => 'بيانات غير صحيحة',
                    'errors' => $validator->errors()
                ], 422);
            }

            $trxId = $request->trx_id;
            $orderId = $request->order_id;

            Log::info('🔵 [DEBUG] التحقق من حالة المعاملة');
            Log::info('🔵 [DEBUG] TRX ID: ' . $trxId);
            Log::info('🔵 [DEBUG] Order ID: ' . $orderId);

            // استدعاء BAS SDK للتحقق من الحالة
            $basResponse = BasFacade::checkTransactionStatus($orderId);
            Log::info('🔵 [DEBUG] استجابة BAS SDK: ' . json_encode($basResponse));

            if ($basResponse['status'] == 1 && $basResponse['code'] == '1111') {
                $trxStatus = $basResponse['body']['trxStatus'];
                $isSuccessful = in_array($trxStatus, ['processed', 'completed']);

                // تحديث حالة المعاملة في قاعدة البيانات
                $transaction = PaymentTransaction::where('trx_id', $trxId)->first();
                if ($transaction) {
                    $transaction->update([
                        'status' => $isSuccessful ? 'paid' : 'failed',
                        'bas_response' => $basResponse,
                    ]);
                }

                return response()->json([
                    'success' => true,
                    'data' => [
                        'trx_id' => $trxId,
                        'order_id' => $orderId,
                        'status' => $trxStatus,
                        'is_successful' => $isSuccessful,
                    ],
                    'message' => 'تم التحقق من حالة المعاملة'
                ]);
            } else {
                return response()->json([
                    'success' => false,
                    'message' => 'فشل في التحقق من حالة المعاملة',
                    'error' => $basResponse['message'] ?? 'خطأ غير معروف'
                ], 500);
            }

        } catch (\Exception $e) {
            Log::error('🔴 [DEBUG] خطأ في التحقق من حالة المعاملة: ' . $e->getMessage());

            return response()->json([
                'success' => false,
                'message' => 'حدث خطأ في الخادم',
                'error' => $e->getMessage()
            ], 500);
        }
    }

    /**
     * تأكيد نجاح الدفع
     */
    public function confirmPayment(Request $request)
    {
        try {
            $validator = Validator::make($request->all(), [
                'trx_id' => 'required|string',
                'order_id' => 'required|string',
            ]);

            if ($validator->fails()) {
                return response()->json([
                    'success' => false,
                    'message' => 'بيانات غير صحيحة',
                    'errors' => $validator->errors()
                ], 422);
            }

            $trxId = $request->trx_id;
            $orderId = $request->order_id;

            Log::info('🔵 [DEBUG] تأكيد نجاح الدفع');
            Log::info('🔵 [DEBUG] TRX ID: ' . $trxId);
            Log::info('🔵 [DEBUG] Order ID: ' . $orderId);

            // البحث عن المعاملة في قاعدة البيانات
            $transaction = PaymentTransaction::where('trx_id', $trxId)->first();
            
            if (!$transaction) {
                return response()->json([
                    'success' => false,
                    'message' => 'المعاملة غير موجودة'
                ], 404);
            }

            // تحديث حالة المعاملة إلى مدفوعة
            $transaction->update(['status' => 'paid']);

            Log::info('🔵 [DEBUG] تم تأكيد الدفع بنجاح');

            return response()->json([
                'success' => true,
                'data' => [
                    'trx_id' => $trxId,
                    'order_id' => $orderId,
                    'status' => 'paid',
                    'amount' => $transaction->amount,
                ],
                'message' => 'تم تأكيد الدفع بنجاح'
            ]);

        } catch (\Exception $e) {
            Log::error('🔴 [DEBUG] خطأ في تأكيد الدفع: ' . $e->getMessage());

            return response()->json([
                'success' => false,
                'message' => 'حدث خطأ في الخادم',
                'error' => $e->getMessage()
            ], 500);
        }
    }
}
