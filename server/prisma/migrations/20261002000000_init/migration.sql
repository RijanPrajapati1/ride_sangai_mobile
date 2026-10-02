-- Trigram search indexes need pg_trgm.
CREATE EXTENSION IF NOT EXISTS pg_trgm;

-- CreateSchema
CREATE SCHEMA IF NOT EXISTS "public";

-- CreateEnum
CREATE TYPE "user_role" AS ENUM ('user', 'admin');

-- CreateEnum
CREATE TYPE "experience_level" AS ENUM ('beginner', 'intermediate', 'advanced', 'pro');

-- CreateEnum
CREATE TYPE "activity_category" AS ENUM ('cycling', 'trekking', 'hiking', 'riding');

-- CreateEnum
CREATE TYPE "ride_type" AS ENUM ('road', 'mountain', 'gravel', 'touring', 'social', 'hillClimb', 'nightRide', 'multiDayTrek', 'dayTrek', 'summitTrek', 'dayHike', 'natureWalk', 'familyHike', 'touringRide', 'offRoadRide', 'trackDay');

-- CreateEnum
CREATE TYPE "ride_difficulty" AS ENUM ('easy', 'moderate', 'hard');

-- CreateEnum
CREATE TYPE "ride_request_status" AS ENUM ('pending', 'approved', 'declined');

-- CreateEnum
CREATE TYPE "notification_type" AS ENUM ('requestApproved', 'requestDeclined', 'newMessage', 'rideReminder', 'rideUpdated', 'newFollower', 'comment', 'like', 'newRideRequest');

-- CreateEnum
CREATE TYPE "notification_entity_type" AS ENUM ('ride', 'rideRequest', 'post', 'comment', 'user', 'conversation', 'group');

-- CreateEnum
CREATE TYPE "group_member_role" AS ENUM ('owner', 'member');

-- CreateEnum
CREATE TYPE "device_platform" AS ENUM ('android', 'ios', 'web');

-- CreateEnum
CREATE TYPE "upload_purpose" AS ENUM ('avatar', 'rideCover', 'post', 'groupCover', 'other');

-- CreateTable
CREATE TABLE "users" (
    "id" UUID NOT NULL,
    "email" VARCHAR(254) NOT NULL,
    "password_hash" TEXT NOT NULL,
    "name" VARCHAR(80) NOT NULL,
    "avatar_url" VARCHAR(2048) NOT NULL DEFAULT '',
    "bio" VARCHAR(500) NOT NULL DEFAULT '',
    "location" VARCHAR(120) NOT NULL DEFAULT '',
    "experience_level" "experience_level" NOT NULL DEFAULT 'beginner',
    "preferred_ride_type" "ride_type" NOT NULL DEFAULT 'road',
    "interests" TEXT[] DEFAULT ARRAY[]::TEXT[],
    "role" "user_role" NOT NULL DEFAULT 'user',
    "followers_count" INTEGER NOT NULL DEFAULT 0,
    "following_count" INTEGER NOT NULL DEFAULT 0,
    "last_login_at" TIMESTAMPTZ(3),
    "created_at" TIMESTAMPTZ(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "updated_at" TIMESTAMPTZ(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,

    CONSTRAINT "users_pkey" PRIMARY KEY ("id")
);

-- CreateTable
CREATE TABLE "user_preferences" (
    "user_id" UUID NOT NULL,
    "push_ride_reminders" BOOLEAN NOT NULL DEFAULT true,
    "push_messages" BOOLEAN NOT NULL DEFAULT true,
    "push_community_activity" BOOLEAN NOT NULL DEFAULT true,
    "dark_mode_enabled" BOOLEAN NOT NULL DEFAULT false,
    "public_profile" BOOLEAN NOT NULL DEFAULT true,
    "show_riding_stats" BOOLEAN NOT NULL DEFAULT true,
    "updated_at" TIMESTAMPTZ(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,

    CONSTRAINT "user_preferences_pkey" PRIMARY KEY ("user_id")
);

-- CreateTable
CREATE TABLE "sessions" (
    "id" UUID NOT NULL,
    "user_id" UUID NOT NULL,
    "user_agent" VARCHAR(255),
    "ip" VARCHAR(64),
    "created_at" TIMESTAMPTZ(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "last_used_at" TIMESTAMPTZ(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "expires_at" TIMESTAMPTZ(3) NOT NULL,
    "revoked_at" TIMESTAMPTZ(3),
    "revoked_reason" VARCHAR(64),

    CONSTRAINT "sessions_pkey" PRIMARY KEY ("id")
);

-- CreateTable
CREATE TABLE "refresh_tokens" (
    "id" UUID NOT NULL,
    "session_id" UUID NOT NULL,
    "token_hash" CHAR(64) NOT NULL,
    "expires_at" TIMESTAMPTZ(3) NOT NULL,
    "used_at" TIMESTAMPTZ(3),
    "created_at" TIMESTAMPTZ(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,

    CONSTRAINT "refresh_tokens_pkey" PRIMARY KEY ("id")
);

-- CreateTable
CREATE TABLE "password_reset_tokens" (
    "id" UUID NOT NULL,
    "user_id" UUID NOT NULL,
    "token_hash" CHAR(64) NOT NULL,
    "expires_at" TIMESTAMPTZ(3) NOT NULL,
    "used_at" TIMESTAMPTZ(3),
    "created_at" TIMESTAMPTZ(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,

    CONSTRAINT "password_reset_tokens_pkey" PRIMARY KEY ("id")
);

-- CreateTable
CREATE TABLE "follows" (
    "follower_id" UUID NOT NULL,
    "following_id" UUID NOT NULL,
    "created_at" TIMESTAMPTZ(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,

    CONSTRAINT "follows_pkey" PRIMARY KEY ("follower_id","following_id")
);

-- CreateTable
CREATE TABLE "device_tokens" (
    "token" VARCHAR(4096) NOT NULL,
    "user_id" UUID NOT NULL,
    "platform" "device_platform" NOT NULL,
    "created_at" TIMESTAMPTZ(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "last_seen_at" TIMESTAMPTZ(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,

    CONSTRAINT "device_tokens_pkey" PRIMARY KEY ("token")
);

-- CreateTable
CREATE TABLE "rides" (
    "id" UUID NOT NULL,
    "organizer_id" UUID NOT NULL,
    "title" VARCHAR(120) NOT NULL,
    "description" VARCHAR(5000) NOT NULL,
    "ride_type" "ride_type" NOT NULL,
    "category" "activity_category" NOT NULL,
    "difficulty" "ride_difficulty" NOT NULL,
    "starts_at" TIMESTAMPTZ(3) NOT NULL,
    "meeting_point" VARCHAR(200) NOT NULL,
    "distance_km" DOUBLE PRECISION NOT NULL,
    "duration_minutes" INTEGER NOT NULL,
    "max_participants" INTEGER NOT NULL,
    "participant_count" INTEGER NOT NULL DEFAULT 1,
    "image_url" VARCHAR(2048) NOT NULL DEFAULT '',
    "requirements" TEXT[] DEFAULT ARRAY[]::TEXT[],
    "reminder_sent_at" TIMESTAMPTZ(3),
    "created_at" TIMESTAMPTZ(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "updated_at" TIMESTAMPTZ(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,

    CONSTRAINT "rides_pkey" PRIMARY KEY ("id")
);

-- CreateTable
CREATE TABLE "ride_requests" (
    "id" UUID NOT NULL,
    "ride_id" UUID NOT NULL,
    "user_id" UUID NOT NULL,
    "status" "ride_request_status" NOT NULL DEFAULT 'pending',
    "message" VARCHAR(500),
    "decline_reason" VARCHAR(500),
    "requested_at" TIMESTAMPTZ(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "decided_at" TIMESTAMPTZ(3),
    "decided_by" UUID,
    "reminder_sent_at" TIMESTAMPTZ(3),

    CONSTRAINT "ride_requests_pkey" PRIMARY KEY ("id")
);

-- CreateTable
CREATE TABLE "posts" (
    "id" UUID NOT NULL,
    "author_id" UUID NOT NULL,
    "text" VARCHAR(2000) NOT NULL,
    "image_url" VARCHAR(2048),
    "like_count" INTEGER NOT NULL DEFAULT 0,
    "comment_count" INTEGER NOT NULL DEFAULT 0,
    "created_at" TIMESTAMPTZ(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "updated_at" TIMESTAMPTZ(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,

    CONSTRAINT "posts_pkey" PRIMARY KEY ("id")
);

-- CreateTable
CREATE TABLE "post_likes" (
    "post_id" UUID NOT NULL,
    "user_id" UUID NOT NULL,
    "created_at" TIMESTAMPTZ(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,

    CONSTRAINT "post_likes_pkey" PRIMARY KEY ("post_id","user_id")
);

-- CreateTable
CREATE TABLE "comments" (
    "id" UUID NOT NULL,
    "post_id" UUID NOT NULL,
    "author_id" UUID NOT NULL,
    "text" VARCHAR(1000) NOT NULL,
    "like_count" INTEGER NOT NULL DEFAULT 0,
    "created_at" TIMESTAMPTZ(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,

    CONSTRAINT "comments_pkey" PRIMARY KEY ("id")
);

-- CreateTable
CREATE TABLE "comment_likes" (
    "comment_id" UUID NOT NULL,
    "user_id" UUID NOT NULL,
    "created_at" TIMESTAMPTZ(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,

    CONSTRAINT "comment_likes_pkey" PRIMARY KEY ("comment_id","user_id")
);

-- CreateTable
CREATE TABLE "conversations" (
    "id" UUID NOT NULL,
    "user_a_id" UUID NOT NULL,
    "user_b_id" UUID NOT NULL,
    "last_message_id" UUID,
    "last_message_at" TIMESTAMPTZ(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "created_at" TIMESTAMPTZ(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,

    CONSTRAINT "conversations_pkey" PRIMARY KEY ("id")
);

-- CreateTable
CREATE TABLE "conversation_participants" (
    "conversation_id" UUID NOT NULL,
    "user_id" UUID NOT NULL,
    "last_read_at" TIMESTAMPTZ(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "joined_at" TIMESTAMPTZ(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,

    CONSTRAINT "conversation_participants_pkey" PRIMARY KEY ("conversation_id","user_id")
);

-- CreateTable
CREATE TABLE "messages" (
    "id" UUID NOT NULL,
    "conversation_id" UUID NOT NULL,
    "sender_id" UUID NOT NULL,
    "text" VARCHAR(2000) NOT NULL,
    "created_at" TIMESTAMPTZ(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,

    CONSTRAINT "messages_pkey" PRIMARY KEY ("id")
);

-- CreateTable
CREATE TABLE "groups" (
    "id" UUID NOT NULL,
    "owner_id" UUID NOT NULL,
    "name" VARCHAR(80) NOT NULL,
    "description" VARCHAR(1000) NOT NULL,
    "cover_image_url" VARCHAR(2048),
    "member_count" INTEGER NOT NULL DEFAULT 0,
    "last_message_at" TIMESTAMPTZ(3),
    "created_at" TIMESTAMPTZ(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "updated_at" TIMESTAMPTZ(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,

    CONSTRAINT "groups_pkey" PRIMARY KEY ("id")
);

-- CreateTable
CREATE TABLE "group_members" (
    "group_id" UUID NOT NULL,
    "user_id" UUID NOT NULL,
    "role" "group_member_role" NOT NULL DEFAULT 'member',
    "joined_at" TIMESTAMPTZ(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "last_read_at" TIMESTAMPTZ(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,

    CONSTRAINT "group_members_pkey" PRIMARY KEY ("group_id","user_id")
);

-- CreateTable
CREATE TABLE "group_messages" (
    "id" UUID NOT NULL,
    "group_id" UUID NOT NULL,
    "sender_id" UUID NOT NULL,
    "text" VARCHAR(2000) NOT NULL,
    "created_at" TIMESTAMPTZ(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,

    CONSTRAINT "group_messages_pkey" PRIMARY KEY ("id")
);

-- CreateTable
CREATE TABLE "notifications" (
    "id" UUID NOT NULL,
    "recipient_id" UUID NOT NULL,
    "type" "notification_type" NOT NULL,
    "title" VARCHAR(200) NOT NULL,
    "body" VARCHAR(1000) NOT NULL,
    "actor_id" UUID,
    "entity_type" "notification_entity_type",
    "entity_id" UUID,
    "collapse_key" VARCHAR(200),
    "read_at" TIMESTAMPTZ(3),
    "created_at" TIMESTAMPTZ(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,

    CONSTRAINT "notifications_pkey" PRIMARY KEY ("id")
);

-- CreateTable
CREATE TABLE "uploads" (
    "id" UUID NOT NULL,
    "owner_id" UUID NOT NULL,
    "storage_key" VARCHAR(255) NOT NULL,
    "content_type" VARCHAR(64) NOT NULL,
    "size_bytes" INTEGER NOT NULL,
    "purpose" "upload_purpose",
    "created_at" TIMESTAMPTZ(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,

    CONSTRAINT "uploads_pkey" PRIMARY KEY ("id")
);

-- CreateTable
CREATE TABLE "banners" (
    "id" UUID NOT NULL,
    "category" "activity_category",
    "title" VARCHAR(80) NOT NULL,
    "subtitle" VARCHAR(240) NOT NULL DEFAULT '',
    "cta_label" VARCHAR(40) NOT NULL DEFAULT '',
    "cta_url" VARCHAR(2048),
    "image_url" VARCHAR(2048),
    "icon" VARCHAR(64),
    "theme" VARCHAR(32),
    "sort_order" INTEGER NOT NULL DEFAULT 0,
    "is_active" BOOLEAN NOT NULL DEFAULT true,
    "starts_at" TIMESTAMPTZ(3),
    "ends_at" TIMESTAMPTZ(3),
    "created_at" TIMESTAMPTZ(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "updated_at" TIMESTAMPTZ(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,

    CONSTRAINT "banners_pkey" PRIMARY KEY ("id")
);

-- CreateTable
CREATE TABLE "admin_audit_log" (
    "id" UUID NOT NULL,
    "actor_id" UUID,
    "action" VARCHAR(64) NOT NULL,
    "target_type" VARCHAR(32) NOT NULL,
    "target_id" UUID,
    "details" JSONB NOT NULL DEFAULT '{}',
    "created_at" TIMESTAMPTZ(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,

    CONSTRAINT "admin_audit_log_pkey" PRIMARY KEY ("id")
);

-- CreateIndex
CREATE UNIQUE INDEX "users_email_key" ON "users"("email");

-- CreateIndex
CREATE INDEX "users_role_name_id_idx" ON "users"("role", "name", "id");

-- CreateIndex
CREATE INDEX "users_followers_count_id_idx" ON "users"("followers_count" DESC, "id");

-- CreateIndex
CREATE INDEX "users_name_trgm_idx" ON "users" USING GIN ("name" gin_trgm_ops);

-- CreateIndex
CREATE INDEX "sessions_user_id_revoked_at_idx" ON "sessions"("user_id", "revoked_at");

-- CreateIndex
CREATE INDEX "sessions_expires_at_idx" ON "sessions"("expires_at");

-- CreateIndex
CREATE UNIQUE INDEX "refresh_tokens_token_hash_key" ON "refresh_tokens"("token_hash");

-- CreateIndex
CREATE INDEX "refresh_tokens_session_id_idx" ON "refresh_tokens"("session_id");

-- CreateIndex
CREATE INDEX "refresh_tokens_expires_at_idx" ON "refresh_tokens"("expires_at");

-- CreateIndex
CREATE UNIQUE INDEX "password_reset_tokens_token_hash_key" ON "password_reset_tokens"("token_hash");

-- CreateIndex
CREATE INDEX "password_reset_tokens_user_id_idx" ON "password_reset_tokens"("user_id");

-- CreateIndex
CREATE INDEX "follows_following_id_created_at_idx" ON "follows"("following_id", "created_at" DESC);

-- CreateIndex
CREATE INDEX "follows_follower_id_created_at_idx" ON "follows"("follower_id", "created_at" DESC);

-- CreateIndex
CREATE INDEX "device_tokens_user_id_idx" ON "device_tokens"("user_id");

-- CreateIndex
CREATE INDEX "rides_starts_at_id_idx" ON "rides"("starts_at", "id");

-- CreateIndex
CREATE INDEX "rides_category_starts_at_id_idx" ON "rides"("category", "starts_at", "id");

-- CreateIndex
CREATE INDEX "rides_organizer_id_starts_at_id_idx" ON "rides"("organizer_id", "starts_at", "id");

-- CreateIndex
CREATE INDEX "rides_title_trgm_idx" ON "rides" USING GIN ("title" gin_trgm_ops);

-- CreateIndex
CREATE INDEX "rides_meeting_point_trgm_idx" ON "rides" USING GIN ("meeting_point" gin_trgm_ops);

-- CreateIndex
CREATE INDEX "ride_requests_ride_id_status_requested_at_id_idx" ON "ride_requests"("ride_id", "status", "requested_at" DESC, "id" DESC);

-- CreateIndex
CREATE INDEX "ride_requests_user_id_status_idx" ON "ride_requests"("user_id", "status");

-- CreateIndex
CREATE INDEX "ride_requests_status_requested_at_id_idx" ON "ride_requests"("status", "requested_at" DESC, "id" DESC);

-- CreateIndex
CREATE INDEX "ride_requests_requested_at_id_idx" ON "ride_requests"("requested_at" DESC, "id" DESC);

-- CreateIndex
CREATE INDEX "ride_requests_ride_id_decided_at_id_idx" ON "ride_requests"("ride_id", "decided_at", "id");

-- CreateIndex
CREATE INDEX "ride_requests_decided_by_idx" ON "ride_requests"("decided_by");

-- CreateIndex
CREATE UNIQUE INDEX "ride_requests_ride_id_user_id_key" ON "ride_requests"("ride_id", "user_id");

-- CreateIndex
CREATE INDEX "posts_created_at_id_idx" ON "posts"("created_at" DESC, "id" DESC);

-- CreateIndex
CREATE INDEX "posts_author_id_created_at_id_idx" ON "posts"("author_id", "created_at" DESC, "id" DESC);

-- CreateIndex
CREATE INDEX "post_likes_user_id_idx" ON "post_likes"("user_id");

-- CreateIndex
CREATE INDEX "comments_post_id_created_at_id_idx" ON "comments"("post_id", "created_at", "id");

-- CreateIndex
CREATE INDEX "comments_author_id_idx" ON "comments"("author_id");

-- CreateIndex
CREATE INDEX "comment_likes_user_id_idx" ON "comment_likes"("user_id");

-- CreateIndex
CREATE UNIQUE INDEX "conversations_last_message_id_key" ON "conversations"("last_message_id");

-- CreateIndex
CREATE INDEX "conversations_user_b_id_idx" ON "conversations"("user_b_id");

-- CreateIndex
CREATE UNIQUE INDEX "conversations_user_a_id_user_b_id_key" ON "conversations"("user_a_id", "user_b_id");

-- CreateIndex
CREATE INDEX "conversation_participants_user_id_conversation_id_idx" ON "conversation_participants"("user_id", "conversation_id");

-- CreateIndex
CREATE INDEX "messages_conversation_id_created_at_id_idx" ON "messages"("conversation_id", "created_at" DESC, "id" DESC);

-- CreateIndex
CREATE INDEX "messages_sender_id_idx" ON "messages"("sender_id");

-- CreateIndex
CREATE INDEX "groups_member_count_created_at_id_idx" ON "groups"("member_count" DESC, "created_at" DESC, "id" DESC);

-- CreateIndex
CREATE INDEX "groups_created_at_id_idx" ON "groups"("created_at" DESC, "id" DESC);

-- CreateIndex
CREATE INDEX "groups_owner_id_idx" ON "groups"("owner_id");

-- CreateIndex
CREATE INDEX "groups_name_trgm_idx" ON "groups" USING GIN ("name" gin_trgm_ops);

-- CreateIndex
CREATE INDEX "group_members_user_id_joined_at_idx" ON "group_members"("user_id", "joined_at" DESC);

-- CreateIndex
CREATE INDEX "group_members_group_id_joined_at_user_id_idx" ON "group_members"("group_id", "joined_at", "user_id");

-- CreateIndex
CREATE INDEX "group_messages_group_id_created_at_id_idx" ON "group_messages"("group_id", "created_at" DESC, "id" DESC);

-- CreateIndex
CREATE INDEX "group_messages_sender_id_idx" ON "group_messages"("sender_id");

-- CreateIndex
CREATE INDEX "notifications_recipient_id_created_at_id_idx" ON "notifications"("recipient_id", "created_at" DESC, "id" DESC);

-- CreateIndex
CREATE INDEX "notifications_recipient_id_read_at_idx" ON "notifications"("recipient_id", "read_at");

-- CreateIndex
CREATE INDEX "notifications_actor_id_idx" ON "notifications"("actor_id");

-- CreateIndex
CREATE UNIQUE INDEX "notifications_recipient_id_collapse_key_key" ON "notifications"("recipient_id", "collapse_key");

-- CreateIndex
CREATE UNIQUE INDEX "uploads_storage_key_key" ON "uploads"("storage_key");

-- CreateIndex
CREATE INDEX "uploads_owner_id_created_at_idx" ON "uploads"("owner_id", "created_at" DESC);

-- CreateIndex
CREATE INDEX "banners_is_active_sort_order_created_at_idx" ON "banners"("is_active", "sort_order", "created_at");

-- CreateIndex
CREATE INDEX "admin_audit_log_created_at_id_idx" ON "admin_audit_log"("created_at" DESC, "id" DESC);

-- CreateIndex
CREATE INDEX "admin_audit_log_actor_id_idx" ON "admin_audit_log"("actor_id");

-- AddForeignKey
ALTER TABLE "user_preferences" ADD CONSTRAINT "user_preferences_user_id_fkey" FOREIGN KEY ("user_id") REFERENCES "users"("id") ON DELETE CASCADE ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "sessions" ADD CONSTRAINT "sessions_user_id_fkey" FOREIGN KEY ("user_id") REFERENCES "users"("id") ON DELETE CASCADE ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "refresh_tokens" ADD CONSTRAINT "refresh_tokens_session_id_fkey" FOREIGN KEY ("session_id") REFERENCES "sessions"("id") ON DELETE CASCADE ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "password_reset_tokens" ADD CONSTRAINT "password_reset_tokens_user_id_fkey" FOREIGN KEY ("user_id") REFERENCES "users"("id") ON DELETE CASCADE ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "follows" ADD CONSTRAINT "follows_follower_id_fkey" FOREIGN KEY ("follower_id") REFERENCES "users"("id") ON DELETE CASCADE ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "follows" ADD CONSTRAINT "follows_following_id_fkey" FOREIGN KEY ("following_id") REFERENCES "users"("id") ON DELETE CASCADE ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "device_tokens" ADD CONSTRAINT "device_tokens_user_id_fkey" FOREIGN KEY ("user_id") REFERENCES "users"("id") ON DELETE CASCADE ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "rides" ADD CONSTRAINT "rides_organizer_id_fkey" FOREIGN KEY ("organizer_id") REFERENCES "users"("id") ON DELETE CASCADE ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "ride_requests" ADD CONSTRAINT "ride_requests_ride_id_fkey" FOREIGN KEY ("ride_id") REFERENCES "rides"("id") ON DELETE CASCADE ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "ride_requests" ADD CONSTRAINT "ride_requests_user_id_fkey" FOREIGN KEY ("user_id") REFERENCES "users"("id") ON DELETE CASCADE ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "ride_requests" ADD CONSTRAINT "ride_requests_decided_by_fkey" FOREIGN KEY ("decided_by") REFERENCES "users"("id") ON DELETE SET NULL ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "posts" ADD CONSTRAINT "posts_author_id_fkey" FOREIGN KEY ("author_id") REFERENCES "users"("id") ON DELETE CASCADE ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "post_likes" ADD CONSTRAINT "post_likes_post_id_fkey" FOREIGN KEY ("post_id") REFERENCES "posts"("id") ON DELETE CASCADE ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "post_likes" ADD CONSTRAINT "post_likes_user_id_fkey" FOREIGN KEY ("user_id") REFERENCES "users"("id") ON DELETE CASCADE ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "comments" ADD CONSTRAINT "comments_post_id_fkey" FOREIGN KEY ("post_id") REFERENCES "posts"("id") ON DELETE CASCADE ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "comments" ADD CONSTRAINT "comments_author_id_fkey" FOREIGN KEY ("author_id") REFERENCES "users"("id") ON DELETE CASCADE ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "comment_likes" ADD CONSTRAINT "comment_likes_comment_id_fkey" FOREIGN KEY ("comment_id") REFERENCES "comments"("id") ON DELETE CASCADE ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "comment_likes" ADD CONSTRAINT "comment_likes_user_id_fkey" FOREIGN KEY ("user_id") REFERENCES "users"("id") ON DELETE CASCADE ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "conversations" ADD CONSTRAINT "conversations_user_a_id_fkey" FOREIGN KEY ("user_a_id") REFERENCES "users"("id") ON DELETE CASCADE ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "conversations" ADD CONSTRAINT "conversations_user_b_id_fkey" FOREIGN KEY ("user_b_id") REFERENCES "users"("id") ON DELETE CASCADE ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "conversations" ADD CONSTRAINT "conversations_last_message_id_fkey" FOREIGN KEY ("last_message_id") REFERENCES "messages"("id") ON DELETE SET NULL ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "conversation_participants" ADD CONSTRAINT "conversation_participants_conversation_id_fkey" FOREIGN KEY ("conversation_id") REFERENCES "conversations"("id") ON DELETE CASCADE ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "conversation_participants" ADD CONSTRAINT "conversation_participants_user_id_fkey" FOREIGN KEY ("user_id") REFERENCES "users"("id") ON DELETE CASCADE ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "messages" ADD CONSTRAINT "messages_conversation_id_fkey" FOREIGN KEY ("conversation_id") REFERENCES "conversations"("id") ON DELETE CASCADE ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "messages" ADD CONSTRAINT "messages_sender_id_fkey" FOREIGN KEY ("sender_id") REFERENCES "users"("id") ON DELETE CASCADE ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "groups" ADD CONSTRAINT "groups_owner_id_fkey" FOREIGN KEY ("owner_id") REFERENCES "users"("id") ON DELETE CASCADE ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "group_members" ADD CONSTRAINT "group_members_group_id_fkey" FOREIGN KEY ("group_id") REFERENCES "groups"("id") ON DELETE CASCADE ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "group_members" ADD CONSTRAINT "group_members_user_id_fkey" FOREIGN KEY ("user_id") REFERENCES "users"("id") ON DELETE CASCADE ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "group_messages" ADD CONSTRAINT "group_messages_group_id_fkey" FOREIGN KEY ("group_id") REFERENCES "groups"("id") ON DELETE CASCADE ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "group_messages" ADD CONSTRAINT "group_messages_sender_id_fkey" FOREIGN KEY ("sender_id") REFERENCES "users"("id") ON DELETE CASCADE ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "notifications" ADD CONSTRAINT "notifications_recipient_id_fkey" FOREIGN KEY ("recipient_id") REFERENCES "users"("id") ON DELETE CASCADE ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "notifications" ADD CONSTRAINT "notifications_actor_id_fkey" FOREIGN KEY ("actor_id") REFERENCES "users"("id") ON DELETE SET NULL ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "uploads" ADD CONSTRAINT "uploads_owner_id_fkey" FOREIGN KEY ("owner_id") REFERENCES "users"("id") ON DELETE CASCADE ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "admin_audit_log" ADD CONSTRAINT "admin_audit_log_actor_id_fkey" FOREIGN KEY ("actor_id") REFERENCES "users"("id") ON DELETE SET NULL ON UPDATE CASCADE;

