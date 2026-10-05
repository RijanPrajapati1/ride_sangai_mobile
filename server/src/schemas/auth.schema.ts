import { Type } from 'typebox';
import {
  IdParams,
  NoContent,
  Nullable,
  Text,
  Timestamp,
  UserRoleSchema,
  Uuid,
  errorResponses,
} from './common.schema.js';

export const Email = Type.String({ format: 'email', maxLength: 254, description: 'Case-insensitive.' });

/** Policy for new passwords. */
export const NewPassword = Type.String({
  minLength: 8,
  maxLength: 128,
  description: 'At least 8 characters.',
});

/** Any existing password (older accounts may predate the current policy). */
const ExistingPassword = Type.String({ minLength: 1, maxLength: 128 });

/** Mirrors the Dart `AuthUser` entity. */
export const AuthUser = Type.Object({
  id: Uuid,
  name: Type.String(),
  email: Type.String(),
  avatarUrl: Type.String({ description: "'' when unset." }),
  role: UserRoleSchema,
  isSuperadmin: Type.Boolean({ description: 'Can use the superadmin web dashboard.' }),
});

export const AuthResponse = Type.Object({
  user: AuthUser,
  accessToken: Type.String({ description: 'Send as `Authorization: Bearer <accessToken>`.' }),
  refreshToken: Type.String({ description: 'Single-use; exchange at POST /auth/refresh for a new pair.' }),
  tokenType: Type.Literal('Bearer'),
  expiresIn: Type.Integer({ description: 'Access token lifetime in seconds.' }),
  accessTokenExpiresAt: Timestamp,
  refreshTokenExpiresAt: Timestamp,
});

export const RegisterBody = Type.Object(
  {
    name: Text(80),
    email: Email,
    password: NewPassword,
  },
  { additionalProperties: false },
);

export const LoginBody = Type.Object(
  { email: Email, password: ExistingPassword },
  { additionalProperties: false },
);

export const RefreshBody = Type.Object(
  { refreshToken: Type.String({ minLength: 20, maxLength: 200 }) },
  { additionalProperties: false },
);

export const ForgotPasswordBody = Type.Object({ email: Email }, { additionalProperties: false });

export const ResetPasswordBody = Type.Object(
  { token: Type.String({ minLength: 20, maxLength: 200 }), password: NewPassword },
  { additionalProperties: false },
);

export const ChangePasswordBody = Type.Object(
  { currentPassword: ExistingPassword, newPassword: NewPassword },
  { additionalProperties: false },
);

export const MessageResponse = Type.Object({ message: Type.String() });

export const SessionItem = Type.Object({
  id: Uuid,
  userAgent: Nullable(Type.String()),
  ip: Nullable(Type.String()),
  createdAt: Timestamp,
  lastUsedAt: Timestamp,
  expiresAt: Timestamp,
  current: Type.Boolean({ description: 'True for the session making this request.' }),
});

export const SessionList = Type.Object({ items: Type.Array(SessionItem) });

// --- Route schemas (validation + serialization + OpenAPI docs) ---------------

const tags = ['Auth'];

export const authSchemas = {
  register: {
    tags,
    summary: 'Create an account and sign in',
    body: RegisterBody,
    response: { 201: AuthResponse, ...errorResponses(400, 409, 429) },
  },
  login: {
    tags,
    summary: 'Sign in with email and password',
    body: LoginBody,
    response: { 200: AuthResponse, ...errorResponses(400, 401, 429) },
  },
  refresh: {
    tags,
    summary: 'Exchange a refresh token for a new token pair',
    description:
      'Refresh tokens are single-use. Replaying a used token revokes the session (theft protection), ' +
      'so clients must not refresh concurrently — serialise refreshes behind one in-flight request.',
    body: RefreshBody,
    response: { 200: AuthResponse, ...errorResponses(400, 401, 429) },
  },
  logout: {
    tags,
    summary: 'Sign out of the current session',
    response: { 204: NoContent, ...errorResponses(401) },
  },
  logoutAll: {
    tags,
    summary: 'Sign out of every session',
    response: { 204: NoContent, ...errorResponses(401) },
  },
  forgotPassword: {
    tags,
    summary: 'Email a password reset link',
    description: 'Always returns 202, whether or not the email has an account.',
    body: ForgotPasswordBody,
    response: { 202: MessageResponse, ...errorResponses(400, 429) },
  },
  resetPassword: {
    tags,
    summary: 'Set a new password using a reset token',
    description: 'Signs the user out of every session.',
    body: ResetPasswordBody,
    response: { 204: NoContent, ...errorResponses(400, 429) },
  },
  changePassword: {
    tags,
    summary: 'Change password (keeps this session, ends all others)',
    body: ChangePasswordBody,
    response: { 204: NoContent, ...errorResponses(400, 401) },
  },
  me: { tags, summary: 'The signed-in user', response: { 200: AuthUser, ...errorResponses(401) } },
  sessions: {
    tags,
    summary: 'Active sessions (signed-in devices)',
    response: { 200: SessionList, ...errorResponses(401) },
  },
  revokeSession: {
    tags,
    summary: 'Sign out one of your sessions',
    params: IdParams,
    response: { 204: NoContent, ...errorResponses(401, 404) },
  },
};
