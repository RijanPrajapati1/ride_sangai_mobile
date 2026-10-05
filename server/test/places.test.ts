import type { InjectOptions } from 'fastify';
import { describe, expect, it } from 'vitest';
import { useTestApp } from './helpers/context.js';
import { registerAdmin, registerUser, type TestUser } from './helpers/factories.js';

const ctx = useTestApp();
const inject = (options: InjectOptions) => ctx.app.inject(options);

// Thamel, Kathmandu
const ME = { lat: 27.7154, lng: 85.3123 };

async function share(user: TestUser, overrides: Record<string, unknown> = {}) {
  const res = await inject({
    method: 'POST',
    url: '/api/v1/places',
    headers: user.headers,
    payload: {
      name: 'Taudaha Lake',
      description: 'Quiet lake with migratory birds, 20 minutes from the ring road.',
      category: 'lake',
      latitude: 27.6476,
      longitude: 85.2813,
      locationName: 'Taudaha, Kirtipur',
      photos: ['https://picsum.photos/seed/taudaha/900/600'],
      activities: ['cycling', 'hiking', 'cycling'],
      bestTime: ' November to February ',
      ...overrides,
    },
  });
  expect(res.statusCode, res.body).toBe(201);
  return res.json();
}

describe('explore places', () => {
  it('shares a place and finds it nearby, nearest first, within the radius', async () => {
    const local = await registerUser(ctx.app);
    const visitor = await registerUser(ctx.app);
    const taudaha = await share(local);
    expect(taudaha).toMatchObject({
      activities: ['cycling', 'hiking'],
      bestTime: 'November to February',
      coverImageUrl: 'https://picsum.photos/seed/taudaha/900/600',
      averageRating: null,
      worthItPercent: null,
      isMine: true,
    });
    const kakani = await share(local, {
      name: 'Kakani Viewpoint',
      category: 'viewpoint',
      latitude: 27.804,
      longitude: 85.2546,
      locationName: 'Kakani, Nuwakot',
    });
    await share(local, {
      name: 'Pokhara Bat Cave',
      category: 'cave',
      latitude: 28.2394,
      longitude: 83.9566,
      locationName: 'Batulechaur, Pokhara',
    });

    const near = (
      await inject({
        method: 'GET',
        url: `/api/v1/places/nearby?lat=${ME.lat}&lng=${ME.lng}&radiusKm=25`,
        headers: visitor.headers,
      })
    ).json();
    expect(near.items.map((p: { name: string }) => p.name)).toEqual(['Taudaha Lake', 'Kakani Viewpoint']);
    expect(near.items[0].distanceKm).toBeGreaterThan(8);
    expect(near.items[0].distanceKm).toBeLessThan(10);

    const page1 = (
      await inject({
        method: 'GET',
        url: `/api/v1/places/nearby?lat=${ME.lat}&lng=${ME.lng}&limit=1`,
        headers: visitor.headers,
      })
    ).json();
    const page2 = (
      await inject({
        method: 'GET',
        url: `/api/v1/places/nearby?lat=${ME.lat}&lng=${ME.lng}&limit=1&cursor=${page1.nextCursor}`,
        headers: visitor.headers,
      })
    ).json();
    expect(page2.items[0].id).toBe(kakani.id);

    const lakes = (
      await inject({
        method: 'GET',
        url: `/api/v1/places/nearby?lat=${ME.lat}&lng=${ME.lng}&category=lake`,
        headers: visitor.headers,
      })
    ).json();
    expect(lakes.items).toHaveLength(1);
    const searched = (
      await inject({ method: 'GET', url: '/api/v1/places?q=kakani', headers: visitor.headers })
    ).json();
    expect(searched.items.map((p: { id: string }) => p.id)).toEqual([kakani.id]);
  });

  it('reviews: one per rider, aggregates, no self-review, author notified', async () => {
    const local = await registerUser(ctx.app);
    const a = await registerUser(ctx.app, { name: 'Priya Gurung' });
    const b = await registerUser(ctx.app);
    const place = await share(local);

    const own = await inject({
      method: 'PUT',
      url: `/api/v1/places/${place.id}/review`,
      headers: local.headers,
      payload: { rating: 5, worthIt: true },
    });
    expect(own.json().error.code).toBe('CANNOT_REVIEW_OWN_PLACE');

    const first = await inject({
      method: 'PUT',
      url: `/api/v1/places/${place.id}/review`,
      headers: a.headers,
      payload: { rating: 5, worthIt: true, text: 'Go at sunrise!', visitedOn: '2026-09-20' },
    });
    expect(first.statusCode).toBe(201);
    expect(first.json()).toMatchObject({ rating: 5, visitedOn: '2026-09-20', isMine: true });
    await inject({
      method: 'PUT',
      url: `/api/v1/places/${place.id}/review`,
      headers: b.headers,
      payload: { rating: 2, worthIt: false },
    });

    let details = (
      await inject({
        method: 'GET',
        url: `/api/v1/places/${place.id}?lat=${ME.lat}&lng=${ME.lng}`,
        headers: a.headers,
      })
    ).json();
    expect(details).toMatchObject({
      averageRating: 3.5,
      reviewCount: 2,
      worthItPercent: 50,
      myReview: { rating: 5, worthIt: true },
    });
    expect(details.distanceKm).toBeGreaterThan(0);

    // Editing replaces the review and the aggregates follow.
    const edit = await inject({
      method: 'PUT',
      url: `/api/v1/places/${place.id}/review`,
      headers: b.headers,
      payload: { rating: 4, worthIt: true },
    });
    expect(edit.statusCode).toBe(200);
    details = (await inject({ method: 'GET', url: `/api/v1/places/${place.id}`, headers: a.headers })).json();
    expect(details).toMatchObject({
      averageRating: 4.5,
      reviewCount: 2,
      worthItPercent: 100,
      distanceKm: null,
    });

    const reviews = (
      await inject({ method: 'GET', url: `/api/v1/places/${place.id}/reviews`, headers: local.headers })
    ).json();
    expect(reviews.items).toHaveLength(2);
    const notes = await ctx.prisma.notification.findMany({
      where: { recipientId: local.id, type: 'placeReview' },
    });
    expect(notes).toHaveLength(2);
    expect(notes.map((n) => n.body)).toContain('Priya Gurung rated Taudaha Lake 5★ — worth the trip!');

    expect(
      (await inject({ method: 'DELETE', url: `/api/v1/places/${place.id}/review`, headers: b.headers }))
        .statusCode,
    ).toBe(204);
    details = (await inject({ method: 'GET', url: `/api/v1/places/${place.id}`, headers: a.headers })).json();
    expect(details).toMatchObject({ averageRating: 5, reviewCount: 1, worthItPercent: 100 });

    const top = (await inject({ method: 'GET', url: '/api/v1/places?sort=top', headers: a.headers })).json();
    expect(top.items[0].id).toBe(place.id);
  });

  it('saves places idempotently, lists them, and lets admins remove places', async () => {
    const local = await registerUser(ctx.app);
    const visitor = await registerUser(ctx.app);
    const admin = await registerAdmin(ctx.app, ctx.prisma);
    const place = await share(local);

    await inject({ method: 'PUT', url: `/api/v1/places/${place.id}/save`, headers: visitor.headers });
    const again = await inject({
      method: 'PUT',
      url: `/api/v1/places/${place.id}/save`,
      headers: visitor.headers,
    });
    expect(again.json()).toEqual({ isSaved: true, saveCount: 1 });
    const saved = (
      await inject({ method: 'GET', url: '/api/v1/me/saved-places', headers: visitor.headers })
    ).json();
    expect(saved.items[0]).toMatchObject({ id: place.id, isSaved: true });
    expect(
      (
        await inject({ method: 'GET', url: `/api/v1/users/${local.id}/places`, headers: visitor.headers })
      ).json().items,
    ).toHaveLength(1);

    const bad = await inject({
      method: 'PATCH',
      url: `/api/v1/places/${place.id}`,
      headers: visitor.headers,
      payload: { name: 'Mine now' },
    });
    expect(bad.statusCode).toBe(403);
    const coords = await inject({
      method: 'POST',
      url: '/api/v1/places',
      headers: local.headers,
      payload: {
        name: 'x',
        description: 'y',
        category: 'lake',
        latitude: 120,
        longitude: 85,
        locationName: 'z',
      },
    });
    expect(coords.statusCode).toBe(400);

    expect(
      (await inject({ method: 'GET', url: '/api/v1/superadmin/stats', headers: admin.headers })).json().places,
    ).toBe(1);
    expect(
      (await inject({ method: 'DELETE', url: `/api/v1/superadmin/places/${place.id}`, headers: admin.headers }))
        .statusCode,
    ).toBe(204);
    const gone = await inject({ method: 'GET', url: `/api/v1/places/${place.id}`, headers: visitor.headers });
    expect(gone.json().error.message).toBe('This place could not be found.');
  });

  it('shows places to explore on the home feed', async () => {
    const local = await registerUser(ctx.app);
    const visitor = await registerUser(ctx.app);
    await share(local);
    const withLocation = (
      await inject({
        method: 'GET',
        url: `/api/v1/home?category=hiking&lat=${ME.lat}&lng=${ME.lng}`,
        headers: visitor.headers,
      })
    ).json();
    expect(withLocation.explorePlaces[0]).toMatchObject({ name: 'Taudaha Lake' });
    expect(withLocation.explorePlaces[0].distanceKm).not.toBeNull();
    const riding = (
      await inject({ method: 'GET', url: '/api/v1/home?category=riding', headers: visitor.headers })
    ).json();
    expect(riding.explorePlaces).toHaveLength(0);
    const meta = (await inject({ method: 'GET', url: '/api/v1/meta' })).json();
    expect(meta.placeCategories).toContainEqual({ value: 'waterfall', label: 'Waterfall' });
  });
});
