# Yatrix API

Backend for the Yatrix mobile app. It covers group rides, treks, hikes and motorbike meetups, plus join requests, community posts, direct messages, groups, Explore (places shared by locals, with reviews), notifications and an admin dashboard.

**Stack:** Node.js 22 · TypeScript · [Fastify 5](https://fastify.dev) · [Prisma 7](https://www.prisma.io) · PostgreSQL · TypeBox (validation and OpenAPI) · Argon2id · JWT · WebSockets · Vitest

---

## Quick start

You need Node.js 22.12 or later and a PostgreSQL server (version 13 or later; 18 is recommended).

```bash
cd server
cp .env.example .env          # set DATABASE_URL to your Postgres
npm install                   # also generates the Prisma client
npm run db:setup              # create the database, run migrations, load demo data
npm start                     # build, apply migrations, start on http://localhost:4000
```

- Interactive API docs: **http://localhost:4000/docs** (OpenAPI JSON at `/docs/json`)
- Health checks: `GET /health` (liveness) and `GET /health/ready` (checks the database)
- For development with auto-reload, use `npm run dev`.

**Starter account** (created by `npm run db:seed`, which also adds the default home banners; riders, rides and posts come from real use):

| Email | Password | Who |
| --- | --- | --- |
| `admin@gmail.com` | `Test@1234` | Superadmin (change with `SEED_SUPERADMIN_EMAIL` / `SEED_SUPERADMIN_PASSWORD`) |

If you don't have a local Postgres, `docker compose up -d db` starts one on `localhost:5432` that matches `.env.example`.

## Scripts

| Command | What it does |
| --- | --- |
| `npm start` | Build, apply pending migrations, start the server |
| `npm run dev` | Start with auto-reload (tsx watch) |
| `npm run build` | Generate the Prisma client and compile to `dist/` |
| `npm run start:prod` | Apply migrations and start the built server (the Dockerfile uses this) |
| `npm run db:create` | Create the database named in `DATABASE_URL` if it doesn't exist |
| `npm run db:migrate` | Apply pending migrations (`prisma migrate deploy`) |
| `npm run db:migrate:dev` | Create a new migration after editing `schema.prisma` (needs `SHADOW_DATABASE_URL`) |
| `npm run db:seed` | Load demo data (skipped if users already exist) |
| `npm run db:reset` | Drop everything, re-run migrations and re-seed (development only) |
| `npm run db:studio` | Browse the data in Prisma Studio |
| `npm test` | Run the tests against a separate `*_test` database |
| `npm run check` | Typecheck, lint and test (run before pushing) |

---

## Architecture

The code is layered. Each layer only calls the one below it:

```
HTTP request
  → routes/        path, method, schema and access rule → controller method
  → controllers/   read the request, call a service, set the HTTP response and status code
  → services/      business rules, authorization, transactions, notifications
  → repositories/  all database access (Prisma); no business rules
  → PostgreSQL     constraints and triggers guard the data rules
```

```
server/
├── prisma/
│   ├── schema.prisma          # data model (single source of truth)
│   ├── migrations/            # SQL migrations (generated, plus hand-written constraints and triggers)
│   ├── seed.ts                # demo data that mirrors the app's dummy data
│   └── seed-data/texts.json   # long texts copied from the app (bios, posts, messages)
├── src/
│   ├── server.ts              # entry point: config → app → listen → jobs → graceful shutdown
│   ├── app.ts                 # buildApp(): plugins, middlewares, services, routes (tests use it too)
│   ├── config/env.ts          # typed, validated environment settings
│   ├── constants/             # enums (same names as the Dart enums) and display labels
│   ├── db/prisma.ts           # Prisma client; UnitOfWork for transactions and after-commit hooks
│   ├── routes/                # one file per area; index.ts mounts them under /api/v1
│   ├── controllers/           # one class per area; handlers are arrow methods
│   ├── services/              # business logic; index.ts builds and wires every service
│   ├── repositories/          # Prisma queries
│   ├── schemas/               # TypeBox request/response schemas and per-route schema maps
│   ├── middlewares/           # authentication, error handler, security, API docs
│   ├── realtime/              # WebSocket hub, plus optional Postgres LISTEN/NOTIFY fan-out
│   ├── jobs/                  # background jobs (ride reminders, cleanup)
│   ├── types/                 # Fastify type extensions; typed Req/Rep helpers
│   ├── utils/                 # errors, pagination, passwords, tokens, storage, validation and more
│   └── generated/prisma/      # generated Prisma client (git-ignored; `npm install` creates it)
├── scripts/create-database.ts
└── test/                      # integration tests (Fastify inject against a real Postgres)
```

### Adding an endpoint

1. **Schema:** add the request and response TypeBox schemas, and a route entry, in `src/schemas/<area>.schema.ts`.
2. **Repository:** add the Prisma query in `src/repositories/<area>.repository.ts`.
3. **Service:** add the business logic in `src/services/<area>.service.ts`. Throw `AppError`s from `utils/errors.ts`.
4. **Controller:** add a handler typed with `Req<typeof schemas.x>` in `src/controllers/<area>.controller.ts`.
5. **Route:** register it in `src/routes/<area>.routes.ts`. Set `config: { auth: 'none' | 'optional' }` only if it must be public.
6. **Test:** add a case in `test/`.

A brand-new area also needs its repository and service wired up in `src/services/index.ts`, and its route file mounted in `src/routes/index.ts`.

### Key design decisions

- **Secure by default.** Every route requires a valid access token unless it opts out with `config.auth`. Every route in `routes/admin.routes.ts` is automatically admin-only.
- **Sessions are checked on every request.** Access tokens are short-lived JWTs (15 minutes) that carry a session id. Logging out, logging out everywhere, changing a password and removing an account all take effect immediately. Each refresh token works only once and is replaced on use; reusing an old one ends the session, in case the token was stolen.
- **One schema for validation, output and docs.** Fastify compiles the TypeBox schemas into fast validators and serializers. Only fields declared in a response schema are sent, so nothing leaks by accident. The same schemas generate the OpenAPI docs.
- **The database enforces the rules.** Triggers maintain the counters (followers, likes, comments, group members, ride participants), so they stay correct even when a cascading delete removes rows. CHECK constraints guard ride capacity, self-follows and similar rules. Approving a request locks the ride row, so two approvals at once can't overfill a ride.
- **Side effects run after commit.** A notification is written in the same transaction as the action that caused it. Realtime pushes are queued with `afterCommit`, so clients never see data from a rolled-back transaction.
- **Cursor pagination everywhere.** Lists return `{ items, nextCursor }`; pass `cursor=<nextCursor>` to get the next page. Pages stay stable when new rows arrive, and deep pages stay fast.
- **Reads shaped for the app.** `GET /home` returns the whole Home screen in one request, and `GET /me/badges` returns all the header counts. Each list item says how it relates to the viewer (`joinStatus`, `isLiked`, `isFollowing`, `isJoined`, `isMe`).

---

## API conventions

- The base path is **`/api/v1`**. Requests and responses are JSON. Send `Authorization: Bearer <accessToken>`.
- **Field names are camelCase and match the Dart entities** (`meetingPoint`, `organizerAvatarUrl`, `participantCount`, …), so `fromJson` maps fields one to one.
- **Enum values match the Dart enum names** (`hillClimb`, `multiDayTrek`, `requestApproved`), so `RideType.values.byName(json['rideType'])` works.
- **Nullability matches the Dart types.** Non-null strings come back as `''` when empty (`avatarUrl`, `ride.imageUrl`, `bio`). Nullable fields come back as `null` (`post.imageUrl`, `group.coverImageUrl`, `actorAvatarUrl`, `declineReason`).
- **Timestamps** are ISO-8601 strings in UTC. **Ids** are UUID strings.
- **Errors** always have the same shape. `code` is stable, and `message` is safe to show the user:

  ```json
  { "error": { "code": "RIDE_FULL", "message": "This ride is full." }, "requestId": "…" }
  ```

  | Status | Typical codes |
  | --- | --- |
  | 400 | `VALIDATION_ERROR` (with `details: [{ field, message }]`), `INVALID_CURSOR`, `WRONG_PASSWORD`, `CANNOT_FOLLOW_SELF`, `CANNOT_MESSAGE_SELF` |
  | 401 | `UNAUTHORIZED`, `INVALID_CREDENTIALS`, `TOKEN_EXPIRED` (refresh the token, then retry), `SESSION_REVOKED`, `REFRESH_TOKEN_REUSED` |
  | 403 | `FORBIDDEN`, `NOT_RIDE_ORGANIZER`, `NOT_GROUP_OWNER`, `NOT_A_MEMBER` |
  | 404 | `RIDE_NOT_FOUND` ("This ride no longer exists."), `POST_NOT_FOUND`, `USER_NOT_FOUND`, `GROUP_NOT_FOUND`, `REQUEST_NOT_FOUND`, … |
  | 409 | `EMAIL_TAKEN`, `RIDE_FULL`, `ALREADY_REQUESTED`, `CANNOT_JOIN_OWN_RIDE`, `RIDE_ALREADY_STARTED`, `REQUEST_NOT_PENDING`, `OWNER_CANNOT_LEAVE` |
  | 413 / 415 | `PAYLOAD_TOO_LARGE`, `UNSUPPORTED_MEDIA_TYPE` |
  | 422 | `RIDE_DATE_IN_PAST`, `MAX_BELOW_PARTICIPANTS` |
  | 429 / 503 | `RATE_LIMITED`, `SERVICE_UNAVAILABLE` (both send a `retry-after` header) |

  The not-found messages reuse the app's own text, for example "This ride no longer exists." and "This rider could not be found."

## API map

Full request and response details are at `/docs`. All paths are under `/api/v1`.

| Area | Endpoints |
| --- | --- |
| **Auth** | `POST /auth/register` · `POST /auth/login` · `POST /auth/refresh` · `POST /auth/logout` · `POST /auth/logout-all` · `POST /auth/forgot-password` · `POST /auth/reset-password` · `POST /auth/change-password` · `GET /auth/me` · `GET /auth/sessions` · `DELETE /auth/sessions/:id` |
| **Me & riders** | `GET/PATCH/DELETE /me` · `GET/PUT/PATCH /me/preferences` · `GET /users?q=` · `GET /users/recommended` · `GET /users/:id` · `PUT/DELETE /users/:id/follow` · `GET /users/:id/followers` · `GET /users/:id/following` · `GET /users/:id/rides` |
| **Rides** | `GET /rides` (upcoming; filters: `category`, `rideType`, `difficulty`, `q`, `from`, `to`) · `POST /rides` · `GET/PATCH/DELETE /rides/:id` · `GET /rides/:id/participants` · `POST/DELETE /rides/:id/join` · `GET /me/rides?scope=upcoming\|organized\|joined\|past` |
| **Join requests** | `GET /rides/:id/requests?status=` · `GET /me/ride-requests` (requests on all rides you organize) · `POST /ride-requests/:id/approve` · `POST /ride-requests/:id/decline` `{ reason? }` |
| **Community** | `GET/POST /posts` · `GET/PATCH/DELETE /posts/:id` · `PUT/DELETE /posts/:id/like` · `GET/POST /posts/:id/comments` · `DELETE /comments/:id` · `PUT/DELETE /comments/:id/like` |
| **Messages** | `GET /conversations` · `POST /conversations` `{ userId }` (returns the existing chat or creates one) · `GET /conversations/unread-count` · `GET /conversations/:id` · `GET/POST /conversations/:id/messages` · `POST /conversations/:id/read` |
| **Groups** | `GET /groups?sort=popular\|newest` · `GET /groups/mine` · `POST /groups` · `GET/PATCH/DELETE /groups/:id` · `POST /groups/:id/join` · `POST /groups/:id/leave` · `GET /groups/:id/members` · `GET/POST /groups/:id/messages` |
| **Notifications** | `GET /notifications` (includes `unreadCount`) · `GET /notifications/unread-count` · `POST /notifications/:id/read` · `POST /notifications/read-all` · `DELETE /notifications/:id` · `POST/DELETE /me/devices` (push tokens) |
| **Explore** | `GET /places/nearby?lat=&lng=&radiusKm=` (nearest first; filters: `category`, `activity`, `minRating`, `q`) · `GET /places?sort=top\|newest` · `POST /places` · `GET/PATCH/DELETE /places/:id` · `PUT/DELETE /places/:id/save` · `GET /places/:id/reviews` · `PUT/DELETE /places/:id/review` · `GET /me/saved-places` · `GET /users/:id/places` |
| **Home** | `GET /home?category=&lat=&lng=` (featured ride, next 6 rides, 2 posts, recommended riders, places to explore, banners, badges) · `GET /me/badges` · `GET /banners` · `GET /meta` (public: enum options and labels) |
| **Uploads** | `POST /uploads` (multipart `file` plus optional `purpose`; returns `url`) · `DELETE /uploads/:id` · files are served at `GET /uploads/*` |
| **Admin** | `GET /admin/stats` · `GET /admin/users` · `PATCH /admin/users/:id/role` · `DELETE /admin/users/:id` · `GET /admin/rides` · `DELETE /admin/rides/:id` · `GET /admin/ride-requests` · `GET /admin/posts` · `DELETE /admin/posts/:id` · `GET /admin/groups` · `DELETE /admin/groups/:id` · `GET /admin/places` · `DELETE /admin/places/:id` · `GET/POST /admin/banners` · `PATCH/DELETE /admin/banners/:id` · `GET /admin/audit-log` |
| **Realtime** | `GET /ws` (WebSocket) |

### Ride rules

- The organizer counts as the first participant, so `participantCount` starts at 1, as in the app.
- Joining creates a **pending** request and notifies the organizer (`newRideRequest`). You can't join your own ride, a full ride, or a ride that has already started.
- Only the organizer or an admin can approve or decline a request. The request must still be pending and the ride must not have started. Approving checks capacity under a row lock. A decline can include a reason, which the rider sees in `myRequest.declineReason` and in the `requestDeclined` notification.
- A declined rider can ask again, which puts the request back to pending. `DELETE /rides/:id/join` withdraws a pending request or leaves a ride you were approved for.
- Editing a ride sends approved riders and pending requesters a `rideUpdated` notification that says what changed. Cancelling a ride notifies them too. A `rideReminder` goes out 2 hours before the start (set with `RIDE_REMINDER_LEAD_MINUTES`).

### Explore rules

- Anyone can share a place: a name, its story, a category (viewpoint, waterfall, lake, trail, heritage, temple, café, campsite and so on), the exact map location, the area name, up to 10 photos, the activities it suits, and optional best time, entry fee and local tips.
- `GET /places/nearby` searches around the coordinates you send, nearest first, within `radiusKm` (25 km by default, up to 300). It needs no PostGIS: an indexed bounding box narrows the candidates, then the exact distance is computed. Each place carries `distanceKm`.
- Each rider gets one review per place: 1–5 stars, "worth it?" yes or no, text, visit date and up to 5 photos. Writing again updates it. Authors can't review their own place. The place shows `averageRating`, `reviewCount` and `worthItPercent`, all kept current by database triggers, and the author gets a `placeReview` notification.
- Saving a place adds it to your "want to go" list (`GET /me/saved-places`). The author or an admin can edit or delete a place.

### Realtime

Connect to `ws://<host>/api/v1/ws` with `Authorization: Bearer <accessToken>`, or pass `?access_token=`. The server sends `{ "type", "data" }` events:

| Event | When | `data` |
| --- | --- | --- |
| `ready` | on connect | `{ userId }` |
| `notification.created` | any new notification | NotificationItem |
| `message.created` | a direct message is sent (to both people) | Message (`isMe` is set for each receiver) |
| `conversation.read` | the other person read the chat | `{ conversationId, userId, readAt }` |
| `groupMessage.created` | a group chat message (to all members) | GroupMessage |

Send `{ "type": "ping" }` to get `{ "type": "pong" }` back. Delivery is best-effort, so refetch over REST after reconnecting. If you run several API instances behind a load balancer, set `REALTIME_PG_FANOUT=true` so events reach every instance through Postgres `LISTEN/NOTIFY`.

---

## Testing

```bash
npm test
```

Tests use a **separate database**: `TEST_DATABASE_URL`, or `DATABASE_URL` with `_test` added to the database name. The name must end in `_test`, because each run rebuilds that database's schema from the migrations, and the test setup refuses to touch any other database. Each test file builds the app once, and every test starts with empty tables. Tests call the real HTTP layer through `app.inject()`, including uploads and WebSockets.

## Configuration

All settings live in `.env`; `.env.example` explains each one. Production requires `JWT_ACCESS_SECRET` (at least 32 random characters). Behind a reverse proxy, set `TRUST_PROXY=true`. If web clients call the API, set a CORS allow-list. Set `PUBLIC_URL` to the public address, because it's used to build upload URLs. Settings are validated at startup; if one is invalid, the server refuses to start and says which.

## Deployment

- **Docker:** run `docker build -t yatrix-api .`. The image applies migrations when it starts (`npm run start:prod`). `docker compose up --build` runs it together with Postgres.
- **Bare metal or PM2:** run `npm ci && npm run build`, then `npm run start:prod`. If you run several instances, set `REALTIME_PG_FANOUT=true`. Background jobs are safe to run on every instance because each claims its work atomically.
- **Timezones:** every database session runs in UTC, so the server's own timezone setting (for example Asia/Kathmandu) never shifts stored times.
- **Shutdown:** on `SIGTERM` or `SIGINT`, the server stops accepting connections, finishes in-flight requests, then closes the database pool.
- **Uploads:** files are stored on local disk in `UPLOAD_DIR`. With several servers, mount shared storage, or swap in an object-storage implementation of `FileStorage` (`src/utils/storage.ts`).
- **Email:** password-reset emails go through the `Mailer` interface (`src/utils/mailer.ts`). The default `LogMailer` only writes the reset link to the log, so plug in SMTP, SES or Resend for production.

## Connecting the mobile app

The API mirrors the app's entities, so each `*LocalDataSource` can be replaced by a remote one that maps JSON field for field. When you wire it up:

- Keep the access and refresh tokens in secure storage. Refresh on `TOKEN_EXPIRED`, and never send two refreshes at once, because each refresh token works only once.
- Replace `AppConstants.currentUserId` with the id from `GET /auth/me` (or use `isMe` on profiles).
- New passwords need **8 or more characters**; the app's validator currently allows 6.
- `NotificationType` gains **`newRideRequest`** (alerts for organizers) and **`placeReview`**; the app already has `placeReview`. Notifications also carry `entityType` and `entityId`, so tapping one can open the right screen.
- Lists are paginated: `{ items, nextCursor }`, 20 items by default, up to 100.
- `GET /conversations/:id/messages` marks the chat as read, so its `unreadCount` drops to 0.
- The image pickers can use real uploads (`POST /uploads`) instead of the demo URLs.
