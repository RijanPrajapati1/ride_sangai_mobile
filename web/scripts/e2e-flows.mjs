// Drives the main dashboard flows end to end through the BFF with the system Chrome.
// Usage: node scripts/e2e-flows.mjs [baseUrl] [screenshotDir]
import { mkdirSync } from 'node:fs';
import { chromium } from 'playwright-core';

const base = process.argv[2] ?? 'http://localhost:3100';
const shots = process.argv[3];
if (shots) mkdirSync(shots, { recursive: true });
const email = process.env.SA_EMAIL ?? 'admin@gmail.com';
const password = process.env.SA_PASSWORD ?? 'Test@1234';
const rider = { email: process.env.RIDER_EMAIL ?? 'aarav@riders.test', password: process.env.RIDER_PASSWORD ?? 'Rider@1234' };

const browser = await chromium.launch({ executablePath: '/usr/bin/google-chrome', headless: true });
const ctx = await browser.newContext({ viewport: { width: 1440, height: 960 } });
const page = await ctx.newPage();
const errors = [];
page.on('pageerror', (e) => errors.push(e.message));
const results = [];
const step = async (name, fn) => {
  try {
    await fn();
    results.push(`PASS ${name}`);
  } catch (e) {
    results.push(`FAIL ${name}: ${e.message.split('\n')[0]}`);
    if (shots) await page.screenshot({ path: `${shots}/fail-${name.replace(/\W+/g, '-')}.png` });
  }
};
const shot = async (name) => shots && page.screenshot({ path: `${shots}/${name}.png` });
const toast = (text) => page.getByText(text).first().waitFor({ timeout: 8000 });

await step('unauthenticated page redirects to /login', async () => {
  await page.goto(`${base}/users`);
  await page.waitForURL(/\/login\?next=%2Fusers/);
});

await step('rider (non-superadmin) is rejected', async () => {
  await page.fill('#email', rider.email);
  await page.fill('#password', rider.password);
  await page.click('button[type=submit]');
  await page.getByRole('alert').getByText('does not have superadmin access').waitFor();
  const cookies = await ctx.cookies();
  if (cookies.some((c) => c.name.startsWith('rs_') && c.value)) throw new Error('session cookie set for rider');
  await shot('flow-rider-rejected');
});

await step('superadmin signs in and lands on ?next', async () => {
  await page.fill('#email', email);
  await page.fill('#password', password);
  await page.click('button[type=submit]');
  await page.waitForURL(`${base}/users`);
  const cookies = await ctx.cookies();
  const access = cookies.find((c) => c.name === 'rs_access');
  const refresh = cookies.find((c) => c.name === 'rs_refresh');
  if (!access?.httpOnly || !refresh?.httpOnly || refresh.path !== '/api') throw new Error('cookie flags wrong');
  const visible = await page.evaluate(() => document.cookie);
  if (visible.includes('rs_access') || visible.includes('rs_refresh')) throw new Error('tokens visible to JS');
});

await step('promote rider to superadmin, then demote', async () => {
  await page.getByRole('button', { name: 'Actions for Kiran Thapa' }).click();
  await page.getByRole('menuitem', { name: 'Make superadmin' }).click();
  await page.getByRole('alertdialog').getByRole('button', { name: 'Make superadmin' }).click();
  await toast('Kiran Thapa is now a superadmin');
  await page.getByRole('tab', { name: 'Superadmins' }).click();
  await page.getByText('kiran@riders.test').waitFor();
  await shot('flow-superadmins');
  await page.getByRole('button', { name: 'Actions for Kiran Thapa' }).click();
  await page.getByRole('menuitem', { name: 'Remove superadmin role' }).click();
  await page.getByRole('alertdialog').getByRole('button', { name: 'Demote' }).click();
  await toast('Kiran Thapa is now a rider');
});

await step('search users', async () => {
  await page.getByRole('tab', { name: 'Riders' }).click();
  await page.getByPlaceholder('Search name or email').fill('priya');
  await page.waitForTimeout(800);
  const rows = await page.locator('tbody tr').count();
  if (rows !== 1) throw new Error(`expected 1 row, got ${rows}`);
});

await step('delete a post', async () => {
  await page.goto(`${base}/content/posts`);
  await page.getByRole('button', { name: /Remove post by/ }).first().waitFor();
  const before = await page.locator('main li').count();
  await page.getByRole('button', { name: /Remove post by/ }).first().click();
  await shot('flow-confirm-delete-post');
  await page.getByRole('alertdialog').getByRole('button', { name: 'Remove' }).click();
  await toast('Post removed');
  await page.waitForTimeout(800);
  const after = await page.locator('main li').count();
  if (after !== before - 1) throw new Error(`posts ${before} -> ${after}`);
});

await step('join requests filter', async () => {
  await page.goto(`${base}/content/requests`);
  await page.getByRole('tab', { name: 'Approved' }).click();
  await page.getByText('Approved').nth(1).waitFor();
});

await step('feedback: change status + note, then delete', async () => {
  await page.goto(`${base}/feedback`);
  const firstRow = page.locator('main ul > li button').first();
  await firstRow.waitFor();
  const message = (await firstRow.locator('p').first().innerText()).slice(0, 30);
  await firstRow.click();
  await page.getByRole('dialog').waitFor();
  await page.getByRole('dialog').getByRole('tab', { name: 'In progress' }).click();
  await toast('Marked as in progress');
  await page.fill('#admin-note', 'Reproduced on Android 14 — fix planned for 1.4.2.');
  await page.getByRole('button', { name: 'Save note' }).click();
  await toast('Note saved');
  await shot('flow-feedback-detail');
  await page.getByRole('button', { name: 'Close' }).last().click();
  await page.getByRole('tab', { name: /In progress/ }).click();
  const row = page.locator('main ul > li button', { hasText: message });
  await row.waitFor();
  await row.click();
  await page.getByRole('dialog').getByRole('button', { name: 'Delete' }).click();
  await page.getByRole('alertdialog').getByRole('button', { name: 'Delete' }).click();
  await toast('Feedback deleted');
});

await step('banners: create, edit, delete', async () => {
  await page.goto(`${base}/banners`);
  await page.getByRole('button', { name: 'New banner' }).waitFor();
  await page.waitForLoadState('networkidle');
  // Clean up leftovers from an earlier run.
  for (const name of ['Delete E2E Dashain ride week', 'Delete E2E Dashain ride week (edited)']) {
    while (await page.getByRole('button', { name, exact: true }).count()) {
      await page.getByRole('button', { name, exact: true }).first().click();
      await page.getByRole('alertdialog').getByRole('button', { name: 'Delete' }).click();
      await page.getByRole('alertdialog').waitFor({ state: 'detached' });
      await page.waitForTimeout(500);
    }
  }
  await page.getByRole('button', { name: 'New banner' }).click();
  await page.getByRole('button', { name: 'Create banner' }).click();
  await page.getByText('A title is required.').waitFor();
  await page.fill('#b-title', 'E2E Dashain ride week');
  await page.fill('#b-subtitle', 'Ride with the community all festival long.');
  await page.fill('#b-cta', 'See rides');
  await page.fill('#b-url', '/rides');
  await page.selectOption('#b-category', 'cycling');
  await page.fill('#b-sort', '-5');
  await shot('flow-banner-form');
  await page.getByRole('button', { name: 'Create banner' }).click();
  await toast('Banner created');
  const card = page
    .locator('div.rounded-xl')
    .filter({ has: page.getByRole('button', { name: 'Delete E2E Dashain ride week' }) })
    .last();
  await card.getByRole('button', { name: 'Edit' }).click();
  await page.fill('#b-title', 'E2E Dashain ride week (edited)');
  await page.getByRole('button', { name: 'Save changes' }).click();
  await toast('Banner updated');
  await page.getByText('E2E Dashain ride week (edited)').first().waitFor();
  await page.getByRole('button', { name: 'Delete E2E Dashain ride week (edited)', exact: true }).click();
  await page.getByRole('alertdialog').getByRole('button', { name: 'Delete' }).click();
  await toast('Banner deleted');
});

await step('audit log shows the actions', async () => {
  await page.goto(`${base}/audit-log`);
  await page.getByText('promoted a rider to superadmin').first().waitFor();
  await page.getByText('removed a post').first().waitFor();
  await page.getByText('deleted a feedback message').first().waitFor();
  await shot('flow-audit-log');
});

await step('expired access cookie is refreshed transparently', async () => {
  const cookies = await ctx.cookies();
  const access = cookies.find((c) => c.name === 'rs_access');
  const exp = Buffer.from(JSON.stringify({ exp: 1000 })).toString('base64url');
  await ctx.addCookies([{ ...access, value: `eyJhbGciOiJIUzI1NiJ9.${exp}.sig` }]);
  await page.goto(`${base}/`);
  await page.getByText('Riders', { exact: true }).waitFor();
  await page.waitForLoadState('networkidle');
  const after = (await ctx.cookies()).find((c) => c.name === 'rs_access');
  if (after.value === access.value || after.value.includes('.sig')) throw new Error('access cookie not rotated');
});

await step('revoked session sends the user to /login', async () => {
  const cookies = await ctx.cookies();
  const access = cookies.find((c) => c.name === 'rs_access');
  const exp = Buffer.from(JSON.stringify({ exp: 9999999999 })).toString('base64url');
  await ctx.addCookies([{ ...access, value: `eyJhbGciOiJIUzI1NiJ9.${exp}.forged` }]);
  await page.goto(`${base}/users`);
  await page.waitForURL(/\/login\?.*reason=expired/);
  await page.getByText('Your session has ended').waitFor();
  await page.waitForLoadState('networkidle');
});

await step('sign in again and sign out', async () => {
  if (process.env.DEBUG_FLOW) {
    page.on('framenavigated', (f) => f === page.mainFrame() && console.log('NAV', f.url()));
    page.on('response', (r) => r.url().includes('/api/') && console.log('RES', r.status(), r.url()));
  }
  await page.getByRole('button', { name: 'Sign in' }).and(page.locator(':enabled')).waitFor();
  await page.fill('#email', email);
  await page.fill('#password', password);
  await page.click('button[type=submit]');
  await page.waitForURL((u) => !u.pathname.startsWith('/login'));
  await page.getByRole('button', { name: /Super Admin/ }).click();
  await page.getByRole('menuitem', { name: 'Sign out' }).click();
  await page.waitForURL(/\/login\?reason=signed-out/);
  const cookies = await ctx.cookies();
  if (cookies.some((c) => c.name.startsWith('rs_') && c.value)) throw new Error('cookies not cleared');
  await page.goto(`${base}/`);
  await page.waitForURL(/\/login/);
});

await browser.close();
console.log(results.join('\n'));
console.log(errors.length ? `Page errors:\n${errors.join('\n')}` : 'No page errors');
process.exit(results.some((r) => r.startsWith('FAIL')) ? 1 : 0);
