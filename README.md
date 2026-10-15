# Metro Institute Mobile App

> Platform edukasi digital untuk mentee Metro Institute.  
> Dibangun dengan Flutter (Android) sebagai bagian dari project magang CPMK PAM.

---

## 🧱 Arsitektur

Project ini menggunakan **Clean Architecture** dengan pemisahan layer:

```
lib/
├── core/                     # Shared infrastructure
│   ├── constants/            # AppConstants, AppRoutes
│   ├── di/                   # Dependency Injection (get_it)
│   ├── errors/               # AppException, typed errors
│   ├── network/              # ApiClient (Dio + interceptors)
│   ├── router/               # AppRouter (go_router + ShellRoute)
│   ├── theme/                # AppColors, AppTheme, AppTextStyles, AppSpacing
│   └── utils/                # AppFormatters, validators
│
├── data/                     # Data layer
│   ├── datasources/
│   │   ├── remote/           # REST API data sources (Dio)
│   │   └── local/            # SharedPreferences / FlutterSecureStorage
│   ├── models/               # JSON serializable data models
│   └── repositories/         # Repository implementations
│
├── domain/                   # Business logic layer (pure Dart)
│   ├── entities/             # Domain entities
│   ├── repositories/         # Repository interfaces (abstract)
│   └── usecases/             # Use cases / interactors
│
├── presentation/             # UI layer
│   ├── common/
│   │   └── widgets/          # Shared widgets, MainShell, SplashScreen
│   └── features/
│       ├── auth/             # Login, Register
│       ├── basecamp/         # Tab 1 — Dashboard utama mentee
│       ├── learn/            # Tab 2 — Eksplorasi & kelas
│       ├── challenge/        # Tab 3 — Tantangan & kuis
│       ├── certificate/      # Tab 4 — Sertifikat
│       ├── profile/          # Tab 5 — Profil & settings
│       ├── skill_test/       # Onboarding skill assessment
│       └── notification/     # Push notification list
│
├── app.dart                  # MaterialApp.router entry
└── main.dart                 # main() — init Firebase + DI
```

---

## 📱 Navigasi

Tidak ada sidebar. Menggunakan **Bottom Navigation Bar** (5 tab) via `go_router` ShellRoute:

| Tab | Nama | Route |
|-----|------|-------|
| 1 | Basecamp | `/basecamp` |
| 2 | Belajar | `/learn` |
| 3 | Tantangan | `/challenge` |
| 4 | Sertifikat | `/certificate` |
| 5 | Profil | `/profile` |

---

## 🎨 Design System

- **Primary:** `#018556` (sinkron dengan website)
- **Accent:** `#FAE653`
- **Font:** Inter (Google Fonts)
- **Radius card/button:** `12px`

Lihat `lib/core/theme/app_colors.dart`

---

## 🔌 Integrasi Backend

- **API:** Express.js backend yang sama dengan website → `http://10.0.2.2:5000/api/v1` (emulator)
- **Auth:** JWT via `flutter_secure_storage`
- **Notifikasi:** Firebase Cloud Messaging (FCM) — push notification only, tidak untuk penyimpanan data
- **Database:** PostgreSQL via Railway (melalui backend API, bukan langsung)

---

## 🚀 Cara Menjalankan

```bash
# Install dependencies
flutter pub get

# Run di emulator
flutter run

# Build APK debug
flutter build apk --debug
```

---

## ⚠️ Aturan Penting

- **DILARANG** menyimpan data user/kelas di Firebase — sesuai Aturan 3d
- Semua data CRUD melalui backend API Express.js / PostgreSQL
- Firebase **hanya** untuk push notification (FCM)

---

*Metro Institute © 2026 — Project Magang*
