-- ============================================================
-- FIXED COMPLETE DATABASE MIGRATION FOR SYNCUP APP
-- ============================================================
-- Run this entire file in Supabase SQL Editor to set up all required tables
-- This includes: notifications, blocked_users, muted_users, and any missing columns
-- FIXED: Changed all UUID references to TEXT to match existing schema
-- ============================================================

-- ============================================================
-- 1. CREATE NOTIFICATIONS TABLE
-- ============================================================
-- This table stores all user notifications (follow requests, likes, comments)

CREATE TABLE IF NOT EXISTS public.notifications (
  id TEXT PRIMARY KEY DEFAULT gen_random_uuid()::text,
  from_user_id TEXT NOT NULL REFERENCES public.users(uid) ON DELETE CASCADE,
  to_user_id TEXT NOT NULL REFERENCES public.users(uid) ON DELETE CASCADE,
  post_id TEXT REFERENCES public.posts(id) ON DELETE CASCADE,
  type VARCHAR(50) NOT NULL CHECK (type IN ('follow', 'follow_request', 'like', 'comment')),
  comment_text TEXT,
  is_read BOOLEAN DEFAULT FALSE,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Create indexes for better query performance
CREATE INDEX IF NOT EXISTS idx_notifications_to_user ON public.notifications(to_user_id);
CREATE INDEX IF NOT EXISTS idx_notifications_from_user ON public.notifications(from_user_id);
CREATE INDEX IF NOT EXISTS idx_notifications_unread ON public.notifications(to_user_id, is_read);
CREATE INDEX IF NOT EXISTS idx_notifications_created_at ON public.notifications(created_at DESC);
CREATE INDEX IF NOT EXISTS idx_notifications_type ON public.notifications(type);

-- Add comments for documentation
COMMENT ON TABLE public.notifications IS 'Stores all user notifications including follow requests, likes, and comments';
COMMENT ON COLUMN public.notifications.type IS 'Type of notification: follow, follow_request, like, or comment';
COMMENT ON COLUMN public.notifications.is_read IS 'Whether the notification has been read by the user';

-- ============================================================
-- 2. CREATE BLOCKED USERS TABLE
-- ============================================================
-- This table stores user blocking relationships

CREATE TABLE IF NOT EXISTS public.blocked_users (
  id TEXT PRIMARY KEY DEFAULT gen_random_uuid()::text,
  blocker_id TEXT NOT NULL REFERENCES public.users(uid) ON DELETE CASCADE,
  blocked_id TEXT NOT NULL REFERENCES public.users(uid) ON DELETE CASCADE,
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
-- 3. CREATE MUTED USERS TABLE
-- ============================================================
-- This table stores user muting relationships

CREATE TABLE IF NOT EXISTS public.muted_users (
  id TEXT PRIMARY KEY DEFAULT gen_random_uuid()::text,
  muter_id TEXT NOT NULL REFERENCES public.users(uid) ON DELETE CASCADE,
  muted_id TEXT NOT NULL REFERENCES public.users(uid) ON DELETE CASCADE,
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
-- 4. ADD MISSING COLUMNS TO USERS TABLE
-- ============================================================

-- Add cover_photo_url if it doesn't exist
DO $$ 
BEGIN
  IF NOT EXISTS (
    SELECT 1 FROM information_schema.columns 
    WHERE table_schema = 'public' 
    AND table_name = 'users' 
    AND column_name = 'cover_photo_url'
  ) THEN
    ALTER TABLE public.users ADD COLUMN cover_photo_url TEXT;
    COMMENT ON COLUMN public.users.cover_photo_url IS 'URL for user profile cover photo';
  END IF;
END $$;

-- Add is_private if it doesn't exist
DO $$ 
BEGIN
  IF NOT EXISTS (
    SELECT 1 FROM information_schema.columns 
    WHERE table_schema = 'public' 
    AND table_name = 'users' 
    AND column_name = 'is_private'
  ) THEN
    ALTER TABLE public.users ADD COLUMN is_private BOOLEAN DEFAULT FALSE;
    COMMENT ON COLUMN public.users.is_private IS 'Whether the user account is private';
  END IF;
END $$;

-- Add has_stories if it doesn't exist
DO $$ 
BEGIN
  IF NOT EXISTS (
    SELECT 1 FROM information_schema.columns 
    WHERE table_schema = 'public' 
    AND table_name = 'users' 
    AND column_name = 'has_stories'
  ) THEN
    ALTER TABLE public.users ADD COLUMN has_stories BOOLEAN DEFAULT FALSE;
    COMMENT ON COLUMN public.users.has_stories IS 'Whether the user has active stories';
  END IF;
END $$;

-- ============================================================
-- 5. ADD MISSING COLUMNS TO POSTS TABLE
-- ============================================================

-- Add type if it doesn't exist (to distinguish posts from reels)
DO $$ 
BEGIN
  IF NOT EXISTS (
    SELECT 1 FROM information_schema.columns 
    WHERE table_schema = 'public' 
    AND table_name = 'posts' 
    AND column_name = 'type'
  ) THEN
    ALTER TABLE public.posts ADD COLUMN type VARCHAR(20) DEFAULT 'post';
    COMMENT ON COLUMN public.posts.type IS 'Type of post: post, reel, carousel';
  END IF;
END $$;

-- Add thumbnail_url if it doesn't exist
DO $$ 
BEGIN
  IF NOT EXISTS (
    SELECT 1 FROM information_schema.columns 
    WHERE table_schema = 'public' 
    AND table_name = 'posts' 
    AND column_name = 'thumbnail_url'
  ) THEN
    ALTER TABLE public.posts ADD COLUMN thumbnail_url TEXT;
    COMMENT ON COLUMN public.posts.thumbnail_url IS 'Thumbnail URL for videos/reels';
  END IF;
END $$;

-- Add views_count if it doesn't exist
DO $$ 
BEGIN
  IF NOT EXISTS (
    SELECT 1 FROM information_schema.columns 
    WHERE table_schema = 'public' 
    AND table_name = 'posts' 
    AND column_name = 'views_count'
  ) THEN
    ALTER TABLE public.posts ADD COLUMN views_count INTEGER DEFAULT 0;
    COMMENT ON COLUMN public.posts.views_count IS 'Number of times the post has been viewed';
  END IF;
END $$;

-- ============================================================
-- 6. ROW LEVEL SECURITY POLICIES - NOTIFICATIONS
-- ============================================================

-- Enable RLS on notifications table
ALTER TABLE public.notifications ENABLE ROW LEVEL SECURITY;

-- Drop existing policies if they exist (to avoid conflicts)
DROP POLICY IF EXISTS "Users can view their own notifications" ON public.notifications;
DROP POLICY IF EXISTS "Users can create notifications" ON public.notifications;
DROP POLICY IF EXISTS "Users can update their own notifications" ON public.notifications;
DROP POLICY IF EXISTS "Users can delete their own notifications" ON public.notifications;

-- Users can view their own notifications
CREATE POLICY "Users can view their own notifications"
  ON public.notifications FOR SELECT
  USING (auth.uid()::text = to_user_id);

-- Users can create notifications (anyone can send notifications)
CREATE POLICY "Users can create notifications"
  ON public.notifications FOR INSERT
  WITH CHECK (auth.uid()::text = from_user_id);

-- Users can update their own notifications (mark as read)
CREATE POLICY "Users can update their own notifications"
  ON public.notifications FOR UPDATE
  USING (auth.uid()::text = to_user_id);

-- Users can delete their own notifications
CREATE POLICY "Users can delete their own notifications"
  ON public.notifications FOR DELETE
  USING (auth.uid()::text = to_user_id);

-- ============================================================
-- 7. ROW LEVEL SECURITY POLICIES - BLOCKED USERS
-- ============================================================

-- Enable RLS on blocked_users table
ALTER TABLE public.blocked_users ENABLE ROW LEVEL SECURITY;

-- Drop existing policies if they exist
DROP POLICY IF EXISTS "Users can view their own blocks" ON public.blocked_users;
DROP POLICY IF EXISTS "Users can create blocks" ON public.blocked_users;
DROP POLICY IF EXISTS "Users can delete their own blocks" ON public.blocked_users;

-- Users can view their own blocks
CREATE POLICY "Users can view their own blocks"
  ON public.blocked_users FOR SELECT
  USING (auth.uid()::text = blocker_id);

-- Users can create blocks
CREATE POLICY "Users can create blocks"
  ON public.blocked_users FOR INSERT
  WITH CHECK (auth.uid()::text = blocker_id);

-- Users can delete their own blocks (unblock)
CREATE POLICY "Users can delete their own blocks"
  ON public.blocked_users FOR DELETE
  USING (auth.uid()::text = blocker_id);

-- ============================================================
-- 8. ROW LEVEL SECURITY POLICIES - MUTED USERS
-- ============================================================

-- Enable RLS on muted_users table
ALTER TABLE public.muted_users ENABLE ROW LEVEL SECURITY;

-- Drop existing policies if they exist
DROP POLICY IF EXISTS "Users can view their own mutes" ON public.muted_users;
DROP POLICY IF EXISTS "Users can create mutes" ON public.muted_users;
DROP POLICY IF EXISTS "Users can delete their own mutes" ON public.muted_users;

-- Users can view their own mutes
CREATE POLICY "Users can view their own mutes"
  ON public.muted_users FOR SELECT
  USING (auth.uid()::text = muter_id);

-- Users can create mutes
CREATE POLICY "Users can create mutes"
  ON public.muted_users FOR INSERT
  WITH CHECK (auth.uid()::text = muter_id);

-- Users can delete their own mutes (unmute)
CREATE POLICY "Users can delete their own mutes"
  ON public.muted_users FOR DELETE
  USING (auth.uid()::text = muter_id);

-- ============================================================
-- 9. HELPER FUNCTIONS
-- ============================================================

-- Function to check if user is blocked
CREATE OR REPLACE FUNCTION is_user_blocked(
  check_user_id TEXT,
  by_user_id TEXT
) RETURNS BOOLEAN AS $$
BEGIN
  RETURN EXISTS (
    SELECT 1 FROM public.blocked_users
    WHERE blocker_id = by_user_id AND blocked_id = check_user_id
  );
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Function to check if user is muted
CREATE OR REPLACE FUNCTION is_user_muted(
  check_user_id TEXT,
  by_user_id TEXT
) RETURNS BOOLEAN AS $$
BEGIN
  RETURN EXISTS (
    SELECT 1 FROM public.muted_users
    WHERE muter_id = by_user_id AND muted_id = check_user_id
  );
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Function to get unread notification count
CREATE OR REPLACE FUNCTION get_unread_notification_count(
  user_id_input TEXT
) RETURNS INTEGER AS $$
BEGIN
  RETURN (
    SELECT COUNT(*)::INTEGER
    FROM public.notifications
    WHERE to_user_id = user_id_input AND is_read = FALSE
  );
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Function to increment comments count
CREATE OR REPLACE FUNCTION increment_comments_count(post_id_input TEXT)
RETURNS VOID AS $$
BEGIN
  UPDATE public.posts
  SET comments_count = COALESCE(comments_count, 0) + 1
  WHERE id = post_id_input;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Function to decrement comments count
CREATE OR REPLACE FUNCTION decrement_comments_count(post_id_input TEXT)
RETURNS VOID AS $$
BEGIN
  UPDATE public.posts
  SET comments_count = GREATEST(COALESCE(comments_count, 0) - 1, 0)
  WHERE id = post_id_input;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- ============================================================
-- VERIFICATION QUERIES (Commented - Run if needed)
-- ============================================================

-- Check if tables were created successfully
-- SELECT table_name FROM information_schema.tables 
-- WHERE table_schema = 'public' 
-- AND table_name IN ('notifications', 'blocked_users', 'muted_users');

-- Check if columns were added successfully
-- SELECT column_name, data_type FROM information_schema.columns
-- WHERE table_schema = 'public' AND table_name = 'users'
-- AND column_name IN ('cover_photo_url', 'is_private', 'has_stories');

-- SELECT column_name, data_type FROM information_schema.columns
-- WHERE table_schema = 'public' AND table_name = 'posts'
-- AND column_name IN ('type', 'thumbnail_url', 'views_count');

-- Check RLS policies
-- SELECT tablename, policyname FROM pg_policies
-- WHERE schemaname = 'public'
-- AND tablename IN ('notifications', 'blocked_users', 'muted_users');

-- ============================================================
-- SUCCESS MESSAGE
-- ============================================================

DO $$
BEGIN
  RAISE NOTICE '✅ DATABASE MIGRATION COMPLETED SUCCESSFULLY!';
  RAISE NOTICE '';
  RAISE NOTICE 'Tables Created/Updated:';
  RAISE NOTICE '  ✓ notifications table';
  RAISE NOTICE '  ✓ blocked_users table';
  RAISE NOTICE '  ✓ muted_users table';
  RAISE NOTICE '  ✓ users table (added columns)';
  RAISE NOTICE '  ✓ posts table (added columns)';
  RAISE NOTICE '';
  RAISE NOTICE 'Security:';
  RAISE NOTICE '  ✓ Row Level Security enabled on all tables';
  RAISE NOTICE '  ✓ Policies created for user data protection';
  RAISE NOTICE '';
  RAISE NOTICE 'Helper Functions:';
  RAISE NOTICE '  ✓ is_user_blocked()';
  RAISE NOTICE '  ✓ is_user_muted()';
  RAISE NOTICE '  ✓ get_unread_notification_count()';
  RAISE NOTICE '  ✓ increment_comments_count()';
  RAISE NOTICE '  ✓ decrement_comments_count()';
  RAISE NOTICE '';
  RAISE NOTICE '🚀 Your app is now ready to use all features!';
END $$;
