# دليل البدء السريع - BAS Payment Gateway

## 🚀 البدء في 5 دقائق

### 1. افتح الدليل التفاعلي
```bash
# افتح ملف index.html في المتصفح
open index.html
# أو
start index.html
```

### 2. اتبع الخطوات
- ✅ **الخطوة 1**: المتطلبات الأساسية
- ✅ **الخطوة 2**: إعداد Laravel Backend  
- ✅ **الخطوة 3**: إعداد Flutter Frontend
- ✅ **الخطوة 4**: التكامل والاختبار
- ✅ **الخطوة 5**: النشر والإنتاج

### 3. استخدم الأمثلة الجاهزة
```bash
# انسخ الملفات من مجلد examples/
examples/laravel_controller.php    # للـ Laravel
examples/flutter_service.dart      # للـ Flutter
examples/usage_example.dart        # مثال الاستخدام
```

### 4. اختبر API
- استخدم أداة اختبار API المدمجة في الدليل
- أدخل URL الباك اند و Auth Token
- اضغط "اختبار Initiate Payment"

### 5. تحقق من القائمة
- راجع `checklist.md` للتأكد من إكمال كل شيء
- استخدم `troubleshooting.md` لحل المشاكل

## 📋 قائمة سريعة

### Laravel Backend
```bash
composer require basgate/laravel-sdk
php artisan make:controller Api/BasPaymentController
php artisan make:migration create_payment_transactions_table
```

### Flutter Frontend
```yaml
dependencies:
  bas_pay_flutter:
    git:
      url: https://github.com/Osamah-Attiah/bas_pay_flutter.git
```

### اختبار سريع
```dart
// في Flutter
final result = await BasPaymentService().processPayment(
  amount: 1000,
  orderId: 'test_123',
  customerId: 'user_1',
  customerName: 'أحمد محمد',
  customerPhone: '777777777',
);
```

### بيانات BAS (مثال - ضع بياناتك في الباك اند فقط)
```
App ID: your_app_id
Merchant Key: your_merchant_key
Client ID: your_client_id
Client Secret: your_client_secret
```

⚠️ **مهم**: هذه البيانات يجب أن تكون في الباك اند فقط وليس في Flutter!

## 🆘 مساعدة سريعة

### مشاكل شائعة
1. **خطأ SSL**: أضف `BAS_VERIFY_SSL=false` في `.env`
2. **خطأ Method not found**: استخدم `callBasPay` بدلاً من `callBasPaymentSdk`
3. **خطأ GetStorage**: أضف `Get.put(GetStorage())` في `main.dart`

### روابط مفيدة
- [الدليل التفاعلي](index.html)
- [حل المشاكل](troubleshooting.md)
- [قائمة التحقق](checklist.md)
- [أمثلة الكود](examples/)

---

**⏱️ الوقت المتوقع**: 30-60 دقيقة للتنفيذ الكامل
**📞 الدعم**: راجع troubleshooting.md أو تواصل مع الفريق
