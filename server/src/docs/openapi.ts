import type { AppConfig } from '../config/env.js';

/**
 * The API is documented as two definitions, picked from the dropdown at the
 * top of /docs:
 *   - Mobile app:       everything riders use (also content owners managing
 *                       their own posts, rides, places and groups).
 *   - Superadmin (web): the dashboard endpoints, plus the sign-in calls.
 * Both are cut from the one OpenAPI document @fastify/swagger generates.
 */

interface OpenApiDocument {
  info: { title: string; description?: string; version: string };
  tags?: { name: string; description?: string }[];
  paths: Record<string, Record<string, { tags?: string[] }>>;
  [key: string]: unknown;
}

export type DocsVariant = 'mobile' | 'superadmin';

const SUPERADMIN_PREFIX = '/api/v1/superadmin';
const SIGN_IN_PATHS = new Set([
  '/api/v1/auth/login',
  '/api/v1/auth/refresh',
  '/api/v1/auth/logout',
  '/api/v1/auth/me',
]);

const MOBILE_TAGS = [
  { name: 'Auth', description: 'Register, sign in, refresh tokens and manage signed-in devices.' },
  { name: 'Users', description: 'My profile and settings; finding and following other riders.' },
  { name: 'Home', description: 'Everything the home screen needs in one call, plus app metadata.' },
  { name: 'Rides', description: 'Discover, create and join rides. The organizer is the admin of the ride.' },
  { name: 'Ride requests', description: 'Organizers approve or decline riders who asked to join.' },
  { name: 'Community', description: 'Posts, likes and comments. Authors manage their own posts.' },
  { name: 'Messages', description: 'One-to-one chats. New messages also arrive over the WebSocket.' },
  { name: 'Groups', description: 'Rider groups with a group chat. The owner manages the group.' },
  { name: 'Explore', description: 'Places worth visiting: nearby search, reviews and saved places.' },
  { name: 'Notifications', description: 'In-app notifications and push-device registration.' },
  {
    name: 'Uploads',
    description: 'Upload an image and store the returned URL on a profile, ride, post or place.',
  },
  { name: 'Feedback', description: 'Send feedback about the app to the Ride Sangai team.' },
  { name: 'Health', description: 'Liveness and readiness probes. No token needed.' },
];

const SUPERADMIN_TAGS = [
  { name: 'Auth', description: 'Sign in with a superadmin account, then call the dashboard endpoints.' },
  {
    name: 'Superadmin',
    description: 'Platform-wide moderation, analytics, leaderboard, feedback and home banners.',
  },
];

function mobileOverview(config: AppConfig): string {
  const minutes = Math.round(config.auth.accessTokenTtlSeconds / 60);
  return [
    'The API behind the **Ride Sangai** app: group rides, treks, hikes and motorbike meetups, community posts, chats, groups and places to explore.',
    '',
    '### Quick start',
    '1. Open **Auth → POST /api/v1/auth/register** (or **login**), press **Try it out**, then **Execute**.',
    '2. The token from the response is applied automatically, so the 🔒 icons close. You can also paste one under **Authorize**.',
    `3. Access tokens last ${minutes} minutes. Exchange the refresh token at **POST /api/v1/auth/refresh**; each refresh token works once.`,
    '',
    '### Who can change what',
    'Every rider is the admin of what they create: the organizer manages their ride and its join requests, authors manage their posts and places, group owners manage their group. Platform-wide moderation lives in the **Superadmin (web)** definition (dropdown at the top).',
    '',
    '### Conventions',
    '| | |',
    '| --- | --- |',
    '| **Fields** | camelCase, identical to the Dart entities |',
    '| **Enums** | Dart enum names (`hillClimb`, `requestApproved`); `GET /api/v1/meta` lists them with labels |',
    '| **Ids and times** | UUID strings; ISO-8601 timestamps in UTC |',
    '| **Lists** | `{ items, nextCursor }`. Pass `nextCursor` back as `cursor`; `null` means the last page |',
    '| **Errors** | `{ error: { code, message, details? }, requestId }`. Branch on `code`; `message` is safe to show users |',
    '| **Realtime** | WebSocket at `/api/v1/ws` with `?access_token=` (new messages, notifications) |',
  ].join('\n');
}

function superadminOverview(): string {
  return [
    'Endpoints for the **Ride Sangai superadmin dashboard** (the `web/` app). Every route requires an account with the `superadmin` role.',
    '',
    '### Quick start',
    '1. **Auth → POST /api/v1/auth/login** with a superadmin account (created by `npm run db:seed`).',
    '2. The token is applied automatically. Responses include `isSuperadmin: true`.',
    '',
    '### What is here',
    '| | |',
    '| --- | --- |',
    '| **Overview** | `GET /stats` (totals), `GET /analytics?days=` (daily activity, active users, breakdowns) |',
    '| **People** | `GET /users`, `PATCH /users/{id}/role`, `DELETE /users/{id}`, `GET /top-users?metric=` |',
    '| **Content** | rides, join requests, posts, groups and places: list and remove |',
    '| **Feedback** | `GET /feedback`, `PATCH /feedback/{id}` (status and internal note) |',
    '| **App content** | home banners: list, create, edit, delete |',
    '| **Accountability** | `GET /audit-log`: every moderation action, who did it and when |',
  ].join('\n');
}

/** Cuts the full document down to one variant, with its own title, overview and tags. */
export function documentFor(full: OpenApiDocument, variant: DocsVariant, config: AppConfig): OpenApiDocument {
  const keep = (path: string) =>
    variant === 'superadmin'
      ? path.startsWith(SUPERADMIN_PREFIX) || SIGN_IN_PATHS.has(path)
      : !path.startsWith(SUPERADMIN_PREFIX);
  const paths = Object.fromEntries(Object.entries(full.paths).filter(([path]) => keep(path)));
  const tags = variant === 'superadmin' ? SUPERADMIN_TAGS : MOBILE_TAGS;
  return {
    ...full,
    info: {
      ...full.info,
      title: variant === 'superadmin' ? 'Ride Sangai · Superadmin API' : 'Ride Sangai · Mobile API',
      description: variant === 'superadmin' ? superadminOverview() : mobileOverview(config),
    },
    tags,
    paths,
  };
}
