-- Add status column to follows for request flow
ALTER TABLE follows ADD COLUMN IF NOT EXISTS status TEXT DEFAULT 'pending' CHECK (status IN ('pending', 'accepted', 'rejected'));

-- Index for fast status lookups
CREATE INDEX IF NOT EXISTS idx_follows_status ON follows(status);
