# بناء تطبيق الراكب (Android و iOS)

كل مستثمر إله نسخة مستقلة: اسم، لون، معرّف بالمتجر، وسيرفر. ولا ملف بيتغيّر بين النسخ؛ كلشي بيجي من أوامر البناء.

## قبل أي بناء

```
scripts/check.sh
```

لازم ينجح. بعدين:

| القيمة | وين | مثال |
|---|---|---|
| عنوان الـ API | `--dart-define=API_BASE_URL` | `https://ride-api.example.com` (https إجباري بالإنتاج) |
| سيرفر الخرائط | `--dart-define=MAP_TILES_URL` | `https://ride-tiles.example.com` |
| اسم النسخة جوّا التطبيق | `--dart-define=APP_NAME` | `Taxi` |
| لون البراند | `--dart-define=BRAND_COLOR` | `#F3D59A` |
| معرّف Android | متغيّر البيئة `ORG_GRADLE_PROJECT_appId` | `com.investor.taxi` |
| الاسم تحت الأيقونة (Android) | `ORG_GRADLE_PROJECT_appLabel` | `Taxi` |

الافتراضي إذا ما انحطّ شي: `com.lenda.ride.rider` و`Ride`.

**المعرّف ما بيتغيّر بعد أول نشر بالمتجر.** اختاره مرة لكل مستثمر.

## Android

### مفتاح التوقيع (مرة وحدة لكل مستثمر)

```
keytool -genkey -v -keystore ~/keys/investor-upload.jks -keyalg RSA -keysize 2048 \
  -validity 10000 -alias upload
```

وبعدين `android/key.properties` (ممنوع بالـ git، موجود بـ `.gitignore`):

```
storePassword=…
keyPassword=…
keyAlias=upload
storeFile=/home/USER/keys/investor-upload.jks
```

بدون هالملف، نسخة الـ release بتنوقّع بمفتاح الـ debug، والـ Play Store بيرفضها.
**احفظ نسخة من المفتاح وكلمات السر برّا الجهاز:** إذا ضاع، ما في تحديثات للتطبيق.

### البناء

```
ORG_GRADLE_PROJECT_appId=com.investor.taxi ORG_GRADLE_PROJECT_appLabel=Taxi \
flutter build appbundle --release --obfuscate --split-debug-info=build/symbols \
  --dart-define=API_BASE_URL=https://ride-api.example.com \
  --dart-define=MAP_TILES_URL=https://ride-tiles.example.com \
  --dart-define=APP_NAME=Taxi --dart-define=BRAND_COLOR=#F3D59A
```

الناتج: `build/app/outputs/bundle/release/app-release.aab` بيترفع على Play Console.
لتجربة على موبايل: نفس الأمر بـ `flutter build apk` بدل `appbundle`.

احفظ مجلد `build/symbols` لكل إصدار: بدونه ما فينا نقرا تقارير الأعطال.

## iOS (على Mac)

مرة وحدة:
1. Xcode وحساب Apple Developer.
2. `cd ios && pod install` (Flutter بيعملها لحاله أول بناء).
3. افتح `ios/Runner.xcworkspace` ← Runner ← Signing & Capabilities:
   - Team: حساب المستثمر أو حسابك.
   - Bundle Identifier: معرّف المستثمر (الافتراضي `com.lenda.ride.rider`).
   - Display Name بتبويب General: اسم النسخة.

البناء:

```
flutter build ipa --release --obfuscate --split-debug-info=build/symbols \
  --dart-define=API_BASE_URL=https://ride-api.example.com \
  --dart-define=MAP_TILES_URL=https://ride-tiles.example.com \
  --dart-define=APP_NAME=Taxi --dart-define=BRAND_COLOR=#F3D59A
```

الناتج بـ `build/ios/ipa/` بيترفع عبر Transporter أو Xcode ← Organizer.

جاهز بالمشروع:
- سطر شرح الموقع (`NSLocationWhenInUseUsageDescription`).
- اللغات: عربي، كوردي (`ckb`)، إنكليزي.
- الآيفون عمودي بس.
- `ITSAppUsesNonExemptEncryption = false` (التطبيق بيستخدم https العادي بس)، فما في سؤال تشفير بكل رفع.

## الإشعارات (لما نفعّلها)

- Android: `android/app/google-services.json` من Firebase، بنفس معرّف التطبيق.
- iOS: `ios/Runner/GoogleService-Info.plist`، ومفتاح APNs بـ Firebase، وتفعيل Push Notifications بـ Xcode.
- بدونهم التطبيق بيشتغل عادي بدون إشعارات (الخطأ بينسجّل وما بيوقف شي).

## ملاحظات

- منع لقطات الشاشة (شاشة الكود، الـ PIN، المبالغ) بيشتغل على Android. iOS ما بيسمح بمنعها.
- الموبايلات عمودي بس على النظامين؛ الآيباد بيدور.
