# دليل حل المشاكل الشائعة - BAS Payment Gateway

## 🔧 مشاكل Laravel Backend

### 1. خطأ "Class not found" للـ BAS SDK

**المشكلة:**
```
Class "Bas\LaravelSdk\Facades\BasFacade" not found
```

**الحل:**
```bash
# تأكد من تثبيت SDK
composer require basgate/laravel-sdk

# مسح cache
php artisan config:clear
php artisan cache:clear
php artisan route:clear

# إعادة تحميل autoload
composer dump-autoload
```

### 2. خطأ SSL Certificate

**المشكلة:**
```
cURL error 60: SSL certificate problem: unable to get local issuer certificate
```

**الحل:**
```php
// في config/bas.php
'verify_ssl' => env('BAS_VERIFY_SSL', false),

// أو في .env
BAS_VERIFY_SSL=false
```

### 3. خطأ "Could not resolve host"

**المشكلة:**
```
cURL error 6: Could not resolve host: sandbox.basgate.com
```

**الحل:**
```php
// تأكد من صحة URL في config/bas.php
'base_url' => env('BAS_BASE_URL', 'https://api-tst.basgate.com'),
```

### 4. خطأ Service Provider غير مسجل

**المشكلة:**
```
Target class [Bas\LaravelSdk\BasServiceProvider] does not exist
```

**الحل:**
```php
// في bootstrap/providers.php
return [
    App\Providers\AppServiceProvider::class,
    Bas\LaravelSdk\BasServiceProvider::class, // تأكد من وجود هذا السطر
];
```

## 📱 مشاكل Flutter Frontend

### 1. خطأ "Method not found"

**المشكلة:**
```
The method 'callBasPaymentSdk' isn't defined for the type 'BasPayFlutter'
```

**الحل:**
```dart
// استخدم الطريقة الصحيحة
final result = await BasPayFlutter().callBasPay(model: model);
```

### 2. خطأ "Package not found"

**المشكلة:**
```
Could not find package bas_pay_flutter
```

**الحل:**
```yaml
# في pubspec.yaml
dependencies:
  bas_pay_flutter:
    git:
      url: https://github.com/Osamah-Attiah/bas_pay_flutter.git
```

### 3. خطأ "GetStorage not found"

**المشكلة:**
```
"GetStorage" not found. You need to call "Get.put(GetStorage())"
```

**الحل:**
```dart
// في main.dart
void main() {
  runApp(MyApp());
}

class InitialBinding extends Bindings {
  @override
  void dependencies() {
    Get.put(GetStorage());
    Get.put(BasPaymentService());
  }
}
```

### 4. خطأ "User data not found"

**المشكلة:**
```
بيانات المستخدم غير موجودة
```

**الحل:**
```dart
// تأكد من حفظ بيانات المستخدم بالـ key الصحيح
_storage.write('current_user', userData);

// وتأكد من قراءتها بالـ key نفسه
final userData = _storage.read('current_user');
```

## 🌐 مشاكل الشبكة والاتصال

### 1. Connection Timeout

**المشكلة:**
```
Connection timed out
```

**الحل:**
```dart
// زيادة timeout في Flutter
final response = await http.post(
  uri,
  headers: headers,
  body: body,
).timeout(Duration(seconds: 30));
```

### 2. خطأ CORS

**المشكلة:**
```
Access to XMLHttpRequest at '...' from origin '...' has been blocked by CORS policy
```

**الحل:**
```php
// في Laravel، أضف middleware للـ CORS
// أو استخدم package مثل fruitcake/laravel-cors
```

### 3. خطأ SSL في التطبيق

**المشكلة:**
```
HandshakeException: Handshake error in client
```

**الحل:**
```dart
// في Flutter، أضف في android/app/src/main/res/xml/network_security_config.xml
<?xml version="1.0" encoding="utf-8"?>
<network-security-config>
    <domain-config cleartextTrafficPermitted="true">
        <domain includeSubdomains="true">YOUR_BACKEND_URL</domain>
    </domain-config>
</network-security-config>
```

## 🔐 مشاكل المصادقة

### 1. خطأ "Unauthorized"

**المشكلة:**
```
HTTP 401 Unauthorized
```

**الحل:**
```dart
// تأكد من إرسال token صحيح
headers: {
  'Authorization': 'Bearer ${_getAuthToken()}',
}
```

### 2. خطأ "Token expired"

**المشكلة:**
```
Token has expired
```

**الحل:**
```dart
// إعادة تسجيل الدخول
await _authService.refreshToken();
```

## 📊 مشاكل البيانات

### 1. خطأ في تنسيق البيانات

**المشكلة:**
```
Invalid JSON format
```

**الحل:**
```dart
// تأكد من ترميز البيانات بشكل صحيح
body: jsonEncode({
  'amount': amount,
  'order_id': orderId,
  // ... باقي البيانات
}),
```

### 2. خطأ في التحقق من البيانات

**المشكلة:**
```
Validation failed
```

**الحل:**
```php
// في Laravel Controller
$validator = Validator::make($request->all(), [
    'amount' => 'required|numeric|min:0.01',
    'order_id' => 'required|string|max:255',
    // ... باقي القواعد
]);
```

## 🔐 نصائح الأمان

### 1. حماية البيانات الحساسة
```dart
// ❌ خطأ - لا تضع بيانات BAS في Flutter
class PaymentConfig {
  static const String basAppId = 'your_app_id'; // خطأ!
}

// ✅ صحيح - البيانات في الباك اند فقط
// Flutter يحصل فقط على trxToken من الباك اند
```

### 2. التحقق من الأمان
- تأكد من أن بيانات BAS موجودة في الباك اند فقط
- لا تضع أي بيانات حساسة في Flutter
- استخدم HTTPS في الإنتاج
- شفر البيانات المحفوظة محلياً

## 🎯 نصائح عامة

### 1. تسجيل الأخطاء
```dart
// في Flutter
print('🔴 [DEBUG] خطأ: ${e.toString()}');

// في Laravel
Log::error('Payment Error: ' . $e->getMessage());
```

### 2. اختبار API
```bash
# استخدم Postman أو curl لاختبار API
curl -X POST http://localhost:8000/api/payment/initiate \
  -H "Content-Type: application/json" \
  -H "Authorization: Bearer YOUR_TOKEN" \
  -d '{"amount": 1000, "order_id": "test_123"}'
```

### 3. مراقبة الشبكة
```dart
// في Flutter، راقب network requests
print('🔵 [DEBUG] Request URL: $url');
print('🔵 [DEBUG] Request Headers: $headers');
print('🔵 [DEBUG] Response: ${response.body}');
```

### 4. اختبار على أجهزة حقيقية
- اختبر على أجهزة Android و iOS حقيقية
- تأكد من عمل الشبكة على الجهاز
- اختبر مع بيانات حقيقية

## 📞 الدعم الفني

إذا لم تجد حل لمشكلتك:

1. **تحقق من السجلات**: راجع logs في Laravel و Flutter
2. **اختبر API**: استخدم Postman لاختبار endpoints
3. **راجع الديكومنتيشن**: تأكد من اتباع الخطوات بشكل صحيح
4. **تواصل مع الدعم**: BAS Gateway أو فريق التطوير

## 🔄 تحديثات مهمة

- **Laravel SDK**: تأكد من استخدام أحدث إصدار
- **Flutter SDK**: تحقق من التحديثات في GitHub
- **API Endpoints**: قد تتغير URLs مع التحديثات

---

**ملاحظة**: هذا الدليل يتم تحديثه باستمرار. تأكد من مراجعة آخر التحديثات.
