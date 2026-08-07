# CampusX Architecture

CampusX uses a Flutter-first layered architecture designed to keep the MVP runnable offline while allowing production services to be attached incrementally.

## Layers

- `app/` owns application bootstrapping and navigation.
- `core/` owns shared models, persistence, state, theme and the API boundary.
- `data/` contains seeded MVP data used while production endpoints are being built.
- `screens/` contains feature surfaces for the campus ecosystem.
- `widgets/` contains reusable UI components.

## Offline-first behavior

User-created listings, saved items, onboarding choices, theme preference and chat messages are persisted locally. Chat messages are written locally first and carry a pending state before the simulated sync acknowledgement.

## Production integration path

The next backend phase can replace seeded data with repositories backed by NestJS/PostgreSQL while retaining the same UI and Riverpod state boundaries. Authentication tokens are isolated behind secure storage and HTTP calls behind Dio.
