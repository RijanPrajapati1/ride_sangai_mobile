/** The API's error envelope: `{ error: { code, message, details? }, requestId }`. */
export interface ApiErrorBody {
  error: { code: string; message: string; details?: unknown };
  requestId?: string;
}

/** An error from the API (or the BFF), carrying the user-facing `message`. */
export class ApiError extends Error {
  constructor(
    readonly status: number,
    readonly code: string,
    message: string,
    readonly details?: unknown,
  ) {
    super(message);
    this.name = 'ApiError';
  }
}

/** Parses an error envelope, falling back to a generic message. */
export function toApiError(status: number, body: unknown): ApiError {
  const env = body as Partial<ApiErrorBody> | null;
  return new ApiError(
    status,
    env?.error?.code ?? `HTTP_${status}`,
    env?.error?.message ?? `Something went wrong (${status}).`,
    env?.error?.details,
  );
}

export function errorMessage(err: unknown): string {
  if (err instanceof ApiError) return err.message;
  if (err instanceof Error && err.message) return err.message;
  return 'Something went wrong.';
}
