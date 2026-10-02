import type { FastifyBaseLogger } from 'fastify';
import pg from 'pg';
import type { RealtimeEvent, RealtimeHub } from './hub.js';

const CHANNEL = 'ride_sangai_realtime';
/** Postgres NOTIFY payloads must stay under 8000 bytes. */
const MAX_PAYLOAD_BYTES = 7_800;

interface Envelope {
  u: string[];
  e: RealtimeEvent;
}

/**
 * Cross-instance realtime delivery over Postgres LISTEN/NOTIFY, so several API
 * instances behind a load balancer reach every connected socket without
 * Redis. Each event is NOTIFYed (recipient lists are chunked to fit the
 * payload limit) and every instance, including the sender, delivers it to its
 * local sockets.
 */
export class PgFanout {
  private listener: pg.Client | undefined;
  private closed = false;
  private retryMs = 1_000;

  constructor(
    private readonly connectionString: string,
    private readonly hub: RealtimeHub,
    private readonly log: FastifyBaseLogger,
  ) {}

  async start(): Promise<void> {
    await this.connect();
    this.hub.setForwarder((userIds, event) => {
      void this.publish(userIds, event);
    });
  }

  private async connect(): Promise<void> {
    const client = new pg.Client({
      connectionString: this.connectionString,
      application_name: 'ride-sangai-realtime',
    });
    client.on('notification', (message) => {
      if (message.channel !== CHANNEL || !message.payload) return;
      try {
        const envelope = JSON.parse(message.payload) as Envelope;
        this.hub.deliverLocal(envelope.u, envelope.e);
      } catch (err) {
        this.log.warn({ err }, 'Ignoring malformed realtime notification');
      }
    });
    client.on('error', (err) => {
      this.log.error({ err }, 'Realtime listener connection failed; reconnecting');
      this.reconnect();
    });
    await client.connect();
    await client.query(`LISTEN ${CHANNEL}`);
    this.listener = client;
    this.retryMs = 1_000;
  }

  private reconnect(): void {
    const old = this.listener;
    this.listener = undefined;
    old?.end().catch(() => undefined);
    if (this.closed) return;
    setTimeout(() => {
      this.connect().catch((err: unknown) => {
        this.log.error({ err }, 'Realtime listener reconnect failed');
        this.retryMs = Math.min(this.retryMs * 2, 30_000);
        this.reconnect();
      });
    }, this.retryMs).unref();
  }

  private async publish(userIds: string[], event: RealtimeEvent): Promise<void> {
    const listener = this.listener;
    if (!listener) {
      this.hub.deliverLocal(userIds, event);
      return;
    }
    const base = Buffer.byteLength(JSON.stringify({ u: [], e: event }));
    if (base > MAX_PAYLOAD_BYTES) {
      this.log.warn({ type: event.type }, 'Realtime event too large to fan out; delivering locally only');
      this.hub.deliverLocal(userIds, event);
      return;
    }
    const perChunk = Math.max(1, Math.floor((MAX_PAYLOAD_BYTES - base) / 39));
    for (let i = 0; i < userIds.length; i += perChunk) {
      const payload = JSON.stringify({ u: userIds.slice(i, i + perChunk), e: event } satisfies Envelope);
      try {
        await listener.query('SELECT pg_notify($1, $2)', [CHANNEL, payload]);
      } catch (err) {
        this.log.error({ err }, 'Failed to fan out realtime event; delivering locally');
        this.hub.deliverLocal(userIds.slice(i, i + perChunk), event);
      }
    }
  }

  async stop(): Promise<void> {
    this.closed = true;
    this.hub.setForwarder(undefined);
    await this.listener?.end().catch(() => undefined);
  }
}
