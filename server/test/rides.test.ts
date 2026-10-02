import { describe, expect, it } from 'vitest';
import { useTestApp } from './helpers/context.js';
import { daysFromNow, registerAdmin, registerUser, type TestUser } from './helpers/factories.js';

const ctx = useTestApp();

function rideInput(overrides: Record<string, unknown> = {}) {
  return {
    title: 'Kathmandu Sunrise Ride',
    description: 'Easy social loop before the traffic.',
    date: daysFromNow(2),
    meetingPoint: 'Ratna Park, Kathmandu',
    rideType: 'social',
    difficulty: 'easy',
    distanceKm: 18,
    durationMinutes: 75,
    maxParticipants: 3,
    requirements: ['Helmet', ' helmet ', 'Lights'],
    ...overrides,
  };
}

async function createRide(user: TestUser, overrides: Record<string, unknown> = {}) {
  const res = await ctx.app.inject({ method: 'POST', url: '/api/v1/rides', headers: user.headers, payload: rideInput(overrides) });
  expect(res.statusCode, res.body).toBe(201);
  return res.json();
}

describe('rides', () => {
  it('creates a ride with the organizer counted and derived category', async () => {
    const org = await registerUser(ctx.app);
    const ride = await createRide(org);
    expect(ride).toMatchObject({
      category: 'cycling',
      participantCount: 1,
      joinStatus: 'organizer',
      imageUrl: '',
      requirements: ['Helmet', 'Lights'],
      organizerId: org.id,
      isFull: false,
    });
  });

  it('rejects rides in the past', async () => {
    const org = await registerUser(ctx.app);
    const res = await ctx.app.inject({
      method: 'POST',
      url: '/api/v1/rides',
      headers: org.headers,
      payload: rideInput({ date: daysFromNow(-1) }),
    });
    expect(res.statusCode).toBe(422);
    expect(res.json().error.code).toBe('RIDE_DATE_IN_PAST');
  });

  it('runs the full join → approve / decline → re-request flow', async () => {
    const org = await registerUser(ctx.app, { name: 'Aarav Poudel' });
    const a = await registerUser(ctx.app);
    const b = await registerUser(ctx.app);
    const c = await registerUser(ctx.app);
    const ride = await createRide(org); // max 3 = organizer + 2

    const own = await ctx.app.inject({ method: 'POST', url: `/api/v1/rides/${ride.id}/join`, headers: org.headers, payload: {} });
    expect(own.json().error.code).toBe('CANNOT_JOIN_OWN_RIDE');

    const ra = await ctx.app.inject({ method: 'POST', url: `/api/v1/rides/${ride.id}/join`, headers: a.headers, payload: { message: 'Count me in' } });
    expect(ra.statusCode).toBe(201);
    expect(ra.json()).toMatchObject({ status: 'pending', userBio: 'Count me in' });
    const dup = await ctx.app.inject({ method: 'POST', url: `/api/v1/rides/${ride.id}/join`, headers: a.headers, payload: {} });
    expect(dup.json().error.code).toBe('ALREADY_REQUESTED');
    const rb = (await ctx.app.inject({ method: 'POST', url: `/api/v1/rides/${ride.id}/join`, headers: b.headers, payload: {} })).json();
    const rc = (await ctx.app.inject({ method: 'POST', url: `/api/v1/rides/${ride.id}/join`, headers: c.headers, payload: {} })).json();

    // Only the organizer (or an admin) may decide.
    const notMine = await ctx.app.inject({ method: 'POST', url: `/api/v1/ride-requests/${rb.id}/approve`, headers: a.headers });
    expect(notMine.statusCode).toBe(403);

    const inbox = await ctx.app.inject({ method: 'GET', url: `/api/v1/rides/${ride.id}/requests?status=pending`, headers: org.headers });
    expect(inbox.json().items).toHaveLength(3);

    expect((await ctx.app.inject({ method: 'POST', url: `/api/v1/ride-requests/${ra.json().id}/approve`, headers: org.headers })).statusCode).toBe(200);
    expect((await ctx.app.inject({ method: 'POST', url: `/api/v1/ride-requests/${rb.id}/approve`, headers: org.headers })).statusCode).toBe(200);
    const full = await ctx.app.inject({ method: 'POST', url: `/api/v1/ride-requests/${rc.id}/approve`, headers: org.headers });
    expect(full.json().error.code).toBe('RIDE_FULL');
    const again = await ctx.app.inject({ method: 'POST', url: `/api/v1/ride-requests/${ra.json().id}/approve`, headers: org.headers });
    expect(again.json().error.code).toBe('REQUEST_NOT_PENDING');

    const declined = await ctx.app.inject({
      method: 'POST',
      url: `/api/v1/ride-requests/${rc.id}/decline`,
      headers: org.headers,
      payload: { reason: '  This ride is at capacity for now  ' },
    });
    expect(declined.json()).toMatchObject({ status: 'declined', declineReason: 'This ride is at capacity for now' });

    const asA = (await ctx.app.inject({ method: 'GET', url: `/api/v1/rides/${ride.id}`, headers: a.headers })).json();
    expect(asA).toMatchObject({ participantCount: 3, isFull: true, joinStatus: 'approved' });
    expect(asA.participantAvatars).toHaveLength(2);
    const asC = (await ctx.app.inject({ method: 'GET', url: `/api/v1/rides/${ride.id}`, headers: c.headers })).json();
    expect(asC.joinStatus).toBe('declined');
    expect(asC.myRequest.declineReason).toBe('This ride is at capacity for now');

    const participants = await ctx.app.inject({ method: 'GET', url: `/api/v1/rides/${ride.id}/participants`, headers: c.headers });
    expect(participants.json().items.map((p: { userId: string }) => p.userId)).toEqual([a.id, b.id]);

    // A leaves → a seat frees up → C re-requests (row resets to pending, reason cleared).
    expect((await ctx.app.inject({ method: 'DELETE', url: `/api/v1/rides/${ride.id}/join`, headers: a.headers })).statusCode).toBe(204);
    const re = await ctx.app.inject({ method: 'POST', url: `/api/v1/rides/${ride.id}/join`, headers: c.headers, payload: {} });
    expect(re.statusCode).toBe(201);
    expect(re.json()).toMatchObject({ id: rc.id, status: 'pending', declineReason: null });
    expect((await ctx.app.inject({ method: 'GET', url: `/api/v1/rides/${ride.id}`, headers: c.headers })).json().participantCount).toBe(2);

    // Notifications: organizer heard about requests; riders heard the decisions.
    const orgNotes = await ctx.prisma.notification.findMany({ where: { recipientId: org.id } });
    expect(orgNotes.every((n) => n.type === 'newRideRequest')).toBe(true);
    const aNote = await ctx.prisma.notification.findFirstOrThrow({ where: { recipientId: a.id } });
    expect(aNote).toMatchObject({ type: 'requestApproved', body: 'Aarav Poudel approved your request to join Kathmandu Sunrise Ride.' });
    const cNotes = await ctx.prisma.notification.findMany({ where: { recipientId: c.id } });
    expect(cNotes[0]?.body).toContain('at capacity');
  });

  it('filters discovery by category and search, and serves My Rides scopes', async () => {
    const org = await registerUser(ctx.app);
    const rider = await registerUser(ctx.app);
    await createRide(org, { title: 'Bhaktapur Heritage Loop', date: daysFromNow(3) });
    const trek = await createRide(org, { title: 'Poon Hill Trek', rideType: 'multiDayTrek', date: daysFromNow(5) });

    const cycling = await ctx.app.inject({ method: 'GET', url: '/api/v1/rides?category=cycling', headers: rider.headers });
    expect(cycling.json().items.map((r: { title: string }) => r.title)).toEqual(['Bhaktapur Heritage Loop']);
    const search = await ctx.app.inject({ method: 'GET', url: '/api/v1/rides?q=poon', headers: rider.headers });
    expect(search.json().items.map((r: { id: string }) => r.id)).toEqual([trek.id]);

    const page1 = await ctx.app.inject({ method: 'GET', url: '/api/v1/rides?limit=1', headers: rider.headers });
    expect(page1.json().nextCursor).toEqual(expect.any(String));
    const page2 = await ctx.app.inject({ method: 'GET', url: `/api/v1/rides?limit=1&cursor=${page1.json().nextCursor}`, headers: rider.headers });
    expect(page2.json().items[0].id).toBe(trek.id);
    expect(page2.json().nextCursor).toBeNull();

    await ctx.app.inject({ method: 'POST', url: `/api/v1/rides/${trek.id}/join`, headers: rider.headers, payload: {} });
    const joined = await ctx.app.inject({ method: 'GET', url: '/api/v1/me/rides?scope=joined', headers: rider.headers });
    expect(joined.json().items).toHaveLength(1);
    expect(joined.json().items[0].joinStatus).toBe('pending');
    const organized = await ctx.app.inject({ method: 'GET', url: '/api/v1/me/rides?scope=organized', headers: org.headers });
    expect(organized.json().items).toHaveLength(2);
  });

  it('notifies participants when the organizer edits or cancels, and lets admins remove rides', async () => {
    const org = await registerUser(ctx.app);
    const rider = await registerUser(ctx.app);
    const admin = await registerAdmin(ctx.app, ctx.prisma);
    const ride = await createRide(org);
    const request = (await ctx.app.inject({ method: 'POST', url: `/api/v1/rides/${ride.id}/join`, headers: rider.headers, payload: {} })).json();
    await ctx.app.inject({ method: 'POST', url: `/api/v1/ride-requests/${request.id}/approve`, headers: org.headers });

    const tooSmall = await ctx.app.inject({ method: 'PATCH', url: `/api/v1/rides/${ride.id}`, headers: org.headers, payload: { maxParticipants: 1 } });
    expect(tooSmall.statusCode).toBe(400);
    const edited = await ctx.app.inject({
      method: 'PATCH',
      url: `/api/v1/rides/${ride.id}`,
      headers: org.headers,
      payload: { meetingPoint: 'Thamel Chowk' },
    });
    expect(edited.json().meetingPoint).toBe('Thamel Chowk');
    const update = await ctx.prisma.notification.findFirstOrThrow({ where: { recipientId: rider.id, type: 'rideUpdated' } });
    expect(update.body).toBe('The meeting point for Kathmandu Sunrise Ride has changed.');

    expect((await ctx.app.inject({ method: 'DELETE', url: `/api/v1/rides/${ride.id}`, headers: rider.headers })).statusCode).toBe(403);
    expect((await ctx.app.inject({ method: 'DELETE', url: `/api/v1/rides/${ride.id}`, headers: admin.headers })).statusCode).toBe(204);
    expect((await ctx.app.inject({ method: 'GET', url: `/api/v1/rides/${ride.id}`, headers: rider.headers })).json().error.message).toBe(
      'This ride no longer exists.',
    );
    expect(await ctx.prisma.adminAuditLog.count({ where: { action: 'ride.delete' } })).toBe(1);
  });
});
