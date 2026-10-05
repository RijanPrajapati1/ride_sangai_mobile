/**
 * Starter data only: the superadmin account and the default home banners.
 * Everything else (riders, rides, posts, places, …) is created by real use.
 *
 *   npm run db:seed        (safe to run again: nothing is duplicated)
 *
 * The superadmin login comes from `.env`:
 *   SEED_SUPERADMIN_EMAIL     (default superadmin@ridesangai.app)
 *   SEED_SUPERADMIN_PASSWORD  (default SuperAdmin@123 — required in production)
 *   SEED_SUPERADMIN_NAME      (default Super Admin)
 */
import { loadConfig, loadDotEnv } from '../src/config/env.js';
import { ACTIVITY_CATEGORIES } from '../src/constants/enums.js';
import { createPrisma } from '../src/db/prisma.js';
import { PasswordHasher } from '../src/utils/password.js';

loadDotEnv();
const config = loadConfig();
const prisma = createPrisma(config.db, 'ride-sangai-seed');

const DEV_PASSWORD = 'SuperAdmin@123';

const SAFETY_TIPS = {
  cycling: 'Always wear a certified helmet and run lights after dark.',
  trekking: 'Check the weather and share your route before high-altitude treks.',
  hiking: 'Carry enough water and let someone know your hiking plan.',
  riding: 'Wear a certified helmet and check your bike before long rides.',
} as const;

const NOUNS = {
  cycling: ['ride', 'rides'],
  trekking: ['trek', 'treks'],
  hiking: ['hike', 'hikes'],
  riding: ['ride', 'rides'],
} as const;

function superadminLogin() {
  const email = (process.env.SEED_SUPERADMIN_EMAIL ?? 'superadmin@ridesangai.app').trim().toLowerCase();
  const password = process.env.SEED_SUPERADMIN_PASSWORD ?? '';
  if (config.isProduction && password.length < 12) {
    throw new Error('Set SEED_SUPERADMIN_PASSWORD (12+ characters) before seeding a production database.');
  }
  return {
    email,
    password: password || DEV_PASSWORD,
    name: (process.env.SEED_SUPERADMIN_NAME ?? 'Super Admin').trim(),
  };
}

/** Creates the superadmin, or promotes an existing account with that email. */
async function seedSuperadmin() {
  const login = superadminLogin();
  const existing = await prisma.user.findUnique({ where: { email: login.email }, select: { id: true } });
  if (existing) {
    await prisma.user.update({ where: { id: existing.id }, data: { role: 'superadmin' } });
    return { ...login, created: false };
  }
  const passwordHash = await new PasswordHasher(config.auth.hash).hash(login.password);
  await prisma.user.create({
    data: {
      email: login.email,
      passwordHash,
      name: login.name,
      role: 'superadmin',
      preferences: { create: {} },
    },
  });
  return { ...login, created: true };
}

/** The home carousel: three banners per activity. Only added when there are none. */
async function seedBanners() {
  if ((await prisma.banner.count()) > 0) return 0;
  let sortOrder = 0;
  const banners = ACTIVITY_CATEGORIES.flatMap((category) => {
    const [singular, plural] = NOUNS[category];
    return [
      {
        category,
        title: 'Ride with friends',
        subtitle: `Invite friends to Ride Sangai and plan your next ${singular} together.`,
        ctaLabel: 'Invite friends',
        icon: 'group_add_outlined',
        theme: 'primary',
        sortOrder: sortOrder++,
      },
      {
        category,
        title: "This week's challenge",
        subtitle: `Join 3 ${plural} this week to earn the Explorer badge.`,
        ctaLabel: 'View challenge',
        icon: 'emoji_events_outlined',
        theme: 'secondary',
        sortOrder: sortOrder++,
      },
      {
        category,
        title: 'Safety first',
        subtitle: SAFETY_TIPS[category],
        ctaLabel: 'Read safety tips',
        icon: 'health_and_safety_outlined',
        theme: 'success',
        sortOrder: sortOrder++,
      },
    ];
  });
  const { count } = await prisma.banner.createMany({ data: banners });
  return count;
}

async function main(): Promise<void> {
  const superadmin = await seedSuperadmin();
  const banners = await seedBanners();

  console.log(
    superadmin.created
      ? `Created superadmin ${superadmin.email}`
      : `Superadmin ${superadmin.email} already exists (role confirmed)`,
  );
  console.log(banners > 0 ? `Added ${banners} home banners` : 'Home banners already present');
  if (superadmin.created && superadmin.password === DEV_PASSWORD) {
    console.log(
      `Development login: ${superadmin.email} / ${DEV_PASSWORD} — change it for any shared environment.`,
    );
  }
}

main()
  .catch((err: unknown) => {
    console.error(err);
    process.exitCode = 1;
  })
  .finally(() => prisma.$disconnect());
