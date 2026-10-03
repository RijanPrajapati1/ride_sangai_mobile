import type { Db, PrismaClient } from '../db/prisma.js';
import type { Prisma } from '../db/prisma.js';

function groupInclude(viewerId: string | null) {
  return {
    owner: { select: { id: true, name: true } },
    members: viewerId ? { where: { userId: viewerId }, select: { role: true }, take: 1 } : false,
  } satisfies Prisma.GroupInclude;
}

export type GroupRecord = Prisma.GroupGetPayload<{ include: ReturnType<typeof groupInclude> }>;

const messageSelect = {
  id: true,
  groupId: true,
  senderId: true,
  text: true,
  createdAt: true,
  sender: { select: { name: true, avatarUrl: true } },
} satisfies Prisma.GroupMessageSelect;

export type GroupMessageRecord = Prisma.GroupMessageGetPayload<{ select: typeof messageSelect }>;

export type GroupSort = 'popular' | 'newest';

/** Data access for groups, memberships and group chat. */
export class GroupRepository {
  constructor(private readonly prisma: PrismaClient) {}

  /**
   * popular: most members first (keyset on memberCount, createdAt, id);
   * newest: most recently created first (keyset on createdAt, id).
   */
  findPage(options: {
    viewerId: string | null;
    sort: GroupSort;
    q?: string;
    after: { memberCount?: number; createdAt: Date; id: string } | null;
    limit: number;
  }) {
    const { after } = options;
    const q = options.q?.trim();
    let keyset: Prisma.GroupWhereInput = {};
    if (after && options.sort === 'popular' && after.memberCount !== undefined) {
      keyset = {
        OR: [
          { memberCount: { lt: after.memberCount } },
          { memberCount: after.memberCount, createdAt: { lt: after.createdAt } },
          { memberCount: after.memberCount, createdAt: after.createdAt, id: { lt: after.id } },
        ],
      };
    } else if (after) {
      keyset = {
        OR: [{ createdAt: { lt: after.createdAt } }, { createdAt: after.createdAt, id: { lt: after.id } }],
      };
    }
    const orderBy: Prisma.GroupOrderByWithRelationInput[] =
      options.sort === 'popular'
        ? [{ memberCount: 'desc' }, { createdAt: 'desc' }, { id: 'desc' }]
        : [{ createdAt: 'desc' }, { id: 'desc' }];
    return this.prisma.group.findMany({
      where: { AND: [q ? { name: { contains: q, mode: 'insensitive' } } : {}, keyset] },
      orderBy,
      take: options.limit + 1,
      include: groupInclude(options.viewerId),
    });
  }

  /** Groups the user belongs to, most recently joined first (keyset on joinedAt, groupId). */
  findMine(userId: string, after: [Date, string] | null, limit: number) {
    return this.prisma.groupMember.findMany({
      where: {
        userId,
        ...(after
          ? { OR: [{ joinedAt: { lt: after[0] } }, { joinedAt: after[0], groupId: { lt: after[1] } }] }
          : {}),
      },
      orderBy: [{ joinedAt: 'desc' }, { groupId: 'desc' }],
      take: limit + 1,
      select: { joinedAt: true, groupId: true, group: { include: groupInclude(userId) } },
    });
  }

  findById(id: string, viewerId: string | null, db: Db = this.prisma): Promise<GroupRecord | null> {
    return db.group.findUnique({ where: { id }, include: groupInclude(viewerId) });
  }

  findBasic(id: string, db: Db = this.prisma) {
    return db.group.findUnique({ where: { id }, select: { id: true, name: true, ownerId: true } });
  }

  /** Creates the group with its creator as owner (memberCount becomes 1 via trigger). */
  async create(data: { ownerId: string; name: string; description: string; coverImageUrl: string | null }) {
    return this.prisma.group.create({
      data: { ...data, members: { create: { userId: data.ownerId, role: 'owner' } } },
      select: { id: true },
    });
  }

  async update(id: string, data: Prisma.GroupUpdateInput): Promise<void> {
    await this.prisma.group.update({ where: { id }, data, select: { id: true } });
  }

  async delete(id: string, db: Db = this.prisma): Promise<void> {
    await db.group.deleteMany({ where: { id } });
  }

  membership(groupId: string, userId: string, db: Db = this.prisma) {
    return db.groupMember.findUnique({
      where: { groupId_userId: { groupId, userId } },
      select: { role: true },
    });
  }

  async addMember(groupId: string, userId: string): Promise<void> {
    await this.prisma.groupMember.createMany({ data: [{ groupId, userId }], skipDuplicates: true });
  }

  async removeMember(groupId: string, userId: string): Promise<void> {
    await this.prisma.groupMember.deleteMany({ where: { groupId, userId } });
  }

  async memberIds(groupId: string): Promise<string[]> {
    const rows = await this.prisma.groupMember.findMany({ where: { groupId }, select: { userId: true } });
    return rows.map((row) => row.userId);
  }

  /** Members in join order (keyset on joinedAt, userId). */
  membersPage(groupId: string, after: [Date, string] | null, limit: number) {
    return this.prisma.groupMember.findMany({
      where: {
        groupId,
        ...(after
          ? { OR: [{ joinedAt: { gt: after[0] } }, { joinedAt: after[0], userId: { gt: after[1] } }] }
          : {}),
      },
      orderBy: [{ joinedAt: 'asc' }, { userId: 'asc' }],
      take: limit + 1,
      select: {
        role: true,
        joinedAt: true,
        userId: true,
        user: { select: { id: true, name: true, avatarUrl: true } },
      },
    });
  }

  /** Newest first (keyset on createdAt, id); callers reverse for display. */
  messagesPage(groupId: string, before: [Date, string] | null, limit: number) {
    return this.prisma.groupMessage.findMany({
      where: {
        groupId,
        ...(before
          ? { OR: [{ createdAt: { lt: before[0] } }, { createdAt: before[0], id: { lt: before[1] } }] }
          : {}),
      },
      orderBy: [{ createdAt: 'desc' }, { id: 'desc' }],
      take: limit + 1,
      select: messageSelect,
    });
  }

  createMessage(data: { groupId: string; senderId: string; text: string }): Promise<GroupMessageRecord> {
    return this.prisma.groupMessage.create({ data, select: messageSelect });
  }
}
