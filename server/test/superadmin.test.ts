import type { InjectOptions } from 'fastify';
import { describe, expect, it } from 'vitest';
import { useTestApp } from './helpers/context.js';
import { registerSuperadmin, registerUser } from './helpers/factories.js';

const ctx = useTestApp();
const inject = (options: InjectOptions) => ctx.app.inject(options);

describe('feedback', () => {
  it('lets riders send feedback and superadmins triage it', async () => {
    const rider = await registerUser(ctx.app, { name: 'Asha' });
    const superadmin = await registerSuperadmin(ctx.app, ctx.prisma);

    const sent = await inject({
      method: 'POST',
      url: '/api/v1/feedback',
      headers: rider.headers,
      payload: {
        category: 'bug',
        message: '  The map freezes on Android.  ',
        rating: 2,
        platform: 'android',
      },
    });
    expect(sent.statusCode, sent.body).toBe(201);
    expect(sent.json()).toMatchObject({
      category: 'bug',
      message: 'The map freezes on Android.',
      status: 'open',
    });

    const invalid = await inject({
      method: 'POST',
      url: '/api/v1/feedback',
      headers: rider.headers,
      payload: { message: 'x', rating: 9 },
    });
    expect(invalid.statusCode).toBe(400);

    expect(
      (await inject({ method: 'GET', url: '/api/v1/superadmin/feedback', headers: rider.headers }))
        .statusCode,
    ).toBe(403);

    const list = await inject({
      method: 'GET',
      url: '/api/v1/superadmin/feedback?status=open',
      headers: superadmin.headers,
    });
    expect(list.json().items).toHaveLength(1);
    expect(list.json().items[0]).toMatchObject({
      platform: 'android',
      user: { name: 'Asha', email: rider.email },
    });

    const id = sent.json().id as string;
    const resolved = await inject({
      method: 'PATCH',
      url: `/api/v1/superadmin/feedback/${id}`,
      headers: superadmin.headers,
      payload: { status: 'resolved', adminNote: 'Fixed in 1.0.1' },
    });
    expect(resolved.statusCode, resolved.body).toBe(200);
    expect(resolved.json()).toMatchObject({ status: 'resolved', adminNote: 'Fixed in 1.0.1' });
    expect(resolved.json().resolvedAt).not.toBeNull();

    const reopened = await inject({
      method: 'PATCH',
      url: `/api/v1/superadmin/feedback/${id}`,
      headers: superadmin.headers,
      payload: { status: 'inProgress' },
    });
    expect(reopened.json()).toMatchObject({ status: 'inProgress', resolvedAt: null });

    const removed = await inject({
      method: 'DELETE',
      url: `/api/v1/superadmin/feedback/${id}`,
      headers: superadmin.headers,
    });
    expect(removed.statusCode).toBe(204);
    expect(
      (
        await inject({
          method: 'DELETE',
          url: `/api/v1/superadmin/feedback/${id}`,
          headers: superadmin.headers,
        })
      ).statusCode,
    ).toBe(404);

    const log = await inject({
      method: 'GET',
      url: '/api/v1/superadmin/audit-log',
      headers: superadmin.headers,
    });
    const actions = log.json().items.map((entry: { action: string }) => entry.action);
    expect(actions).toEqual(expect.arrayContaining(['feedback.update', 'feedback.remove']));
  });
});

describe('analytics and leaderboard', () => {
  it('reports daily activity, active users and breakdowns', async () => {
    const rider = await registerUser(ctx.app);
    const superadmin = await registerSuperadmin(ctx.app, ctx.prisma);
    await inject({
      method: 'POST',
      url: '/api/v1/posts',
      headers: rider.headers,
      payload: { text: 'First ride of the season!' },
    });
    await inject({
      method: 'POST',
      url: '/api/v1/feedback',
      headers: rider.headers,
      payload: { message: 'Love it', rating: 5, category: 'praise' },
    });

    const res = await inject({
      method: 'GET',
      url: '/api/v1/superadmin/analytics?days=7',
      headers: superadmin.headers,
    });
    expect(res.statusCode, res.body).toBe(200);
    const body = res.json();
    expect(body.days).toBe(7);
    expect(body.daily).toHaveLength(7);
    expect(body.daily.at(-1).date).toBe(new Date().toISOString().slice(0, 10));
    // Superadmins aren't counted as signups.
    expect(body.totals).toMatchObject({ signups: 1, posts: 1, feedback: 1 });
    expect(body.activeUsers.last24Hours).toBeGreaterThanOrEqual(2);
    expect(body.feedbackAverageRating).toBe(5);
    expect(body.feedbackByStatus).toEqual([{ key: 'open', count: 1 }]);

    expect(
      (
        await inject({
          method: 'GET',
          url: '/api/v1/superadmin/analytics?days=3',
          headers: superadmin.headers,
        })
      ).statusCode,
    ).toBe(400);
  });

  it('ranks riders by the chosen metric', async () => {
    const quiet = await registerUser(ctx.app, { name: 'Quiet' });
    const poster = await registerUser(ctx.app, { name: 'Poster' });
    const superadmin = await registerSuperadmin(ctx.app, ctx.prisma);
    for (const text of ['One', 'Two']) {
      await inject({ method: 'POST', url: '/api/v1/posts', headers: poster.headers, payload: { text } });
    }
    await inject({ method: 'PUT', url: `/api/v1/users/${poster.id}/follow`, headers: quiet.headers });

    const byPosts = await inject({
      method: 'GET',
      url: '/api/v1/superadmin/top-users?metric=posts&limit=5',
      headers: superadmin.headers,
    });
    expect(byPosts.statusCode, byPosts.body).toBe(200);
    expect(byPosts.json().metric).toBe('posts');
    expect(byPosts.json().items[0]).toMatchObject({ rank: 1, name: 'Poster', posts: 2, followers: 1 });
    expect(byPosts.json().items.map((u: { name: string }) => u.name)).not.toContain('Super Admin');

    const bad = await inject({
      method: 'GET',
      url: '/api/v1/superadmin/top-users?metric=hacks',
      headers: superadmin.headers,
    });
    expect(bad.statusCode).toBe(400);
  });
});
