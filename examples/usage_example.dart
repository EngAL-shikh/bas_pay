import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:get_storage/get_storage.dart';
import 'bas_payment_service.dart';

// مثال على استخدام BasPaymentService في Flutter Controller
class PaymentController extends GetxController {
  final BasPaymentService _paymentService = Get.find<BasPaymentService>();
  final GetStorage _storage = Get.find<GetStorage>();

  // متغيرات الحالة
  final RxBool _isProcessing = false.obs;
  final RxString _paymentStatus = 'idle'.obs;
  final RxString _errorMessage = ''.obs;

  // Getters
  bool get isProcessing => _isProcessing.value;
  String get paymentStatus => _paymentStatus.value;
  String get errorMessage => _errorMessage.value;

  /// معالجة دفع الباقة
  Future<bool> processPackagePayment({
    required String packageName,
    required double amount,
  }) async {
    try {
      print('🟣 [DEBUG] ===== بدء عملية دفع الباقة =====');
      print('🟣 [DEBUG] المبلغ: $amount');
      print('🟣 [DEBUG] اسم الباقة: $packageName');

      // التحقق من تسجيل الدخول
      final userData = _storage.read('current_user');
      if (userData == null) {
        _errorMessage.value = 'يجب تسجيل الدخول أولاً';
        _isProcessing.value = false;
        return false;
      }

      print('🟣 [DEBUG] تم تعيين حالة المعالجة إلى true');
      _isProcessing.value = true;
      _paymentStatus.value = 'initiating';
      _errorMessage.value = '';

      // إنشاء معرف فريد للطلب
      final orderId =
          '${packageName}_package_${DateTime.now().millisecondsSinceEpoch}';
      print('🟣 [DEBUG] معرف الطلب: $orderId');

      // بدء استدعاء خدمة الدفع
      print('🟣 [DEBUG] بدء استدعاء خدمة الدفع...');
      final result = await _paymentService.processPayment(
        amount: amount,
        orderId: orderId,
        customerId: userData['id'].toString(),
        customerName: userData['name'],
        customerPhone: userData['phone'],
      );

      print('🟣 [DEBUG] نتيجة خدمة الدفع: $result');

      if (result['success'] == true) {
        _paymentStatus.value = 'completed';
        print('🟣 [DEBUG] ===== انتهت عملية دفع الباقة بنجاح =====');

        // إظهار رسالة نجاح
        Get.snackbar(
          'نجح الدفع',
          'تم دفع الباقة بنجاح!',
          backgroundColor: Colors.green,
          colorText: Colors.white,
          duration: Duration(seconds: 3),
        );

        return true;
      } else {
        _paymentStatus.value = 'failed';
        _errorMessage.value = result['error'] ?? 'فشل في عملية الدفع';
        print('🔴 [DEBUG] فشلت عملية الدفع: ${_errorMessage.value}');
        print('🟣 [DEBUG] ===== انتهت عملية دفع الباقة بالفشل =====');

        // إظهار رسالة خطأ
        Get.snackbar(
          'فشل الدفع',
          _errorMessage.value,
          backgroundColor: Colors.red,
          colorText: Colors.white,
          duration: Duration(seconds: 5),
        );

        return false;
      }
    } catch (e) {
      _paymentStatus.value = 'error';
      _errorMessage.value = 'حدث خطأ غير متوقع: ${e.toString()}';
      print('🔴 [DEBUG] خطأ في معالجة الدفع: ${e.toString()}');
      return false;
    } finally {
      _isProcessing.value = false;
    }
  }

  /// معالجة الدفع المباشر
  Future<bool> processDirectPayment({
    required double amount,
    required String description,
  }) async {
    try {
      print('🟠 [DEBUG] ===== بدء عملية الدفع المباشر =====');
      print('🟠 [DEBUG] المبلغ: $amount');
      print('🟠 [DEBUG] الوصف: $description');

      // التحقق من تسجيل الدخول
      final userData = _storage.read('current_user');
      if (userData == null) {
        _errorMessage.value = 'يجب تسجيل الدخول أولاً';
        return false;
      }

      _isProcessing.value = true;
      _paymentStatus.value = 'initiating';

      // إنشاء معرف فريد للطلب
      final orderId = 'direct_payment_${DateTime.now().millisecondsSinceEpoch}';

      // بدء عملية الدفع
      final result = await _paymentService.processPayment(
        amount: amount,
        orderId: orderId,
        customerId: userData['id'].toString(),
        customerName: userData['name'],
        customerPhone: userData['phone'],
      );

      print('🟠 [DEBUG] نتيجة عملية الدفع: $result');

      if (result['success'] == true) {
        _paymentStatus.value = 'completed';
        print('🟠 [DEBUG] ===== انتهت عملية الدفع المباشر بنجاح =====');

        Get.snackbar(
          'نجح الدفع',
          'تم الدفع بنجاح!',
          backgroundColor: Colors.green,
          colorText: Colors.white,
        );

        return true;
      } else {
        _paymentStatus.value = 'failed';
        _errorMessage.value = result['error'] ?? 'فشل في عملية الدفع';
        print('🟠 [DEBUG] فشلت العملية، البقاء في الشاشة الحالية');
        print('🟠 [DEBUG] ===== انتهت عملية الدفع المباشر =====');

        Get.snackbar(
          'فشل الدفع',
          _errorMessage.value,
          backgroundColor: Colors.red,
          colorText: Colors.white,
        );

        return false;
      }
    } catch (e) {
      _paymentStatus.value = 'error';
      _errorMessage.value = 'حدث خطأ: ${e.toString()}';
      return false;
    } finally {
      _isProcessing.value = false;
    }
  }

  /// إعادة تعيين حالة الدفع
  void resetPaymentState() {
    _isProcessing.value = false;
    _paymentStatus.value = 'idle';
    _errorMessage.value = '';
    _paymentService.clearCurrentTransaction();
  }

  /// الحصول على رسالة الحالة
  String getStatusMessage() {
    switch (_paymentStatus.value) {
      case 'idle':
        return 'ابدأ الدفع';
      case 'initiating':
        return 'جاري إنشاء طلب الدفع...';
      case 'processing_sdk':
        return 'جاري معالجة الدفع عبر BAS...';
      case 'checking_status':
        return 'جاري التحقق من حالة الدفع...';
      case 'confirming':
        return 'جاري تأكيد الدفع...';
      case 'completed':
        return 'تم الدفع بنجاح';
      case 'failed':
      case 'error':
        return _errorMessage.value.isNotEmpty ? _errorMessage.value : 'حدث خطأ';
      default:
        return 'غير معروف';
    }
  }

  /// الحصول على لون الزر حسب الحالة
  Color getButtonColor() {
    switch (_paymentStatus.value) {
      case 'idle':
        return Colors.blue;
      case 'initiating':
      case 'processing_sdk':
      case 'checking_status':
      case 'confirming':
        return Colors.orange;
      case 'completed':
        return Colors.green;
      case 'failed':
      case 'error':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }
}

// مثال على استخدام Controller في Widget
class PaymentWidget extends StatelessWidget {
  final PaymentController controller = Get.put(PaymentController());

  @override
  Widget build(BuildContext context) {
    return Obx(
      () => Column(
        children: [
          // زر الدفع
          ElevatedButton(
            onPressed: controller.isProcessing
                ? null
                : () async {
                    final success = await controller.processPackagePayment(
                      packageName: 'golden',
                      amount: 50000.0,
                    );

                    if (success) {
                      // الانتقال لصفحة أخرى أو إجراء إضافي
                      Get.toNamed('/success');
                    }
                  },
            style: ElevatedButton.styleFrom(
              backgroundColor: controller.getButtonColor(),
              padding: EdgeInsets.symmetric(horizontal: 32, vertical: 16),
            ),
            child: controller.isProcessing
                ? Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          valueColor: AlwaysStoppedAnimation<Color>(
                            Colors.white,
                          ),
                        ),
                      ),
                      SizedBox(width: 8),
                      Text(controller.getStatusMessage()),
                    ],
                  )
                : Text(controller.getStatusMessage()),
          ),

          // رسالة الخطأ
          if (controller.errorMessage.isNotEmpty)
            Container(
              margin: EdgeInsets.only(top: 16),
              padding: EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.red.shade50,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.red.shade200),
              ),
              child: Text(
                controller.errorMessage,
                style: TextStyle(color: Colors.red.shade700),
                textAlign: TextAlign.center,
              ),
            ),
        ],
      ),
    );
  }
}

// مثال على إعداد التطبيق
class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return GetMaterialApp(
      title: 'BAS Payment Example',
      home: PaymentPage(),
      initialBinding: InitialBinding(),
    );
  }
}

class InitialBinding extends Bindings {
  @override
  void dependencies() {
    Get.put(GetStorage());
    Get.put(BasPaymentService());
  }
}

class PaymentPage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('دفع الباقة'), backgroundColor: Colors.blue),
      body: Padding(
        padding: EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Card(
              child: Padding(
                padding: EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'الباقة الذهبية',
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    SizedBox(height: 8),
                    Text(
                      'السعر: 50,000 ريال',
                      style: TextStyle(
                        fontSize: 18,
                        color: Colors.green,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    SizedBox(height: 16),
                    PaymentWidget(),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
