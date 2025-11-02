-- Add Comments System to Database
-- Run this in your Supabase SQL Editor

-- 0. Add comments_count column to posts table if it doesn't exist
ALTER TABLE posts ADD COLUMN IF NOT EXISTS comments_count INTEGER DEFAULT 0;

-- 1. Create comments table
CREATE TABLE IF NOT EXISTS comments (
  id TEXT PRIMARY KEY DEFAULT gen_random_uuid()::text,
  post_id TEXT NOT NULL REFERENCES posts(id) ON DELETE CASCADE,
  user_id TEXT NOT NULL REFERENCES users(uid) ON DELETE CASCADE,
  text TEXT NOT NULL,
  likes_count INTEGER DEFAULT 0,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Create indexes for comments
CREATE INDEX IF NOT EXISTS idx_comments_post_id ON comments(post_id);
CREATE INDEX IF NOT EXISTS idx_comments_user_id ON comments(user_id);
CREATE INDEX IF NOT EXISTS idx_comments_created_at ON comments(created_at DESC);

-- 2. Create comment_likes table
CREATE TABLE IF NOT EXISTS comment_likes (
  id TEXT PRIMARY KEY DEFAULT gen_random_uuid()::text,
  comment_id TEXT NOT NULL REFERENCES comments(id) ON DELETE CASCADE,
  user_id TEXT NOT NULL REFERENCES users(uid) ON DELETE CASCADE,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  UNIQUE(comment_id, user_id)
);

-- Create indexes for comment_likes
CREATE INDEX IF NOT EXISTS idx_comment_likes_comment_id ON comment_likes(comment_id);
CREATE INDEX IF NOT EXISTS idx_comment_likes_user_id ON comment_likes(user_id);

-- 3. Add comments_enabled column to posts (if not exists)
ALTER TABLE posts ADD COLUMN IF NOT EXISTS comments_enabled BOOLEAN DEFAULT true;

-- 4. Create RPC functions for comment counts

-- Increment comment count on post
CREATE OR REPLACE FUNCTION increment_comments_count(post_id_input TEXT)
RETURNS VOID AS $$
BEGIN
  UPDATE posts 
  SET comments_count = COALESCE(comments_count, 0) + 1 
  WHERE id = post_id_input;
END;
$$ LANGUAGE plpgsql;

-- Decrement comment count on post
CREATE OR REPLACE FUNCTION decrement_comments_count(post_id_input TEXT)
RETURNS VOID AS $$
BEGIN
  UPDATE posts 
  SET comments_count = GREATEST(COALESCE(comments_count, 0) - 1, 0) 
  WHERE id = post_id_input;
END;
$$ LANGUAGE plpgsql;

-- Increment comment likes
CREATE OR REPLACE FUNCTION increment_comment_likes(comment_id_input TEXT)
RETURNS VOID AS $$
BEGIN
  UPDATE comments 
  SET likes_count = COALESCE(likes_count, 0) + 1 
  WHERE id = comment_id_input;
END;
$$ LANGUAGE plpgsql;

-- Decrement comment likes
CREATE OR REPLACE FUNCTION decrement_comment_likes(comment_id_input TEXT)
RETURNS VOID AS $$
BEGIN
  UPDATE comments 
  SET likes_count = GREATEST(COALESCE(likes_count, 0) - 1, 0) 
  WHERE id = comment_id_input;
END;
$$ LANGUAGE plpgsql;

-- 5. Enable Row Level Security
ALTER TABLE comments ENABLE ROW LEVEL SECURITY;
ALTER TABLE comment_likes ENABLE ROW LEVEL SECURITY;

-- 6. Drop existing policies if they exist
DROP POLICY IF EXISTS "Anyone can view comments" ON comments;
DROP POLICY IF EXISTS "Users can create comments" ON comments;
DROP POLICY IF EXISTS "Users can update their own comments" ON comments;
DROP POLICY IF EXISTS "Users can delete their own comments" ON comments;
DROP POLICY IF EXISTS "Anyone can view comment likes" ON comment_likes;
DROP POLICY IF EXISTS "Users can like comments" ON comment_likes;
DROP POLICY IF EXISTS "Users can unlike comments" ON comment_likes;

-- 7. Create RLS Policies for comments

-- Anyone can view comments
CREATE POLICY "Anyone can view comments" 
ON comments FOR SELECT 
USING (true);

-- Users can create comments on posts where comments are enabled
CREATE POLICY "Users can create comments" 
ON comments FOR INSERT 
WITH CHECK (
  auth.uid()::text = user_id 
  AND EXISTS (
    SELECT 1 FROM posts 
    WHERE id = post_id 
    AND comments_enabled = true
  )
);

-- Users can update their own comments
CREATE POLICY "Users can update their own comments" 
ON comments FOR UPDATE 
USING (auth.uid()::text = user_id);

-- Users can delete their own comments
CREATE POLICY "Users can delete their own comments" 
ON comments FOR DELETE 
USING (auth.uid()::text = user_id);

-- 8. Create RLS Policies for comment_likes

-- Anyone can view comment likes
CREATE POLICY "Anyone can view comment likes" 
ON comment_likes FOR SELECT 
USING (true);

-- Users can like comments
CREATE POLICY "Users can like comments" 
ON comment_likes FOR INSERT 
WITH CHECK (auth.uid()::text = user_id);

-- Users can unlike comments
CREATE POLICY "Users can unlike comments" 
ON comment_likes FOR DELETE 
USING (auth.uid()::text = user_id);

-- Success message
DO $$
BEGIN
  RAISE NOTICE '✅ Comments system migration completed successfully!';
  RAISE NOTICE '📊 Tables created: comments, comment_likes';
  RAISE NOTICE '🔐 Row Level Security enabled with policies';
  RAISE NOTICE '⚡ RPC functions created for count management';
END $$;
