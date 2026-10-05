/** A cursor-paginated list: pass `nextCursor` back as `cursor`; null on the last page. */
export interface Page<T> {
  items: T[];
  nextCursor: string | null;
}

export interface PageQuery {
  cursor?: string | null;
  limit?: number;
}
