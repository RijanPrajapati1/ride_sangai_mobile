import type { UnitOfWork } from '../db/prisma.js';
import type { RealtimeHub } from '../realtime/hub.js';
import type { GroupMessageRecord, GroupRecord, GroupRepository, GroupSort } from '../repositories/group.repository.js';
import { audit } from '../utils/audit.js';
import { badRequest, conflict, forbidden, notFound } from '../utils/errors.js';
import { decodeCursor, decodeTimeCursor, pageLimit, timeCursor, toPage } from '../utils/pagination.js';
import { assertImageUrl, blankToNull } from '../utils/validation.js';
import type { Actor } from './ride.service.js';

const GROUP_NOT_FOUND = () => notFound('This group no longer exists.', 'GROUP_NOT_FOUND');

/** Maps a group to the API shape (the Dart `Group` entity) for one viewer. */
export function toGroupDto(group: GroupRecord) {
  const membership = Array.isArray(group.members) ? group.members[0] : undefined;
  return {
    id: group.id,
    name: group.name,
    description: group.description,
    coverImageUrl: group.coverImageUrl,
    memberCount: group.memberCount,
    isJoined: membership !== undefined,
    myRole: membership?.role ?? null,
    organizerId: group.owner.id,
    organizerName: group.owner.name,
    lastMessageAt: group.lastMessageAt,
    createdAt: group.createdAt,
  };
}

export type GroupDto = ReturnType<typeof toGroupDto>;

/** Maps a group message to the API shape (the Dart `GroupMessage` entity) for one viewer. */
export function toGroupMessageDto(message: GroupMessageRecord, viewerId: string) {
  return {
    id: message.id,
    groupId: message.groupId,
    senderId: message.senderId,
    senderName: message.sender.name,
    senderAvatarUrl: message.sender.avatarUrl,
    text: message.text,
    sentAt: message.createdAt,
    isMe: message.senderId === viewerId,
  };
}

function cleanCover(url: string | null | undefined): string | null {
  const cover = blankToNull(url);
  if (cover) assertImageUrl(cover, 'coverImageUrl');
  return cover;
}

/** Rider groups and group chat. */
export class GroupService {
  constructor(
    private readonly uow: UnitOfWork,
    readonly repo: GroupRepository,
    private readonly realtime: RealtimeHub,
  ) {}

  async list(viewerId: string, query: { sort?: GroupSort; q?: string; limit?: number; cursor?: string }) {
    const sort = query.sort ?? 'popular';
    const limit = pageLimit(query.limit);
    let after: { memberCount?: number; createdAt: Date; id: string } | null = null;
    if (sort === 'popular') {
      const parts = decodeCursor(query.cursor, ['number', 'string', 'string']);
      if (parts) {
        const createdAt = new Date(parts[1] as string);
        if (Number.isNaN(createdAt.getTime())) throw badRequest('The pagination cursor is invalid or expired.', 'INVALID_CURSOR');
        after = { memberCount: parts[0] as number, createdAt, id: parts[2] as string };
      }
    } else {
      const parts = decodeTimeCursor(query.cursor);
      if (parts) after = { createdAt: parts[0], id: parts[1] };
    }
    const rows = await this.repo.findPage({ viewerId, sort, ...(query.q ? { q: query.q } : {}), after, limit });
    return toPage(
      rows,
      limit,
      (group) => (sort === 'popular' ? [group.memberCount, group.createdAt.toISOString(), group.id] : timeCursor(group.createdAt, group.id)),
      toGroupDto,
    );
  }

  async mine(viewerId: string, query: { limit?: number; cursor?: string }) {
    const limit = pageLimit(query.limit);
    const rows = await this.repo.findMine(viewerId, decodeTimeCursor(query.cursor), limit);
    return toPage(rows, limit, (row) => timeCursor(row.joinedAt, row.groupId), (row) => toGroupDto(row.group));
  }

  async get(groupId: string, viewerId: string): Promise<GroupDto> {
    const group = await this.repo.findById(groupId, viewerId);
    if (!group) throw GROUP_NOT_FOUND();
    return toGroupDto(group);
  }

  /** The creator becomes the owner and first member. */
  async create(owner: Actor, input: { name: string; description: string; coverImageUrl?: string | null }) {
    const { id } = await this.repo.create({
      ownerId: owner.id,
      name: input.name.trim(),
      description: input.description.trim(),
      coverImageUrl: cleanCover(input.coverImageUrl),
    });
    return this.get(id, owner.id);
  }

  private async assertCanManage(groupId: string, actor: Actor) {
    const group = await this.repo.findBasic(groupId);
    if (!group) throw GROUP_NOT_FOUND();
    if (group.ownerId !== actor.id && actor.role !== 'admin') throw forbidden('Only the group owner can do that.', 'NOT_GROUP_OWNER');
    return group;
  }

  async update(actor: Actor, groupId: string, input: { name?: string; description?: string; coverImageUrl?: string | null }) {
    await this.assertCanManage(groupId, actor);
    await this.repo.update(groupId, {
      ...(input.name !== undefined ? { name: input.name.trim() } : {}),
      ...(input.description !== undefined ? { description: input.description.trim() } : {}),
      ...(input.coverImageUrl !== undefined ? { coverImageUrl: cleanCover(input.coverImageUrl) } : {}),
    });
    return this.get(groupId, actor.id);
  }

  /** The owner, or an admin moderating. Members and chat history go with it. */
  async remove(actor: Actor, groupId: string): Promise<void> {
    const group = await this.assertCanManage(groupId, actor);
    await this.uow.run(async ({ db }) => {
      if (group.ownerId !== actor.id) {
        await audit(db, { actorId: actor.id, action: 'group.delete', targetType: 'group', targetId: groupId, details: { name: group.name } });
      }
      await this.repo.delete(groupId, db);
    });
  }

  /** Idempotent. */
  async join(viewer: Actor, groupId: string): Promise<GroupDto> {
    if (!(await this.repo.findBasic(groupId))) throw GROUP_NOT_FOUND();
    await this.repo.addMember(groupId, viewer.id);
    return this.get(groupId, viewer.id);
  }

  /** Idempotent. The owner cannot leave (delete the group instead). */
  async leave(viewer: Actor, groupId: string): Promise<void> {
    const group = await this.repo.findBasic(groupId);
    if (!group) throw GROUP_NOT_FOUND();
    if (group.ownerId === viewer.id) throw conflict('Owners cannot leave their own group. Delete it instead.', 'OWNER_CANNOT_LEAVE');
    await this.repo.removeMember(groupId, viewer.id);
  }

  async members(groupId: string, query: { limit?: number; cursor?: string }) {
    if (!(await this.repo.findBasic(groupId))) throw GROUP_NOT_FOUND();
    const limit = pageLimit(query.limit);
    const rows = await this.repo.membersPage(groupId, decodeTimeCursor(query.cursor), limit);
    return toPage(
      rows,
      limit,
      (row) => timeCursor(row.joinedAt, row.userId),
      (row) => ({ userId: row.user.id, name: row.user.name, avatarUrl: row.user.avatarUrl, role: row.role, joinedAt: row.joinedAt }),
    );
  }

  /** Readable by any signed-in rider (non-members see a "join to chat" bar in the app). */
  async messages(groupId: string, viewerId: string, query: { limit?: number; cursor?: string }) {
    if (!(await this.repo.findBasic(groupId))) throw GROUP_NOT_FOUND();
    const limit = pageLimit(query.limit);
    const rows = await this.repo.messagesPage(groupId, decodeTimeCursor(query.cursor), limit);
    const page = toPage(rows, limit, (row) => timeCursor(row.createdAt, row.id), (row) => toGroupMessageDto(row, viewerId));
    page.items.reverse();
    return page;
  }

  /** Members only; delivered live to every member's connected devices. */
  async send(sender: Actor, groupId: string, text: string) {
    if (!(await this.repo.findBasic(groupId))) throw GROUP_NOT_FOUND();
    if (!(await this.repo.membership(groupId, sender.id))) {
      throw forbidden('Join this group to send messages.', 'NOT_A_MEMBER');
    }
    const message = await this.repo.createMessage({ groupId, senderId: sender.id, text: text.trim() });
    const memberIds = await this.repo.memberIds(groupId);
    this.realtime.publish(
      memberIds.filter((id) => id !== sender.id),
      { type: 'groupMessage.created', data: toGroupMessageDto(message, '') },
    );
    this.realtime.publish([sender.id], { type: 'groupMessage.created', data: toGroupMessageDto(message, sender.id) });
    return toGroupMessageDto(message, sender.id);
  }
}
