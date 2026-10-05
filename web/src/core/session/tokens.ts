/**
 * The API's token envelope (login/refresh response), as far as the session
 * layer needs it. The full user entity lives in features/auth/domain.
 */
export interface TokenEnvelope {
  user: { id: string; isSuperadmin: boolean; [key: string]: unknown };
  accessToken: string;
  refreshToken: string;
  expiresIn: number;
  accessTokenExpiresAt: string;
  refreshTokenExpiresAt: string;
}
