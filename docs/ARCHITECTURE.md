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
  design/                ← الـ tokens، الـ theme، الخطوط، الـ responsive، الخريطة، (1c) المكوّنات
  features/<ميزة>/
    domain/              ← كيانات، واجهات repositories، use cases. Dart صافي: بدون Flutter ولا Dio
    data/                ← DTOs، مصادر البيانات (API)، تنفيذ الـ repositories
    presentation/        ← شاشات، widgets، controllers (Riverpod)
    <ميزة>_providers.dart ← التوصيل: الملف الوحيد اللي بيعرف data وdomain سوا (repositories وuse cases)
  l10n/                  ← app_ar.arb، app_ku.arb، app_en.arb (+ gen/ مولّد، مش بالـ git)
```

- اتجاه الاعتماد: `presentation → domain ← data`. الـ domain ما بيستورد شي من الطبقتين.
- الشاشة ما بتنادي الـ API أبداً: شاشة ← controller ← use case ← repository ← data source.
- مثال كامل: `features/onboarding` (البداية، اللغة، الهاتف، الكود، الاسم، الموقع).
- الاتصال بالباك إند واحد بس: `apiClientProvider` (`core/network/api_client_provider.dart`). لما السيرفر ينهي الجلسة بيزيد `sessionEndedProvider`، والتطبيق بيرجع لتسجيل الدخول.
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

- كل استدعاء للباك إند بطبقة الـ data ملفوف بـ `guard()` (`core/error/guard.dart`؛ `Result` لحاله بـ `result.dart` Dart صافي للـ domain) وبيرجع `Result<T>` (`Ok` أو `Err(Failure)`). ما في exception بيطلع من طبقة الـ data.
- `Failure` نوع مغلق (sealed). كل نوع إله رسالة مترجمة (`failure.message(context.l10n)`).
- الميزة اللي عندها رسالة أدق بتحوّل الـ `Failure` لـ enum خاص فيها بالـ domain (متل `codeProblemOf` → `CodeProblem.wrongCode`)، وإلا الرسالة العامة.
- الجواب الناقص من السيرفر (`requiredText` بـ `core/network/json.dart`) بيصير `UnexpectedFailure`، ولا مرة قيمة فاضية بتمشي.
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

## التصميم (lib/design)

- **الألوان** من `context.palette` بس (`surface`، `textPrimary`، `brand`، `brandStrong`، `danger`…). ممنوع `Color(0x…)` أو `Colors.x` بالشاشات. القيم بـ `tokens/base_colors.dart` حسب `docs/design/stitch-prompts.md`.
- **النصوص** من `context.typo` بس (`display`، `h1`، `h2`، `h3`، `body`، `bodyStrong`، `caption`، `micro`، `button`، `price`، `amount`). ممنوع `fontSize` أو `fontWeight` بالشاشات.
- **المسافات والزوايا والمقاسات** من `Space`، `Radii`، `Sizes` (`tokens/metrics.dart`)، والظلال من `Shadows`.
- **البراند لكل نسخة** وقت البناء: `--dart-define=BRAND_COLOR=#RRGGBB` (واختيارياً `BRAND_STRONG_COLOR`). كل الدرجات (النص فوق الزر، النص الملوّن على الفاتح والغامق) بتنحسب بتباين 4.5:1 على الأقل. الافتراضي ذهبي ليندا.
- **الخطوط** مضمّنة بـ `assets/fonts` (IBM Plex Sans Arabic + IBM Plex Sans، رخصة OFL مسجّلة بقائمة الرخص). العربي والكردي بخط Arabic أولاً، الإنكليزي بـ Latin أولاً.
- **الخريطة**: `mapStyleUrl(brightness:, locale:)` بيختار light/dark وar/en من `MAP_TILES_URL`.

## المكوّنات المشتركة (lib/design/components)

- الشاشات بتنبني من المكوّنات الجاهزة بس (`import '…/design/components/components.dart'`): `AppScaffold`، `AppTopBar`، `AppButton` (primary/secondary/ink/danger/text، مع loading)، `AppIconButton`، `AppListRow`، `SectionHeader`، `EndActionRow` (محتوى + زر نصي بالآخر، الزر أقصاه نص العرض)، `AppTextField`، `PhoneField`، `OtpBoxes`، `AppChoiceChips`، `NumericKeypad`، `MoneyText`، `PlateBadge`، `AppAvatar`، `DriverCard`، `RouteSummary`، `VehicleOptionCard`، `StatusBanner`، `SkeletonView` + `SkeletonBox` (و`SkeletonList`، `SkeletonCard`)، `EmptyState`، `FailureView`، `showAppToast`، `showAppSheet` + `SheetTitle`، `AppBottomNav`.
- **التحميل:** الشاشة اللي بتنطر بيانات بتعرض هيكلها فاضي مع موجة shimmer (`SkeletonView` حوالين شكل الشاشة مبني من `SkeletonBox`)، ولا مرة دائرة بتفتل. الزر اللي بينطر نتيجة كبسته (`AppButton(loading: true)`) بيعرض تلات نقاط بتنط وما بينكبس مرة تانية. الحركتين بيوقفوا إذا الجهاز طالب حركة أقل.
- مكوّن ناقص بينضاف لـ `lib/design/components` (مع مثال بالمعرض)، مش جوّا الميزة.
- `FailureView` و`showAppToast` بياخدوا `Failure` أو رسالتها المترجمة، ولا مرة نص تقني.
- **المبالغ** دايماً بـ `MoneyText` أو `formatMoney`: أرقام غربية، فواصل الآلاف، الرقم معزول LTR، والعملة من الترجمة.
- **أزرار الأيقونة** إلها `semanticLabel` إلزامي (قارئ الشاشة).
- `scripts/check-design-usage.sh` بيرفض بالكود الجديد: `Color(0x…)`، `Colors.x` (إلا `transparent`)، `fontSize`/`fontWeight` برا `design/tokens` و`design/theme`، و`left/right` (`EdgeInsets.only(left:)`، `Alignment.centerLeft`، `TextAlign.left`، `Positioned(left:)`).

## معرض المكوّنات

نسخة debug بس:

```
flutter run --dart-define=SHOW_GALLERY=true --dart-define=API_BASE_URL=https://ride-api.lenda-agency.com
```

بيفتح المعرض بدل التطبيق، مع زرّين لتبديل اللغة (عربي ← كردي ← إنكليزي) والمظهر. `test/features/dev_gallery/gallery_test.dart` بيبنيه كامل على شاشة 390×844 بالثلاث لغات والوضعين، فأي overflow بيفشّل الاختبار.

## Responsive

- عرض الشاشة بـ `context.screenSize` (`compact` < 600، `medium` < 840، `expanded`).
- محتوى كل شاشة ملفوف بـ `ContentWidth`: عرض كامل عالموبايل، وعمود متوسّط أقصاه 560 على الأعرض.
- تكبير الخط بالجهاز محترم بين 0.85× و1.3× (`TextScaleClamp` على مستوى التطبيق).
- ممنوع ارتفاعات أو عروض ثابتة للنصوص؛ المقاسات الثابتة للعناصر التفاعلية بس (`Sizes`).

## الملفات القديمة

`scripts/legacy-files.txt` فيه ملفات ما قبل إعادة البناء. معفية من الفحوص لحد ما تنستبدل، والسطر بينشال لما الملف ينحذف. `lib/core/api/*`، `lib/state/session_storage.dart` و`lib/core/app_config.dart` صاروا مجرد تحويلات للأماكن الجديدة لحد ما الشاشات القديمة تنستبدل.

## قبل كل commit

`check.sh` بيشغّل الـ analyzer عبر `scripts/check-analyzer.sh`: الأخطاء والتحذيرات ممنوعة بكل الكود، والتنبيهات (lints) ممنوعة بالكود الجديد والاختبارات.

```
scripts/check.sh
```
