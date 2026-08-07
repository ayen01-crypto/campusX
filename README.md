# CampusX

**Everything campus. One app.**

CampusX is a Flutter-first university ecosystem for students to buy and sell items, find rentals and roommates, discover tutors and internships, buy event tickets, book services, find campus businesses, and claim student deals.

## Included in this MVP

- Modern responsive Flutter UI for mobile and web
- Onboarding, authentication UI, university and interest selection
- Marketplace with local listings and listing creation
- Rentals, roommates, tutors, internships, events, services, businesses and deals
- Saved items
- Offline-first chat persistence
- Notifications, profile and settings
- Dark mode
- Riverpod state management
- go_router navigation
- SharedPreferences persistence
- Dio API client boundary
- Secure-storage boundary for future auth tokens
- GitHub Codespaces dev container
- GitHub Actions CI

## Run in GitHub Codespaces

The Codespace automatically installs Flutter stable, creates missing platform folders, and runs `flutter pub get`.

```bash
flutter run -d web-server --web-hostname 0.0.0.0 --web-port 3000
```

Open forwarded port **3000** from the Codespaces Ports panel.

## Local Android

```bash
flutter pub get
flutter run
```

## Architecture

```text
lib/
├── app/       app + router
├── core/      models, state, persistence, theme, API boundary
├── data/      seeded MVP data
├── screens/   product screens
└── widgets/   reusable UI
```

## Backend integration

This repository currently ships as a complete frontend/MVP with local/offline data. The API boundary is intentionally isolated so NestJS/PostgreSQL services can be connected without rebuilding the UI.
