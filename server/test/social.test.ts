import type { InjectOptions } from 'fastify';
import { describe, expect, it } from 'vitest';
import { useTestApp } from './helpers/context.js';
import { registerUser } from './helpers/factories.js';

const ctx = useTestApp();
const inject = (options: InjectOptions) => ctx.app.inject(options);

describe('profiles and follows', () => {
  it('edits the profile, keeps counters server-owned and hides email from others', async () => {
    const me = await registerUser(ctx.app, { name: 'Alex Shrestha' });
    const other = await registerUser(ctx.app);
    const patch = await inject({
      method: 'PATCH',
      url: '/api/v1/me',
      headers: me.headers,
      payload: {
        bio: ' Weekend climber ',
        cyclingInterests: ['Hill Climbs', 'hill climbs', ' Coffee Rides '],
        preferredRideType: 'hillClimb',
      },
    });
    expect(patch.statusCode, patch.body).toBe(200);
    expect(patch.json()).toMatchObject({
      bio: 'Weekend climber',
      cyclingInterests: ['Hill Climbs', 'Coffee Rides'],
      isMe: true,
    });
    // Server-owned fields sent by the client (the app sends whole profiles) are ignored.
    const sneaky = await inject({
      method: 'PATCH',
      url: '/api/v1/me',
      headers: me.headers,
      payload: { location: 'Patan', followersCount: 999 },
    });
    expect(sneaky.json()).toMatchObject({ location: 'Patan', followersCount: 0 });

    const seen = (
      await inject({ method: 'GET', url: `/api/v1/users/${me.id}`, headers: other.headers })
    ).json();
    expect(seen.email).toBeNull();
    expect(seen.bio).toBe('Weekend climber');
  });

  it('follows idempotently, keeps both counters right and notifies once', async () => {
    const a = await registerUser(ctx.app, { name: 'Roshani Basnet' });
    const b = await registerUser(ctx.app);
    for (let i = 0; i < 2; i++) {
      const res = await inject({ method: 'PUT', url: `/api/v1/users/${b.id}/follow`, headers: a.headers });
      expect(res.json()).toEqual({ isFollowing: true, followersCount: 1 });
    }
    expect(
      (await inject({ method: 'GET', url: '/api/v1/me', headers: a.headers })).json().followingCount,
    ).toBe(1);
    expect(await ctx.prisma.notification.count({ where: { recipientId: b.id, type: 'newFollower' } })).toBe(
      1,
    );
    const self = await inject({ method: 'PUT', url: `/api/v1/users/${a.id}/follow`, headers: a.headers });
    expect(self.json().error.code).toBe('CANNOT_FOLLOW_SELF');
    const followers = await inject({
      method: 'GET',
      url: `/api/v1/users/${b.id}/followers`,
      headers: b.headers,
    });
    expect(followers.json().items[0]).toMatchObject({ id: a.id, isFollowing: false });
    await inject({ method: 'DELETE', url: `/api/v1/users/${b.id}/follow`, headers: a.headers });
    expect(
      (await inject({ method: 'GET', url: `/api/v1/users/${b.id}`, headers: a.headers })).json(),
    ).toMatchObject({
      followersCount: 0,
      isFollowing: false,
    });
  });

  it('applies privacy settings and recommends only public, unfollowed riders', async () => {
    const me = await registerUser(ctx.app);
    const shy = await registerUser(ctx.app);
    const open = await registerUser(ctx.app);
    await inject({
      method: 'PATCH',
      url: '/api/v1/me',
      headers: shy.headers,
      payload: { bio: 'secret', location: 'Patan' },
    });
    await inject({
      method: 'PATCH',
      url: '/api/v1/me/preferences',
      headers: shy.headers,
      payload: { publicProfile: false },
    });
    const seen = (
      await inject({ method: 'GET', url: `/api/v1/users/${shy.id}`, headers: me.headers })
    ).json();
    expect(seen).toMatchObject({ bio: '', location: '', isPrivate: true });
    const recommended = (
      await inject({ method: 'GET', url: '/api/v1/users/recommended', headers: me.headers })
    ).json();
    expect(recommended.items.map((u: { id: string }) => u.id)).toEqual([open.id]);
    const prefs = (
      await inject({ method: 'GET', url: '/api/v1/me/preferences', headers: shy.headers })
    ).json();
    expect(prefs).toEqual({
      pushRideReminders: true,
      pushMessages: true,
      pushCommunityActivity: true,
      darkModeEnabled: false,
      publicProfile: false,
      showRidingStats: true,
    });
  });
});

describe('community', () => {
  it('posts, likes idempotently, comments and keeps counters', async () => {
    const author = await registerUser(ctx.app);
    const fan = await registerUser(ctx.app, { name: 'Kabita Lama' });
    const post = (
      await inject({
        method: 'POST',
        url: '/api/v1/posts',
        headers: author.headers,
        payload: { text: 'Nagarkot climb done!', imageUrl: '' },
      })
    ).json();
    expect(post).toMatchObject({ imageUrl: null, likeCount: 0, isLiked: false, isMine: true });

    await inject({ method: 'PUT', url: `/api/v1/posts/${post.id}/like`, headers: fan.headers });
    const again = await inject({ method: 'PUT', url: `/api/v1/posts/${post.id}/like`, headers: fan.headers });
    expect(again.json()).toEqual({ isLiked: true, likeCount: 1 });
    const comment = await inject({
      method: 'POST',
      url: `/api/v1/posts/${post.id}/comments`,
      headers: fan.headers,
      payload: { text: 'Inspiring!' },
    });
    expect(comment.statusCode).toBe(201);

    const feed = (await inject({ method: 'GET', url: '/api/v1/posts?limit=2', headers: fan.headers })).json();
    expect(feed.items[0]).toMatchObject({
      id: post.id,
      likeCount: 1,
      commentCount: 1,
      isLiked: true,
      isMine: false,
    });
    const comments = (
      await inject({ method: 'GET', url: `/api/v1/posts/${post.id}/comments`, headers: author.headers })
    ).json();
    expect(comments.items[0]).toMatchObject({ text: 'Inspiring!', userName: 'Kabita Lama' });

    const types = (await ctx.prisma.notification.findMany({ where: { recipientId: author.id } }))
      .map((n) => n.type)
      .sort();
    expect(types).toEqual(['comment', 'like']);

    expect(
      (await inject({ method: 'DELETE', url: `/api/v1/posts/${post.id}`, headers: fan.headers })).statusCode,
    ).toBe(403);
    expect(
      (await inject({ method: 'DELETE', url: `/api/v1/posts/${post.id}`, headers: author.headers }))
        .statusCode,
    ).toBe(204);
    const gone = await inject({ method: 'GET', url: `/api/v1/posts/${post.id}`, headers: fan.headers });
    expect(gone.json().error.message).toBe('This post could not be found.');
  });
});

describe('messages', () => {
  it('opens one conversation per pair, tracks unread and marks read on open', async () => {
    const a = await registerUser(ctx.app, { name: 'Aarav Poudel' });
    const b = await registerUser(ctx.app);
    const open1 = await inject({
      method: 'POST',
      url: '/api/v1/conversations',
      headers: a.headers,
      payload: { userId: b.id },
    });
    expect(open1.statusCode).toBe(201);
    expect(open1.json()).toMatchObject({ userId: b.id, lastMessage: 'Say hello 👋', unreadCount: 0 });
    const open2 = await inject({
      method: 'POST',
      url: '/api/v1/conversations',
      headers: b.headers,
      payload: { userId: a.id },
    });
    expect(open2.statusCode).toBe(200);
    expect(open2.json().id).toBe(open1.json().id);
    const self = await inject({
      method: 'POST',
      url: '/api/v1/conversations',
      headers: a.headers,
      payload: { userId: a.id },
    });
    expect(self.json().error.code).toBe('CANNOT_MESSAGE_SELF');

    const id = open1.json().id;
    for (const text of ['Hey! Sunrise ride Saturday?', 'Ratna Park, 5:30am']) {
      const sent = await inject({
        method: 'POST',
        url: `/api/v1/conversations/${id}/messages`,
        headers: a.headers,
        payload: { text },
      });
      expect(sent.json().isMe).toBe(true);
    }
    const inbox = (await inject({ method: 'GET', url: '/api/v1/conversations', headers: b.headers })).json();
    expect(inbox.items[0]).toMatchObject({
      userName: 'Aarav Poudel',
      lastMessage: 'Ratna Park, 5:30am',
      unreadCount: 2,
    });
    expect(
      (await inject({ method: 'GET', url: '/api/v1/me/badges', headers: b.headers })).json(),
    ).toMatchObject({
      unreadMessages: 2,
      unreadNotifications: 1,
    });

    const history = (
      await inject({ method: 'GET', url: `/api/v1/conversations/${id}/messages`, headers: b.headers })
    ).json();
    expect(history.items.map((m: { text: string; isMe: boolean }) => [m.text, m.isMe])).toEqual([
      ['Hey! Sunrise ride Saturday?', false],
      ['Ratna Park, 5:30am', false],
    ]);
    expect(
      (await inject({ method: 'GET', url: '/api/v1/conversations/unread-count', headers: b.headers })).json()
        .count,
    ).toBe(0);

    const outsider = await registerUser(ctx.app);
    expect(
      (
        await inject({
          method: 'GET',
          url: `/api/v1/conversations/${id}/messages`,
          headers: outsider.headers,
        })
      ).statusCode,
    ).toBe(404);
  });
});

describe('groups', () => {
  it('creates, joins idempotently, chats and enforces membership and ownership', async () => {
    const owner = await registerUser(ctx.app);
    const rider = await registerUser(ctx.app);
    const group = (
      await inject({
        method: 'POST',
        url: '/api/v1/groups',
        headers: owner.headers,
        payload: { name: 'Kathmandu Riders', description: 'Sunrise loops' },
      })
    ).json();
    expect(group).toMatchObject({ memberCount: 1, isJoined: true, myRole: 'owner', coverImageUrl: null });

    const notMember = await inject({
      method: 'POST',
      url: `/api/v1/groups/${group.id}/messages`,
      headers: rider.headers,
      payload: { text: 'hi' },
    });
    expect(notMember.json().error.code).toBe('NOT_A_MEMBER');
    await inject({ method: 'POST', url: `/api/v1/groups/${group.id}/join`, headers: rider.headers });
    const joined = (
      await inject({ method: 'POST', url: `/api/v1/groups/${group.id}/join`, headers: rider.headers })
    ).json();
    expect(joined).toMatchObject({ memberCount: 2, isJoined: true, myRole: 'member' });

    await inject({
      method: 'POST',
      url: `/api/v1/groups/${group.id}/messages`,
      headers: rider.headers,
      payload: { text: 'Count me in!' },
    });
    const chat = (
      await inject({ method: 'GET', url: `/api/v1/groups/${group.id}/messages`, headers: owner.headers })
    ).json();
    expect(chat.items[0]).toMatchObject({ text: 'Count me in!', isMe: false });

    const popular = (
      await inject({ method: 'GET', url: '/api/v1/groups?sort=popular', headers: rider.headers })
    ).json();
    expect(popular.items[0].id).toBe(group.id);
    expect(
      (await inject({ method: 'GET', url: '/api/v1/groups/mine', headers: rider.headers })).json().items,
    ).toHaveLength(1);

    const ownerLeave = await inject({
      method: 'POST',
      url: `/api/v1/groups/${group.id}/leave`,
      headers: owner.headers,
    });
    expect(ownerLeave.json().error.code).toBe('OWNER_CANNOT_LEAVE');
    expect(
      (await inject({ method: 'POST', url: `/api/v1/groups/${group.id}/leave`, headers: rider.headers }))
        .statusCode,
    ).toBe(204);
    expect(
      (await inject({ method: 'DELETE', url: `/api/v1/groups/${group.id}`, headers: rider.headers }))
        .statusCode,
    ).toBe(403);
    expect(
      (await inject({ method: 'DELETE', url: `/api/v1/groups/${group.id}`, headers: owner.headers }))
        .statusCode,
    ).toBe(204);
    expect(
      (await inject({ method: 'GET', url: `/api/v1/groups/${group.id}`, headers: owner.headers })).json()
        .error.message,
    ).toBe('This group no longer exists.');
  });
});

describe('notifications', () => {
  it('lists with unread count, collapses DM notifications and marks read', async () => {
    const a = await registerUser(ctx.app);
    const b = await registerUser(ctx.app);
    const conv = (
      await inject({
        method: 'POST',
        url: '/api/v1/conversations',
        headers: a.headers,
        payload: { userId: b.id },
      })
    ).json();
    for (const text of ['one', 'two', 'three']) {
      await inject({
        method: 'POST',
        url: `/api/v1/conversations/${conv.id}/messages`,
        headers: a.headers,
        payload: { text },
      });
    }
    const list = (await inject({ method: 'GET', url: '/api/v1/notifications', headers: b.headers })).json();
    expect(list.unreadCount).toBe(1);
    expect(list.items).toHaveLength(1);
    expect(list.items[0]).toMatchObject({
      type: 'newMessage',
      entityType: 'conversation',
      entityId: conv.id,
      isRead: false,
    });
    expect(list.items[0].description).toContain('three');

    const read = await inject({
      method: 'POST',
      url: `/api/v1/notifications/${list.items[0].id}/read`,
      headers: b.headers,
    });
    expect(read.json()).toEqual({ count: 0 });
    // After reading, the next message creates a fresh notification.
    await inject({
      method: 'POST',
      url: `/api/v1/conversations/${conv.id}/messages`,
      headers: a.headers,
      payload: { text: 'four' },
    });
    expect(
      (await inject({ method: 'GET', url: '/api/v1/notifications/unread-count', headers: b.headers })).json()
        .count,
    ).toBe(1);
    expect(
      (
        await inject({
          method: 'POST',
          url: '/api/v1/notifications/read-all',
          headers: b.headers,
          payload: {},
        })
      ).json(),
    ).toEqual({ updated: 1 });
    const foreign = await inject({
      method: 'POST',
      url: `/api/v1/notifications/${list.items[0].id}/read`,
      headers: a.headers,
    });
    expect(foreign.statusCode).toBe(404);
  });
});
