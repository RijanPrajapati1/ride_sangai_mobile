import { randomUUID } from 'node:crypto';
import type { TypeBoxTypeProvider } from '@fastify/type-provider-typebox';
import websocket from '@fastify/websocket';
import Fastify, { type FastifyInstance, type FastifyServerOptions } from 'fastify';
import type { AppConfig } from './config/env.js';
import { createPrisma, type PrismaClient } from './db/prisma.js';
import { LogMailer, type Mailer } from './utils/mailer.js';
import { createServices } from './services/index.js';
import { registerRoutes } from './routes/index.js';
import type { PushSender } from './services/notification.service.js';
import authenticate from './middlewares/authenticate.js';
import docs from './middlewares/docs.js';
import errorHandler from './middlewares/error-handler.js';
import security from './middlewares/security.js';
import { RealtimeHub } from './realtime/hub.js';
import './types/fastify.js';

export interface AppDependencies {
  /** Share a Prisma client across app instances (tests). The app then won't disconnect it. */
  prisma?: PrismaClient;
  mailer?: Mailer;
  push?: PushSender;
  logger?: FastifyServerOptions['logger'];
}

export type App = FastifyInstance;

function loggerOptions(config: AppConfig): FastifyServerOptions['logger'] {
  const base = {
    level: config.logLevel,
    redact: {
      paths: [
        'req.headers.authorization',
        'req.headers.cookie',
        '*.password',
        '*.currentPassword',
        '*.newPassword',
        '*.refreshToken',
        '*.accessToken',
        '*.token',
      ],
      censor: '[redacted]',
    },
    serializers: {
      // Never log `?access_token=` (WebSocket upgrades).
      req: (req: { method: string; url: string; id: string; ip?: string }) => ({
        id: req.id,
        method: req.method,
        url: req.url.replace(/([?&]access_token=)[^&]+/, '$1[redacted]'),
        ip: req.ip,
      }),
    },
  };
  if (config.env === 'development') {
    return {
      ...base,
      transport: { target: 'pino-pretty', options: { translateTime: 'HH:MM:ss.l', ignore: 'pid,hostname' } },
    };
  }
  return base;
}

/**
 * Builds a fully wired Fastify instance without listening. `server.ts` calls
 * this for production; tests call it and use `app.inject()`.
 */
export async function buildApp(config: AppConfig, deps: AppDependencies = {}): Promise<App> {
  const app = Fastify({
    logger: deps.logger ?? loggerOptions(config),
    trustProxy: config.trustProxy,
    bodyLimit: config.bodyLimitBytes,
    requestIdHeader: 'x-request-id',
    genReqId: () => randomUUID(),
    // Graceful shutdown: stop accepting keep-alive requests and let in-flight ones finish.
    return503OnClosing: true,
    forceCloseConnections: 'idle',
    ajv: {
      customOptions: {
        removeAdditional: true,
        useDefaults: true,
        coerceTypes: 'array',
        allErrors: false,
      },
    },
  }).withTypeProvider<TypeBoxTypeProvider>();

  const prisma = deps.prisma ?? createPrisma(config.db);
  const realtime = new RealtimeHub(app.log);
  const mailer = deps.mailer ?? new LogMailer(app.log);

  app.decorate('config', config);
  app.decorate('prisma', prisma);
  app.decorate('realtime', realtime);
  app.decorate(
    'services',
    createServices({
      config,
      prisma,
      realtime,
      mailer,
      log: app.log,
      ...(deps.push ? { push: deps.push } : {}),
    }),
  );

  await app.register(errorHandler);
  await app.register(authenticate);
  await app.register(security);
  if (config.docs.enabled) await app.register(docs);
  if (config.realtime.enabled) await app.register(websocket, { options: { maxPayload: 16 * 1024 } });

  await registerRoutes(app);

  app.addHook('onClose', async () => {
    realtime.closeAll();
    if (!deps.prisma) await prisma.$disconnect();
  });

  return app;
}
