-- =============================================================================
-- Data rules Prisma cannot express in schema.prisma:
--   * CHECK constraints (business invariants enforced by the database)
--   * Counter-maintenance triggers (correct for every write path, including
--     ON DELETE CASCADE when a user, post, ride or group is removed)
-- Prisma Migrate ignores CHECK constraints, functions and triggers when it
-- diffs the schema, so they are safe from being dropped by later migrations.
-- =============================================================================

-- Which dashboard category a ride type belongs to (mirrors RideTypeX.category in the app).
CREATE FUNCTION ride_type_category(t ride_type) RETURNS activity_category
LANGUAGE sql IMMUTABLE PARALLEL SAFE
AS $$
  SELECT CASE
    WHEN t::text IN ('road', 'mountain', 'gravel', 'touring', 'social', 'hillClimb', 'nightRide') THEN 'cycling'
    WHEN t::text IN ('multiDayTrek', 'dayTrek', 'summitTrek') THEN 'trekking'
    WHEN t::text IN ('dayHike', 'natureWalk', 'familyHike') THEN 'hiking'
    ELSE 'riding'
  END::activity_category
$$;

-- --- CHECK constraints ---------------------------------------------------------

ALTER TABLE users
  ADD CONSTRAINT users_email_lowercase CHECK (email = lower(email) AND email ~ '^[^@\s]+@[^@\s]+$'),
  ADD CONSTRAINT users_name_not_blank CHECK (btrim(name) <> ''),
  ADD CONSTRAINT users_counts_non_negative CHECK (followers_count >= 0 AND following_count >= 0),
  ADD CONSTRAINT users_interests_max CHECK (cardinality(interests) <= 20);

ALTER TABLE follows
  ADD CONSTRAINT follows_no_self CHECK (follower_id <> following_id);

ALTER TABLE rides
  ADD CONSTRAINT rides_category_matches_type CHECK (category = ride_type_category(ride_type)),
  ADD CONSTRAINT rides_text_not_blank CHECK (btrim(title) <> '' AND btrim(description) <> '' AND btrim(meeting_point) <> ''),
  ADD CONSTRAINT rides_positive_numbers CHECK (distance_km > 0 AND duration_minutes > 0),
  ADD CONSTRAINT rides_max_participants_range CHECK (max_participants BETWEEN 2 AND 1000),
  ADD CONSTRAINT rides_capacity CHECK (participant_count >= 1 AND participant_count <= max_participants),
  ADD CONSTRAINT rides_requirements_max CHECK (cardinality(requirements) <= 20);

ALTER TABLE ride_requests
  ADD CONSTRAINT ride_requests_decline_reason_only_when_declined CHECK (status = 'declined' OR decline_reason IS NULL);

ALTER TABLE posts
  ADD CONSTRAINT posts_text_not_blank CHECK (btrim(text) <> ''),
  ADD CONSTRAINT posts_counts_non_negative CHECK (like_count >= 0 AND comment_count >= 0);

ALTER TABLE comments
  ADD CONSTRAINT comments_text_not_blank CHECK (btrim(text) <> ''),
  ADD CONSTRAINT comments_like_count_non_negative CHECK (like_count >= 0);

ALTER TABLE conversations
  ADD CONSTRAINT conversations_pair_order CHECK (user_a_id < user_b_id);

ALTER TABLE messages
  ADD CONSTRAINT messages_text_not_blank CHECK (btrim(text) <> '');

ALTER TABLE groups
  ADD CONSTRAINT groups_text_not_blank CHECK (btrim(name) <> '' AND btrim(description) <> ''),
  ADD CONSTRAINT groups_member_count_non_negative CHECK (member_count >= 0);

ALTER TABLE group_messages
  ADD CONSTRAINT group_messages_text_not_blank CHECK (btrim(text) <> '');

ALTER TABLE uploads
  ADD CONSTRAINT uploads_size_positive CHECK (size_bytes > 0);

ALTER TABLE banners
  ADD CONSTRAINT banners_window CHECK (starts_at IS NULL OR ends_at IS NULL OR starts_at < ends_at);

-- --- Counter triggers ----------------------------------------------------------

-- follows → users.followers_count / following_count. Both rows are updated in
-- one statement (primary-key order), so concurrent A→B / B→A follows cannot deadlock.
CREATE FUNCTION trg_follows_counts() RETURNS trigger
LANGUAGE plpgsql AS $$
DECLARE
  delta integer := CASE WHEN TG_OP = 'INSERT' THEN 1 ELSE -1 END;
  v_follower uuid := CASE WHEN TG_OP = 'INSERT' THEN NEW.follower_id ELSE OLD.follower_id END;
  v_following uuid := CASE WHEN TG_OP = 'INSERT' THEN NEW.following_id ELSE OLD.following_id END;
BEGIN
  UPDATE users
     SET followers_count = GREATEST(followers_count + CASE WHEN id = v_following THEN delta ELSE 0 END, 0),
         following_count = GREATEST(following_count + CASE WHEN id = v_follower THEN delta ELSE 0 END, 0)
   WHERE id IN (v_follower, v_following);
  RETURN NULL;
END
$$;
CREATE TRIGGER follows_counts AFTER INSERT OR DELETE ON follows
  FOR EACH ROW EXECUTE FUNCTION trg_follows_counts();

-- ride_requests → rides.participant_count (organizer + approved riders).
-- Going over max_participants violates rides_capacity, so a race can never overfill a ride.
CREATE FUNCTION trg_ride_requests_participant_count() RETURNS trigger
LANGUAGE plpgsql AS $$
DECLARE
  delta integer := 0;
  target uuid;
BEGIN
  IF TG_OP = 'INSERT' THEN
    delta := CASE WHEN NEW.status = 'approved' THEN 1 ELSE 0 END;
    target := NEW.ride_id;
  ELSIF TG_OP = 'DELETE' THEN
    delta := CASE WHEN OLD.status = 'approved' THEN -1 ELSE 0 END;
    target := OLD.ride_id;
  ELSE
    IF NEW.ride_id <> OLD.ride_id THEN
      RAISE EXCEPTION 'ride_requests.ride_id cannot change';
    END IF;
    delta := (CASE WHEN NEW.status = 'approved' THEN 1 ELSE 0 END)
           - (CASE WHEN OLD.status = 'approved' THEN 1 ELSE 0 END);
    target := NEW.ride_id;
  END IF;
  IF delta <> 0 THEN
    UPDATE rides SET participant_count = participant_count + delta WHERE id = target;
  END IF;
  RETURN NULL;
END
$$;
CREATE TRIGGER ride_requests_participant_count AFTER INSERT OR DELETE OR UPDATE OF status, ride_id ON ride_requests
  FOR EACH ROW EXECUTE FUNCTION trg_ride_requests_participant_count();

-- post_likes → posts.like_count
CREATE FUNCTION trg_post_likes_count() RETURNS trigger
LANGUAGE plpgsql AS $$
BEGIN
  IF TG_OP = 'INSERT' THEN
    UPDATE posts SET like_count = like_count + 1 WHERE id = NEW.post_id;
  ELSE
    UPDATE posts SET like_count = GREATEST(like_count - 1, 0) WHERE id = OLD.post_id;
  END IF;
  RETURN NULL;
END
$$;
CREATE TRIGGER post_likes_count AFTER INSERT OR DELETE ON post_likes
  FOR EACH ROW EXECUTE FUNCTION trg_post_likes_count();

-- comments → posts.comment_count
CREATE FUNCTION trg_comments_count() RETURNS trigger
LANGUAGE plpgsql AS $$
BEGIN
  IF TG_OP = 'INSERT' THEN
    UPDATE posts SET comment_count = comment_count + 1 WHERE id = NEW.post_id;
  ELSE
    UPDATE posts SET comment_count = GREATEST(comment_count - 1, 0) WHERE id = OLD.post_id;
  END IF;
  RETURN NULL;
END
$$;
CREATE TRIGGER comments_count AFTER INSERT OR DELETE ON comments
  FOR EACH ROW EXECUTE FUNCTION trg_comments_count();

-- comment_likes → comments.like_count
CREATE FUNCTION trg_comment_likes_count() RETURNS trigger
LANGUAGE plpgsql AS $$
BEGIN
  IF TG_OP = 'INSERT' THEN
    UPDATE comments SET like_count = like_count + 1 WHERE id = NEW.comment_id;
  ELSE
    UPDATE comments SET like_count = GREATEST(like_count - 1, 0) WHERE id = OLD.comment_id;
  END IF;
  RETURN NULL;
END
$$;
CREATE TRIGGER comment_likes_count AFTER INSERT OR DELETE ON comment_likes
  FOR EACH ROW EXECUTE FUNCTION trg_comment_likes_count();

-- group_members → groups.member_count
CREATE FUNCTION trg_group_members_count() RETURNS trigger
LANGUAGE plpgsql AS $$
BEGIN
  IF TG_OP = 'INSERT' THEN
    UPDATE groups SET member_count = member_count + 1 WHERE id = NEW.group_id;
  ELSE
    UPDATE groups SET member_count = GREATEST(member_count - 1, 0) WHERE id = OLD.group_id;
  END IF;
  RETURN NULL;
END
$$;
CREATE TRIGGER group_members_count AFTER INSERT OR DELETE ON group_members
  FOR EACH ROW EXECUTE FUNCTION trg_group_members_count();

-- messages → conversations.last_message_id / last_message_at (never moves backwards)
CREATE FUNCTION trg_messages_touch_conversation() RETURNS trigger
LANGUAGE plpgsql AS $$
BEGIN
  UPDATE conversations
     SET last_message_id = NEW.id,
         last_message_at = NEW.created_at
   WHERE id = NEW.conversation_id
     AND (last_message_id IS NULL OR last_message_at <= NEW.created_at);
  RETURN NULL;
END
$$;
CREATE TRIGGER messages_touch_conversation AFTER INSERT ON messages
  FOR EACH ROW EXECUTE FUNCTION trg_messages_touch_conversation();

-- group_messages → groups.last_message_at
CREATE FUNCTION trg_group_messages_touch_group() RETURNS trigger
LANGUAGE plpgsql AS $$
BEGIN
  UPDATE groups
     SET last_message_at = NEW.created_at
   WHERE id = NEW.group_id
     AND (last_message_at IS NULL OR last_message_at <= NEW.created_at);
  RETURN NULL;
END
$$;
CREATE TRIGGER group_messages_touch_group AFTER INSERT ON group_messages
  FOR EACH ROW EXECUTE FUNCTION trg_group_messages_touch_group();

-- Reading a notification releases its collapse key, so the next event of the
-- same kind creates a fresh notification instead of updating a read one.
CREATE FUNCTION trg_notifications_release_collapse_key() RETURNS trigger
LANGUAGE plpgsql AS $$
BEGIN
  IF NEW.read_at IS NOT NULL THEN
    NEW.collapse_key := NULL;
  END IF;
  RETURN NEW;
END
$$;
CREATE TRIGGER notifications_release_collapse_key BEFORE INSERT OR UPDATE OF read_at ON notifications
  FOR EACH ROW EXECUTE FUNCTION trg_notifications_release_collapse_key();
