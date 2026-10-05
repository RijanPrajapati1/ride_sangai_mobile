-- The platform-wide role is now "superadmin" (the web dashboard). Everyone
-- else is a "user" who manages the posts, rides, places and groups they own.
ALTER TYPE "user_role" RENAME VALUE 'admin' TO 'superadmin';

-- CreateEnum
CREATE TYPE "feedback_category" AS ENUM ('bug', 'idea', 'praise', 'other');

-- CreateEnum
CREATE TYPE "feedback_status" AS ENUM ('open', 'in_progress', 'resolved');

-- CreateTable
CREATE TABLE "feedback" (
    "id" UUID NOT NULL,
    "user_id" UUID,
    "category" "feedback_category" NOT NULL DEFAULT 'other',
    "rating" SMALLINT,
    "message" VARCHAR(2000) NOT NULL,
    "platform" VARCHAR(20),
    "app_version" VARCHAR(40),
    "status" "feedback_status" NOT NULL DEFAULT 'open',
    "admin_note" VARCHAR(1000) NOT NULL DEFAULT '',
    "resolved_at" TIMESTAMPTZ(3),
    "created_at" TIMESTAMPTZ(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "updated_at" TIMESTAMPTZ(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,

    CONSTRAINT "feedback_pkey" PRIMARY KEY ("id")
);

-- CreateIndex
CREATE INDEX "feedback_created_at_id_idx" ON "feedback"("created_at" DESC, "id" DESC);

-- CreateIndex
CREATE INDEX "feedback_status_created_at_id_idx" ON "feedback"("status", "created_at" DESC, "id" DESC);

-- CreateIndex
CREATE INDEX "feedback_user_id_idx" ON "feedback"("user_id");

-- AddForeignKey
ALTER TABLE "feedback" ADD CONSTRAINT "feedback_user_id_fkey" FOREIGN KEY ("user_id") REFERENCES "users"("id") ON DELETE SET NULL ON UPDATE CASCADE;


-- Hand-written: Prisma does not model CHECK constraints.
ALTER TABLE "feedback" ADD CONSTRAINT "feedback_rating_range" CHECK ("rating" IS NULL OR "rating" BETWEEN 1 AND 5);
ALTER TABLE "feedback" ADD CONSTRAINT "feedback_message_not_blank" CHECK (btrim("message") <> '');
