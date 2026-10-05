/**
 * Look and behaviour of the Swagger UI page at /docs. Colours are the mobile
 * app's palette (mobile/lib/app/theme/app_colors.dart). Rules are scoped under
 * `#swagger-ui` so they win over Swagger's own light and dark styles without
 * `!important`; Swagger's dark-mode toggle switches `html.dark-mode`.
 */

export const DOCS_LOGO_SVG = `<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 64 64">
<defs><linearGradient id="g" x1="0" y1="0" x2="1" y2="1"><stop offset="0" stop-color="#1FB6A8"/><stop offset="1" stop-color="#15897E"/></linearGradient></defs>
<rect width="64" height="64" rx="16" fill="url(#g)"/>
<path d="M10 46 L26 22 L34 34 L40 26 L54 46 Z" fill="#fff" opacity=".95"/>
<circle cx="45" cy="17" r="5" fill="#FF6B35"/>
</svg>`;

export const DOCS_CSS = `
:root {
  --rs-bg: #F6F8F9; --rs-surface: #FFFFFF; --rs-surface-alt: #F0F3F4;
  --rs-text: #16232B; --rs-text-2: #6C7B85; --rs-border: #E4E9EB;
  --rs-primary: #1FB6A8; --rs-primary-strong: #15897E; --rs-primary-soft: #DFF7F4;
  --rs-accent: #FF6B35;
  --rs-get: #1E63D6; --rs-get-bg: rgba(59,130,246,.12);
  --rs-post: #1A8A55; --rs-post-bg: rgba(47,177,112,.14);
  --rs-put: #B26A00; --rs-put-bg: rgba(245,166,35,.16);
  --rs-patch: #6D3FD6; --rs-patch-bg: rgba(139,92,246,.14);
  --rs-delete: #C9302C; --rs-delete-bg: rgba(229,72,77,.13);
  --rs-code-bg: #0F1A1F;
  --rs-font: Inter, Roboto, "Segoe UI", system-ui, -apple-system, sans-serif;
  --rs-mono: "JetBrains Mono", "Ubuntu Mono", ui-monospace, Menlo, Consolas, monospace;
}
html.dark-mode {
  --rs-bg: #0E1518; --rs-surface: #172024; --rs-surface-alt: #1E292E;
  --rs-text: #F2F5F6; --rs-text-2: #9AAAB1; --rs-border: #2A363B;
  --rs-primary-soft: #163430;
  --rs-get: #7DB0FF; --rs-get-bg: rgba(59,130,246,.18);
  --rs-post: #5FD39A; --rs-post-bg: rgba(47,177,112,.18);
  --rs-put: #F7C066; --rs-put-bg: rgba(245,166,35,.18);
  --rs-patch: #B79CFF; --rs-patch-bg: rgba(139,92,246,.2);
  --rs-delete: #FF8A8E; --rs-delete-bg: rgba(229,72,77,.18);
}
html:root, html:root body { background: var(--rs-bg); }
#swagger-ui, #swagger-ui * { font-family: var(--rs-font); }
#swagger-ui :is(pre, code, kbd, samp, textarea, .microlight, .microlight *, .opblock-summary-path, .opblock-summary-path *,
  .parameter__type, .parameter__in, .model, .model *) { font-family: var(--rs-mono); }
#swagger-ui .swagger-ui { background: var(--rs-bg); color: var(--rs-text); }
#swagger-ui .wrapper { max-width: 1240px; }

/* Top bar: logo, the API dropdown and the dark-mode toggle */
#swagger-ui .topbar { background: var(--rs-surface); border-bottom: 1px solid var(--rs-border); padding: 10px 0;
  position: sticky; top: 0; z-index: 20; }
#swagger-ui .topbar-wrapper { gap: 16px; }
#swagger-ui .topbar-wrapper .link { display: flex; align-items: center; gap: 10px; flex: 0 0 auto; }
#swagger-ui .topbar-wrapper .link img { height: 34px; width: 34px; }
#swagger-ui .topbar-wrapper .link::after { content: "Ride Sangai API"; color: var(--rs-text); font-weight: 700; font-size: 17px; }
#swagger-ui .topbar .download-url-wrapper { justify-content: flex-end; }
#swagger-ui .topbar .download-url-wrapper .select-label { color: var(--rs-text-2); font-weight: 600; font-size: 13px; max-width: 420px; }
#swagger-ui .topbar .download-url-wrapper .select-label select { border: 1px solid var(--rs-border); border-radius: 10px;
  background-color: var(--rs-surface-alt); color: var(--rs-text); font-weight: 600; padding: 8px 32px 8px 12px; box-shadow: none; }
#swagger-ui .topbar .download-url-wrapper input.download-url-input,
#swagger-ui .topbar .download-url-wrapper .download-url-button { display: none; }
#swagger-ui .topbar .dark-mode-toggle button svg { fill: var(--rs-text-2); }

/* Overview */
#swagger-ui .info { margin: 36px 0 24px; }
#swagger-ui .info .title { color: var(--rs-text); font-size: 32px; font-weight: 800; }
#swagger-ui .info .title small { background: var(--rs-primary-soft); border-radius: 999px; padding: 2px 10px; }
#swagger-ui .info .title small pre { color: var(--rs-primary-strong); font-family: var(--rs-font); font-weight: 700; }
#swagger-ui .info .title small.version-stamp { background: var(--rs-surface-alt); }
#swagger-ui .info .title small.version-stamp pre { color: var(--rs-text-2); }
#swagger-ui .info a.link .url { color: var(--rs-text-2); font-size: 13px; }
#swagger-ui .info .description { max-width: 860px; }
#swagger-ui .info .markdown :is(p, li, td, th) { color: var(--rs-text); font-size: 14.5px; line-height: 1.6; }
#swagger-ui .info .markdown h3 { color: var(--rs-text); font-size: 17px; margin: 22px 0 8px; }
#swagger-ui .info .markdown table { border-collapse: collapse; width: 100%; background: var(--rs-surface);
  border: 1px solid var(--rs-border); border-radius: 12px; overflow: hidden; }
#swagger-ui .info .markdown td { border-top: 1px solid var(--rs-border); padding: 9px 12px; vertical-align: top; }
#swagger-ui .info .markdown thead { display: none; }
#swagger-ui .markdown code, #swagger-ui .renderedMarkdown code { background: var(--rs-surface-alt); color: var(--rs-primary-strong);
  border-radius: 6px; padding: 1px 6px; font-size: 13px; }
html.dark-mode #swagger-ui .markdown code { color: #6FE0D3; }

/* Servers + Authorize */
#swagger-ui .scheme-container { background: transparent; box-shadow: none; padding: 0; margin: 0 0 16px; }
#swagger-ui .scheme-container .schemes { background: var(--rs-surface); border: 1px solid var(--rs-border);
  border-radius: 14px; padding: 14px 18px; align-items: center; }
#swagger-ui .scheme-container .schemes > label, #swagger-ui .servers-title { color: var(--rs-text-2); }
#swagger-ui select, #swagger-ui input[type=text], #swagger-ui input[type=password], #swagger-ui input[type=search],
#swagger-ui input[type=email], #swagger-ui textarea { border: 1px solid var(--rs-border); border-radius: 10px;
  background-color: var(--rs-surface); color: var(--rs-text); box-shadow: none; }
#swagger-ui .filter-container .operation-filter-input { margin: 4px 0 16px; padding: 10px 14px; }

/* Buttons */
#swagger-ui .btn { border-radius: 10px; font-weight: 600; box-shadow: none; border: 1px solid var(--rs-border);
  color: var(--rs-text); background: var(--rs-surface); }
#swagger-ui .btn.authorize { border-color: var(--rs-primary); color: var(--rs-primary-strong); }
#swagger-ui .btn.authorize svg { fill: var(--rs-primary-strong); }
#swagger-ui .btn.execute, #swagger-ui .btn.btn-primary { background: var(--rs-primary-strong); border-color: var(--rs-primary-strong); color: #fff; }
#swagger-ui .btn.try-out__btn { border-color: var(--rs-primary); color: var(--rs-primary-strong); }
#swagger-ui .btn.cancel { border-color: var(--rs-delete); color: var(--rs-delete); }

/* Tag sections as cards */
#swagger-ui .opblock-tag-section { background: var(--rs-surface); border: 1px solid var(--rs-border);
  border-radius: 14px; padding: 2px 16px; margin-bottom: 12px; }
#swagger-ui .opblock-tag { border-bottom: none; color: var(--rs-text); font-size: 19px; font-weight: 700; padding: 12px 0; }
#swagger-ui .opblock-tag small { color: var(--rs-text-2); font-size: 14px; font-weight: 400; padding-left: 12px; }
#swagger-ui .opblock-tag svg, #swagger-ui .expand-operation svg, #swagger-ui .opblock-control-arrow svg { fill: var(--rs-text-2); }
#swagger-ui .opblock-tag-section.is-open .opblock-tag { border-bottom: 1px solid var(--rs-border); margin-bottom: 10px; }

/* Operations */
#swagger-ui .opblock { background: var(--rs-surface); border: 1px solid var(--rs-border); border-left-width: 3px;
  border-radius: 10px; box-shadow: none; margin-bottom: 8px; }
#swagger-ui .opblock .opblock-summary { border-bottom: none; padding: 6px 10px; }
#swagger-ui .opblock .opblock-summary-method { border-radius: 8px; min-width: 76px; font-family: var(--rs-font);
  font-weight: 700; font-size: 12px; letter-spacing: .04em; text-shadow: none; padding: 7px 0; }
#swagger-ui .opblock .opblock-summary-path { color: var(--rs-text); font-size: 14px; font-weight: 600; }
#swagger-ui .opblock .opblock-summary-description { color: var(--rs-text-2); font-size: 13.5px; }
#swagger-ui .opblock .opblock-section-header { background: var(--rs-surface-alt); box-shadow: none; }
#swagger-ui .opblock .opblock-section-header h4, #swagger-ui .opblock-description-wrapper p,
#swagger-ui .parameter__name, #swagger-ui .response-col_status, #swagger-ui .responses-inner h4, #swagger-ui .responses-inner h5,
#swagger-ui table thead tr :is(td, th), #swagger-ui .tab li { color: var(--rs-text); }
#swagger-ui .parameter__type, #swagger-ui .parameter__in { color: var(--rs-text-2); }
#swagger-ui .opblock.opblock-get { border-color: var(--rs-get); background: var(--rs-surface); }
#swagger-ui .opblock.opblock-get .opblock-summary-method { background: var(--rs-get-bg); color: var(--rs-get); }
#swagger-ui .opblock.opblock-post { border-color: var(--rs-post); background: var(--rs-surface); }
#swagger-ui .opblock.opblock-post .opblock-summary-method { background: var(--rs-post-bg); color: var(--rs-post); }
#swagger-ui .opblock.opblock-put { border-color: var(--rs-put); background: var(--rs-surface); }
#swagger-ui .opblock.opblock-put .opblock-summary-method { background: var(--rs-put-bg); color: var(--rs-put); }
#swagger-ui .opblock.opblock-patch { border-color: var(--rs-patch); background: var(--rs-surface); }
#swagger-ui .opblock.opblock-patch .opblock-summary-method { background: var(--rs-patch-bg); color: var(--rs-patch); }
#swagger-ui .opblock.opblock-delete { border-color: var(--rs-delete); background: var(--rs-surface); }
#swagger-ui .opblock.opblock-delete .opblock-summary-method { background: var(--rs-delete-bg); color: var(--rs-delete); }
#swagger-ui .opblock :is(.opblock-summary-get, .opblock-summary-post, .opblock-summary-put, .opblock-summary-patch, .opblock-summary-delete) { border-color: var(--rs-border); }

/* Code */
#swagger-ui .opblock-body pre.microlight, #swagger-ui .highlight-code > .microlight, #swagger-ui textarea.curl {
  background: var(--rs-code-bg) !important; border-radius: 10px; font-size: 12.5px; }
#swagger-ui .model-box, #swagger-ui section.models { background: var(--rs-surface); border-color: var(--rs-border); border-radius: 12px; }

/* Authorize dialog */
#swagger-ui .dialog-ux .modal-ux { background: var(--rs-surface); border: 1px solid var(--rs-border); border-radius: 16px; }
#swagger-ui .dialog-ux .modal-ux-header { border-bottom-color: var(--rs-border); }
#swagger-ui .dialog-ux .modal-ux-header h3, #swagger-ui .dialog-ux .modal-ux-content :is(p, h4, label) { color: var(--rs-text); }

@media (max-width: 640px) {
  #swagger-ui .topbar-wrapper .link::after { content: ""; }
  #swagger-ui .info .title { font-size: 24px; }
}
`;

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
