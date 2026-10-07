# Yatrix

Group rides, treks, hikes and motorbike meetups. Find a ride, ask to join, chat with other riders and groups, and explore hidden places that locals share and review.

This monorepo holds two apps:

| Folder | What | Stack |
| --- | --- | --- |
| [`mobile/`](mobile/) | The app (Android, iOS, web, desktop) | Flutter · Riverpod · go_router |
| [`server/`](server/) | The REST and realtime API | Node.js · TypeScript · Fastify · Prisma · PostgreSQL |

## Getting started

**Backend** (details in [server/README.md](server/README.md)):

```bash
cd server
cp .env.example .env     # point DATABASE_URL at your Postgres
npm install
npm run db:setup         # create the database, migrate, load demo data
npm start                # http://localhost:4000 · API docs at /docs
```

**Mobile app:**

```bash
cd mobile
flutter pub get
flutter run
```

The app still runs on its built-in dummy data, so the two aren't connected yet. Connecting them means swapping only the app's data layer:

- The API uses the app's own field names and enum values.
- The server is seeded with the same demo riders, rides, posts, chats and groups.

Both use the same demo logins: `demo@bikersync.app` / `biker123` for a rider and `admin@gmail.com` / `Test@1234` for the admin.

## Repository layout

```
ride_sangai/
├── mobile/    Flutter app (lib/, android/, ios/, …)
└── server/    API (src/, prisma/, test/, …)
```

Run Flutter commands from `mobile/` and npm commands from `server/`.
