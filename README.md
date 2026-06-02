# قرآني Qurani

<div align="center" dir="rtl">

تطبيق قرآني مجاني بالكامل، بدون إعلانات وبدون اشتراكات، يهدف إلى خدمة كتاب الله كصدقة جارية.

</div>

> Qurani is a free Quran app — no ads, no paid features, no tracking. Built as sadaqah jariyah.

---

## ✨ الميزات | Features

- 📖 قراءة القرآن الكريم برسم عثماني (QCF)
- 🎧 الاستماع للتلاوات مع تتبع كلمة بكلمة
- 🎙️ اختيار القرّاء من قائمة موسّعة
- 🔍 البحث الذكي في السور والآيات
- 🔖 العلامات المرجعية (Bookmarks)
- 📝 الملاحظات والتعليقات على الآيات
- 📿 الختمة وتتبع التقدّم في القراءة
- 📚 التفسير
- 🕌 أوقات الصلاة بناءً على الموقع
- 🧭 اتجاه القبلة
- 🤲 الأذكار والتنبيهات المحلية
- 🌙 دعم الوضع الليلي
- 🇸🇦 دعم اللغة العربية واتجاه RTL بالكامل
- 📴 العمل دون اتصال للقراءة الأساسية
- 🏠 ودجات الشاشة الرئيسية (آية اليوم، الصلاة، الذكر)

---

## 🚧 حالة المشروع | Project Status

- المشروع حالياً تحت التخصيص والتحضير للإطلاق العام.
- تمت إزالة Firebase بالكامل، ولا يوجد أي تتبّع أو تحليلات.
- التطبيق يحترم الخصوصية: **لا إعلانات، لا اشتراكات، لا مزايا مدفوعة.**
- مرحلة ما قبل الإصدار (pre-release).

---

## 🛠️ التقنيات | Tech Stack

- **Flutter** — إطار العمل متعدد المنصات
- **Dart** — لغة البرمجة
- **BLoC + Cubit** — إدارة الحالة
- **Hive** — التخزين المحلي السريع
- **flutter_local_notifications** + **awesome_notifications** — التنبيهات المحلية
- **just_audio** + **just_audio_background** — تشغيل التلاوات في الخلفية
- **home_widget** + **workmanager** — ودجات الشاشة الرئيسية والتحديثات الدورية
- **adhan_dart** + **hijri** — حساب مواقيت الصلاة والتقويم الهجري
- **flutter_qiblah** + **flutter_compass_v2** — اتجاه القبلة
- **go_router** — التوجيه
- **خطوط وأصول قرآنية محلية** (QCF, KFGQPC, Indopak…) للعمل دون إنترنت

> ❌ لا يستخدم التطبيق Firebase أو أي خدمة تتبع/تحليلات.

---

## 🚀 التشغيل محلياً | Run Locally

### المتطلبات

- Flutter SDK ≥ 3.10
- Dart SDK ≥ 3.0
- جهاز/محاكي Android أو iOS أو متصفّح Chrome للويب

### التشغيل

```bash
git clone <your-fork-url>
cd al_furkan_quran_local

flutter clean
flutter pub get
flutter analyze
flutter run -d chrome --web-port=8801
```

### تشغيل على منصّات أخرى

```bash
flutter devices                # عرض الأجهزة المتاحة
flutter run -d linux           # سطح المكتب لينكس
flutter run -d <device-id>     # Android / iOS
```

---

## 📦 معلومات التطبيق | App Identity

| | |
|---|---|
| **Arabic name** | قرآني |
| **English name** | Qurani |
| **Application ID** | `com.ziad.qurani` |
| **Internal package** | `qurani` |
| **URL scheme** | `qurani://` |
| **Developer** | المهندس زياد |

---

## 📁 هيكل المشروع | Project Structure

```
lib/
├── main.dart
└── src/
    ├── core/            # BLoC, services, audio, notifications, storage
    ├── features/        # ميزات معزولة (audio, prayer, qibla, …)
    ├── screen/          # الشاشات
    ├── widget/          # المكوّنات القابلة لإعادة الاستخدام
    ├── resources/       # موارد القرآن (نص، ميتاداتا، تفاسير)
    ├── theme/           # الثيمات والألوان
    ├── constants/       # ثوابت السلاسل والأحجام
    └── utils/           # أدوات مساعدة
assets/
├── branding/            # شعارات Qurani
├── fonts/               # خطوط قرآنية وخطوط واجهة
├── quran_script/        # نصوص المصحف
├── meta_data/           # ميتاداتا السور والآيات
└── wahy/                # أذكار، تفسير السعدي
```

---

## 🤝 المساهمة | Contributing

التطبيق صدقة جارية — أي مساهمة في تحسين الجودة أو إصلاح الأخطاء أو تحسين تجربة المستخدم مرحّب بها.

1. افتح **Issue** لمناقشة التغيير المقترح.
2. أنشئ فرعاً من `main`.
3. أرسل **Pull Request** مع وصف واضح.

---

## 📜 الترخيص | License

هذا المشروع متفرّع (fork) من مشروع مفتوح المصدر مرخّص تحت **MIT License**. يُرجى الرجوع إلى ملف [LICENSE](LICENSE) في جذر المستودع للاطلاع على نص الترخيص الكامل وحقوق المؤلفين الأصليين.

التخصيصات والتعديلات المضافة في هذا الفرع (Qurani) متاحة بدورها كصدقة جارية.

---

## 🧑‍💻 المطوّر | Developer

**المهندس زياد**

---

<div align="center" dir="rtl">

**اللهم اجعل هذا العمل خالصاً لوجهك الكريم، وانفع به المسلمين.**

</div>
