// Takes screenshots of the dashboard with the system Chrome (no browser download).
// Usage: node scripts/screenshots.mjs <outDir> [prefix] [baseUrl]
// Env: SA_EMAIL / SA_PASSWORD (defaults to the seeded superadmin).
import { mkdirSync } from 'node:fs';
import { chromium } from 'playwright-core';

const out = process.argv[2] ?? './screenshots';
const prefix = process.argv[3] ?? '';
const base = process.argv[4] ?? 'http://localhost:3100';
const email = process.env.SA_EMAIL ?? 'superadmin@ridesangai.app';
const password = process.env.SA_PASSWORD ?? 'SuperAdmin@123';
mkdirSync(out, { recursive: true });

const PAGES = [
  ['overview', '/'],
  ['users', '/users'],
  ['top-users', '/top-users'],
  ['posts', '/content/posts'],
  ['rides', '/content/rides'],
  ['requests', '/content/requests'],
  ['places', '/content/places'],
  ['groups', '/content/groups'],
  ['feedback', '/feedback'],
  ['banners', '/banners'],
  ['audit-log', '/audit-log'],
  ['404', '/does-not-exist'],
];

const VARIANTS = (process.env.VARIANTS ?? 'light,dark,phone').split(',');

const browser = await chromium.launch({ executablePath: '/usr/bin/google-chrome', headless: true });
const errors = [];
for (const variant of VARIANTS) {
  const phone = variant === 'phone' || variant === 'phone-dark';
  const dark = variant === 'dark' || variant === 'phone-dark';
  const ctx = await browser.newContext({
    viewport: phone ? { width: 390, height: 844 } : { width: 1440, height: 960 },
    deviceScaleFactor: phone ? 2 : 1,
  });
  await ctx.addCookies([{ name: 'rs-theme', value: dark ? 'dark' : 'light', url: base }]);
  const page = await ctx.newPage();
  page.on('console', (m) => m.type() === 'error' && errors.push(`[${variant}] ${page.url()} ${m.text()}`));
  page.on('pageerror', (e) => errors.push(`[${variant}] ${page.url()} ${e.message}`));

  await page.goto(`${base}/login`);
  await page.waitForLoadState('networkidle');
  await page.screenshot({ path: `${out}/${prefix}login-${variant}.png`, fullPage: true });
  await page.fill('#email', email);
  await page.fill('#password', password);
  await Promise.all([page.waitForURL((u) => !u.pathname.startsWith('/login')), page.click('button[type=submit]')]);

  for (const [name, path] of PAGES) {
    await page.goto(`${base}${path}`);
    await page.waitForLoadState('networkidle');
    await page.waitForTimeout(400);
    await page.screenshot({ path: `${out}/${prefix}${name}-${variant}.png`, fullPage: true });
  }
  await ctx.close();
}
await browser.close();
console.log(errors.length ? `Console errors:\n${errors.join('\n')}` : 'No console errors');
