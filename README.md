<div align="center">

<img src="https://img.shields.io/badge/Flutter-3.x-02569B?style=for-the-badge&logo=flutter&logoColor=white" alt="Flutter"/>
<img src="https://img.shields.io/badge/Dart-3.x-0175C2?style=for-the-badge&logo=dart&logoColor=white" alt="Dart"/>
<img src="https://img.shields.io/badge/Platform-Android%20%7C%20iOS-lightgrey?style=for-the-badge&logo=android&logoColor=white" alt="Platform"/>
<img src="https://img.shields.io/badge/License-MIT-green?style=for-the-badge" alt="License"/>

# 🎓 DIU CGPA Tracker

**A beautifully crafted Flutter app for Daffodil International University (DIU) students to track, analyze, and plan their academic journey.**

[Features](#-features) • [Screenshots](#-screenshots) • [Getting Started](#-getting-started) • [Architecture](#-architecture) • [Tech Stack](#-tech-stack) • [Contributing](#-contributing)

</div>

---

## ✨ Overview

**DIU CGPA Tracker** is a mobile-first academic companion built specifically for DIU's **CSE department** students. It takes your semester-by-semester SGPA history, handles academic exceptions (retakes, backlogs, course failures), and computes your accurate **Cumulative GPA (CGPA)** — all stored **100% offline** on your device.

Whether you're a regular student following the standard curriculum or an irregular student with a custom course plan, this app adapts to your situation and keeps your academic data at your fingertips.

---

## 🚀 Features

### 📊 Smart CGPA Engine
- Automatically calculates your **Cumulative GPA** from semester results
- Applies an **Exception Engine** that accounts for:
  - ✅ Course retakes / grade improvements
  - ✅ Failed courses and backlogs
  - ✅ Irregular student course plans

### 🧭 Guided Registration Wizard
A 5–6 step onboarding wizard that collects everything it needs to model your academic path:
| Step | Regular | Irregular |
|------|---------|-----------|
| Academic Identity | ✅ | ✅ |
| Semester Progress | ✅ | ✅ |
| SGPA History | ✅ | ✅ |
| Academic Exceptions | ✅ | ✅ |
| Course Plan Review | ❌ | ✅ |
| Review & Confirm | ✅ | ✅ |

### 📈 Academic Dashboard
- **Hero CGPA Card** — large, glanceable cumulative GPA with color-coded performance tier
- **Degree Progress** — credit completion, semesters done vs remaining, and Regular/Irregular track badge
- **Latest Result Panel** — SGPA for your most recently completed semester
- **Next Semester Plan** — auto-generated course plan for the upcoming semester
- **Academic Tools Grid** — quick-launch cards for future tools (Retake Analyzer, Target CGPA, Semester Planner, What-if Sandbox)

### 📜 CGPA Details Screen
- Full semester history with expandable cards
- Per-semester course list with course code, title, credit, and failed-course highlighting
- Color-coded SGPA badges (Outstanding / Very Good / Good / Needs Improvement)

### 🔒 Fully Offline
All data is persisted locally using **Hive** — no account, no server, no internet needed.

---

## 📱 Screenshots

> _Coming soon — run the app and take your own!_

---

## 🛠 Getting Started

### Prerequisites

| Tool | Version |
|------|---------|
| Flutter | ≥ 3.x (SDK `^3.12.0`) |
| Dart | ≥ 3.x |
| Android Studio / Xcode | Latest |

### Installation

```bash
# 1. Clone the repository
git clone https://github.com/jaherunhasanrimon/diu_cgpa_tracker.git
cd diu_cgpa_tracker

# 2. Install dependencies
flutter pub get

# 3. Generate Hive adapters (code generation)
dart run build_runner build --delete-conflicting-outputs

# 4. Run on your device / emulator
flutter run
```

> **Tip:** Run `flutter doctor` first to make sure your environment is properly configured.

### Build for Release

```bash
# Android APK
flutter build apk --release

# iOS (requires macOS + Xcode)
flutter build ios --release
```

---

## 🏗 Architecture

The project follows a **feature-first clean architecture** pattern:

```
lib/
├── main.dart                   # App entry point
├── app.dart                    # MaterialApp + Riverpod ProviderScope
├── core/
│   ├── config/                 # App-wide configuration
│   ├── constants/              # Shared constants
│   ├── router/                 # GoRouter navigation (app_router.dart)
│   ├── storage/                # Hive initialization (HiveService)
│   ├── theme/                  # AppColors, AppTextStyles, AppSpacing
│   └── utils/                  # Helper utilities
├── features/
│   ├── auth/                   # Onboarding & registration wizard
│   ├── academic/               # CSE curriculum source & course models
│   ├── academic_exception/     # Exception model, engine, repository
│   ├── cgpa/                   # CGPA engine, repository, providers, UI
│   ├── dashboard/              # Main dashboard screen & widgets
│   ├── onboarding/             # First-run onboarding screens
│   └── splash/                 # Splash screen
└── shared/
    └── widgets/                # Reusable UI components (PrimaryButton, etc.)
```

Each feature follows a layered structure:

```
feature/
├── data/
│   ├── models/         # Hive-annotated data models
│   └── sources/        # Local data sources (curriculum data, etc.)
├── domain/             # Business logic engines (CgpaEngine, ExceptionEngine)
├── providers/          # Riverpod providers
├── repository/         # Data access layer
└── presentation/       # Screens & widgets
```

---

## 🧰 Tech Stack

| Category | Library | Purpose |
|----------|---------|---------|
| **Framework** | Flutter | Cross-platform UI |
| **State Management** | [flutter_riverpod](https://pub.dev/packages/flutter_riverpod) `^2.5.1` | Reactive state management |
| **Navigation** | [go_router](https://pub.dev/packages/go_router) `^14.2.0` | Declarative routing |
| **Local Storage** | [hive](https://pub.dev/packages/hive) + [hive_flutter](https://pub.dev/packages/hive_flutter) | Fast offline key-value storage |
| **Fonts** | [google_fonts](https://pub.dev/packages/google_fonts) | Outfit & Inter typefaces |
| **Animations** | [flutter_animate](https://pub.dev/packages/flutter_animate) | Micro-animations & transitions |
| **Utilities** | [equatable](https://pub.dev/packages/equatable), [uuid](https://pub.dev/packages/uuid), [intl](https://pub.dev/packages/intl) | Value equality, IDs, localization |
| **Code Gen** | [build_runner](https://pub.dev/packages/build_runner), [hive_generator](https://pub.dev/packages/hive_generator) | Hive type adapter generation |

---

## 📐 How CGPA Is Calculated

The `CgpaEngine` uses the standard weighted-average formula:

```
CGPA = Σ(SGPA_i × Credit_i) / Σ(Credit_i)
```

Before calculation, the `ExceptionEngine` adjusts semester results:
- **Retake wins:** If a course was retaken and improved, the higher grade replaces the lower one in the relevant semester's effective credit-weighted score.
- **Failed courses:** Their credits are excluded from the completed-credit count.
- **Blocked courses:** Courses blocked by prerequisites are tracked separately for the semester plan.

---

## 🗂 Supported Intakes / Curriculum

Currently the **CSE curriculum source** supports DIU's trimester-based (`Tri`) and semester-based (`Spring`, `Fall`, `Summer`) intake structures. The `CseCurriculumSource` maps each intake to the appropriate semester-course plan used for:
- Degree progress tracking (total curriculum credits)
- Per-semester course listing in the CGPA Details screen
- Automatic next-semester plan generation

---

## 🤝 Contributing

Contributions are welcome! Please follow these steps:

1. **Fork** the repository
2. **Create** a feature branch: `git checkout -b feature/my-awesome-feature`
3. **Commit** your changes: `git commit -m 'feat: add my awesome feature'`
4. **Push** to the branch: `git push origin feature/my-awesome-feature`
5. **Open** a Pull Request

Please make sure to run `flutter analyze` and `flutter test` before submitting a PR.

---

## 📋 Roadmap

- [ ] **Retake Analyzer** — suggest which courses to retake for the most CGPA gain
- [ ] **Target CGPA Calculator** — plan future semester SGPAs to hit a desired CGPA
- [ ] **Semester Planner** — credit-load planner for upcoming semesters
- [ ] **What-if Sandbox** — simulate "what if" grade scenarios
- [ ] **PDF Export** — export CGPA report as a shareable PDF
- [ ] **Dark Mode** — full dark theme support
- [ ] **Multi-department** — extend curriculum support beyond CSE

---

## 📄 License

This project is licensed under the **MIT License** — see the [LICENSE](LICENSE) file for details.

---

<div align="center">

Made with ❤️ for DIU students &nbsp;·&nbsp; Built with Flutter

</div>
