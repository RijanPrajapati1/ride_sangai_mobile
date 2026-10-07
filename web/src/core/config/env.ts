import 'server-only';

const DEFAULT_API_URL = 'http://localhost:4000/api/v1';

/** Base URL of the Yatrix API, without a trailing slash. Server-side only. */
export const API_URL = (process.env.API_URL || DEFAULT_API_URL).replace(/\/+$/, '');

/** Optional public origin of the dashboard, used for the CSRF Origin check. */
export const APP_ORIGIN = process.env.APP_ORIGIN?.replace(/\/+$/, '') || null;

export const IS_PROD = process.env.NODE_ENV === 'production';

/** Timeout for calls to the API. */
export const API_TIMEOUT_MS = 15_000;
