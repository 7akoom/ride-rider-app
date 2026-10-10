# تطبيق الراكب — برومبتات Google Stitch

آخر تحديث: 10 تشرين الأول 2026

## طريقة الاستخدام

1. افتح مشروع جديد بـ Stitch، نوع **Mobile App**.
2. بأول رسالة الصق **Design Brief** + **الدفعة 1** مع بعض.
3. لكل دفعة جديدة بنفس المشروع: الصق **الدفعة** لحالها (الـ brief محفوظ بسياق المشروع). إذا لاحظت إنه بلّش يخرب الألوان أو الخط، الصق الـ brief مرة تانية قبل الدفعة.
4. كل التصميم **عربي RTL ووضع فاتح** أول شي. بعد ما نخلص الثمان دفعات:
   - **برومبت الوضع الغامق** على 4-5 شاشات أساسية بس.
   - **برومبت فحص LTR** على 2-3 شاشات بس، لنتأكد إنه الانعكاس صحيح. الباقي بينعكس تلقائياً بـ Flutter.
5. صدّر كل دفعة (Figma أو HTML) وابعتلي ياها، وأنا بنفّذ بـ Flutter.

البرومبتات بالإنكليزي لأنه Stitch بيفهمها أدق، والنصوص اللي جوّا الشاشات بالعربي.

---

## Design Brief (الصقه بأول جلسة)

```
DESIGN BRIEF — Rider app for a ride-hailing platform (white-label)

PRODUCT
A ride-hailing app for riders in Iraq (Erbil first). Single country, single currency per deployment: Iraqi Dinar, written "د.ع" after the number (e.g. "6,000 د.ع"). The app is sold to different operators under their own brand, so the design must NOT depend on one brand colour: the gold accent below is a swappable brand token. Everything else (neutrals, status colours, type, spacing) is fixed.

LANGUAGES & DIRECTION
Arabic (default, RTL), Kurdish Sorani (RTL), English (LTR). Design every screen in Arabic RTL: text right-aligned, back arrow on the RIGHT pointing right (→), chevrons in list rows point LEFT (‹), primary actions and progress flow right-to-left, bottom-sheet handles centred. Numbers, prices, phone numbers, plate numbers and times stay Western digits (0-9) and LTR inside RTL text. Media/playback icons and the map itself never mirror.

VISUAL DIRECTION
Premium, calm, confident — "night drive" luxury, not playful. Map-first: the map is the canvas, content lives in rounded bottom sheets that snap to 3 heights. Generous whitespace, few strong elements per screen, one primary action per screen. No gradients except a very subtle gold glow on the wallet balance card. No stock photos; vehicle images are clean 3D-style side views of generic cars (no brand logos).

COLOUR TOKENS — LIGHT MODE (design in this first)
- background #F7F6F2 (warm off-white)
- surface #FFFFFF (cards, sheets)
- surface-2 #F1EFE9 (inputs, chips, secondary buttons)
- border #E6E2D8
- text-primary #05070F, text-secondary #4A5060, text-tertiary #8A90A0
- brand #F3D59A (gold, fills only: primary buttons, selected chip, active tab indicator, selected vehicle card border). Text/icons ON gold are always #05070F, never white.
- brand-strong #8A6A2B (gold for text, links and icons on light backgrounds)
- ink #05070F (dark navy: app bar on wallet/home header, "driver on the way" header, secondary filled buttons with white text)
- info / route #2563EB (route line on map, links, info badges)
- success #15803D, warning #B45309, danger #DC2626 (with 10% tint backgrounds for banners)
- pickup marker = ink circle with white person icon; drop-off marker = gold square with ink flag icon.

COLOUR TOKENS — DARK MODE (later)
background #05070F, surface #0D1220, surface-2 #151B2C, border rgba(255,255,255,0.08), text-primary #FFFFFF, text-secondary #9BA1B0, text-tertiary #6B7280, brand #F3D59A (same, text on it #05070F), brand-strong #F3D59A, info #60A5FA, success #4ADE80, warning #FBBF24, danger #F87171. Map style dark.

TYPOGRAPHY
IBM Plex Sans Arabic for Arabic/Kurdish, IBM Plex Sans for Latin.
Display 32/40 bold (big numbers: ETA, balance, price), H1 24/32 bold, H2 20/28 semibold, H3 17/24 semibold, Body 15/22 regular, Caption 13/18, Micro 11/14 medium. Prices and balances use tabular figures.

SHAPE & SPACING
4-pt grid; screen side padding 16; card padding 16; gap between sections 24.
Radius: buttons 14, cards 16, bottom sheets 24 (top corners), chips full pill, inputs 12, small icon buttons 12 (44×44 square, surface with 1px border).
Elevation: only bottom sheets and floating map buttons get a soft shadow (0 8 24 rgba(5,7,15,0.10)); cards are flat with 1px border.

COMPONENTS
- Primary button: full width, 52 high, gold fill, ink text, semibold 16.
- Secondary button: full width, 52 high, surface with 1px border, ink text.
- Destructive: text-only danger colour, or danger-outline button for "cancel trip".
- Top bar: 44×44 back button (→ in RTL) on the right, title right-aligned, optional action button on the left.
- Bottom navigation (3 tabs, ink background in light mode too, white icons, active = gold icon + label): الرئيسية، الأنشطة، الحساب.
- List row: 56-64 high, icon in 40×40 surface-2 rounded square on the right, title + caption, chevron ‹ on the left.
- Chips/filters: pill, surface-2; selected = ink fill with white text.
- Vehicle option card: 3D car image on the left, name + seats + ETA on the right, price bold; selected = 2px gold border + soft gold tint.
- Driver card: driver photo (circle 48), name, ★ rating, car model + colour, plate number in a bordered "plate" badge (ink border, bold), round buttons: call and chat.
- Status banners: tinted background + icon + one line + optional action.
- Inputs: 52 high, surface-2, label above, helper/error text below.
- Amount entry screens: huge centred number (Display 48) with "د.ع" small, custom numeric keypad.
- Empty states: simple line illustration in brand-strong + one sentence + one button.
- Icons: Phosphor-style outline 24px, 1.5 stroke; filled variant only for the active bottom-nav tab.

MAP
Self-hosted OpenStreetMap vector style, light grey roads, minimal POIs, Arabic labels. No Google logo anywhere. Floating map controls: 44×44 white rounded squares (recentre, menu). Route line 5px info blue. Driver car = small top-down car icon that rotates with heading.

STATES TO SHOW WHERE RELEVANT
loading (skeleton shimmer, not spinners), empty, error with retry, disabled buttons (surface-2 + text-tertiary).

DEVICE
Android phone, 390×844 frame, status bar visible, gesture nav bar at the bottom.
```

---

## الدفعة 1 — الدخول والتسجيل

```
Using the design brief, create these 6 screens (Arabic, RTL, light mode):

1. Splash — ink background (#05070F), centred app logo placeholder (gold rounded mark + wordmark "رايد"), small gold glow behind it, nothing else.

2. Language picker — title "اختر لغتك", three large selectable cards: "العربية", "کوردی", "English", each with a radio on the left; selected card has gold border. Primary button "متابعة" at the bottom. Small line under the cards: "يمكنك تغييرها لاحقاً من الإعدادات".

3. Phone number — top: back button. Title "أدخل رقم هاتفك", subtitle "سنرسل لك رمز تحقق عبر واتساب". Phone input with country part fixed on the left of the field (flag of Iraq + "+964", not editable) and the number field "7XX XXX XXXX". Below: checkbox line "أوافق على الشروط وسياسة الخصوصية" (links in brand-strong). Primary button "إرسال الرمز" disabled until valid. Numeric keypad open.

4. OTP — title "أدخل رمز التحقق", subtitle "أرسلنا رمزاً من 6 أرقام إلى +964 750 123 4567" with a small "تعديل" link. Six separate digit boxes (LTR order even in RTL), the active one with gold border. Below: "إعادة الإرسال بعد 0:45" in text-tertiary, which becomes a link "إعادة إرسال الرمز". Show also an error state variant: boxes with danger border + "الرمز غير صحيح، حاول مرة أخرى".

5. Your name — title "شو اسمك؟", subtitle "هيك رح يشوفك الكابتن". Two inputs: "الاسم الأول", "اسم العائلة". Optional input "البريد الإلكتروني (اختياري)". Primary button "ابدأ".

6. Location permission — full-screen friendly illustration of a map pin over a simple city skyline (brand-strong line art), title "اسمح بالوصول إلى موقعك", body "نستخدم موقعك لتحديد نقطة الانطلاق بدقة وإيجاد أقرب كابتن." Primary "السماح بالوصول إلى الموقع", secondary text button "ليس الآن".
```

---

## الدفعة 2 — الرئيسية والحجز

```
Using the design brief, create these 6 screens (Arabic, RTL, light mode):

1. Home — full-screen map with the user's blue location dot. Top: menu-less; floating 44×44 buttons: notifications bell with a red dot (top-left) and recentre (above the sheet, left). A small banner pinned under the status bar ONLY if location is off ("تم إيقاف الوصول إلى الموقع — فعّله لتجربة أفضل" + button "تفعيل"). Bottom sheet (half height) containing:
   - Greeting "مساء الخير، أحمد" (H2).
   - Big search field "لوين رايح؟" with a magnifier, and on its left a small pill button "الآن ⌄" (to schedule).
   - Horizontal row of saved places shortcuts: "المنزل" (home icon), "العمل" (briefcase), "فندق" + a "＋ إضافة" chip.
   - Two small tiles side by side: "الرصيد 12,500 د.ع" (wallet icon) and "عروضك: خصم 30% على رحلتك القادمة" (tag icon, gold tint).
   - Bottom navigation: الرئيسية (active)، الأنشطة، الحساب.

2. Where to — top: back button. A card with two connected fields (vertical dotted line between a pickup dot and a drop-off square): "الموقع الحالي" and "أدخل وجهتك" (focused, keyboard open). On the left of the card a round "＋" button to add a stop. Below: chips "مقترحة" (selected) "المحفوظة" "أماكن مميزة". List of places, each row: category icon, name, short address, distance on the left ("7.5 كم"), and a ⋮ menu. Rows: "المنزل", "فندق روتانا أربيل", "مطار أربيل الدولي", "فاميلي مول". Then two action rows with ‹ : "حدّد على الخريطة" (map icon) and "ابحث في مدينة أخرى" (globe icon).

3. Where to — with stops — same card now with 4 fields: pickup, "محطة 1: سوق القلعة" (with × to remove), "محطة 2: أضف محطة", destination "فاميلي مول". Caption under the card: "يمكنك إضافة محطتين كحد أقصى". Primary button "تم".

4. Pick on map — full map, a large fixed centre pin (gold square drop-off marker with a shadow), floating back button. Bottom card: place icon, name "جمعية إقليم كردستان للسياحة", address two lines, heart icon to save. Primary button "تأكيد الوجهة".

5. Choose ride — map at top 45% showing route (blue line) from pickup to drop-off, two floating labels on the map: pickup "الانطلاق خلال 5 دقائق" and drop-off "الوصول حوالي 12:34 م". Bottom sheet:
   - Warning-tint banner with lightning icon: "الطلب مرتفع الآن، الأسعار أعلى قليلاً".
   - Vehicle option cards: "اقتصادي — 4 مقاعد — 5 دقائق — 3,000 د.ع" (selected), "مريح — 4 مقاعد — 7 دقائق — 3,750 د.ع". Show a small strikethrough old price + new price on the selected one when a coupon applies, with a tiny success caption "تم تطبيق BTS26".
   - Row of three compact controls: payment method "نقداً ⌄" (cash icon), "كوبون" (tag icon), "لشخص آخر" (person icon).
   - Bottom: a square secondary button with a clock icon (schedule) on the left and the primary button "اطلب اقتصادي" taking the rest.

6. Payment & coupon sheet (modal bottom sheet over screen 5) — title "طريقة الدفع": options "نقداً" (selected), "المحفظة — الرصيد 12,500 د.ع". Under a divider: coupon input "أدخل كود الخصم" with button "تطبيق", and a state showing an applied coupon chip "BTS26 — خصم 30%" with × .
```

---

## الدفعة 3 — جدولة، شخص آخر، والبحث عن كابتن

```
Using the design brief, create these 5 screens (Arabic, RTL, light mode):

1. Schedule a ride (bottom sheet) — title "احجز لوقت لاحق". Day selector chips: "اليوم" "غداً" "السبت 12" ... ; time wheel picker (hour : minute, 5-min steps, ص/م). Caption: "بين 30 دقيقة و7 أيام من الآن · سنبدأ البحث عن كابتن قبل الموعد بـ 10 دقائق". Primary "تأكيد الموعد".

2. Ride for someone else (bottom sheet) — title "الرحلة لشخص آخر", body "سنرسل للكابتن اسم ورقم الراكب". Inputs "اسم الراكب" and phone with "+964". Toggle row "أنا الراكب" (off). Primary "حفظ".

3. Searching for a captain — map zoomed on pickup with an animated pulsing gold radar ring around the pickup marker. Bottom sheet: H1 "نبحث عن كابتن قريب…", caption "عادةً أقل من دقيقة", thin indeterminate progress bar in gold, a summary row (pickup → drop-off, vehicle "اقتصادي", price "3,000 د.ع", "نقداً"), and a danger-outline button "إلغاء الطلب".

4. No captain found — same layout, illustration of an empty road, H2 "ما لقينا كابتن متاح حالياً", body "جرّب مرة أخرى أو اختر فئة أخرى". Primary "حاول مرة أخرى", secondary "تغيير الفئة".

5. Scheduled ride confirmed — success check illustration, H2 "تم حجز رحلتك", card with date/time "السبت 12 تشرين الأول · 8:30 ص", pickup, destination, vehicle, estimated price. Buttons: primary "تم", text danger "إلغاء الحجز".
```

---

## الدفعة 4 — أثناء الرحلة

```
Using the design brief, create these 6 screens (Arabic, RTL, light mode):

1. Captain on the way — map 50% top: car icon on the blue route heading to pickup, floating label at pickup "الانطلاق خلال 4 دقائق". Floating top buttons: back (right), "الأمان" pill with shield icon (centre, info colour), share (left). Bottom sheet:
   - Caption "كابتنك في الطريق", Display "4 دقائق".
   - Driver card: car image, "تويوتا كورولا · بيج", plate badge "A25626 22", driver photo, "سالم سليمان ★ 4.9", round buttons call + chat (chat with a small unread dot).
   - Section "تفاصيل الرحلة": pickup and destination rows with an edit pencil on destination, button "＋ إضافة محطة".
   - Payment row "نقداً · 3,000 د.ع".
   - Danger text button at the bottom "إلغاء الرحلة".

2. Captain arrived — same structure, header turns ink with white text: "وصل الكابتن", caption "الانتظار المجاني ينتهي خلال 2:41" with a small circular timer in gold. After free time show a warning-tint row "بدأ احتساب الانتظار: 250 د.ع/دقيقة".

3. On trip — map with route to destination, progress along the route. Sheet: Display "12:34 م" with caption "الوصول المتوقع", destination name, chips for stops ("محطة 1 ✓", "محطة 2"), driver mini-card (photo, name, plate, call/chat), two equal buttons: "مشاركة الرحلة" (share icon) and "طوارئ SOS" (danger fill, white text).

4. Safety sheet (opened from the "الأمان" pill) — title "مركز الأمان". Rows: "مشاركة تفاصيل الرحلة مع شخص تثق به", "الاتصال بالطوارئ" (danger, opens confirm), "الإبلاغ عن مشكلة أمان". Below, a confirm dialog state for SOS: "هل تريد إرسال تنبيه طوارئ؟ سنخبر فريق الأمان ونشارك موقعك." buttons "إرسال التنبيه" (danger) and "إلغاء".

5. Chat with captain — top bar with driver photo, name, plate, call button. Message bubbles (RTL): the rider's own bubbles sit on the LEFT in ink with white text, the captain's bubbles on the RIGHT in surface-2. Quick reply chips above the input: "أنا قادم", "أنا عند المدخل", "تأخرت دقيقتين". Input "اكتب رسالة…" with send button (gold). Small note at the top of the chat: "لا تشارك معلومات الدفع".

6. Cancel ride — bottom sheet: H2 "ليش بدك تلغي؟" radio list: "الكابتن تأخر"، "غيّرت رأيي"، "طلبت بالغلط"، "الكابتن طلب الإلغاء"، "سبب آخر" (with text field). Warning-tint banner: "سيتم احتساب رسوم إلغاء 1,000 د.ع لأن الكابتن في الطريق منذ أكثر من دقيقتين". Buttons: danger "إلغاء الرحلة", secondary "الرجوع للرحلة".
```

---

## الدفعة 5 — نهاية الرحلة

```
Using the design brief, create these 4 screens (Arabic, RTL, light mode):

1. Trip completed — small static map with the travelled route at top. H1 "وصلت بالسلامة" and Display price "3,000 د.ع" with caption "نقداً — ادفع للكابتن". Driver mini-row (photo, name). Card "تفاصيل الأجرة": أجرة الرحلة، الانتظار، خصم الكوبون (success, negative), الازدحام, الإجمالي (bold). Primary "تقييم الرحلة", text button "عرض الفاتورة".

2. Rate & tip — driver photo large centred, "كيف كانت رحلتك مع سالم؟", 5 large stars (gold when filled, 4 selected). Quick tags chips that appear after rating: "قيادة آمنة"، "سيارة نظيفة"، "لطيف"، "يعرف الطريق". Text area "أضف تعليقاً (اختياري)". Tip section: "أضف إكرامية للكابتن" with chips "500" "1,000" "2,000" "مبلغ آخر" (selected chip ink), caption "الإكرامية تذهب كاملة للكابتن من محفظتك". Primary "إرسال".

3. Receipt — top bar "الفاتورة" with share/download icon. Trip id, date and time, route summary (pickup, stops, destination with times), distance and duration, vehicle and driver, full fare breakdown, payment method, tip line. Bottom: "تحتاج مساعدة بهذه الرحلة؟" row ‹ .

4. Thank-you / tip sent — success check, "شكراً! وصلت إكراميتك لسالم", primary "العودة للرئيسية".
```

---

## الدفعة 6 — المحفظة

```
Using the design brief, create these 8 screens (Arabic, RTL, light mode):

1. Wallet home — ink header card with a subtle gold glow, caption "رصيد المحفظة", Display "12,500 د.ع". If rider owes money: danger-tint banner under it "عليك 1,000 د.ع رسوم إلغاء — ستُخصم من أول شحن" . Four action tiles in a row (3D-style icons): "شحن"، "إرسال"، "طلب مال"، "قسيمة". Section "الطلبات الواردة" with one card: "محمد طلب منك 5,000 د.ع" + buttons "دفع" / "رفض". Section "آخر الحركات" + link "الكل ←": rows with icon, title, date, amount (+ in success, − in text-primary). Bottom nav hidden (pushed screen).

2. Transactions — filter chips "الكل" "إيداع" "سحب" "إكراميات" "استردادات"; list grouped by date headers ("الخميس 17 أيلول") with day-end balance on the left of the header; row types: "شحن عبر زين كاش" +, "دفع رحلة" −, "إرسال إلى محمد" −, "استرداد رحلة" +, "قسيمة" +. Top-left action "كشف حساب".

3. Statement — date range selector (chips "30 يوم", "3 أشهر", "مخصص"), summary card: رصيد أول الفترة، مجموع الداخل، مجموع الخارج، رصيد آخر الفترة; list below.

4. Top up — amount entry: huge "5,000" with "د.ع", quick chips "5,000" "10,000" "25,000", provider card "زين كاش" (selected, logo placeholder) with caption "سيتم تحويلك لصفحة زين كاش لإتمام الدفع". Keypad. Primary "متابعة". Note line "الحد الأدنى 1,000 د.ع".

5. Top up result — two variants side by side: success ("تم شحن 5,000 د.ع" + new balance) and failed ("فشل الدفع" + reason "تم إلغاء العملية من زين كاش" + "حاول مرة أخرى").

6. Send money — step A: search "ابحث باسم أو رقم هاتف", recent recipients avatars row, contacts list, "إضافة رقم جديد". Step B: recipient avatar + name + number, huge amount entry, "أضف ملاحظة", caption "التحويل فقط لأرقام مسجّلة في التطبيق". Step C: PIN entry bottom sheet "أدخل رمز المحفظة" with 4 dots and keypad, link "نسيت الرمز؟". Step D: success "تم إرسال 5,000 د.ع إلى HK".

7. Request money — amount entry, toggle "من شخص محدد" / "رابط مفتوح"; specific: pick contact; open: shows a QR code card + code "K7XM-2PQR" + "مشاركة الرابط" button, caption "صالح لمدة 72 ساعة".

8. Redeem voucher (bottom sheet) — title "استخدم قسيمة", body "أدخل رمز القسيمة لإضافة رصيد إلى محفظتك", input formatted "XXXX-XXXX-XXXX-XXXX", primary "استخدام"; and a success state "تمت إضافة 10,000 د.ع". Plus "Wallet PIN setup" screen: "أنشئ رمز المحفظة" 4 boxes, then "أكّد الرمز".
```

---

## الدفعة 7 — الأنشطة والحساب

```
Using the design brief, create these 8 screens (Arabic, RTL, light mode):

1. Activity — title "الأنشطة", tabs with icons: "الكل" (active, gold underline), "الرحلات", "المدفوعات". Section "القادمة" with a scheduled ride card (clock icon, date, destination, "إلغاء"). Then list grouped by date: trip rows (car image, "رحلة إلى فندق", "اقتصادي", price on left, status caption: "مكتملة" success / "ملغاة" danger), money rows ("إرسال إلى محمد"). Bottom nav: الأنشطة active.

2. Trip details — static map with route, date/time, driver + car + plate, pickup/destination with times, fare breakdown, rating you gave, buttons "تحتاج مساعدة؟" and "إعادة الرحلة".

3. Account — header: avatar (photo or initials), name "أحمد كريم", phone, edit pencil. Groups with section titles:
   "حسابك": المعلومات الشخصية، العناوين المحفوظة، المحفظة، الإشعارات (with unread count badge "3"), الكوبونات والعروض.
   "الدعم": مركز المساعدة، تذاكري، مركز الأمان.
   "التفضيلات": اللغة (العربية)، المظهر (تلقائي)، المدينة (أربيل، العراق).
   "الخصوصية": تحميل بياناتي، حذف الحساب (danger).
   Footer: "الشروط والأحكام" link + app version. Bottom nav: الحساب active.

4. Personal info — avatar with camera badge, rows with ‹ : الاسم، رقم الهاتف، البريد الإلكتروني (with "＋ أضف" chip if empty), الجنس، تاريخ الميلاد، الجنسية. Show the gender bottom sheet ("ذكر"/"أنثى") and date picker as small inset states.

5. Saved addresses — promo card (ink, camera 3D icon, gold "جديد" badge): "أضف صور المدخل — ساعد الكابتن يلاقيك أسرع". List: المنزل، العمل، فندق (each with ⋮). Primary "إضافة عنوان جديد". Caption "حتى 20 عنواناً".

6. Add / edit address — small map with pin at top (tap to adjust), label chips "المنزل" "العمل" "آخر" (with name input when "آخر"), inputs "اسم البناية" "الطابق / الشقة", "ملاحظة للكابتن" (textarea, e.g. "البوابة الخلفية"), photo slot "صورة المدخل (اختياري)" with dashed border and camera icon. Primary "حفظ العنوان".

7. Notifications — list of notification cards with icon by type (trip, wallet, promo, support), title, body, time, unread ones with a gold dot and slightly tinted background; top-left action "تعليم الكل كمقروء". Empty state variant.

8. Preferences — Language sheet (3 options with radios), Appearance sheet ("فاتح", "داكن", "تلقائي حسب النظام"), City picker list with search ("أربيل" selected, "السليمانية", "دهوك", "بغداد").
```

---

## الدفعة 8 — الدعم والخصوصية

```
Using the design brief, create these 8 screens (Arabic, RTL, light mode):

1. Help center — title "مركز المساعدة", search field "ابحث في المساعدة", card "مساعدة بخصوص آخر رحلة" (trip mini-row with date and price + ‹), categories grid of 6 tiles with icons: "الرحلات"، "الدفع والمحفظة"، "الحساب"، "الأمان"، "المفقودات"، "العروض". Row "تذاكري (2 مفتوحة)" ‹.

2. Help article — breadcrumb category, H1 title, readable body text with numbered steps, then "هل كانت هذه المقالة مفيدة؟" with 👍 / 👎 outline buttons, and at the bottom a secondary button "تواصل معنا".

3. New ticket — "اختر الرحلة" selector (trip card), category radio list ("الكابتن طلب مبلغ أعلى"، "شي ضايع بالسيارة"، "مشكلة بالدفع"، "سلوك الكابتن"، "غير ذلك"), textarea "اشرح المشكلة", attachments row (up to 5 thumbnails + add tile), primary "إرسال".

4. My tickets — list with status pills: "مفتوحة" (info), "بانتظار ردك" (warning), "محلولة" (success), "مغلقة" (neutral); each with ticket subject, trip reference, last update.

5. Ticket conversation — header with subject + status pill; system line "تم فتح التذكرة · 10:04"; agent bubbles (right, surface-2, with "فريق الدعم" name) and user bubbles (left, ink); an attachment bubble with image thumbnail; input with paperclip and send. When resolved: banner at the bottom "تم حل المشكلة؟" with 1–5 star CSAT row and "إرسال التقييم".

6. Download my data — explanation "نجهّز ملفاً فيه بياناتك (الملف الشخصي، الرحلات، المحفظة، التذاكر، الإشعارات). بنبعتلك إشعار لما يجهز.", primary "طلب نسخة من بياناتي", list of previous requests with status ("قيد التجهيز"، "جاهز — تنزيل · ينتهي خلال 6 أيام"، "منتهي"), caption "طلب واحد كل 24 ساعة".

7. Delete account — warning illustration, H2 "حذف الحساب", list of what happens: "سيتوقف حسابك فوراً"، "لديك 30 يوماً للتراجع بتسجيل الدخول"، "بعدها تُحذف بياناتك الشخصية نهائياً". Blocking state card (danger tint) "لا يمكن الحذف الآن: لديك رحلة مجدولة قادمة" with link. Balance-loss state (warning tint) "ستخسر رصيدك 12,500 د.ع" with checkbox "أفهم أنني سأخسر رصيدي". Primary danger "متابعة" → OTP step (reuse the OTP screen style) titled "تأكيد الحذف".

8. Shared states — a set of small frames: skeleton loading of a list, network error full-screen ("ما في اتصال بالإنترنت" + "إعادة المحاولة"), service area error ("هذه المنطقة خارج نطاق الخدمة حالياً"), app update required, and a toast/snackbar example ("تم حفظ العنوان").
```

---

## بعد الدفعات

### الوضع الغامق (على 5 شاشات)

```
Create dark-mode versions of these screens using the DARK MODE tokens from the brief (same layout, nothing else changes): Home, Choose ride, Captain on the way, Wallet home, Account. Map uses a dark style. Gold stays #F3D59A with #05070F text on it.
```

### فحص الاتجاه LTR (على 3 شاشات)

```
Create English LTR versions of: Where to, Captain on the way, Wallet home. Mirror the layout: back arrow on the LEFT pointing left, chevrons point right, text left-aligned, the pickup/destination connector on the left. Prices stay "3,000 IQD". Keep the same tokens and components.
```

---

## ملاحظات للتنفيذ (لـ Claude)

- اسم "رايد" بشاشة البداية placeholder؛ الاسم واللوغو من إعدادات النسخة.
- زر المحادثة مع الكابتن مصمم، بس **ما إله backend بعد** (قرار 10 تشرين الأول: منعمله لاحقاً). بالتطبيق يظهر لما يجهز الباك إند.
- كل الأرقام والأسعار بالبرومبتات أمثلة؛ الحدود الحقيقية من الباك إند (الشحن 1,000 – 1,000,000، الإكرامية 250 – 25,000 خلال 72 ساعة، الحجز 30 دقيقة – 7 أيام، محطتين، 20 عنوان).
- الوضع الفاتح بالـ Flutter: نفس الـ tokens كـ ThemeExtension، والـ brand قابل للتبديل من إعدادات النسخة.
