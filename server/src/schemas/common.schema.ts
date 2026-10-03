import { Type, type TSchema } from 'typebox';
import {
  ACTIVITY_CATEGORIES,
  EXPERIENCE_LEVELS,
  NOTIFICATION_TYPES,
  RIDE_DIFFICULTIES,
  RIDE_JOIN_STATUSES,
  RIDE_REQUEST_STATUSES,
  RIDE_TYPES,
  USER_ROLES,
} from '../constants/enums.js';

/**
 * Shared TypeBox schemas. Route schemas do double duty: Fastify compiles them
 * into fast validators (requests) and serializers (responses), and they feed
 * the OpenAPI document at /docs. Response serialization is a whitelist: a
 * property that is not in the response schema never leaves the server.
 *
 * API conventions:
 *  - JSON keys are camelCase and match the Dart entity field names.
 *  - Enum values match the Dart enum value names.
 *  - Timestamps are ISO-8601 UTC strings; ids are UUID strings.
 *  - Lists are `{ items, nextCursor }` (see lib/pagination.ts).
 */

export const Uuid = Type.String({ format: 'uuid' });

export const IdParams = Type.Object({ id: Uuid });

/** Response timestamp: a Date (serialised to ISO-8601) or an ISO string. */
export const Timestamp = Type.Unsafe<Date | string>({ type: 'string', format: 'date-time' });

/** Request timestamp: must be an ISO-8601 date-time string. */
export const DateTimeInput = Type.String({ format: 'date-time' });

export function Nullable<T extends TSchema>(schema: T) {
  return Type.Union([schema, Type.Null()]);
}

export function Paginated<T extends TSchema>(item: T) {
  return Type.Object({
    items: Type.Array(item),
    nextCursor: Nullable(
      Type.String({ description: 'Pass as `cursor` to get the next page; null on the last page.' }),
    ),
  });
}

export const ActivityCategorySchema = Type.Enum(ACTIVITY_CATEGORIES);
export const RideTypeSchema = Type.Enum(RIDE_TYPES);
export const RideDifficultySchema = Type.Enum(RIDE_DIFFICULTIES);
export const ExperienceLevelSchema = Type.Enum(EXPERIENCE_LEVELS);
export const RideRequestStatusSchema = Type.Enum(RIDE_REQUEST_STATUSES);
export const RideJoinStatusSchema = Type.Enum(RIDE_JOIN_STATUSES);
export const NotificationTypeSchema = Type.Enum(NOTIFICATION_TYPES);
export const UserRoleSchema = Type.Enum(USER_ROLES);

/** Compact user reference embedded in other resources. */
export const UserSummary = Type.Object({
  id: Uuid,
  name: Type.String(),
  avatarUrl: Type.String({ description: "'' when unset." }),
});

export const ErrorResponse = Type.Object(
  {
    error: Type.Object({
      code: Type.String({ description: 'Stable machine-readable code, e.g. RIDE_FULL.' }),
      message: Type.String({ description: 'Human-readable message, safe to show to users.' }),
      details: Type.Optional(Type.Unknown()),
    }),
    requestId: Type.Optional(Type.String()),
  },
  { description: 'Error envelope returned for every 4xx/5xx response.' },
);

/** Spread into a route's `response` map to document its error statuses. */
export function errorResponses(...statuses: number[]): Record<number, typeof ErrorResponse> {
  return Object.fromEntries(statuses.map((status) => [status, ErrorResponse]));
}

/** 204 response. Typed `void` so handlers can call `reply.status(204).send()`. */
export const NoContent = Type.Unsafe<void>({ type: 'null', description: 'No content' });

/**
 * Text with a length cap. Unless `minLength` is 0 it must contain at least one
 * non-whitespace character. Services still `.trim()` before storing.
 */
export function Text(maxLength: number, options: { minLength?: number; description?: string } = {}) {
  const minLength = options.minLength ?? 1;
  return Type.String({
    minLength,
    maxLength,
    ...(minLength > 0 ? { pattern: '\\S' } : {}),
    ...(options.description ? { description: options.description } : {}),
  });
}
