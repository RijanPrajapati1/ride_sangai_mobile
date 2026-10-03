import type { FastifyBaseLogger } from 'fastify';
import type { AppConfig } from '../config/env.js';
import { UnitOfWork, type PrismaClient } from '../db/prisma.js';
import type { RealtimeHub } from '../realtime/hub.js';
import { AdminRepository } from '../repositories/admin.repository.js';
import { AuthRepository } from '../repositories/auth.repository.js';
import { BannerRepository } from '../repositories/banner.repository.js';
import { ConversationRepository } from '../repositories/conversation.repository.js';
import { GroupRepository } from '../repositories/group.repository.js';
import { NotificationRepository } from '../repositories/notification.repository.js';
import { PlaceRepository } from '../repositories/place.repository.js';
import { PostRepository } from '../repositories/post.repository.js';
import { RideRepository } from '../repositories/ride.repository.js';
import { UploadRepository } from '../repositories/upload.repository.js';
import { UserRepository } from '../repositories/user.repository.js';
import type { Mailer } from '../utils/mailer.js';
import { PasswordHasher } from '../utils/password.js';
import { AdminService } from './admin.service.js';
import { AuthService } from './auth.service.js';
import { ConversationService } from './conversation.service.js';
import { GroupService } from './group.service.js';
import { HomeService } from './home.service.js';
import { NotificationService, type PushSender } from './notification.service.js';
import { PlaceService } from './place.service.js';
import { PostService } from './post.service.js';
import { RideService } from './ride.service.js';
import { TokenService } from './token.service.js';
import { UploadService } from './upload.service.js';
import { UserService } from './user.service.js';
import { LocalDiskStorage } from '../utils/storage.js';

export interface ServiceDependencies {
  config: AppConfig;
  prisma: PrismaClient;
  realtime: RealtimeHub;
  mailer: Mailer;
  log: FastifyBaseLogger;
  push?: PushSender;
}

/**
 * Composition root: builds every repository and service once and wires their
 * dependencies. Controllers receive services from here; nothing else
 * constructs them.
 */
export function createServices(deps: ServiceDependencies) {
  const { config, prisma, realtime, mailer, log } = deps;
  const uow = new UnitOfWork(prisma);

  const repositories = {
    auth: new AuthRepository(prisma),
    user: new UserRepository(prisma),
    notification: new NotificationRepository(prisma),
    ride: new RideRepository(prisma),
    post: new PostRepository(prisma),
    conversation: new ConversationRepository(prisma),
    group: new GroupRepository(prisma),
    banner: new BannerRepository(prisma),
    admin: new AdminRepository(prisma),
    upload: new UploadRepository(prisma),
    place: new PlaceRepository(prisma),
  };

  const passwords = new PasswordHasher(config.auth.hash);
  const tokens = new TokenService(config.auth, repositories.auth);
  const notification = new NotificationService(repositories.notification, realtime, deps.push);

  const auth = new AuthService(uow, repositories.auth, config.auth, passwords, tokens, mailer, realtime, log);
  const user = new UserService(uow, repositories.user, notification, passwords, tokens, realtime);

  const ride = new RideService(uow, repositories.ride, notification);
  const post = new PostService(uow, repositories.post, notification);
  const place = new PlaceService(uow, repositories.place, notification);
  const conversation = new ConversationService(
    uow,
    repositories.conversation,
    repositories.user,
    notification,
    realtime,
  );
  const group = new GroupService(uow, repositories.group, realtime);
  const upload = new UploadService(
    repositories.upload,
    new LocalDiskStorage(config.uploads.dir, config.publicUrl),
  );
  const admin = new AdminService(uow, repositories.admin, user, repositories.banner);
  const home = new HomeService(
    ride,
    post,
    user,
    notification,
    conversation,
    repositories.banner,
    place,
    config.uploads.maxBytes,
  );

  return {
    uow,
    repositories,
    passwords,
    tokens,
    notification,
    auth,
    user,
    ride,
    post,
    conversation,
    group,
    home,
    admin,
    upload,
    place,
  };
}

export type Services = ReturnType<typeof createServices>;
