/**
 * The one error type services throw on purpose. The global error handler turns
 * it into `{ error: { code, message, details? }, requestId }` with `statusCode`.
 *
 * `code` is a stable, machine-readable SCREAMING_SNAKE_CASE identifier the
 * mobile app can switch on (e.g. RIDE_FULL); `message` is human-readable and
 * safe to show to users.
 */
export class AppError extends Error {
  constructor(
    readonly statusCode: number,
    readonly code: string,
    message: string,
    readonly details?: unknown,
  ) {
    super(message);
    this.name = 'AppError';
  }
}

export const badRequest = (message: string, code = 'BAD_REQUEST', details?: unknown) =>
  new AppError(400, code, message, details);

export const unauthorized = (message = 'Authentication required.', code = 'UNAUTHORIZED') =>
  new AppError(401, code, message);

export const forbidden = (message = 'You do not have permission to do that.', code = 'FORBIDDEN') =>
  new AppError(403, code, message);

export const notFound = (message = 'The requested item was not found.', code = 'NOT_FOUND') =>
  new AppError(404, code, message);

export const conflict = (message: string, code = 'CONFLICT', details?: unknown) =>
  new AppError(409, code, message, details);

/** A well-formed request that breaks a business rule (e.g. joining a full ride). */
export const unprocessable = (message: string, code = 'UNPROCESSABLE', details?: unknown) =>
  new AppError(422, code, message, details);

export const tooManyRequests = (message = 'Too many requests, please slow down.', code = 'RATE_LIMITED') =>
  new AppError(429, code, message);

export function isAppError(err: unknown): err is AppError {
  return err instanceof AppError;
}
