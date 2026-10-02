import type { FastifyBaseLogger } from 'fastify';

/**
 * A server → client push. `type` is dot-namespaced (e.g. `message.created`);
 * `data` is the same JSON shape the REST API returns for that resource.
 */
export interface RealtimeEvent<T = unknown> {
  type: string;
  data: T;
}

/** Minimal socket surface the hub needs (satisfied by `ws` WebSocket). */
export interface RealtimeSocket {
  readonly readyState: number;
  send(data: string): void;
  close(code?: number, reason?: string): void;
}

const OPEN = 1;

/**
 * Tracks connected sockets per user and delivers events to them.
 *
 * Services call `publish(userIds, event)` — normally from an
 * `executor.onCommit(...)` callback so clients never see rolled-back data.
 * Delivery is best-effort: clients reconcile via REST on reconnect.
 */
export class RealtimeHub {
  private readonly sockets = new Map<string, Set<RealtimeSocket>>();
  /** Hook for cross-instance fan-out (see realtime/pg-fanout.ts). */
  private forwarder: ((userIds: string[], event: RealtimeEvent) => void) | undefined;

  constructor(private readonly log: FastifyBaseLogger) {}

  /** Number of open sockets on this instance. */
  get connectionCount(): number {
    let count = 0;
    for (const set of this.sockets.values()) count += set.size;
    return count;
  }

  isOnline(userId: string): boolean {
    return (this.sockets.get(userId)?.size ?? 0) > 0;
  }

  attach(userId: string, socket: RealtimeSocket): void {
    let set = this.sockets.get(userId);
    if (!set) {
      set = new Set();
      this.sockets.set(userId, set);
    }
    set.add(socket);
  }

  detach(userId: string, socket: RealtimeSocket): void {
    const set = this.sockets.get(userId);
    if (!set) return;
    set.delete(socket);
    if (set.size === 0) this.sockets.delete(userId);
  }

  /** Closes every socket of a user (logout everywhere, account removed). */
  disconnectUser(userId: string, reason = 'session ended'): void {
    for (const socket of this.sockets.get(userId) ?? []) socket.close(4001, reason);
    this.sockets.delete(userId);
  }

  setForwarder(forwarder: ((userIds: string[], event: RealtimeEvent) => void) | undefined): void {
    this.forwarder = forwarder;
  }

  /** Delivers to the given users on every instance. */
  publish(userIds: Iterable<string>, event: RealtimeEvent): void {
    const recipients = [...new Set(userIds)];
    if (recipients.length === 0) return;
    if (this.forwarder) {
      this.forwarder(recipients, event);
    } else {
      this.deliverLocal(recipients, event);
    }
  }

  /** Delivers to sockets connected to this instance only. */
  deliverLocal(userIds: readonly string[], event: RealtimeEvent): void {
    let payload: string | undefined;
    for (const userId of userIds) {
      const set = this.sockets.get(userId);
      if (!set) continue;
      payload ??= JSON.stringify(event);
      for (const socket of set) {
        if (socket.readyState !== OPEN) continue;
        try {
          socket.send(payload);
        } catch (err) {
          this.log.warn({ err, userId }, 'Failed to push realtime event');
        }
      }
    }
  }

  closeAll(): void {
    for (const set of this.sockets.values()) {
      for (const socket of set) socket.close(1001, 'server shutting down');
    }
    this.sockets.clear();
  }
}
