# CampusX

**Everything campus. One app.**

CampusX is an offline-first university ecosystem built with Flutter and NestJS. Students can buy and sell items, find rentals and roommates, discover tutors and internships, buy event tickets, book services, find campus businesses, claim student deals and communicate through real-time chat.

## Stack

### Client

- Flutter + Dart
- Riverpod
- go_router
- Dio
- SharedPreferences + secure storage
- Socket.IO client
- Image/file picking
- Responsive mobile and web UI

### API

- NestJS + TypeScript
- Prisma 7
- PostgreSQL
- Socket.IO WebSockets
- JWT + bcrypt authentication
- S3-compatible object storage through MinIO locally
- Redis local infrastructure prepared for scaling/cache work

## Product modules

- Authentication and university onboarding
- Marketplace
- Rentals
- Roommates
- Tutors
- Internships
- Events and ticketing
- Services
- Campus businesses
- Student deals
- Saved listings
- Offline-first + real-time messaging
- Notifications
- Profiles and reputation
- Media uploads
- Booking/application/ticket/deal transaction APIs
- Development payment lifecycle with production-safe provider boundaries

## Codespaces setup

The committed dev container installs Flutter Stable, Node 22 and Docker tooling, then installs Flutter and API dependencies.

If your Codespace existed before the latest configuration, rebuild it from the Command Palette:

```text
Codespaces: Rebuild Container
```

## Start the full local development stack

From the repository root:

```bash
bash tool/dev_stack.sh
```

This starts PostgreSQL, Redis and MinIO, generates Prisma Client, creates the development migration when needed, seeds the database and starts the NestJS development server.

The API is exposed locally at:

```text
http://localhost:4000/v1
```

Health check:

```text
http://localhost:4000/v1/health
```

### Demo seed accounts

```text
Student
student@campusx.local
CampusX123!

Provider
provider@campusx.local
CampusX123!
```

These credentials are development seed data only.

## Run Flutter in a second terminal

For a local browser environment:

```bash
flutter run \
  -d web-server \
  --web-hostname 0.0.0.0 \
  --web-port 3000 \
  --dart-define=API_BASE_URL=http://localhost:4000/v1
```

For GitHub Codespaces, expose port **4000**, copy its forwarded HTTPS URL from the Ports panel, and pass it to Flutter with `/v1` appended:

```bash
flutter run \
  -d web-server \
  --web-hostname 0.0.0.0 \
  --web-port 3000 \
  --dart-define=API_BASE_URL=https://YOUR-4000-FORWARDED-URL/v1
```

Open forwarded port **3000** to use CampusX.

### Development-only ticket payment testing

Mock payment confirmation is disabled in production. To expose the development test button in Flutter:

```bash
flutter run \
  -d web-server \
  --web-hostname 0.0.0.0 \
  --web-port 3000 \
  --dart-define=API_BASE_URL=http://localhost:4000/v1 \
  --dart-define=ENABLE_MOCK_PAYMENTS=true
```

Real MTN MoMo and Airtel Money collections must not be enabled until their production credentials and callback adapters are configured.

## Database commands

```bash
cd api

npx prisma generate
npx prisma migrate dev
npm run seed
npx prisma studio
```

## Repository structure

```text
campusX/
├── .devcontainer/           Codespaces full-stack environment
├── .github/workflows/       Flutter + API CI
├── api/
│   ├── prisma/              schema and seed
│   └── src/
│       ├── auth/
│       ├── engagement/
│       ├── listings/
│       ├── messaging/
│       ├── notifications/
│       ├── payments/
│       ├── prisma/
│       ├── universities/
│       ├── uploads/
│       └── users/
├── lib/
│   ├── app/
│   ├── core/
│   ├── data/
│   ├── screens/
│   └── widgets/
├── tool/
│   ├── bootstrap_api.sh
│   ├── bootstrap_platforms.sh
│   └── dev_stack.sh
└── docker-compose.yml
```

## Offline-first messaging

CampusX writes outgoing messages locally first. Each message receives a client-generated unique ID. When connectivity returns, REST synchronization retries the same ID, while Socket.IO provides live delivery when connected. The backend enforces `clientId` uniqueness so reconnection retries do not create duplicate messages.

## Payments

CampusX never treats a paid event ticket as valid before payment confirmation. Paid ticket requests create a pending payment record first. The included mock provider is development-only and is explicitly blocked when `NODE_ENV=production`. Real payment providers plug into this lifecycle through verified provider callbacks.

## CI

GitHub Actions validates both stacks:

- Flutter dependency bootstrap
- Dart formatting normalization for validation
- `flutter analyze`
- `flutter test`
- Flutter web build
- Node dependency installation
- Prisma Client generation
- Prisma schema validation
- NestJS TypeScript build
