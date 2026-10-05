// `ui` is the Swagger UI instance in the page's initializer script, where this
// function is pasted as source (see responseInterceptor below).
declare const ui: {
  preauthorizeApiKey(name: string, value: string): void;
  authActions: { logout(names: string[]): void };
};

/**
 * Runs in the browser. After a successful login, register or refresh, applies
 * the new access token so every lock closes; after logout, clears it.
 */
export function rememberToken(res: { ok: boolean; url: string; body?: { accessToken?: unknown } }) {
  if (typeof ui === 'undefined' || !res.ok) return res;
  if (/\/auth\/(login|register|refresh)(\?|$)/.test(res.url) && typeof res.body?.accessToken === 'string') {
    ui.preauthorizeApiKey('bearerAuth', res.body.accessToken);
  } else if (/\/auth\/logout(-all)?(\?|$)/.test(res.url)) {
    ui.authActions.logout(['bearerAuth']);
  }
  return res;
}
