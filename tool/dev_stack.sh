#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$ROOT"

docker compose up -d postgres redis minio

cd "$ROOT/api"
if [[ ! -f .env ]]; then
  cp .env.example .env
fi

npm install
npx prisma generate
npx prisma migrate dev --name init
npm run seed

cat <<'EOF'

CampusX infrastructure is ready.

API:     http://localhost:4000/v1
Health:  http://localhost:4000/v1/health
Flutter: run from another terminal with:
  flutter run -d web-server --web-hostname 0.0.0.0 --web-port 3000 --dart-define=API_BASE_URL=http://localhost:4000/v1

Starting API development server now...
EOF

npm run start:dev
