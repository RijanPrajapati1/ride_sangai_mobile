-- Explore: places shared by locals, reviews ("worth it?") and saves.

-- CreateEnum
CREATE TYPE "place_category" AS ENUM ('viewpoint', 'waterfall', 'lake', 'river', 'trail', 'heritage', 'temple', 'cafe', 'food', 'campsite', 'village', 'cave', 'other');

-- AlterEnum
ALTER TYPE "notification_entity_type" ADD VALUE 'place';

-- AlterEnum
ALTER TYPE "notification_type" ADD VALUE 'placeReview';

-- AlterEnum
ALTER TYPE "upload_purpose" ADD VALUE 'place';

-- CreateTable
CREATE TABLE "places" (
    "id" UUID NOT NULL,
    "author_id" UUID NOT NULL,
    "name" VARCHAR(120) NOT NULL,
    "description" VARCHAR(3000) NOT NULL,
    "category" "place_category" NOT NULL,
    "latitude" DOUBLE PRECISION NOT NULL,
    "longitude" DOUBLE PRECISION NOT NULL,
    "location_name" VARCHAR(200) NOT NULL,
    "photos" TEXT[] DEFAULT ARRAY[]::TEXT[],
    "activities" "activity_category"[] DEFAULT ARRAY[]::"activity_category"[],
    "best_time" VARCHAR(200),
    "tips" VARCHAR(2000),
    "entry_fee" VARCHAR(120),
    "review_count" INTEGER NOT NULL DEFAULT 0,
    "rating_total" INTEGER NOT NULL DEFAULT 0,
    "rating_avg" DOUBLE PRECISION NOT NULL DEFAULT 0,
    "worth_it_count" INTEGER NOT NULL DEFAULT 0,
    "save_count" INTEGER NOT NULL DEFAULT 0,
    "created_at" TIMESTAMPTZ(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "updated_at" TIMESTAMPTZ(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,

    CONSTRAINT "places_pkey" PRIMARY KEY ("id")
);

-- CreateTable
CREATE TABLE "place_reviews" (
    "id" UUID NOT NULL,
    "place_id" UUID NOT NULL,
    "author_id" UUID NOT NULL,
    "rating" INTEGER NOT NULL,
    "worth_it" BOOLEAN NOT NULL,
    "text" VARCHAR(2000) NOT NULL DEFAULT '',
    "visited_on" DATE,
    "photos" TEXT[] DEFAULT ARRAY[]::TEXT[],
    "created_at" TIMESTAMPTZ(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "updated_at" TIMESTAMPTZ(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,

    CONSTRAINT "place_reviews_pkey" PRIMARY KEY ("id")
);

-- CreateTable
CREATE TABLE "place_saves" (
    "place_id" UUID NOT NULL,
    "user_id" UUID NOT NULL,
    "created_at" TIMESTAMPTZ(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,

    CONSTRAINT "place_saves_pkey" PRIMARY KEY ("place_id","user_id")
);

-- CreateIndex
CREATE INDEX "places_latitude_longitude_idx" ON "places"("latitude", "longitude");

-- CreateIndex
CREATE INDEX "places_rating_avg_review_count_id_idx" ON "places"("rating_avg" DESC, "review_count" DESC, "id" DESC);

-- CreateIndex
CREATE INDEX "places_created_at_id_idx" ON "places"("created_at" DESC, "id" DESC);

-- CreateIndex
CREATE INDEX "places_author_id_created_at_idx" ON "places"("author_id", "created_at" DESC);

-- CreateIndex
CREATE INDEX "places_category_idx" ON "places"("category");

-- CreateIndex
CREATE INDEX "places_name_trgm_idx" ON "places" USING GIN ("name" gin_trgm_ops);

-- CreateIndex
CREATE INDEX "place_reviews_place_id_created_at_id_idx" ON "place_reviews"("place_id", "created_at" DESC, "id" DESC);

-- CreateIndex
CREATE INDEX "place_reviews_author_id_idx" ON "place_reviews"("author_id");

-- CreateIndex
CREATE UNIQUE INDEX "place_reviews_place_id_author_id_key" ON "place_reviews"("place_id", "author_id");

-- CreateIndex
CREATE INDEX "place_saves_user_id_created_at_idx" ON "place_saves"("user_id", "created_at" DESC);

-- AddForeignKey
ALTER TABLE "places" ADD CONSTRAINT "places_author_id_fkey" FOREIGN KEY ("author_id") REFERENCES "users"("id") ON DELETE CASCADE ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "place_reviews" ADD CONSTRAINT "place_reviews_place_id_fkey" FOREIGN KEY ("place_id") REFERENCES "places"("id") ON DELETE CASCADE ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "place_reviews" ADD CONSTRAINT "place_reviews_author_id_fkey" FOREIGN KEY ("author_id") REFERENCES "users"("id") ON DELETE CASCADE ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "place_saves" ADD CONSTRAINT "place_saves_place_id_fkey" FOREIGN KEY ("place_id") REFERENCES "places"("id") ON DELETE CASCADE ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "place_saves" ADD CONSTRAINT "place_saves_user_id_fkey" FOREIGN KEY ("user_id") REFERENCES "users"("id") ON DELETE CASCADE ON UPDATE CASCADE;


-- --- Rules Prisma cannot express ------------------------------------------------

ALTER TABLE places
  ADD CONSTRAINT places_coordinates CHECK (latitude BETWEEN -90 AND 90 AND longitude BETWEEN -180 AND 180),
  ADD CONSTRAINT places_text_not_blank CHECK (btrim(name) <> '' AND btrim(description) <> '' AND btrim(location_name) <> ''),
  ADD CONSTRAINT places_photos_max CHECK (cardinality(photos) <= 10),
  ADD CONSTRAINT places_aggregates_non_negative CHECK (review_count >= 0 AND rating_total >= 0 AND worth_it_count >= 0 AND save_count >= 0);

ALTER TABLE place_reviews
  ADD CONSTRAINT place_reviews_rating_range CHECK (rating BETWEEN 1 AND 5),
  ADD CONSTRAINT place_reviews_photos_max CHECK (cardinality(photos) <= 5);

-- place_reviews → places.review_count / rating_total / rating_avg / worth_it_count
CREATE FUNCTION trg_place_reviews_aggregates() RETURNS trigger
LANGUAGE plpgsql AS $$
DECLARE
  target uuid := CASE WHEN TG_OP = 'DELETE' THEN OLD.place_id ELSE NEW.place_id END;
  d_count integer := 0;
  d_total integer := 0;
  d_worth integer := 0;
BEGIN
  IF TG_OP IN ('INSERT', 'UPDATE') THEN
    d_count := d_count + 1;
    d_total := d_total + NEW.rating;
    d_worth := d_worth + CASE WHEN NEW.worth_it THEN 1 ELSE 0 END;
  END IF;
  IF TG_OP IN ('DELETE', 'UPDATE') THEN
    d_count := d_count - 1;
    d_total := d_total - OLD.rating;
    d_worth := d_worth - CASE WHEN OLD.worth_it THEN 1 ELSE 0 END;
  END IF;
  UPDATE places
     SET review_count = GREATEST(review_count + d_count, 0),
         rating_total = GREATEST(rating_total + d_total, 0),
         worth_it_count = GREATEST(worth_it_count + d_worth, 0),
         rating_avg = CASE WHEN review_count + d_count > 0
                           THEN round(((rating_total + d_total)::numeric / (review_count + d_count)), 2)::double precision
                           ELSE 0 END
   WHERE id = target;
  RETURN NULL;
END
$$;
CREATE TRIGGER place_reviews_aggregates AFTER INSERT OR DELETE OR UPDATE OF rating, worth_it ON place_reviews
  FOR EACH ROW EXECUTE FUNCTION trg_place_reviews_aggregates();

-- place_saves → places.save_count
CREATE FUNCTION trg_place_saves_count() RETURNS trigger
LANGUAGE plpgsql AS $$
BEGIN
  IF TG_OP = 'INSERT' THEN
    UPDATE places SET save_count = save_count + 1 WHERE id = NEW.place_id;
  ELSE
    UPDATE places SET save_count = GREATEST(save_count - 1, 0) WHERE id = OLD.place_id;
  END IF;
  RETURN NULL;
END
$$;
CREATE TRIGGER place_saves_count AFTER INSERT OR DELETE ON place_saves
  FOR EACH ROW EXECUTE FUNCTION trg_place_saves_count();
