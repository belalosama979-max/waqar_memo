<p align="center"><img src="assets/brand/logo_primary_light.png" width="520" alt="الوقار"></p>

# الوقار — إدارة حلقات التسميع

تطبيق عربي بالكامل (RTL) لإدارة حلقات تحفيظ القرآن الكريم على أندرويد و iOS (الهواتف
والأجهزة اللوحية): تسجيل التسميع واحتساب النقاط، متابعة الطلاب، لوحات الصدارة،
الإحصاءات، والتقارير — مع فصل تام بين قسمي الذكور والإناث مفروض من الخادم.

An Arabic-only Flutter app for managing Quran recitation circles, backed by Firebase.

## المزايا

- **شاشة بداية متحركة، ٣ شاشات تعريفية، شاشة ترحيب**، وتسجيل دخول للمعلمين (اختيار القسم ثم الاسم وكلمة المرور) وللإدارة (البريد وكلمة المرور).
- **كلمة مرور مؤقتة** «الاسم الأول + 123» يُلزَم المعلم بتغييرها عند أول دخول (يُتحقق منها في الخادم).
- **لوحة المعلم:** بطاقات الطلاب (الاسم، مجموع النقاط، آخر تسميع وتاريخه، تسجيل تسميع، الملف الشخصي) مع البحث والفرز والتصفية.
- **تسجيل التسميع:** جزء (٣٠ جزءاً) أو سورة (١١٤ سورة بترتيب المصحف)، التقييم (ممتاز جداً ٦٠، ممتاز ٤٠، جيد جداً ٢٥، لم يسمع ٠، رجع في التسميع ١٠)، «كمية إضافية»، وحساب فوري لمجموع الجلسة، ومنع التكرار.
- **السجل الكامل** بخط زمني، ويحتفظ باسم المعلم وقت التسميع حتى بعد نقل الطالب.
- **لوحتا صدارة منفصلتان** (طلاب المعلم / طلاب القسم) مع منصة لأفضل ثلاثة.
- **الملف الشخصي للطالب** مع رسوم بيانية لتقدم النقاط وتوزيع التقييمات.
- **لوحة الإدارة:** إدارة المعلمين (إضافة، تعديل، حذف، إيقاف، إعادة تعيين الدخول)، إدارة الطلاب (إضافة، تعديل، نقل، حذف)، سجل التسميع، تعديل قيم النقاط، الإعلانات، والإحصاءات اليومية/الأسبوعية/الشهرية وأفضل الطلاب والمعلمين.
- **العمل دون اتصال:** ذاكرة محلية، طابور للتسميعات غير المرسلة، ومزامنة تلقائية مع شريط حالة عربي.
- **الإشعارات** عبر Firebase Cloud Messaging (إعلانات، وتنبيهات إنجاز الطلاب).
- **التصدير:** تقارير PDF عربية للطالب ولوحات الصدارة، وملفات Excel، والمشاركة والطباعة.

## التقنيات

Flutter · Riverpod 3 · GoRouter · Freezed/json_serializable · Firebase Auth · Cloud
Firestore (offline persistence) · Cloud Functions · Cloud Messaging · App Check ·
Storage · fl_chart · pdf/printing · excel · flutter_secure_storage · shared_preferences.

## البدء السريع

```bash
flutter pub get
dart run build_runner build --delete-conflicting-outputs --force-jit
cd functions && npm install
npx firebase emulators:start --project demo-alwaqar     # ثم في نافذة أخرى:
node scripts/seed-emulator.js
cd .. && flutter run --dart-define-from-file=env/emulator.json
```

> على ويندوز: مسار المجلد العربي يعطّل بعض الأدوات — راجع [docs/DEVELOPMENT.md](docs/DEVELOPMENT.md).

## التوثيق

| | |
|---|---|
| [docs/FIREBASE_SETUP.md](docs/FIREBASE_SETUP.md) | إعداد Firebase، نموذج البيانات، قواعد الأمان، الدوال |
| [docs/DEVELOPMENT.md](docs/DEVELOPMENT.md) | التطوير المحلي، المحاكيات، الاختبارات، المعمارية، العمل دون اتصال |
| [docs/RELEASE.md](docs/RELEASE.md) | توقيع أندرويد وبناء APK/AAB، وبناء iOS |
| [docs/BRAND.md](docs/BRAND.md) | الهوية البصرية والألوان والخطوط والأصول |

## الأمان

لا توجد أي مفاتيح أو بيانات اعتماد في المستودع: إعدادات Firebase تُمرَّر وقت البناء من
`env/firebase.json` (مستبعد من git)، ومفاتيح التوقيع في `android/key.properties`
(مستبعد). جميع عمليات الصلاحيات تتم عبر Cloud Functions وقواعد Firestore.

## الترخيص

الخطوط Amiri و Tajawal مرخّصة بـ SIL OFL 1.1 (انظر `assets/fonts/`).
