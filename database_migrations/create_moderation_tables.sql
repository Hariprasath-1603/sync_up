-- ============================================================
-- CREATE BLOCKED USERS TABLE
-- ============================================================
-- This table stores user blocking relationships
-- When user A blocks user B:
--   - User B cannot see user A's content
--   - User B cannot interact with user A (like, comment, follow)
--   - User B cannot send messages to user A

CREATE TABLE IF NOT EXISTS public.blocked_users (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  blocker_id UUID NOT NULL REFERENCES public.users(uid) ON DELETE CASCADE,
  blocked_id UUID NOT NULL REFERENCES public.users(uid) ON DELETE CASCADE,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  UNIQUE(blocker_id, blocked_id),
  CHECK (blocker_id != blocked_id)
);

-- Create indexes for better query performance
CREATE INDEX IF NOT EXISTS idx_blocked_users_blocker ON public.blocked_users(blocker_id);
CREATE INDEX IF NOT EXISTS idx_blocked_users_blocked ON public.blocked_users(blocked_id);
CREATE INDEX IF NOT EXISTS idx_blocked_users_created_at ON public.blocked_users(created_at DESC);

-- Add comments for documentation
COMMENT ON TABLE public.blocked_users IS 'Stores user blocking relationships for content moderation';
COMMENT ON COLUMN public.blocked_users.blocker_id IS 'User who initiated the block';
COMMENT ON COLUMN public.blocked_users.blocked_id IS 'User who is being blocked';

-- ============================================================
-- CREATE MUTED USERS TABLE
-- ============================================================
-- This table stores user muting relationships
-- When user A mutes user B:
--   - User A won't see user B's posts in their feed
--   - User B can still see and interact with user A's content
--   - Muting is one-way and private (user B doesn't know they're muted)

CREATE TABLE IF NOT EXISTS public.muted_users (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  muter_id UUID NOT NULL REFERENCES public.users(uid) ON DELETE CASCADE,
  muted_id UUID NOT NULL REFERENCES public.users(uid) ON DELETE CASCADE,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  UNIQUE(muter_id, muted_id),
  CHECK (muter_id != muted_id)
);

-- Create indexes for better query performance
CREATE INDEX IF NOT EXISTS idx_muted_users_muter ON public.muted_users(muter_id);
CREATE INDEX IF NOT EXISTS idx_muted_users_muted ON public.muted_users(muted_id);
CREATE INDEX IF NOT EXISTS idx_muted_users_created_at ON public.muted_users(created_at DESC);

-- Add comments for documentation
COMMENT ON TABLE public.muted_users IS 'Stores user muting relationships for feed filtering';
COMMENT ON COLUMN public.muted_users.muter_id IS 'User who initiated the mute';
COMMENT ON COLUMN public.muted_users.muted_id IS 'User who is being muted';

-- ============================================================
-- ROW LEVEL SECURITY POLICIES
-- ============================================================

-- Enable RLS on blocked_users table
ALTER TABLE public.blocked_users ENABLE ROW LEVEL SECURITY;

-- Users can view their own blocked list
CREATE POLICY "Users can view their own blocked users"
  ON public.blocked_users FOR SELECT
  USING (auth.uid() = blocker_id);

-- Users can block other users
CREATE POLICY "Users can block other users"
  ON public.blocked_users FOR INSERT
  WITH CHECK (auth.uid() = blocker_id);

-- Users can unblock users they have blocked
CREATE POLICY "Users can unblock users"
  ON public.blocked_users FOR DELETE
  USING (auth.uid() = blocker_id);

-- Enable RLS on muted_users table
ALTER TABLE public.muted_users ENABLE ROW LEVEL SECURITY;

-- Users can view their own muted list
CREATE POLICY "Users can view their own muted users"
  ON public.muted_users FOR SELECT
  USING (auth.uid() = muter_id);

-- Users can mute other users
CREATE POLICY "Users can mute other users"
  ON public.muted_users FOR INSERT
  WITH CHECK (auth.uid() = muter_id);

-- Users can unmute users they have muted
CREATE POLICY "Users can unmute users"
  ON public.muted_users FOR DELETE
  USING (auth.uid() = muter_id);

-- ============================================================
-- HELPER FUNCTIONS
-- ============================================================

-- Function to check if user A has blocked user B
CREATE OR REPLACE FUNCTION is_user_blocked(blocker UUID, blocked UUID)
RETURNS BOOLEAN AS $$
BEGIN
  RETURN EXISTS (
    SELECT 1 FROM public.blocked_users
    WHERE blocker_id = blocker AND blocked_id = blocked
  );
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Function to check if user A has muted user B
CREATE OR REPLACE FUNCTION is_user_muted(muter UUID, muted UUID)
RETURNS BOOLEAN AS $$
BEGIN
  RETURN EXISTS (
    SELECT 1 FROM public.muted_users
    WHERE muter_id = muter AND muted_id = muted
  );
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- ============================================================
-- VERIFICATION QUERIES
-- ============================================================

-- Verify tables were created
-- SELECT table_name FROM information_schema.tables 
-- WHERE table_schema = 'public' 
-- AND table_name IN ('blocked_users', 'muted_users');

-- Verify indexes were created
-- SELECT indexname FROM pg_indexes 
-- WHERE tablename IN ('blocked_users', 'muted_users');

-- Verify RLS is enabled
-- SELECT tablename, rowsecurity FROM pg_tables 
-- WHERE tablename IN ('blocked_users', 'muted_users');

-- ============================================================
-- SUCCESS MESSAGE
-- ============================================================
-- Run this migration in Supabase SQL Editor
-- After running, the blocked_users and muted_users tables will be ready to use
-- All Row Level Security policies will be active
