import { ACTIVITY_CATEGORIES, EXPERIENCE_LEVELS, NOTIFICATION_TYPES, RIDE_DIFFICULTIES, rideTypesFor, type ActivityCategory } from '../constants/enums.js';
import { CATEGORY_LABELS, DIFFICULTY_LABELS, EXPERIENCE_LABELS, RIDE_TYPE_LABELS } from '../constants/labels.js';
import type { BannerRepository } from '../repositories/banner.repository.js';
import type { Banner } from '../generated/prisma/client.js';
import type { ConversationService } from './conversation.service.js';
import type { NotificationService } from './notification.service.js';
import type { PostService } from './post.service.js';
import type { RideService } from './ride.service.js';
import type { UserService, Viewer } from './user.service.js';

/** Maps a banner to the API shape. */
export function toBannerDto(banner: Banner) {
  return {
    id: banner.id,
    category: banner.category,
    title: banner.title,
    subtitle: banner.subtitle,
    ctaLabel: banner.ctaLabel,
    ctaUrl: banner.ctaUrl,
    imageUrl: banner.imageUrl,
    icon: banner.icon,
    theme: banner.theme,
    sortOrder: banner.sortOrder,
    isActive: banner.isActive,
    startsAt: banner.startsAt,
    endsAt: banner.endsAt,
  };
}

/** Screen-shaped reads: the home feed in one round trip, badges and app metadata. */
export class HomeService {
  constructor(
    private readonly rides: RideService,
    private readonly posts: PostService,
    private readonly users: UserService,
    private readonly notifications: NotificationService,
    private readonly conversations: ConversationService,
    private readonly banners: BannerRepository,
    private readonly uploadMaxBytes: number,
  ) {}

  async badges(userId: string) {
    const [unreadNotifications, unreadMessages, pendingRideRequests] = await Promise.all([
      this.notifications.unreadCount(userId),
      this.conversations.totalUnread(userId),
      this.rides.pendingCountFor(userId),
    ]);
    return { unreadNotifications, unreadMessages, pendingRideRequests };
  }

  async listBanners(category?: ActivityCategory) {
    return (await this.banners.active(category)).map(toBannerDto);
  }

  /**
   * Everything the Home screen shows, fetched in parallel: the featured (soonest)
   * ride plus the next six in the category, the two newest posts, recommended
   * riders, banners and badge counts.
   */
  async home(viewer: Viewer & { id: string }, category: ActivityCategory) {
    const [upcoming, posts, recommendedRiders, banners, badges, me] = await Promise.all([
      this.rides.discover(viewer.id, { category, limit: 7 }),
      this.posts.feed(viewer.id, { limit: 2 }),
      this.users.recommended(viewer, { category, limit: 10 }),
      this.banners.active(category),
      this.badges(viewer.id),
      this.users.getProfile(viewer.id, viewer),
    ]);
    const [featuredRide, ...upcomingRides] = upcoming.items;
    return {
      category,
      me,
      featuredRide: featuredRide ?? null,
      upcomingRides,
      communityPreview: posts.items,
      recommendedRiders,
      banners: banners.map(toBannerDto),
      badges,
    };
  }

  /** Enum values and labels so the app can build pickers and filters from the server. */
  meta() {
    return {
      categories: ACTIVITY_CATEGORIES.map((value) => ({
        value,
        ...CATEGORY_LABELS[value],
        rideTypes: rideTypesFor(value).map((type) => ({ value: type, label: RIDE_TYPE_LABELS[type] })),
      })),
      difficulties: RIDE_DIFFICULTIES.map((value) => ({ value, label: DIFFICULTY_LABELS[value] })),
      experienceLevels: EXPERIENCE_LEVELS.map((value) => ({ value, label: EXPERIENCE_LABELS[value] })),
      notificationTypes: [...NOTIFICATION_TYPES],
      limits: {
        rideTitle: 120,
        rideDescription: 5000,
        meetingPoint: 200,
        maxParticipants: { min: 2, max: 1000 },
        postText: 2000,
        commentText: 1000,
        messageText: 2000,
        groupName: 80,
        groupDescription: 1000,
        declineReason: 500,
        bio: 500,
        uploadBytes: this.uploadMaxBytes,
      },
    };
  }
}
