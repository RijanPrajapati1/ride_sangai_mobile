import type { TypeBoxTypeProvider } from '@fastify/type-provider-typebox';
import type {
  ContextConfigDefault,
  FastifyReply,
  FastifyRequest,
  FastifySchema,
  RawReplyDefaultExpression,
  RawRequestDefaultExpression,
  RawServerDefault,
  RouteGenericInterface,
} from 'fastify';

/**
 * Typed request/reply for controllers. Pass the route's schema object so
 * `request.body`, `request.query`, `request.params` and `reply.send()` are
 * typed from the same TypeBox schema that validates them:
 *
 *   login = async (request: Req<typeof authSchemas.login>) => ...
 */
export type Req<S extends FastifySchema> = FastifyRequest<
  RouteGenericInterface,
  RawServerDefault,
  RawRequestDefaultExpression,
  S,
  TypeBoxTypeProvider
>;

export type Rep<S extends FastifySchema> = FastifyReply<
  RouteGenericInterface,
  RawServerDefault,
  RawRequestDefaultExpression,
  RawReplyDefaultExpression,
  ContextConfigDefault,
  S,
  TypeBoxTypeProvider
>;
