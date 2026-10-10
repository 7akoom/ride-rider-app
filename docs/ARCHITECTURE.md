# معمارية تطبيق الراكب

هالقواعد إلزامية لكل كود جديد. `scripts/check.sh` بيفحص اللي بينفحص منها تلقائياً، ولازم ينجح قبل أي commit.

## الطبقات (Clean Architecture)

```
lib/
  main.dart              ← سطر واحد: bootstrap()
  app/                   ← تشغيل التطبيق، MaterialApp، شاشة خطأ الإعدادات
  core/                  ← بنية مشتركة بدون أي ميزة
    config/              ← قيم --dart-define والتحقق منها (AppEnv)
    error/               ← Failure، التحويل، الرسائل، Result/guard، المعالج العام
    l10n/                ← اللغات والاتجاه والـ delegates و context.l10n
    network/             ← ApiClient، تجديد التوكن، تحويل أخطاء Dio
    security/            ← التخزين الآمن، منع لقطات الشاشة، إخفاء البيانات بالـ logs
  design/                ← (حزمة 1b/1c) الـ tokens، الـ theme، المكوّنات المشتركة
  features/<ميزة>/
    domain/              ← كيانات، واجهات repositories، use cases. Dart صافي: بدون Flutter ولا Dio
    data/                ← DTOs، مصادر البيانات (API)، تنفيذ الـ repositories
    presentation/        ← شاشات، widgets، controllers (Riverpod)
  l10n/                  ← app_ar.arb، app_ku.arb، app_en.arb (+ gen/ مولّد، مش بالـ git)
```

- اتجاه الاعتماد: `presentation → domain ← data`. الـ domain ما بيستورد شي من الطبقتين.
- الشاشة ما بتنادي الـ API أبداً: شاشة ← controller ← use case ← repository ← data source.
- ميزة ما بتستورد من جوّا ميزة تانية. المشترك بينطلع لـ `core/` أو `design/`.

## حجم الملفات والتكرار

- **حد أقصى 200 سطر للملف** (`scripts/check-file-size.sh`). الملف اللي بيكبر بينقسم حسب المسؤولية.
- widget واحد عام لكل ملف تقريباً؛ الـ widgets الخاصة الصغيرة مسموحة بنفس الملف.
- أي شكل أو منطق بيتكرر مرتين بيصير مكوّن بـ `design/` أو helper بـ `core/`.

## النصوص واللغات

- **ممنوع أي نص ظاهر للمستخدم بالكود.** كل نص بـ `lib/l10n/app_*.arb` بمفتاح، وبينقرا بـ `context.l10n.<key>`. `scripts/check-hardcoded-strings.sh` بيرفض: أي حرف عربي/كردي بالكود (حتى بالتعليقات)، `Text('…')`، و`label/title/hintText/tooltip…: '…'`.
- القالب `app_en.arb` (مع وصف لكل مفتاح). أي مفتاح جديد بينضاف للثلاث ملفات بنفس الـ commit (`test/l10n/arb_parity_test.dart` بيفحص).
- أسماء المفاتيح: `<مكان><شي>` بالـ camelCase، متل `homeWhereTo`، `walletTopUpTitle`، `errorNoConnection`.
- الاتجاه من اللغة: العربي والكردي RTL، الإنكليزي LTR. **ممنوع** `left/right` بالمسافات والمحاذاة: `EdgeInsetsDirectional`، `AlignmentDirectional`، `start/end`.
- لوحات الأرقام، الأرقام، أرقام الهواتف، اللوحات والمبالغ ما بتنعكس.
- الكردي (`ku`، سوراني) نصوصه من `app_ku.arb`؛ نصوص الـ widgets الجاهزة (date picker…) من العربي.
- لغة الطلبات للباك إند (`Accept-Language`) هي لغة التطبيق.

## الأخطاء

- كل استدعاء للباك إند بطبقة الـ data ملفوف بـ `guard()` وبيرجع `Result<T>` (`Ok` أو `Err(Failure)`). ما في exception بيطلع من طبقة الـ data.
- `Failure` نوع مغلق (sealed). كل نوع إله رسالة مترجمة (`failure.message(context.l10n)`).
- الميزة اللي عندها رسالة أدق حسب `BackendFailure.reason` (مثلاً عليه دين) بتعرضها، وإلا الرسالة العامة.
- **ممنوع** عرض رسالة السيرفر أو نص الـ exception أو كود HTTP للمستخدم، بأي لغة.
- الأخطاء غير المتوقعة بتروح لـ `ErrorReporter` (بعد `Redactor`)، مش للشاشة. المعالج العام (`installGlobalErrorHandlers`) بيلقط كل شي فلت، وبيحط `FriendlyErrorWidget` بدل الشاشة الحمرا.

## الأمان

- التوكنات بـ `SessionStorage` (Keystore/Keychain) بس. ممنوع بـ `SharedPreferences` أو الذاكرة الدائمة.
- نسخة الإنتاج: `API_BASE_URL` و`MAP_TILES_URL` لازم https، وإلا التطبيق بيعرض شاشة خطأ الإعدادات وما بيشتغل. Android بيمنع HTTP العادي بالإنتاج (مسموح بنسخة الـ debug بس).
- `allowBackup=false` وقواعد `data_extraction_rules`: بيانات التطبيق ما بتنسخ للسحابة ولا لجهاز جديد.
- الشاشات اللي فيها PIN أو مبالغ أو أكواد OTP ملفوفة بـ `SecureScreen` (بتمنع لقطات الشاشة والتسجيل).
- ممنوع `print`. ممنوع تسجيل توكنات أو أرقام هواتف أو إيميلات، حتى بالـ debug (`Redactor`).
- بناء الإنتاج:
  ```
  flutter build apk --release --obfuscate --split-debug-info=build/symbols \
    --dart-define=API_BASE_URL=https://… --dart-define=MAP_TILES_URL=https://… \
    --dart-define=APP_NAME=…
  ```
- تثبيت الشهادة (certificate pinning): مؤجّل لسيرفر الإنتاج، لأنه شهادات Cloudflare بتتجدد تلقائياً.

## Responsive (حزمة 1b)

- كل المقاسات من الـ tokens، والنصوص بتحترم تكبير الخط بالجهاز (مع سقف).
- على التابلت والشاشات العريضة: المحتوى بعرض أقصى ومتوسّط.

## الملفات القديمة

`scripts/legacy-files.txt` فيه ملفات ما قبل إعادة البناء. معفية من الفحوص لحد ما تنستبدل، والسطر بينشال لما الملف ينحذف. `lib/core/api/*`، `lib/state/session_storage.dart` و`lib/core/app_config.dart` صاروا مجرد تحويلات للأماكن الجديدة لحد ما الشاشات القديمة تنستبدل.

## قبل كل commit

`check.sh` بيشغّل الـ analyzer عبر `scripts/check-analyzer.sh`: الأخطاء والتحذيرات ممنوعة بكل الكود، والتنبيهات (lints) ممنوعة بالكود الجديد والاختبارات.

```
scripts/check.sh
```
