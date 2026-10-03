import type { FastifyBaseLogger } from 'fastify';

export interface PasswordResetEmail {
  to: string;
  name: string;
  resetUrl: string;
  expiresInMinutes: number;
}

/**
 * Outbound email. The default implementation only logs, so the API works
 * end-to-end without an email provider; swap in an SMTP/SES/Resend
 * implementation of this interface in `buildApp` for production.
 */
export interface Mailer {
  sendPasswordReset(email: PasswordResetEmail): Promise<void>;
}

export class LogMailer implements Mailer {
  constructor(private readonly log: FastifyBaseLogger) {}

  async sendPasswordReset(email: PasswordResetEmail): Promise<void> {
    this.log.info(
      { to: email.to, resetUrl: email.resetUrl, expiresInMinutes: email.expiresInMinutes },
      'Password reset requested (LogMailer: no email provider configured, link logged instead)',
    );
  }
}

/** Collects emails in memory; handy in tests. */
export class MemoryMailer implements Mailer {
  readonly passwordResets: PasswordResetEmail[] = [];

  async sendPasswordReset(email: PasswordResetEmail): Promise<void> {
    this.passwordResets.push(email);
  }
}
