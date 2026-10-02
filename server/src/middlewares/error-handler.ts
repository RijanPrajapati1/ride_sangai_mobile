import type { FastifyError, FastifyReply, FastifyRequest } from 'fastify';
import fp from 'fastify-plugin';
import { PgCode, pgCode, prismaCode } from '../utils/db-errors.js';
import { AppError } from '../utils/errors.js';

interface ErrorBody {
  error: { code: string; message: string; details?: unknown };
  requestId: string;
}

/** Friendlier codes for framework errors a client can trigger. */
const FASTIFY_CODES: Record<string, { code: string; message?: string }> = {
  FST_ERR_CTP_BODY_TOO_LARGE: { code: 'PAYLOAD_TOO_LARGE', message: 'The request body is too large.' },
  FST_ERR_CTP_INVALID_MEDIA_TYPE: { code: 'UNSUPPORTED_MEDIA_TYPE' },
  FST_ERR_CTP_INVALID_CONTENT_LENGTH: { code: 'BAD_REQUEST' },
  FST_ERR_CTP_EMPTY_JSON_BODY: { code: 'BAD_REQUEST', message: 'The request body must not be empty.' },
  FST_ERR_CTP_INVALID_JSON_BODY: { code: 'INVALID_JSON', message: 'The request body is not valid JSON.' },
  FST_ERR_VALIDATION: { code: 'VALIDATION_ERROR' },
};

function validationDetails(err: FastifyError) {
  return (err.validation ?? []).map((issue) => {
    const missing = (issue.params as { missingProperty?: string } | undefined)?.missingProperty;
    const pointer = issue.instancePath ? issue.instancePath.slice(1).replaceAll('/', '.') : '';
    const field = [pointer, missing].filter(Boolean).join('.');
    return { field: field || err.validationContext || 'request', message: issue.message ?? 'is invalid' };
  });
}

/** Maps database errors (via Prisma) to API errors. Services catch the expected ones first. */
function fromDatabaseError(err: Error): { status: number; code: string; message: string } | null {
  switch (prismaCode(err)) {
    case 'P2002':
      return { status: 409, code: 'CONFLICT', message: 'That already exists.' };
    case 'P2003':
      return {
        status: 409,
        code: 'REFERENCE_CONFLICT',
        message: 'A related item does not exist or is still in use.',
      };
    case 'P2025':
      return { status: 404, code: 'NOT_FOUND', message: 'The requested item was not found.' };
    case 'P2034':
      return { status: 503, code: 'TRY_AGAIN', message: 'The server is busy. Please try again.' };
    case 'P2000':
      return { status: 400, code: 'VALUE_TOO_LONG', message: 'A value in the request is too long.' };
  }
  switch (pgCode(err)) {
    case PgCode.uniqueViolation:
      return { status: 409, code: 'CONFLICT', message: 'That already exists.' };
    case PgCode.foreignKeyViolation:
      return {
        status: 409,
        code: 'REFERENCE_CONFLICT',
        message: 'A related item does not exist or is still in use.',
      };
    case PgCode.checkViolation:
    case PgCode.notNullViolation:
      return { status: 422, code: 'CONSTRAINT_VIOLATION', message: 'The request breaks a data rule.' };
    case PgCode.invalidTextRepresentation:
    case PgCode.stringTooLong:
      return { status: 400, code: 'BAD_REQUEST', message: 'A value in the request has the wrong format.' };
    case PgCode.serializationFailure:
    case PgCode.deadlockDetected:
      return { status: 503, code: 'TRY_AGAIN', message: 'The server is busy. Please try again.' };
    case PgCode.queryCanceled:
      return { status: 503, code: 'TIMEOUT', message: 'The request took too long. Please try again.' };
  }
  return null;
}

export function toErrorResponse(
  err: FastifyError | Error,
  request: FastifyRequest,
): { status: number; body: ErrorBody } {
  const requestId = request.id;

  if (err instanceof AppError) {
    return {
      status: err.statusCode,
      body: {
        error: {
          code: err.code,
          message: err.message,
          ...(err.details !== undefined ? { details: err.details } : {}),
        },
        requestId,
      },
    };
  }

  const fastifyError = err as FastifyError;
  if (fastifyError.validation) {
    return {
      status: 400,
      body: {
        error: {
          code: 'VALIDATION_ERROR',
          message: 'Some fields are missing or invalid.',
          details: validationDetails(fastifyError),
        },
        requestId,
      },
    };
  }

  const dbError = fromDatabaseError(err);
  if (dbError)
    return {
      status: dbError.status,
      body: { error: { code: dbError.code, message: dbError.message }, requestId },
    };

  const status = fastifyError.statusCode;
  if (status !== undefined && status >= 400 && status < 500) {
    const known = fastifyError.code ? FASTIFY_CODES[fastifyError.code] : undefined;
    return {
      status,
      body: {
        error: {
          code:
            known?.code ?? (status === 429 ? 'RATE_LIMITED' : status === 404 ? 'NOT_FOUND' : 'BAD_REQUEST'),
          message: known?.message ?? err.message,
        },
        requestId,
      },
    };
  }

  if (status === 503) {
    return {
      status,
      body: {
        error: { code: 'SERVICE_UNAVAILABLE', message: 'The server is busy. Please try again shortly.' },
        requestId,
      },
    };
  }

  return {
    status: 500,
    body: {
      error: { code: 'INTERNAL_ERROR', message: 'Something went wrong. Please try again.' },
      requestId,
    },
  };
}

export default fp(
  async (app) => {
    app.setErrorHandler((err: FastifyError, request: FastifyRequest, reply: FastifyReply) => {
      const { status, body } = toErrorResponse(err, request);
      if (status >= 500) {
        request.log.error({ err }, 'Request failed');
      } else if (!(err instanceof AppError)) {
        request.log.info(
          { err: { message: err.message, code: (err as FastifyError).code } },
          'Request rejected',
        );
      }
      if (status === 429 || status === 503) {
        reply.header('retry-after', reply.getHeader('retry-after') ?? '10');
      }
      return reply.status(status).send(body);
    });

    app.setNotFoundHandler((request, reply) =>
      reply.status(404).send({
        error: {
          code: 'ROUTE_NOT_FOUND',
          message: `Route ${request.method} ${request.url.split('?')[0]} not found.`,
        },
        requestId: request.id,
      } satisfies ErrorBody),
    );

    app.addHook('onSend', async (request, reply) => {
      reply.header('x-request-id', request.id);
    });
  },
  { name: 'error-handler' },
);
