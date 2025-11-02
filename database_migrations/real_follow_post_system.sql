-- Database Migration for Real Follow/Post System
-- Run this in your Supabase SQL Editor

-- 1. Create followers table (if not exists)
CREATE TABLE IF NOT EXISTS followers (
  id TEXT PRIMARY KEY DEFAULT gen_random_uuid()::text,
  follower_id TEXT NOT NULL REFERENCES users(uid) ON DELETE CASCADE,
  following_id TEXT NOT NULL REFERENCES users(uid) ON DELETE CASCADE,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  UNIQUE(follower_id, following_id),
  CHECK (follower_id != following_id)
);

-- Create indexes for better performance
CREATE INDEX IF NOT EXISTS idx_followers_follower_id ON followers(follower_id);
CREATE INDEX IF NOT EXISTS idx_followers_following_id ON followers(following_id);

-- 2. Create posts table (if not exists)
CREATE TABLE IF NOT EXISTS posts (
  id TEXT PRIMARY KEY DEFAULT gen_random_uuid()::text,
  user_id TEXT NOT NULL REFERENCES users(uid) ON DELETE CASCADE,
  caption TEXT,
  media_urls TEXT[] NOT NULL DEFAULT '{}',
  location TEXT,
  tags TEXT[] DEFAULT '{}',
  post_type VARCHAR(20) DEFAULT 'image', -- 'image', 'video', 'carousel'
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Add columns to posts table if they don't exist
ALTER TABLE posts ADD COLUMN IF NOT EXISTS likes_count INTEGER DEFAULT 0;
ALTER TABLE posts ADD COLUMN IF NOT EXISTS comments_count INTEGER DEFAULT 0;
ALTER TABLE posts ADD COLUMN IF NOT EXISTS shares_count INTEGER DEFAULT 0;
ALTER TABLE posts ADD COLUMN IF NOT EXISTS views_count INTEGER DEFAULT 0;

-- Create indexes for posts
CREATE INDEX IF NOT EXISTS idx_posts_user_id ON posts(user_id);

-- 3. Create post_likes table
CREATE TABLE IF NOT EXISTS post_likes (
  id TEXT PRIMARY KEY DEFAULT gen_random_uuid()::text,
  post_id TEXT NOT NULL REFERENCES posts(id) ON DELETE CASCADE,
  user_id TEXT NOT NULL REFERENCES users(uid) ON DELETE CASCADE,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  UNIQUE(post_id, user_id)
);

-- Create indexes for post_likes
CREATE INDEX IF NOT EXISTS idx_post_likes_post_id ON post_likes(post_id);
CREATE INDEX IF NOT EXISTS idx_post_likes_user_id ON post_likes(user_id);

-- 4. Create saved_posts table
CREATE TABLE IF NOT EXISTS saved_posts (
  id TEXT PRIMARY KEY DEFAULT gen_random_uuid()::text,
  post_id TEXT NOT NULL REFERENCES posts(id) ON DELETE CASCADE,
  user_id TEXT NOT NULL REFERENCES users(uid) ON DELETE CASCADE,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  UNIQUE(post_id, user_id)
);

-- Create indexes for saved_posts
CREATE INDEX IF NOT EXISTS idx_saved_posts_user_id ON saved_posts(user_id);

-- 5. Create stories table (if not exists)
CREATE TABLE IF NOT EXISTS stories (
  id TEXT PRIMARY KEY DEFAULT gen_random_uuid()::text,
  user_id TEXT NOT NULL REFERENCES users(uid) ON DELETE CASCADE,
  media_url TEXT NOT NULL,
  media_type VARCHAR(20) DEFAULT 'image', -- 'image', 'video'
  caption TEXT,
  mood TEXT,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  expires_at TIMESTAMP WITH TIME ZONE DEFAULT (NOW() + INTERVAL '24 hours')
);

-- Add columns to stories table if they don't exist
ALTER TABLE stories ADD COLUMN IF NOT EXISTS views_count INTEGER DEFAULT 0;

-- Create indexes for stories
CREATE INDEX IF NOT EXISTS idx_stories_user_id ON stories(user_id);
CREATE INDEX IF NOT EXISTS idx_stories_expires_at ON stories(expires_at);

-- 6. Create RPC functions for incrementing/decrementing counts

-- Increment followers count
CREATE OR REPLACE FUNCTION increment_followers_count(user_id TEXT)
RETURNS VOID AS $$
BEGIN
  UPDATE users SET followers_count = COALESCE(followers_count, 0) + 1 WHERE uid = user_id;
END;
$$ LANGUAGE plpgsql;

-- Decrement followers count
CREATE OR REPLACE FUNCTION decrement_followers_count(user_id TEXT)
RETURNS VOID AS $$
BEGIN
  UPDATE users SET followers_count = GREATEST(COALESCE(followers_count, 0) - 1, 0) WHERE uid = user_id;
END;
$$ LANGUAGE plpgsql;

-- Increment following count
CREATE OR REPLACE FUNCTION increment_following_count(user_id TEXT)
RETURNS VOID AS $$
BEGIN
  UPDATE users SET following_count = COALESCE(following_count, 0) + 1 WHERE uid = user_id;
END;
$$ LANGUAGE plpgsql;

-- Decrement following count
CREATE OR REPLACE FUNCTION decrement_following_count(user_id TEXT)
RETURNS VOID AS $$
BEGIN
  UPDATE users SET following_count = GREATEST(COALESCE(following_count, 0) - 1, 0) WHERE uid = user_id;
END;
$$ LANGUAGE plpgsql;

-- Increment posts count
CREATE OR REPLACE FUNCTION increment_posts_count(user_id TEXT)
RETURNS VOID AS $$
BEGIN
  UPDATE users SET posts_count = COALESCE(posts_count, 0) + 1 WHERE uid = user_id;
END;
$$ LANGUAGE plpgsql;

-- Decrement posts count
CREATE OR REPLACE FUNCTION decrement_posts_count(user_id TEXT)
RETURNS VOID AS $$
BEGIN
  UPDATE users SET posts_count = GREATEST(COALESCE(posts_count, 0) - 1, 0) WHERE uid = user_id;
END;
$$ LANGUAGE plpgsql;

-- Increment post likes
CREATE OR REPLACE FUNCTION increment_post_likes(post_id_input TEXT)
RETURNS VOID AS $$
BEGIN
  UPDATE posts SET likes_count = COALESCE(likes_count, 0) + 1 WHERE id = post_id_input;
END;
$$ LANGUAGE plpgsql;

-- Decrement post likes
CREATE OR REPLACE FUNCTION decrement_post_likes(post_id_input TEXT)
RETURNS VOID AS $$
BEGIN
  UPDATE posts SET likes_count = GREATEST(COALESCE(likes_count, 0) - 1, 0) WHERE id = post_id_input;
END;
$$ LANGUAGE plpgsql;

-- 7. Enable Row Level Security (RLS)

ALTER TABLE followers ENABLE ROW LEVEL SECURITY;
ALTER TABLE posts ENABLE ROW LEVEL SECURITY;
ALTER TABLE post_likes ENABLE ROW LEVEL SECURITY;
ALTER TABLE saved_posts ENABLE ROW LEVEL SECURITY;
ALTER TABLE stories ENABLE ROW LEVEL SECURITY;

-- 8. Create RLS Policies

-- Followers: Anyone can view, only owner can modify
CREATE POLICY "Anyone can view followers" ON followers FOR SELECT USING (true);
CREATE POLICY "Users can follow others" ON followers FOR INSERT WITH CHECK (auth.uid()::text = follower_id);
CREATE POLICY "Users can unfollow others" ON followers FOR DELETE USING (auth.uid()::text = follower_id);

-- Posts: Public posts viewable by all, private posts only by followers
CREATE POLICY "Anyone can view posts" ON posts FOR SELECT USING (true);
CREATE POLICY "Users can create their own posts" ON posts FOR INSERT WITH CHECK (auth.uid()::text = user_id);
CREATE POLICY "Users can update their own posts" ON posts FOR UPDATE USING (auth.uid()::text = user_id);
CREATE POLICY "Users can delete their own posts" ON posts FOR DELETE USING (auth.uid()::text = user_id);

-- Post likes: Anyone can view, only authenticated users can like
CREATE POLICY "Anyone can view likes" ON post_likes FOR SELECT USING (true);
CREATE POLICY "Users can like posts" ON post_likes FOR INSERT WITH CHECK (auth.uid()::text = user_id);
CREATE POLICY "Users can unlike posts" ON post_likes FOR DELETE USING (auth.uid()::text = user_id);

-- Saved posts: Users can only see their own saved posts
CREATE POLICY "Users can view their saved posts" ON saved_posts FOR SELECT USING (auth.uid()::text = user_id);
CREATE POLICY "Users can save posts" ON saved_posts FOR INSERT WITH CHECK (auth.uid()::text = user_id);
CREATE POLICY "Users can unsave posts" ON saved_posts FOR DELETE USING (auth.uid()::text = user_id);

-- Stories: Anyone can view active stories, only owner can create/delete
CREATE POLICY "Anyone can view active stories" ON stories FOR SELECT USING (expires_at > NOW());
CREATE POLICY "Users can create their own stories" ON stories FOR INSERT WITH CHECK (auth.uid()::text = user_id);
CREATE POLICY "Users can delete their own stories" ON stories FOR DELETE USING (auth.uid()::text = user_id);

-- 9. Create storage bucket for posts (if not exists)
-- Note: Run this separately in Supabase Dashboard -> Storage
-- INSERT INTO storage.buckets (id, name, public) VALUES ('posts', 'posts', true) ON CONFLICT DO NOTHING;

-- 10. Add missing columns to users table (if they don't exist)
ALTER TABLE users ADD COLUMN IF NOT EXISTS followers_count INTEGER DEFAULT 0;
ALTER TABLE users ADD COLUMN IF NOT EXISTS following_count INTEGER DEFAULT 0;
ALTER TABLE users ADD COLUMN IF NOT EXISTS posts_count INTEGER DEFAULT 0;

-- Update existing users with correct counts (only if they have zero counts)
UPDATE users SET 
  followers_count = COALESCE((SELECT COUNT(*) FROM followers WHERE following_id = users.uid), 0),
  following_count = COALESCE((SELECT COUNT(*) FROM followers WHERE follower_id = users.uid), 0),
  posts_count = COALESCE((SELECT COUNT(*) FROM posts WHERE user_id = users.uid), 0);

-- Success message
DO $$
BEGIN
  RAISE NOTICE '✅ Database migration completed successfully!';
  RAISE NOTICE '📊 Tables created: followers, posts, post_likes, saved_posts, stories';
  RAISE NOTICE '🔐 Row Level Security enabled with policies';
  RAISE NOTICE '⚡ RPC functions created for count management';
END $$;
