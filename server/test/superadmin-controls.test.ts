import type { InjectOptions } from 'fastify';
import { describe, expect, it } from 'vitest';
import { useTestApp } from './helpers/context.js';
import { daysFromNow, registerSuperadmin, registerUser } from './helpers/factories.js';

const ctx = useTestApp();
const inject = (options: InjectOptions) => ctx.app.inject(options);

async function auditActions(): Promise<string[]> {
  const rows = await ctx.prisma.adminAuditLog.findMany({ select: { action: true } });
  return rows.map((row) => row.action);
}

describe('superadmin user controls', () => {
  it('disables an account: signs it out, blocks sign-in and hides it, until re-enabled', async () => {
    const admin = await registerSuperadmin(ctx.app, ctx.prisma);
    const rider = await registerUser(ctx.app, { name: 'Trouble Maker' });
    const viewer = await registerUser(ctx.app);

    const disabled = await inject({
      method: 'POST',
      url: `/api/v1/superadmin/users/${rider.id}/disable`,
      headers: admin.headers,
      payload: { reason: '  Spam  ' },
    });
    expect(disabled.statusCode, disabled.body).toBe(200);
    expect(disabled.json()).toMatchObject({ disabledReason: 'Spam', activity: { activeSessions: 0 } });
    expect(disabled.json().disabledAt).not.toBeNull();

    // The session they had is gone, and so is the refresh token.
    expect((await inject({ method: 'GET', url: '/api/v1/me', headers: rider.headers })).statusCode).toBe(401);
    const refresh = await inject({
      method: 'POST',
      url: '/api/v1/auth/refresh',
      payload: { refreshToken: rider.refreshToken },
    });
    expect(refresh.statusCode).toBe(401);

    const login = await inject({
      method: 'POST',
      url: '/api/v1/auth/login',
      payload: { email: rider.email, password: rider.password },
    });
    expect(login.statusCode).toBe(403);
    expect(login.json().error.code).toBe('ACCOUNT_DISABLED');
    // A wrong password still reads as wrong credentials, so status is not revealed.
    const wrong = await inject({
      method: 'POST',
      url: '/api/v1/auth/login',
      payload: { email: rider.email, password: 'not-the-password' },
    });
    expect(wrong.json().error.code).toBe('INVALID_CREDENTIALS');

    const search = await inject({ method: 'GET', url: '/api/v1/users?q=Trouble', headers: viewer.headers });
    expect(search.json().items).toHaveLength(0);

    const list = await inject({
      method: 'GET',
      url: '/api/v1/superadmin/users?status=disabled',
      headers: admin.headers,
    });
    expect(list.json().items.map((u: { id: string }) => u.id)).toEqual([rider.id]);

    const enabled = await inject({
      method: 'POST',
      url: `/api/v1/superadmin/users/${rider.id}/enable`,
      headers: admin.headers,
    });
    expect(enabled.json()).toMatchObject({ disabledAt: null, disabledReason: null });
    const back = await inject({
      method: 'POST',
      url: '/api/v1/auth/login',
      payload: { email: rider.email, password: rider.password },
    });
    expect(back.statusCode).toBe(200);
    expect(await auditActions()).toEqual(expect.arrayContaining(['user.disable', 'user.enable']));
  });

  it('will not disable yourself or another superadmin', async () => {
    const admin = await registerSuperadmin(ctx.app, ctx.prisma);
    const other = await registerSuperadmin(ctx.app, ctx.prisma);
    const self = await inject({
      method: 'POST',
      url: `/api/v1/superadmin/users/${admin.id}/disable`,
      headers: admin.headers,
      payload: {},
    });
    expect(self.json().error.code).toBe('CANNOT_DISABLE_SELF');
    const peer = await inject({
      method: 'POST',
      url: `/api/v1/superadmin/users/${other.id}/disable`,
      headers: admin.headers,
      payload: {},
    });
    expect(peer.json().error.code).toBe('CANNOT_DISABLE_SUPERADMIN');
    const rider = await registerUser(ctx.app);
    const forbidden = await inject({
      method: 'POST',
      url: `/api/v1/superadmin/users/${admin.id}/disable`,
      headers: rider.headers,
      payload: {},
    });
    expect(forbidden.statusCode).toBe(403);
  });

  it('edits any profile and email, and reports activity and devices', async () => {
    const admin = await registerSuperadmin(ctx.app, ctx.prisma);
    const rider = await registerUser(ctx.app, { name: 'Old Name' });
    const taken = await registerUser(ctx.app);

    const edited = await inject({
      method: 'PATCH',
      url: `/api/v1/superadmin/users/${rider.id}`,
      headers: admin.headers,
      payload: {
        name: ' New Name ',
        email: 'New.Address@Example.com',
        bio: 'Edited by the team',
        location: 'Pokhara',
      },
    });
    expect(edited.statusCode, edited.body).toBe(200);
    expect(edited.json()).toMatchObject({
      name: 'New Name',
      email: 'new.address@example.com',
      bio: 'Edited by the team',
      location: 'Pokhara',
      activity: { ridesOrganized: 0, posts: 0, activeSessions: 1 },
    });
    expect(edited.json().sessions).toHaveLength(1);

    const login = await inject({
      method: 'POST',
      url: '/api/v1/auth/login',
      payload: { email: 'new.address@example.com', password: rider.password },
    });
    expect(login.statusCode).toBe(200);

    const conflict = await inject({
      method: 'PATCH',
      url: `/api/v1/superadmin/users/${rider.id}`,
      headers: admin.headers,
      payload: { email: taken.email },
    });
    expect(conflict.statusCode).toBe(409);
    expect(conflict.json().error.code).toBe('EMAIL_TAKEN');
    expect(await auditActions()).toContain('user.update');
  });

  it('signs a user out everywhere and sets a new password', async () => {
    const admin = await registerSuperadmin(ctx.app, ctx.prisma);
    const rider = await registerUser(ctx.app);

    const out = await inject({
      method: 'POST',
      url: `/api/v1/superadmin/users/${rider.id}/sign-out`,
      headers: admin.headers,
    });
    expect(out.json().activity.activeSessions).toBe(0);
    expect((await inject({ method: 'GET', url: '/api/v1/me', headers: rider.headers })).statusCode).toBe(401);

    const set = await inject({
      method: 'PUT',
      url: `/api/v1/superadmin/users/${rider.id}/password`,
      headers: admin.headers,
      payload: { password: 'brand-new-password-1' },
    });
    expect(set.statusCode, set.body).toBe(204);
    const old = await inject({
      method: 'POST',
      url: '/api/v1/auth/login',
      payload: { email: rider.email, password: rider.password },
    });
    expect(old.statusCode).toBe(401);
    const fresh = await inject({
      method: 'POST',
      url: '/api/v1/auth/login',
      payload: { email: rider.email, password: 'brand-new-password-1' },
    });
    expect(fresh.statusCode).toBe(200);
    expect(await auditActions()).toEqual(expect.arrayContaining(['user.signOut', 'user.setPassword']));
  });
});

describe('superadmin content controls', () => {
  it("edits anyone's ride, post, place and group", async () => {
    const admin = await registerSuperadmin(ctx.app, ctx.prisma);
    const owner = await registerUser(ctx.app);

    const ride = (
      await inject({
        method: 'POST',
        url: '/api/v1/rides',
        headers: owner.headers,
        payload: {
          title: 'Sunrise Ride',
          description: 'Loop',
          date: daysFromNow(3),
          meetingPoint: 'Ratna Park',
          rideType: 'social',
          difficulty: 'easy',
          distanceKm: 18,
          durationMinutes: 75,
          maxParticipants: 5,
        },
      })
    ).json();
    const editedRide = await inject({
      method: 'PATCH',
      url: `/api/v1/superadmin/rides/${ride.id}`,
      headers: admin.headers,
      payload: { title: 'Sunrise Ride (moved)', meetingPoint: 'Patan Durbar Square' },
    });
    expect(editedRide.statusCode, editedRide.body).toBe(200);
    expect(editedRide.json()).toMatchObject({
      title: 'Sunrise Ride (moved)',
      meetingPoint: 'Patan Durbar Square',
    });

    const post = (
      await inject({
        method: 'POST',
        url: '/api/v1/posts',
        headers: owner.headers,
        payload: { text: 'Spammy link' },
      })
    ).json();
    const editedPost = await inject({
      method: 'PATCH',
      url: `/api/v1/superadmin/posts/${post.id}`,
      headers: admin.headers,
      payload: { text: 'Removed a link that broke the guidelines.' },
    });
    expect(editedPost.json().text).toBe('Removed a link that broke the guidelines.');

    const place = (
      await inject({
        method: 'POST',
        url: '/api/v1/places',
        headers: owner.headers,
        payload: {
          name: 'Taudaha Lake',
          description: 'Quiet lake',
          category: 'lake',
          latitude: 27.6476,
          longitude: 85.2813,
          locationName: 'Kirtipur',
          activities: ['cycling'],
        },
      })
    ).json();
    const editedPlace = await inject({
      method: 'PATCH',
      url: `/api/v1/superadmin/places/${place.id}`,
      headers: admin.headers,
      payload: { name: 'Taudaha Lake (Kirtipur)' },
    });
    expect(editedPlace.json().name).toBe('Taudaha Lake (Kirtipur)');

    const group = (
      await inject({
        method: 'POST',
        url: '/api/v1/groups',
        headers: owner.headers,
        payload: { name: 'Riders', description: 'Loops' },
      })
    ).json();
    const editedGroup = await inject({
      method: 'PATCH',
      url: `/api/v1/superadmin/groups/${group.id}`,
      headers: admin.headers,
      payload: { description: 'Weekend loops around the valley' },
    });
    expect(editedGroup.json().description).toBe('Weekend loops around the valley');

    expect(await auditActions()).toEqual(
      expect.arrayContaining(['ride.update', 'post.update', 'place.update', 'group.update']),
    );
  });

  it('lists and removes any comment and review', async () => {
    const admin = await registerSuperadmin(ctx.app, ctx.prisma);
    const author = await registerUser(ctx.app);
    const troll = await registerUser(ctx.app, { name: 'Troll' });

    const post = (
      await inject({
        method: 'POST',
        url: '/api/v1/posts',
        headers: author.headers,
        payload: { text: 'Ride recap' },
      })
    ).json();
    await inject({
      method: 'POST',
      url: `/api/v1/posts/${post.id}/comments`,
      headers: troll.headers,
      payload: { text: 'rude words' },
    });
    const comments = await inject({
      method: 'GET',
      url: `/api/v1/superadmin/comments?postId=${post.id}`,
      headers: admin.headers,
    });
    expect(comments.json().items).toHaveLength(1);
    expect(comments.json().items[0]).toMatchObject({
      text: 'rude words',
      author: { name: 'Troll' },
      post: { id: post.id },
    });
    const removedComment = await inject({
      method: 'DELETE',
      url: `/api/v1/superadmin/comments/${comments.json().items[0].id}`,
      headers: admin.headers,
    });
    expect(removedComment.statusCode).toBe(204);

    const place = (
      await inject({
        method: 'POST',
        url: '/api/v1/places',
        headers: author.headers,
        payload: {
          name: 'Viewpoint',
          description: 'Views',
          category: 'viewpoint',
          latitude: 27.7,
          longitude: 85.3,
          locationName: 'Valley',
          activities: ['hiking'],
        },
      })
    ).json();
    await inject({
      method: 'PUT',
      url: `/api/v1/places/${place.id}/review`,
      headers: troll.headers,
      payload: { rating: 1, worthIt: false, text: 'fake review' },
    });
    const reviews = await inject({
      method: 'GET',
      url: `/api/v1/superadmin/reviews?placeId=${place.id}`,
      headers: admin.headers,
    });
    expect(reviews.json().items[0]).toMatchObject({ rating: 1, place: { name: 'Viewpoint' } });
    await inject({
      method: 'DELETE',
      url: `/api/v1/superadmin/reviews/${reviews.json().items[0].id}`,
      headers: admin.headers,
    });
    const after = await inject({ method: 'GET', url: `/api/v1/places/${place.id}`, headers: author.headers });
    expect(after.json()).toMatchObject({ reviewCount: 0, averageRating: null });
    expect(await auditActions()).toEqual(expect.arrayContaining(['comment.delete', 'review.delete']));
  });

  it('approves and declines join requests on any ride', async () => {
    const admin = await registerSuperadmin(ctx.app, ctx.prisma);
    const organizer = await registerUser(ctx.app);
    const a = await registerUser(ctx.app);
    const b = await registerUser(ctx.app);
    const ride = (
      await inject({
        method: 'POST',
        url: '/api/v1/rides',
        headers: organizer.headers,
        payload: {
          title: 'Hill Climb',
          description: 'Climb',
          date: daysFromNow(4),
          meetingPoint: 'Balaju',
          rideType: 'hillClimb',
          difficulty: 'hard',
          distanceKm: 40,
          durationMinutes: 180,
          maxParticipants: 5,
        },
      })
    ).json();
    const reqA = (
      await inject({ method: 'POST', url: `/api/v1/rides/${ride.id}/join`, headers: a.headers, payload: {} })
    ).json();
    const reqB = (
      await inject({ method: 'POST', url: `/api/v1/rides/${ride.id}/join`, headers: b.headers, payload: {} })
    ).json();
    const approved = await inject({
      method: 'POST',
      url: `/api/v1/superadmin/ride-requests/${reqA.id}/approve`,
      headers: admin.headers,
    });
    expect(approved.json().status).toBe('approved');
    const declined = await inject({
      method: 'POST',
      url: `/api/v1/superadmin/ride-requests/${reqB.id}/decline`,
      headers: admin.headers,
      payload: { reason: 'Ride is for advanced riders' },
    });
    expect(declined.json()).toMatchObject({
      status: 'declined',
      declineReason: 'Ride is for advanced riders',
    });
  });
});

describe('announcements', () => {
  it('notifies every active rider and keeps a history', async () => {
    const admin = await registerSuperadmin(ctx.app, ctx.prisma);
    const rider = await registerUser(ctx.app);
    const suspended = await registerUser(ctx.app);
    await inject({
      method: 'POST',
      url: `/api/v1/superadmin/users/${suspended.id}/disable`,
      headers: admin.headers,
      payload: {},
    });

    const sent = await inject({
      method: 'POST',
      url: '/api/v1/superadmin/announcements',
      headers: admin.headers,
      payload: { title: 'Dashain rides', message: 'Group rides are back after the festival.' },
    });
    expect(sent.statusCode, sent.body).toBe(201);
    const total = await ctx.prisma.user.count({ where: { role: 'user', disabledAt: null } });
    expect(sent.json().recipients).toBe(total);

    const inbox = await inject({ method: 'GET', url: '/api/v1/notifications', headers: rider.headers });
    expect(inbox.json().items[0]).toMatchObject({
      type: 'announcement',
      title: 'Dashain rides',
      description: 'Group rides are back after the festival.',
      actorId: null,
    });
    expect(await ctx.prisma.notification.count({ where: { recipientId: suspended.id } })).toBe(0);

    const history = await inject({
      method: 'GET',
      url: '/api/v1/superadmin/announcements',
      headers: admin.headers,
    });
    expect(history.json().items[0]).toMatchObject({
      action: 'announcement.send',
      details: { title: 'Dashain rides', recipients: total },
    });

    const stats = await inject({ method: 'GET', url: '/api/v1/superadmin/stats', headers: admin.headers });
    expect(stats.json().disabledUsers).toBeGreaterThanOrEqual(1);
  });
});
