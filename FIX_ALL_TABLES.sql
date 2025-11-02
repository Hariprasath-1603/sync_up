-- =====================================================
-- COMPLETE DATABASE FIX
-- Run this in Supabase SQL Editor to fix ALL issues
-- =====================================================

-- ========================================
-- PART 1: Add missing privacy columns to users table
-- ========================================

-- Add privacy settings columns
ALTER TABLE users 
ADD COLUMN IF NOT EXISTS is_private BOOLEAN DEFAULT false;

ALTER TABLE users 
ADD COLUMN IF NOT EXISTS show_activity_status BOOLEAN DEFAULT true;

ALTER TABLE users 
ADD COLUMN IF NOT EXISTS allow_messages_from_everyone BOOLEAN DEFAULT false;

-- Update existing users to have default values
UPDATE users 
SET 
  is_private = COALESCE(is_private, false),
  show_activity_status = COALESCE(show_activity_status, true),
  allow_messages_from_everyone = COALESCE(allow_messages_from_everyone, false)
WHERE 
  is_private IS NULL 
  OR show_activity_status IS NULL 
  OR allow_messages_from_everyone IS NULL;

-- ========================================
-- PART 2: Fix posts table and related tables
-- ========================================

-- Drop tables in correct order (respecting foreign keys)
DROP TABLE IF EXISTS comment_likes CASCADE;
DROP TABLE IF EXISTS comments CASCADE;
DROP TABLE IF EXISTS saved_posts CASCADE;
DROP TABLE IF EXISTS post_likes CASCADE;
DROP TABLE IF EXISTS posts CASCADE;

-- Recreate posts table with ALL required columns
CREATE TABLE posts (
  id TEXT PRIMARY KEY DEFAULT gen_random_uuid()::text,
  user_id TEXT NOT NULL REFERENCES users(uid) ON DELETE CASCADE,
  caption TEXT,
  media_urls TEXT[] NOT NULL DEFAULT '{}',
  location TEXT,
  tags TEXT[] DEFAULT '{}',
  post_type VARCHAR(20) DEFAULT 'image',
  likes_count INTEGER DEFAULT 0,
  comments_count INTEGER DEFAULT 0,
  shares_count INTEGER DEFAULT 0,
  views_count INTEGER DEFAULT 0,
  comments_enabled BOOLEAN DEFAULT true,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Create indexes
CREATE INDEX idx_posts_user_id ON posts(user_id);
CREATE INDEX idx_posts_created_at ON posts(created_at DESC);

-- Recreate post_likes table
CREATE TABLE post_likes (
  id TEXT PRIMARY KEY DEFAULT gen_random_uuid()::text,
  post_id TEXT NOT NULL REFERENCES posts(id) ON DELETE CASCADE,
  user_id TEXT NOT NULL REFERENCES users(uid) ON DELETE CASCADE,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  UNIQUE(post_id, user_id)
);

CREATE INDEX idx_post_likes_post_id ON post_likes(post_id);
CREATE INDEX idx_post_likes_user_id ON post_likes(user_id);

-- Recreate saved_posts table
CREATE TABLE saved_posts (
  id TEXT PRIMARY KEY DEFAULT gen_random_uuid()::text,
  post_id TEXT NOT NULL REFERENCES posts(id) ON DELETE CASCADE,
  user_id TEXT NOT NULL REFERENCES users(uid) ON DELETE CASCADE,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  UNIQUE(post_id, user_id)
);

CREATE INDEX idx_saved_posts_user_id ON saved_posts(user_id);

-- Recreate comments table
CREATE TABLE comments (
  id TEXT PRIMARY KEY DEFAULT gen_random_uuid()::text,
  post_id TEXT NOT NULL REFERENCES posts(id) ON DELETE CASCADE,
  user_id TEXT NOT NULL REFERENCES users(uid) ON DELETE CASCADE,
  text TEXT NOT NULL,
  likes_count INTEGER DEFAULT 0,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

CREATE INDEX idx_comments_post_id ON comments(post_id);
CREATE INDEX idx_comments_user_id ON comments(user_id);

-- Create comment_likes table
CREATE TABLE comment_likes (
  id TEXT PRIMARY KEY DEFAULT gen_random_uuid()::text,
  comment_id TEXT NOT NULL REFERENCES comments(id) ON DELETE CASCADE,
  user_id TEXT NOT NULL REFERENCES users(uid) ON DELETE CASCADE,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  UNIQUE(comment_id, user_id)
);

CREATE INDEX idx_comment_likes_comment_id ON comment_likes(comment_id);
CREATE INDEX idx_comment_likes_user_id ON comment_likes(user_id);

-- Enable RLS on all tables
ALTER TABLE posts ENABLE ROW LEVEL SECURITY;
ALTER TABLE post_likes ENABLE ROW LEVEL SECURITY;
ALTER TABLE saved_posts ENABLE ROW LEVEL SECURITY;
ALTER TABLE comments ENABLE ROW LEVEL SECURITY;
ALTER TABLE comment_likes ENABLE ROW LEVEL SECURITY;

-- Create RLS Policies for posts
DROP POLICY IF EXISTS "Anyone can view posts" ON posts;
DROP POLICY IF EXISTS "Users can create their own posts" ON posts;
DROP POLICY IF EXISTS "Users can update their own posts" ON posts;
DROP POLICY IF EXISTS "Users can delete their own posts" ON posts;

CREATE POLICY "Anyone can view posts" ON posts FOR SELECT USING (true);
CREATE POLICY "Users can create their own posts" ON posts FOR INSERT WITH CHECK (auth.uid()::text = user_id);
CREATE POLICY "Users can update their own posts" ON posts FOR UPDATE USING (auth.uid()::text = user_id);
CREATE POLICY "Users can delete their own posts" ON posts FOR DELETE USING (auth.uid()::text = user_id);

-- Create RLS Policies for post_likes
DROP POLICY IF EXISTS "Anyone can view likes" ON post_likes;
DROP POLICY IF EXISTS "Users can like posts" ON post_likes;
DROP POLICY IF EXISTS "Users can unlike posts" ON post_likes;

CREATE POLICY "Anyone can view likes" ON post_likes FOR SELECT USING (true);
CREATE POLICY "Users can like posts" ON post_likes FOR INSERT WITH CHECK (auth.uid()::text = user_id);
CREATE POLICY "Users can unlike posts" ON post_likes FOR DELETE USING (auth.uid()::text = user_id);

-- Create RLS Policies for saved_posts
DROP POLICY IF EXISTS "Users can view their saved posts" ON saved_posts;
DROP POLICY IF EXISTS "Users can save posts" ON saved_posts;
DROP POLICY IF EXISTS "Users can unsave posts" ON saved_posts;

CREATE POLICY "Users can view their saved posts" ON saved_posts FOR SELECT USING (auth.uid()::text = user_id);
CREATE POLICY "Users can save posts" ON saved_posts FOR INSERT WITH CHECK (auth.uid()::text = user_id);
CREATE POLICY "Users can unsave posts" ON saved_posts FOR DELETE USING (auth.uid()::text = user_id);

-- Create RLS Policies for comments
DROP POLICY IF EXISTS "Anyone can view comments" ON comments;
DROP POLICY IF EXISTS "Users can create comments" ON comments;
DROP POLICY IF EXISTS "Users can update their own comments" ON comments;
DROP POLICY IF EXISTS "Users can delete their own comments" ON comments;

CREATE POLICY "Anyone can view comments" ON comments FOR SELECT USING (true);
CREATE POLICY "Users can create comments" ON comments FOR INSERT WITH CHECK (auth.uid()::text = user_id);
CREATE POLICY "Users can update their own comments" ON comments FOR UPDATE USING (auth.uid()::text = user_id);
CREATE POLICY "Users can delete their own comments" ON comments FOR DELETE USING (auth.uid()::text = user_id);

-- Create RLS Policies for comment_likes
DROP POLICY IF EXISTS "Anyone can view comment likes" ON comment_likes;
DROP POLICY IF EXISTS "Users can like comments" ON comment_likes;
DROP POLICY IF EXISTS "Users can unlike comments" ON comment_likes;

CREATE POLICY "Anyone can view comment likes" ON comment_likes FOR SELECT USING (true);
CREATE POLICY "Users can like comments" ON comment_likes FOR INSERT WITH CHECK (auth.uid()::text = user_id);
CREATE POLICY "Users can unlike comments" ON comment_likes FOR DELETE USING (auth.uid()::text = user_id);

-- Recreate RPC functions
CREATE OR REPLACE FUNCTION increment_posts_count(user_id TEXT)
RETURNS VOID AS $$
BEGIN
  UPDATE users SET posts_count = COALESCE(posts_count, 0) + 1 WHERE uid = user_id;
END;
$$ LANGUAGE plpgsql;

CREATE OR REPLACE FUNCTION decrement_posts_count(user_id TEXT)
RETURNS VOID AS $$
BEGIN
  UPDATE users SET posts_count = GREATEST(COALESCE(posts_count, 0) - 1, 0) WHERE uid = user_id;
END;
$$ LANGUAGE plpgsql;

CREATE OR REPLACE FUNCTION increment_post_likes(post_id_input TEXT)
RETURNS VOID AS $$
BEGIN
  UPDATE posts SET likes_count = COALESCE(likes_count, 0) + 1 WHERE id = post_id_input;
END;
$$ LANGUAGE plpgsql;

CREATE OR REPLACE FUNCTION decrement_post_likes(post_id_input TEXT)
RETURNS VOID AS $$
BEGIN
  UPDATE posts SET likes_count = GREATEST(COALESCE(likes_count, 0) - 1, 0) WHERE id = post_id_input;
END;
$$ LANGUAGE plpgsql;

CREATE OR REPLACE FUNCTION increment_comments_count(post_id_input TEXT)
RETURNS VOID AS $$
BEGIN
  UPDATE posts SET comments_count = COALESCE(comments_count, 0) + 1 WHERE id = post_id_input;
END;
$$ LANGUAGE plpgsql;

CREATE OR REPLACE FUNCTION decrement_comments_count(post_id_input TEXT)
RETURNS VOID AS $$
BEGIN
  UPDATE posts SET comments_count = GREATEST(COALESCE(comments_count, 0) - 1, 0) WHERE id = post_id_input;
END;
$$ LANGUAGE plpgsql;

CREATE OR REPLACE FUNCTION increment_comment_likes(comment_id_input TEXT)
RETURNS VOID AS $$
BEGIN
  UPDATE comments SET likes_count = COALESCE(likes_count, 0) + 1 WHERE id = comment_id_input;
END;
$$ LANGUAGE plpgsql;

CREATE OR REPLACE FUNCTION decrement_comment_likes(comment_id_input TEXT)
RETURNS VOID AS $$
BEGIN
  UPDATE comments SET likes_count = GREATEST(COALESCE(likes_count, 0) - 1, 0) WHERE id = comment_id_input;
END;
$$ LANGUAGE plpgsql;

-- Force schema reload
NOTIFY pgrst, 'reload schema';

-- ========================================
-- PART 3: Verification queries
-- ========================================

-- Check users table columns
SELECT 'USERS TABLE COLUMNS:' as info;
SELECT 
  column_name,
  data_type,
  column_default
FROM information_schema.columns
WHERE table_name = 'users'
  AND table_schema = 'public'
  AND column_name IN ('is_private', 'show_activity_status', 'allow_messages_from_everyone')
ORDER BY ordinal_position;

-- Check posts table columns
SELECT 'POSTS TABLE COLUMNS:' as info;
SELECT 
  column_name,
  data_type,
  column_default
FROM information_schema.columns
WHERE table_name = 'posts'
  AND table_schema = 'public'
ORDER BY ordinal_position;

-- Success message
DO $$
BEGIN
  RAISE NOTICE '========================================';
  RAISE NOTICE '✅ ALL TABLES FIXED SUCCESSFULLY!';
  RAISE NOTICE '========================================';
  RAISE NOTICE '👤 Users table: Added privacy columns';
  RAISE NOTICE '   - is_private';
  RAISE NOTICE '   - show_activity_status';
  RAISE NOTICE '   - allow_messages_from_everyone';
  RAISE NOTICE '';
  RAISE NOTICE '📝 Posts table: Completely recreated';
  RAISE NOTICE '   - All columns present';
  RAISE NOTICE '   - RLS policies active';
  RAISE NOTICE '   - RPC functions ready';
  RAISE NOTICE '';
  RAISE NOTICE '🎯 Ready to signup and create posts!';
  RAISE NOTICE '========================================';
END $$;
