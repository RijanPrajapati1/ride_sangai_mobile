import type { InjectOptions } from 'fastify';
import { describe, expect, it } from 'vitest';
import { useTestApp } from './helpers/context.js';
import { daysFromNow, registerSuperadmin, registerUser } from './helpers/factories.js';

const ctx = useTestApp();
const inject = (options: InjectOptions) => ctx.app.inject(options);

// A 1x1 PNG.
const PNG = Buffer.from(
  'iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAQAAAC1HAwCAAAAC0lEQVR42mNkYAAAAAYAAjCB0C8AAAAASUVORK5CYII=',
  'base64',
);

function multipart(fields: Record<string, string>, file?: { name: string; data: Buffer; type: string }) {
  const boundary = '----yatrix';
  const parts: Buffer[] = [];
  for (const [key, value] of Object.entries(fields)) {
    parts.push(
      Buffer.from(`--${boundary}\r\nContent-Disposition: form-data; name="${key}"\r\n\r\n${value}\r\n`),
    );
  }
  if (file) {
    parts.push(
      Buffer.from(
        `--${boundary}\r\nContent-Disposition: form-data; name="file"; filename="${file.name}"\r\nContent-Type: ${file.type}\r\n\r\n`,
      ),
    );
    parts.push(file.data, Buffer.from('\r\n'));
  }
  parts.push(Buffer.from(`--${boundary}--\r\n`));
  return {
    payload: Buffer.concat(parts),
    headers: { 'content-type': `multipart/form-data; boundary=${boundary}` },
  };
}

describe('home and meta', () => {
  it('serves the home feed in one request and public metadata', async () => {
    const me = await registerUser(ctx.app);
    const org = await registerUser(ctx.app);
    for (const days of [3, 1, 2]) {
      await inject({
        method: 'POST',
        url: '/api/v1/rides',
        headers: org.headers,
        payload: {
          title: `Ride in ${days} days`,
          description: 'Loop',
          date: daysFromNow(days),
          meetingPoint: 'Ratna Park',
          rideType: 'road',
          difficulty: 'easy',
          distanceKm: 20,
          durationMinutes: 60,
          maxParticipants: 10,
        },
      });
    }
    await inject({
      method: 'POST',
      url: '/api/v1/posts',
      headers: org.headers,
      payload: { text: 'Hello riders' },
    });
    const home = await inject({ method: 'GET', url: '/api/v1/home?category=cycling', headers: me.headers });
    expect(home.statusCode, home.body).toBe(200);
    const body = home.json();
    expect(body.featuredRide.title).toBe('Ride in 1 days');
    expect(body.upcomingRides.map((r: { title: string }) => r.title)).toEqual([
      'Ride in 2 days',
      'Ride in 3 days',
    ]);
    expect(body.communityPreview).toHaveLength(1);
    expect(body.recommendedRiders.map((u: { id: string }) => u.id)).toEqual([org.id]);
    expect(body.badges).toEqual({ unreadNotifications: 0, unreadMessages: 0, pendingRideRequests: 0 });
    expect(body.me.id).toBe(me.id);

    const meta = await inject({ method: 'GET', url: '/api/v1/meta' });
    expect(meta.statusCode).toBe(200);
    const trekking = meta.json().categories.find((c: { value: string }) => c.value === 'trekking');
    expect(trekking).toMatchObject({
      activityNoun: 'Treks',
      rideTypes: [
        { value: 'multiDayTrek', label: 'Multi-day Trek' },
        { value: 'dayTrek', label: 'Day Trek' },
        { value: 'summitTrek', label: 'Summit Trek' },
      ],
    });
  });
});

describe('admin', () => {
  it('is admin-only and moderates users, posts and banners with an audit trail', async () => {
    const admin = await registerSuperadmin(ctx.app, ctx.prisma);
    const rider = await registerUser(ctx.app);
    expect(
      (await inject({ method: 'GET', url: '/api/v1/superadmin/stats', headers: rider.headers })).statusCode,
    ).toBe(403);

    const stats = (
      await inject({ method: 'GET', url: '/api/v1/superadmin/stats', headers: admin.headers })
    ).json();
    expect(stats).toMatchObject({ riders: 1, superadmins: 1, rides: 0, posts: 0 });

    const users = (
      await inject({ method: 'GET', url: '/api/v1/superadmin/users', headers: admin.headers })
    ).json();
    expect(users.items.map((u: { id: string; email: string }) => [u.id, u.email])).toEqual([
      [rider.id, rider.email],
    ]);

    const banner = await inject({
      method: 'POST',
      url: '/api/v1/superadmin/banners',
      headers: admin.headers,
      payload: { title: 'Safety first', category: 'cycling', ctaLabel: 'Read safety tips' },
    });
    expect(banner.statusCode, banner.body).toBe(201);
    const banners = (
      await inject({ method: 'GET', url: '/api/v1/banners?category=cycling', headers: rider.headers })
    ).json();
    expect(banners.items.map((b: { title: string }) => b.title)).toEqual(['Safety first']);
    expect(
      (await inject({ method: 'GET', url: '/api/v1/banners?category=hiking', headers: rider.headers })).json()
        .items,
    ).toHaveLength(0);

    const self = await inject({
      method: 'DELETE',
      url: `/api/v1/superadmin/users/${admin.id}`,
      headers: admin.headers,
    });
    expect(self.json().error.code).toBe('CANNOT_REMOVE_SELF');
    expect(
      (
        await inject({
          method: 'DELETE',
          url: `/api/v1/superadmin/users/${rider.id}`,
          headers: admin.headers,
        })
      ).statusCode,
    ).toBe(204);
    // The removed rider's token stops working immediately.
    expect((await inject({ method: 'GET', url: '/api/v1/me', headers: rider.headers })).statusCode).toBe(401);
    const log = (
      await inject({ method: 'GET', url: '/api/v1/superadmin/audit-log', headers: admin.headers })
    ).json();
    expect(log.items[0]).toMatchObject({ action: 'user.remove', targetId: rider.id });
  });
});

describe('uploads', () => {
  it('accepts images by content, serves them, and rejects other files', async () => {
    const user = await registerUser(ctx.app);
    const form = multipart({ purpose: 'avatar' }, { name: 'me.png', data: PNG, type: 'image/png' });
    const res = await inject({
      method: 'POST',
      url: '/api/v1/uploads',
      headers: { ...user.headers, ...form.headers },
      payload: form.payload,
    });
    expect(res.statusCode, res.body).toBe(201);
    const upload = res.json();
    expect(upload).toMatchObject({ contentType: 'image/png', purpose: 'avatar', sizeBytes: PNG.length });

    const file = await inject({ method: 'GET', url: new URL(upload.url).pathname });
    expect(file.statusCode).toBe(200);
    expect(file.headers['cache-control']).toContain('immutable');

    const fake = multipart(
      {},
      { name: 'evil.png', data: Buffer.from('<script>alert(1)</script>'), type: 'image/png' },
    );
    const rejected = await inject({
      method: 'POST',
      url: '/api/v1/uploads',
      headers: { ...user.headers, ...fake.headers },
      payload: fake.payload,
    });
    expect(rejected.statusCode).toBe(415);

    expect(
      (await inject({ method: 'DELETE', url: `/api/v1/uploads/${upload.id}`, headers: user.headers }))
        .statusCode,
    ).toBe(204);
    expect((await inject({ method: 'GET', url: new URL(upload.url).pathname })).statusCode).toBe(404);
  });
});

describe('realtime', () => {
  it('pushes new messages over the WebSocket', async () => {
    const a = await registerUser(ctx.app);
    const b = await registerUser(ctx.app);
    const ws = await ctx.app.injectWS('/api/v1/ws', { headers: b.headers });
    const events: Array<{ type: string; data: Record<string, unknown> }> = [];
    const got = new Promise<void>((resolve) => {
      ws.on('message', (raw) => {
        events.push(JSON.parse(raw.toString()));
        if (events.some((e) => e.type === 'message.created')) resolve();
      });
    });
    const conv = (
      await inject({
        method: 'POST',
        url: '/api/v1/conversations',
        headers: a.headers,
        payload: { userId: b.id },
      })
    ).json();
    await inject({
      method: 'POST',
      url: `/api/v1/conversations/${conv.id}/messages`,
      headers: a.headers,
      payload: { text: 'live!' },
    });
    await got;
    expect(events.find((e) => e.type === 'message.created')?.data).toMatchObject({
      text: 'live!',
      isMe: false,
    });
    ws.terminate();
  });

  it('rejects unauthenticated sockets', async () => {
    await expect(ctx.app.injectWS('/api/v1/ws')).rejects.toThrow();
  });
});
