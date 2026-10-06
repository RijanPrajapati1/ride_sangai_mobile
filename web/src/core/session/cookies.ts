/**
 * Cookie names shared by the BFF route handlers and `src/proxy.ts`.
 *
 * - The access token cookie is scoped to `/` so page navigations (and the
 *   proxy's route protection) can see that a session exists.
 * - The refresh token cookie is scoped to `/api` so it is only ever sent to the
 *   BFF route handlers (`/api/auth/*`, `/api/backend/*`), never with page or
 *   asset requests.
 */
export const ACCESS_COOKIE = 'rs_access';
export const REFRESH_COOKIE = 'rs_refresh';

export const ACCESS_COOKIE_PATH = '/';
export const REFRESH_COOKIE_PATH = '/api';
