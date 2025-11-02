-- ============================================================
-- COMPLETE DATABASE MIGRATION FOR SYNCUP APP
-- ============================================================
-- Run this entire file in Supabase SQL Editor to set up all required tables
-- This includes: notifications, blocked_users, muted_users, and any missing columns
-- ============================================================

-- Enable UUID extension if not already enabled
CREATE EXTENSION IF NOT EXISTS "uuid-ossp";

-- ============================================================
-- 1. CREATE NOTIFICATIONS TABLE
-- ============================================================
-- This table stores all user notifications (follow requests, likes, comments)

CREATE TABLE IF NOT EXISTS public.notifications (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  from_user_id UUID NOT NULL REFERENCES public.users(uid) ON DELETE CASCADE,
  to_user_id UUID NOT NULL REFERENCES public.users(uid) ON DELETE CASCADE,
  post_id UUID REFERENCES public.posts(id) ON DELETE CASCADE,
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
-- 3. CREATE MUTED USERS TABLE
-- ============================================================
-- This table stores user muting relationships

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
-- 4. ROW LEVEL SECURITY POLICIES - NOTIFICATIONS
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
  USING (auth.uid() = to_user_id);

-- Users can create notifications (when they perform actions)
CREATE POLICY "Users can create notifications"
  ON public.notifications FOR INSERT
  WITH CHECK (auth.uid() = from_user_id);

-- Users can update their own notifications (mark as read)
CREATE POLICY "Users can update their own notifications"
  ON public.notifications FOR UPDATE
  USING (auth.uid() = to_user_id);

-- Users can delete their own notifications
CREATE POLICY "Users can delete their own notifications"
  ON public.notifications FOR DELETE
  USING (auth.uid() = to_user_id);

-- ============================================================
-- 5. ROW LEVEL SECURITY POLICIES - BLOCKED USERS
-- ============================================================

-- Enable RLS on blocked_users table
ALTER TABLE public.blocked_users ENABLE ROW LEVEL SECURITY;

-- Drop existing policies if they exist
DROP POLICY IF EXISTS "Users can view their own blocked users" ON public.blocked_users;
DROP POLICY IF EXISTS "Users can block other users" ON public.blocked_users;
DROP POLICY IF EXISTS "Users can unblock users" ON public.blocked_users;

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

-- ============================================================
-- 6. ROW LEVEL SECURITY POLICIES - MUTED USERS
-- ============================================================

-- Enable RLS on muted_users table
ALTER TABLE public.muted_users ENABLE ROW LEVEL SECURITY;

-- Drop existing policies if they exist
DROP POLICY IF EXISTS "Users can view their own muted users" ON public.muted_users;
DROP POLICY IF EXISTS "Users can mute other users" ON public.muted_users;
DROP POLICY IF EXISTS "Users can unmute users" ON public.muted_users;

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
-- 7. HELPER FUNCTIONS
-- ============================================================

-- Function to check if user A has blocked user B
CREATE OR REPLACE FUNCTION public.is_user_blocked(blocker UUID, blocked UUID)
RETURNS BOOLEAN AS $$
BEGIN
  RETURN EXISTS (
    SELECT 1 FROM public.blocked_users
    WHERE blocker_id = blocker AND blocked_id = blocked
  );
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Function to check if user A has muted user B
CREATE OR REPLACE FUNCTION public.is_user_muted(muter UUID, muted UUID)
RETURNS BOOLEAN AS $$
BEGIN
  RETURN EXISTS (
    SELECT 1 FROM public.muted_users
    WHERE muter_id = muter AND muted_id = muted
  );
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Function to get unread notification count for a user
CREATE OR REPLACE FUNCTION public.get_unread_notification_count(user_id UUID)
RETURNS INTEGER AS $$
BEGIN
  RETURN (
    SELECT COUNT(*) 
    FROM public.notifications 
    WHERE to_user_id = user_id AND is_read = FALSE
  );
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- ============================================================
-- 8. ENSURE USERS TABLE HAS REQUIRED COLUMNS
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
    COMMENT ON COLUMN public.users.cover_photo_url IS 'URL of the user''s cover/banner photo';
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
-- 9. ENSURE POSTS TABLE HAS REQUIRED COLUMNS
-- ============================================================

-- Add type column if it doesn't exist (for distinguishing posts from reels)
DO $$ 
BEGIN
  IF NOT EXISTS (
    SELECT 1 FROM information_schema.columns 
    WHERE table_schema = 'public' 
    AND table_name = 'posts' 
    AND column_name = 'type'
  ) THEN
    ALTER TABLE public.posts ADD COLUMN type VARCHAR(50) DEFAULT 'post';
    COMMENT ON COLUMN public.posts.type IS 'Type of post: post, reel, story, etc.';
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
    COMMENT ON COLUMN public.posts.thumbnail_url IS 'Thumbnail URL for video posts/reels';
  END IF;
END $$;

-- Add views_count if it doesn't exist (for reels)
DO $$ 
BEGIN
  IF NOT EXISTS (
    SELECT 1 FROM information_schema.columns 
    WHERE table_schema = 'public' 
    AND table_name = 'posts' 
    AND column_name = 'views_count'
  ) THEN
    ALTER TABLE public.posts ADD COLUMN views_count INTEGER DEFAULT 0;
    COMMENT ON COLUMN public.posts.views_count IS 'Number of views (mainly for reels)';
  END IF;
END $$;

-- ============================================================
-- 10. CREATE INDEXES FOR POSTS TABLE (IF NOT EXISTS)
-- ============================================================

CREATE INDEX IF NOT EXISTS idx_posts_user_id ON public.posts(user_id);
CREATE INDEX IF NOT EXISTS idx_posts_type ON public.posts(type);
CREATE INDEX IF NOT EXISTS idx_posts_created_at ON public.posts(created_at DESC);
CREATE INDEX IF NOT EXISTS idx_posts_likes_count ON public.posts(likes_count DESC);
CREATE INDEX IF NOT EXISTS idx_posts_views_count ON public.posts(views_count DESC);

-- ============================================================
-- 11. VERIFICATION QUERIES
-- ============================================================
-- Uncomment and run these separately to verify the migration worked

-- Check all tables were created
-- SELECT table_name FROM information_schema.tables 
-- WHERE table_schema = 'public' 
-- AND table_name IN ('notifications', 'blocked_users', 'muted_users')
-- ORDER BY table_name;

-- Check all indexes were created for notifications
-- SELECT indexname FROM pg_indexes 
-- WHERE tablename = 'notifications'
-- ORDER BY indexname;

-- Check RLS is enabled on all tables
-- SELECT tablename, rowsecurity 
-- FROM pg_tables 
-- WHERE schemaname = 'public'
-- AND tablename IN ('notifications', 'blocked_users', 'muted_users', 'users', 'posts')
-- ORDER BY tablename;

-- Check user table columns
-- SELECT column_name, data_type, column_default
-- FROM information_schema.columns
-- WHERE table_schema = 'public' 
-- AND table_name = 'users'
-- ORDER BY ordinal_position;

-- Check posts table columns
-- SELECT column_name, data_type, column_default
-- FROM information_schema.columns
-- WHERE table_schema = 'public' 
-- AND table_name = 'posts'
-- ORDER BY ordinal_position;

-- Test helper functions
-- SELECT public.is_user_blocked('some-uuid'::uuid, 'another-uuid'::uuid);
-- SELECT public.is_user_muted('some-uuid'::uuid, 'another-uuid'::uuid);
-- SELECT public.get_unread_notification_count('your-user-uuid'::uuid);

-- ============================================================
-- 12. SUCCESS MESSAGE
-- ============================================================

DO $$ 
BEGIN
  RAISE NOTICE '✅ Database migration completed successfully!';
  RAISE NOTICE '';
  RAISE NOTICE 'Created tables:';
  RAISE NOTICE '  - notifications (with 5 indexes)';
  RAISE NOTICE '  - blocked_users (with 3 indexes)';
  RAISE NOTICE '  - muted_users (with 3 indexes)';
  RAISE NOTICE '';
  RAISE NOTICE 'Added/verified columns:';
  RAISE NOTICE '  - users.cover_photo_url';
  RAISE NOTICE '  - users.is_private';
  RAISE NOTICE '  - users.has_stories';
  RAISE NOTICE '  - posts.type';
  RAISE NOTICE '  - posts.thumbnail_url';
  RAISE NOTICE '  - posts.views_count';
  RAISE NOTICE '';
  RAISE NOTICE 'Created helper functions:';
  RAISE NOTICE '  - is_user_blocked(blocker, blocked)';
  RAISE NOTICE '  - is_user_muted(muter, muted)';
  RAISE NOTICE '  - get_unread_notification_count(user_id)';
  RAISE NOTICE '';
  RAISE NOTICE 'All Row Level Security policies are active!';
  RAISE NOTICE '';
  RAISE NOTICE '🎉 Your database is now ready for the SyncUp app!';
END $$;

-- ============================================================
-- END OF MIGRATION
-- ============================================================
-- Next steps:
-- 1. Hot reload your Flutter app (press 'r' in terminal)
-- 2. Check console - errors should be gone
-- 3. Test notifications, blocking, and muting features
-- ============================================================
