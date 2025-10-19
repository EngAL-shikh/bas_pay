import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:get/get.dart';
import 'package:get_storage/get_storage.dart';
import 'package:bas_pay_flutter/bas_pay_flutter.dart';
import 'package:bas_pay_flutter/models/init_bas_sdk_model.dart';

class BasPaymentService extends GetxService {
  // متغيرات لحفظ بيانات المعاملة
  String? _currentTrxToken;
  String? _currentTrxId;
  String? _currentOrderId;

  /// إنشاء طلب دفع جديد
  Future<Map<String, dynamic>> initiatePayment({
    required double amount,
    required String orderId,
    required String customerId,
    required String customerName,
    required String customerPhone,
  }) async {
    try {
      print('🔵 [DEBUG] بدء إنشاء طلب الدفع');
      print('🔵 [DEBUG] المبلغ: $amount');
      print('🔵 [DEBUG] معرف الطلب: $orderId');
      print('🔵 [DEBUG] معرف العميل: $customerId');
      print('🔵 [DEBUG] اسم العميل: $customerName');
      print('🔵 [DEBUG] هاتف العميل: $customerPhone');
      print(
        '🔵 [DEBUG] URL الباك اند: ${_getBackendUrl()}/api/payment/initiate',
      );
      print(
        '🔵 [DEBUG] رمز المصادقة: ${_getAuthToken().isNotEmpty ? "موجود" : "غير موجود"}',
      );

      // إرسال طلب للباك اند لإنشاء المعاملة
      final response = await http.post(
        Uri.parse('${_getBackendUrl()}/api/payment/initiate'),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
          'Authorization': 'Bearer ${_getAuthToken()}',
        },
        body: jsonEncode({
          'amount': amount,
          'order_id': orderId,
          'customer_id': customerId,
          'customer_name': customerName,
          'customer_phone': customerPhone,
        }),
      );

      print('🔵 [DEBUG] استجابة الخادم - Status Code: ${response.statusCode}');
      print('🔵 [DEBUG] استجابة الخادم - Body: ${response.body}');

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        print('🔵 [DEBUG] بيانات الاستجابة: $data');

        if (data['success'] == true) {
          _currentTrxToken = data['data']['trx_token'];
          _currentTrxId = data['data']['trx_id'];
          _currentOrderId = orderId;

          print('🔵 [DEBUG] تم إنشاء طلب الدفع بنجاح');
          print('🔵 [DEBUG] TRX Token: $_currentTrxToken');
          print('🔵 [DEBUG] TRX ID: $_currentTrxId');

          return {
            'success': true,
            'trx_token': _currentTrxToken,
            'trx_id': _currentTrxId,
            'order_id': orderId,
          };
        } else {
          print('🔴 [DEBUG] فشل في إنشاء طلب الدفع: ${data['message']}');
          return {
            'success': false,
            'error': data['message'] ?? 'فشل في إنشاء طلب الدفع',
          };
        }
      } else {
        print(
          '🔴 [DEBUG] خطأ في الاتصال بالخادم - Status: ${response.statusCode}',
        );
        return {'success': false, 'error': 'خطأ في الاتصال بالخادم'};
      }
    } catch (e) {
      print('🔴 [DEBUG] خطأ في إنشاء طلب الدفع: ${e.toString()}');
      return {'success': false, 'error': 'حدث خطأ: ${e.toString()}'};
    }
  }

  /// استدعاء واجهة الدفع BAS
  Future<Map<String, dynamic>> callBasPaymentSdk({
    required String trxToken,
    required String userPhone,
    required String fullName,
  }) async {
    try {
      print('🟡 [DEBUG] بدء استدعاء واجهة الدفع BAS');
      print('🟡 [DEBUG] TRX Token: $trxToken');
      print('🟡 [DEBUG] هاتف المستخدم: $userPhone');
      print('🟡 [DEBUG] الاسم الكامل: $fullName');

      // استدعاء BAS SDK الحقيقي
      print('🟡 [DEBUG] بدء استدعاء BAS SDK الحقيقي...');

      try {
        // استدعاء BAS SDK الحقيقي حسب الديكومنتيشن
        print('🟡 [DEBUG] استدعاء callBasPay...');

        // إنشاء نموذج البيانات للـ SDK
        final model = InitBasSdkModel.dev(
          trxToken: trxToken,
          userIdentifier: userPhone,
          fullName: fullName,
          language: 'ar',
          product: 'YOUR_APP_NAME', // غيّر هذا لاسم تطبيقك
        );

        print('🟡 [DEBUG] نموذج البيانات: ${model.toJson()}');

        // استدعاء SDK
        final result = await BasPayFlutter().callBasPay(model: model);

        print('🟡 [DEBUG] نتيجة BAS SDK: ${result.resultStatus}');
        print('🟡 [DEBUG] بيانات النتيجة: ${result.resultModel?.toJson()}');

        if (result.resultStatus && result.resultModel?.status == true) {
          return {
            'success': true,
            'trx_id': trxToken,
            'message': 'تم الدفع بنجاح',
            'is_simulation': false, // دفع حقيقي
            'bas_result': result.resultModel?.toJson(),
          };
        } else {
          return {
            'success': false,
            'error':
                'فشل في عملية الدفع: ${result.resultModel?.message ?? 'خطأ غير معروف'}',
          };
        }
      } catch (sdkError) {
        print('🔴 [DEBUG] خطأ في BAS SDK: ${sdkError.toString()}');
        return {
          'success': false,
          'error': 'فشل في عملية الدفع: ${sdkError.toString()}',
        };
      }
    } catch (e) {
      print('🔴 [DEBUG] خطأ في واجهة الدفع: ${e.toString()}');
      return {
        'success': false,
        'error': 'حدث خطأ في واجهة الدفع: ${e.toString()}',
      };
    }
  }

  /// التحقق من حالة المعاملة
  Future<Map<String, dynamic>> checkTransactionStatus({
    required String trxId,
    required String orderId,
  }) async {
    try {
      final response = await http.post(
        Uri.parse('${_getBackendUrl()}/api/payment/check-status'),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
          'Authorization': 'Bearer ${_getAuthToken()}',
        },
        body: jsonEncode({'trx_id': trxId, 'order_id': orderId}),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return {
          'success': data['success'] ?? false,
          'data': data['data'],
          'message': data['message'],
        };
      } else {
        return {'success': false, 'error': 'خطأ في الاتصال بالخادم'};
      }
    } catch (e) {
      return {'success': false, 'error': 'حدث خطأ: ${e.toString()}'};
    }
  }

  /// تأكيد نجاح الدفع
  Future<Map<String, dynamic>> confirmPayment({
    required String trxId,
    required String orderId,
  }) async {
    try {
      final response = await http.post(
        Uri.parse('${_getBackendUrl()}/api/payment/confirm'),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
          'Authorization': 'Bearer ${_getAuthToken()}',
        },
        body: jsonEncode({'trx_id': trxId, 'order_id': orderId}),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return {
          'success': data['success'] ?? false,
          'data': data['data'],
          'message': data['message'],
        };
      } else {
        return {'success': false, 'error': 'خطأ في الاتصال بالخادم'};
      }
    } catch (e) {
      return {'success': false, 'error': 'حدث خطأ: ${e.toString()}'};
    }
  }

  /// دالة شاملة لتنفيذ عملية الدفع الكاملة
  Future<Map<String, dynamic>> processPayment({
    required double amount,
    required String orderId,
    required String customerId,
    required String customerName,
    required String customerPhone,
  }) async {
    try {
      print('🟢 [DEBUG] ===== بدء عملية الدفع الكاملة =====');
      print('🟢 [DEBUG] المبلغ: $amount');
      print('🟢 [DEBUG] معرف الطلب: $orderId');
      print('🟢 [DEBUG] معرف العميل: $customerId');

      // الخطوة 1: إنشاء طلب الدفع
      print('🟢 [DEBUG] الخطوة 1: إنشاء طلب الدفع...');
      final initiateResult = await initiatePayment(
        amount: amount,
        orderId: orderId,
        customerId: customerId,
        customerName: customerName,
        customerPhone: customerPhone,
      );

      print('🟢 [DEBUG] نتيجة إنشاء طلب الدفع: $initiateResult');
      if (!initiateResult['success']) {
        print('🔴 [DEBUG] فشل في إنشاء طلب الدفع، إيقاف العملية');
        return initiateResult;
      }

      // الخطوة 2: استدعاء واجهة الدفع
      print('🟢 [DEBUG] الخطوة 2: استدعاء واجهة الدفع...');
      final paymentResult = await callBasPaymentSdk(
        trxToken: initiateResult['trx_token'],
        userPhone: customerPhone,
        fullName: customerName,
      );

      print('🟢 [DEBUG] نتيجة استدعاء واجهة الدفع: $paymentResult');
      if (!paymentResult['success']) {
        print('🔴 [DEBUG] فشل في استدعاء واجهة الدفع، إيقاف العملية');
        return paymentResult;
      }

      // الخطوة 3: التحقق من حالة المعاملة
      print('🟢 [DEBUG] الخطوة 3: التحقق من حالة المعاملة...');
      final statusResult = await checkTransactionStatus(
        trxId: initiateResult['trx_id'],
        orderId: orderId,
      );

      print('🟢 [DEBUG] نتيجة التحقق من الحالة: $statusResult');
      if (!statusResult['success'] || !statusResult['data']['is_successful']) {
        print('🔴 [DEBUG] لم يتم تأكيد الدفع، إيقاف العملية');
        return {'success': false, 'error': 'لم يتم تأكيد الدفع'};
      }

      // الخطوة 4: تأكيد الدفع
      print('🟢 [DEBUG] الخطوة 4: تأكيد الدفع...');
      final confirmResult = await confirmPayment(
        trxId: initiateResult['trx_id'],
        orderId: orderId,
      );

      print('🟢 [DEBUG] نتيجة تأكيد الدفع: $confirmResult');
      print('🟢 [DEBUG] ===== انتهت عملية الدفع الكاملة =====');
      return confirmResult;
    } catch (e) {
      print('🔴 [DEBUG] خطأ في عملية الدفع الكاملة: ${e.toString()}');
      return {
        'success': false,
        'error': 'حدث خطأ في عملية الدفع: ${e.toString()}',
      };
    }
  }

  /// الحصول على URL الباك اند
  String _getBackendUrl() {
    // غيّر هذا لـ URL الباك اند الخاص بك
    return 'http://YOUR_BACKEND_URL:8000';
  }

  /// الحصول على رمز المصادقة
  String _getAuthToken() {
    // يمكنك الحصول على الرمز من GetStorage أو أي مكان آخر
    try {
      return Get.find<GetStorage>().read('auth_token') ?? '';
    } catch (e) {
      return '';
    }
  }

  /// مسح بيانات المعاملة الحالية
  void clearCurrentTransaction() {
    _currentTrxToken = null;
    _currentTrxId = null;
    _currentOrderId = null;
  }

  /// الحصول على بيانات المعاملة الحالية
  Map<String, String?> getCurrentTransaction() {
    return {
      'trx_token': _currentTrxToken,
      'trx_id': _currentTrxId,
      'order_id': _currentOrderId,
    };
  }
}
