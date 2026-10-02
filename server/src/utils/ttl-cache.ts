/**
 * Tiny in-memory TTL cache with a size cap (oldest entries evicted first).
 * Good for short-lived hot lookups such as verified auth sessions.
 */
export class TtlCache<K, V> {
  private readonly entries = new Map<K, { value: V; expiresAt: number }>();

  constructor(
    private readonly ttlMs: number,
    private readonly maxEntries = 10_000,
  ) {}

  get enabled(): boolean {
    return this.ttlMs > 0;
  }

  get(key: K): V | undefined {
    if (!this.enabled) return undefined;
    const entry = this.entries.get(key);
    if (!entry) return undefined;
    if (entry.expiresAt <= Date.now()) {
      this.entries.delete(key);
      return undefined;
    }
    return entry.value;
  }

  set(key: K, value: V): void {
    if (!this.enabled) return;
    if (this.entries.size >= this.maxEntries) {
      const oldest = this.entries.keys().next();
      if (!oldest.done) this.entries.delete(oldest.value);
    }
    this.entries.set(key, { value, expiresAt: Date.now() + this.ttlMs });
  }

  delete(key: K): void {
    this.entries.delete(key);
  }

  /** Removes every entry whose value matches, e.g. all sessions of one user. */
  deleteWhere(predicate: (value: V) => boolean): void {
    for (const [key, entry] of this.entries) {
      if (predicate(entry.value)) this.entries.delete(key);
    }
  }

  clear(): void {
    this.entries.clear();
  }
}
