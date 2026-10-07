# Yatrix — Superadmin dashboard

The web dashboard the Yatrix platform team uses to run the community: platform
health and analytics, rider management, content moderation (posts, rides, join
requests, places, groups), the feedback inbox, home-screen banners and the
moderation audit log.

It is a Next.js 16 (App Router) app that talks to the Fastify API in `../server`
through a **backend-for-frontend (BFF)**: the browser only ever talks to Next.js,
and API tokens never reach the browser.

Only accounts with the `superadmin` role (`isSuperadmin: true`) can sign in.
Regular riders manage their own rides and posts in the mobile app.

## Quick start

```bash
cp .env.example .env.local   # then adjust API_URL if needed
npm install
npm run dev                  # http://localhost:3000
```

The API must be running (see `../server/README.md`). Seeded superadmin login
(created by `npm run db:seed` in `server/`):

| Email | Password |
| --- | --- |
| `admin@gmail.com` | `Test@1234` |

### Scripts

| Script | What it does |
| --- | --- |
| `npm run dev` | Dev server (`-- -p 3100` for another port) |
| `npm run build` / `npm start` | Production build / server |
| `npm run lint` | ESLint (Next.js + TypeScript rules) |
| `npm run typecheck` | `tsc --noEmit` (strict) |
| `npm run e2e -- <baseUrl> [screenshotDir]` | Drives the main flows end to end in the system Chrome (`playwright-core`, no browser download): login, rider rejection, promote/demote, delete post, feedback status/note/delete, banner create/edit/delete, audit log, token refresh, revoked session, sign out. Expects test data (riders such as `aarav@riders.test`). |
| `npm run screenshots -- <outDir> [prefix] [baseUrl]` | Full-page screenshots of every page in light, dark and phone width |

## Environment variables

| Variable | Default | Notes |
| --- | --- | --- |
| `API_URL` | `http://localhost:4000/api/v1` | Base URL of the Yatrix API. **Server-side only** — never exposed to the browser. |
| `APP_ORIGIN` | _(unset)_ | Public origin of the dashboard, e.g. `https://admin.yatrix.app`. Used by the CSRF check. When unset, the request's `X-Forwarded-Host`/`Host` header is used. Set it in production behind a proxy. |

## Pages

| Route | Page |
| --- | --- |
| `/login` | Branded sign-in |
| `/` | Overview: KPI cards, active riders (24h/7d/30d), activity chart (7/30/90/365 days, toggleable series), breakdowns (rides by category, requests and feedback by status), average rating, top riders and recent feedback previews |
| `/users` | Riders / superadmins, search, "Load more" pagination, promote/demote, remove (with confirmation; you can't act on yourself) |
| `/top-users` | Leaderboard with metric selector and every metric as a column |
| `/content/posts`, `/rides`, `/requests`, `/places`, `/groups` | Content moderation with delete (confirmation); rides filter by upcoming/past + search, join requests by status |
| `/feedback` | Inbox with Open / In progress / Resolved tabs and category filter; detail dialog to change status, write an internal note, delete |
| `/banners` | Banner cards with live preview; create / edit / pause / delete |
| `/audit-log` | Day-grouped timeline of moderation actions |
| anything else | Branded 404 |

## Security model

```
Browser ──(cookies, same-origin)──▶ Next.js BFF ──(Authorization: Bearer)──▶ Yatrix API
```

- **No tokens in the browser.** `POST /api/auth/login` (route handler) calls the
  API's `/auth/login`. If the account is not a superadmin, it immediately calls
  `/auth/logout` for that session and returns 403. Otherwise the access and
  refresh tokens are stored in cookies that are `HttpOnly`, `SameSite=Lax`,
  `Secure` in production, and **path-scoped**:
  - `rs_access` — `Path=/` (pages need to know a session exists);
  - `rs_refresh` — `Path=/api`, so it is only sent to the BFF route handlers,
    never with page or asset requests.
- **Proxy allowlist.** `/api/backend/[...path]` forwards to `API_URL` with the
  bearer token from the cookie. Only `superadmin/**` (any method) and
  `GET auth/me` are allowed; path segments must match `[A-Za-z0-9_-]+`
  (no `..`, no encoded slashes). Everything else gets 404. Only `content-type`
  and the bearer token are forwarded; bodies are capped at 1 MB.
- **Token refresh.** Access tokens live 15 minutes. Before forwarding, the BFF
  reads the JWT `exp` claim; if the token is missing, expired or expiring within
  30 s it refreshes first, and it also refreshes and retries once on an upstream
  `401 TOKEN_EXPIRED`. Refresh tokens are single-use, so refreshes are
  **single-flight**: concurrent requests with the same refresh token share one
  `/auth/refresh` call, and the result is remembered for 60 s so a late request
  still carrying the old cookie never replays it (a replay would revoke the
  session). New tokens are written back as rotated cookies.
  _This is per server process; when running several instances, use sticky
  sessions or move the in-flight map to a shared store._
- **Session end.** Any other upstream 401 (revoked, invalid, reused refresh
  token) clears both cookies and returns `401 SESSION_ENDED`; the client then
  does a full page load to `/login?reason=expired`. If a refresh shows the
  account is no longer a superadmin, the session is logged out too.
- **CSRF.** On top of `SameSite=Lax`, every non-GET request to the BFF
  (including login and logout) must carry an `Origin` header that matches the
  app (`APP_ORIGIN`, or the Host header).
- **Route protection.** `src/proxy.ts` (Next 16's replacement for
  `middleware.ts`) redirects page requests without a session cookie to
  `/login?next=…` and signed-in users away from `/login`. The `next` parameter
  only accepts same-app relative paths. The login button stays disabled until
  React has hydrated, so credentials can never be sent by a native form post.
- **Headers.** `proxy.ts` sets a per-request **nonce-based CSP**
  (`script-src 'self' 'nonce-…' 'strict-dynamic'`, `frame-ancestors 'none'`,
  `object-src 'none'`, `base-uri 'self'`, `form-action 'self'`;
  `'unsafe-eval'` only in development). `next.config.ts` adds
  `X-Frame-Options: DENY`, `X-Content-Type-Options: nosniff`,
  `Referrer-Policy: strict-origin-when-cross-origin`, a restrictive
  `Permissions-Policy`, COOP/CORP, HSTS in production, and a
  `default-src 'none'` CSP + `no-store` for `/api/*`. `X-Powered-By` is off.
- **No secrets in logs.** Nothing logs tokens, passwords or request bodies.
  The UI shows the API's error `message` (safe by contract) in toasts.

## Project structure

The code is organised by **feature**, mirroring the mobile app's
`data / domain / presentation` layering.

```
src/
├── app/                      Routing only: thin page/layout/route files
│   ├── (auth)/login/         → features/auth           (route group: no sidebar; URL is /login)
│   ├── (dashboard)/          layout + one folder per page (route group: sidebar layout; URLs like /users)
│   ├── api/auth/login|logout → features/auth/server
│   ├── api/backend/[...path] → core/session/bff-proxy
│   ├── layout.tsx            root layout (theme cookie, providers)
│   └── not-found.tsx
├── proxy.ts                  route protection + nonce CSP
├── core/                     framework-level, feature-agnostic
│   ├── config/               env (API_URL, APP_ORIGIN)
│   ├── http/                 api-client (browser → BFF), ApiError + envelope parsing, Page<T>
│   ├── session/              cookie names, server session + single-flight refresh, CSRF, BFF proxy
│   └── query/                TanStack Query client/provider, cursor-pagination hook
├── shared/                   reusable UI with no feature knowledge
│   ├── ui/                   button, card, dialog, input, badge, skeleton, switch, dropdown, avatar
│   ├── layout/               app shell (sidebar/topbar), brand, theme + toggle, page header, toaster, 404
│   ├── components/           empty/error states, load more, confirm dialog, data table, search, segmented control
│   └── lib/                  cn, formatting, debounce
└── features/<feature>/       auth · navigation · overview · users · top-users · content · feedback · banners · audit-log
    ├── domain/               entities and enums for this feature only
    ├── data/                 repository: calls the API via core/http, returns domain types
    ├── application/          TanStack Query hooks (queries/mutations), zod schemas
    ├── presentation/         screens and components
    └── index.ts              public API used by app/ (and, sparingly, other features)
```

Folders in parentheses, like `(auth)` and `(dashboard)`, are Next.js route
groups: they give pages a shared layout without adding to the URL. The
sidebar, its sections and the user menu live in `features/navigation`; the
`(dashboard)/layout.tsx` route file just renders it.

`features/auth` also has `server/` + `server.ts`: the login/logout route
handlers. They are exported from a separate entry point so client code that
imports `@/features/auth` never pulls in server-only modules.

### Dependency rule

```
app  ──▶  features  ──▶  core / shared
```

- `app/` only wires routes to feature entry points (`@/features/<name>`).
- A feature never imports another feature's internals — only its `index.ts`
  (the overview uses `TopRidersPreview` and `RecentFeedbackPreview` this way).
- `core/` and `shared/` never import from `features/` or `app/`; `core/` does
  not import `shared/` (`shared/` may use `core/http` error helpers).
- Server-only modules (`core/config`, `core/session/*`, `features/auth/server`)
  import `server-only`, so they fail the build if pulled into client code.

### Design notes

- Brand palette from the mobile app (teal `#1FB6A8`/`#15897E`, orange
  `#FF6B35`) as CSS tokens in `src/app/globals.css`, with a dark theme. The
  theme lives in a non-sensitive `rs-theme` cookie so the server renders the
  right class (no flash, no inline script under the CSP). Default is light.
- Chart series colours are a fixed, colour-blind-checked palette (each series
  keeps its colour when others are toggled); breakdowns are labelled bars.
- Every list starts empty in a fresh database, so every list and chart has a
  designed empty state, plus loading skeletons and error states with retry.
