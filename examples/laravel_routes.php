<?php

// routes/api.php

use App\Http\Controllers\Api\BasPaymentController;
use Illuminate\Support\Facades\Route;

/*
|--------------------------------------------------------------------------
| API Routes
|--------------------------------------------------------------------------
|
| Here is where you can register API routes for your application. These
| routes are loaded by the RouteServiceProvider and all of them will
| be assigned to the "api" middleware group. Make something great!
|
*/

// مسارات المصادقة
Route::prefix('auth')->group(function () {
    Route::post('login', [AuthController::class, 'login']);
    Route::post('register', [AuthController::class, 'register']);
    Route::post('logout', [AuthController::class, 'logout'])->middleware('auth:sanctum');
    Route::get('user', [AuthController::class, 'user'])->middleware('auth:sanctum');
});

// مسارات الدفع عبر BAS
Route::prefix('payment')->middleware('auth:sanctum')->group(function () {
    // إنشاء طلب دفع جديد
    Route::post('initiate', [BasPaymentController::class, 'initiatePayment']);
    
    // التحقق من حالة المعاملة
    Route::post('check-status', [BasPaymentController::class, 'checkTransactionStatus']);
    
    // تأكيد نجاح الدفع
    Route::post('confirm', [BasPaymentController::class, 'confirmPayment']);
    
    // الحصول على تاريخ المدفوعات
    Route::get('history', [BasPaymentController::class, 'getPaymentHistory']);
    
    // إلغاء معاملة
    Route::post('cancel', [BasPaymentController::class, 'cancelPayment']);
});

// مسارات عامة (بدون مصادقة)
Route::prefix('public')->group(function () {
    // معلومات الباقات المتاحة
    Route::get('packages', [PackageController::class, 'getAvailablePackages']);
    
    // معلومات الأسعار
    Route::get('pricing', [PackageController::class, 'getPricing']);
});

// مسارات الإدارة (للمطورين فقط)
Route::prefix('admin')->middleware(['auth:sanctum', 'admin'])->group(function () {
    // إحصائيات المدفوعات
    Route::get('payment-stats', [AdminController::class, 'getPaymentStats']);
    
    // جميع المعاملات
    Route::get('transactions', [AdminController::class, 'getAllTransactions']);
    
    // تحديث حالة معاملة
    Route::put('transaction/{id}/status', [AdminController::class, 'updateTransactionStatus']);
});
