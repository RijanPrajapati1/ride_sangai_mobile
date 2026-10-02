import type { FastifyInstance } from 'fastify';
import { sendRideReminders } from './ride-reminders.js';

interface Job {
  name: string;
  everyMs: number;
  run: () => Promise<unknown>;
}

/**
 * In-process scheduler for background jobs. Each job is safe to run on many
 * instances at once; a job never overlaps with itself on one instance.
 * Returns a function that stops all jobs.
 */
export function startJobs(app: FastifyInstance): () => void {
  const jobs: Job[] = [
    {
      name: 'ride-reminders',
      everyMs: 60_000,
      run: () => sendRideReminders(app, app.config.jobs.rideReminderLeadMinutes),
    },
    {
      name: 'auth-housekeeping',
      everyMs: 60 * 60_000,
      run: () => app.services.repositories.auth.purgeExpired(),
    },
  ];

  const timers = jobs.map((job) => {
    let running = false;
    const tick = async () => {
      if (running) return;
      running = true;
      try {
        const result = await job.run();
        app.log.debug({ job: job.name, result }, 'Job finished');
      } catch (err) {
        app.log.error({ err, job: job.name }, 'Job failed');
      } finally {
        running = false;
      }
    };
    const timer = setInterval(tick, job.everyMs);
    timer.unref();
    setTimeout(tick, 5_000).unref();
    return timer;
  });

  return () => timers.forEach(clearInterval);
}
