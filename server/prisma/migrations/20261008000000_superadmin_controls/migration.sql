-- Superadmin controls: suspending accounts and platform-wide announcements.

-- A disabled account cannot sign in or refresh, its sessions are revoked when
-- it is disabled, and it is hidden from rider search and recommendations.
-- Its content stays visible; remove the account to take that down too.
ALTER TABLE "users" ADD COLUMN "disabled_at" TIMESTAMPTZ(3);
ALTER TABLE "users" ADD COLUMN "disabled_reason" VARCHAR(300);

CREATE INDEX "users_disabled_at_idx" ON "users"("disabled_at");

-- In-app notification sent to every rider from the dashboard.
ALTER TYPE "notification_type" ADD VALUE 'announcement';
