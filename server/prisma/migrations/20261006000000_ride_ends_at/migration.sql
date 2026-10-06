-- Rides stay listed as upcoming until they end (starts_at + duration), not
-- only until they start. ends_at is derived and kept in sync by a trigger, so
-- every writer (API, seed, admin tools) gets it right without app code.

ALTER TABLE "rides" ADD COLUMN "ends_at" TIMESTAMPTZ(3);

UPDATE "rides" SET "ends_at" = "starts_at" + "duration_minutes" * INTERVAL '1 minute';

ALTER TABLE "rides" ALTER COLUMN "ends_at" SET NOT NULL;
ALTER TABLE "rides" ALTER COLUMN "ends_at" SET DEFAULT CURRENT_TIMESTAMP;

CREATE FUNCTION trg_rides_ends_at() RETURNS trigger
LANGUAGE plpgsql AS $$
BEGIN
  NEW.ends_at := NEW.starts_at + NEW.duration_minutes * INTERVAL '1 minute';
  RETURN NEW;
END;
$$;

CREATE TRIGGER rides_ends_at BEFORE INSERT OR UPDATE OF starts_at, duration_minutes, ends_at ON rides
  FOR EACH ROW EXECUTE FUNCTION trg_rides_ends_at();

CREATE INDEX "rides_ends_at_starts_at_id_idx" ON "rides"("ends_at", "starts_at", "id");
