import closeWithGrace from 'close-with-grace';
import { buildApp } from './app.js';
import { loadConfig, loadDotEnv } from './config/env.js';
import { startJobs } from './jobs/index.js';

loadDotEnv();
const config = loadConfig();
const app = await buildApp(config);

try {
  await app.listen({ host: config.host, port: config.port });
} catch (err) {
  app.log.fatal({ err }, 'Failed to start the server');
  await app.close().catch(() => undefined);
  process.exit(1);
}

const stopJobs = config.jobs.enabled ? startJobs(app) : () => undefined;

app.log.info(
  { env: config.env, docs: config.docs.enabled ? `${config.publicUrl}/docs` : 'disabled' },
  `Ride Sangai API listening on ${config.host}:${config.port}`,
);

// Migrations are applied by `prisma migrate deploy` (see `npm start` / `npm run db:migrate`).

// SIGINT/SIGTERM/uncaught errors: stop jobs, finish in-flight requests, close the pool.
closeWithGrace({ delay: 10_000 }, async ({ signal, err }) => {
  if (err) app.log.error({ err }, 'Shutting down after an unexpected error');
  else app.log.info({ signal }, 'Shutting down');
  stopJobs();
  await app.close();
});
