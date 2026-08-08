#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$ROOT/api"

if [[ ! -f .env ]]; then
  cp .env.example .env
fi

npm install
npx prisma generate

echo "CampusX API dependencies are ready."
echo "Start infrastructure with: docker compose up -d postgres redis minio"
echo "Then run: cd api && npx prisma migrate dev --name init && npm run seed && npm run start:dev"
