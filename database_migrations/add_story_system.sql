-- =====================================================
-- Story System Database Migration (FIXED)
-- Run this in Supabase SQL Editor
-- =====================================================

-- 1. Add has_stories column to users table (if not exists)
ALTER TABLE users ADD COLUMN IF NOT EXISTS has_stories BOOLEAN DEFAULT FALSE;

-- 2. Drop and recreate stories table with correct TEXT type
-- This is safe if you don't have important data yet
DROP TABLE IF EXISTS story_viewers CASCADE;
DROP TABLE IF EXISTS stories CASCADE;

-- 3. Create stories table with TEXT id
CREATE TABLE stories (
  id TEXT PRIMARY KEY DEFAULT gen_random_uuid()::text,
  user_id TEXT NOT NULL REFERENCES users(uid) ON DELETE CASCADE,
  media_url TEXT NOT NULL,
  media_type VARCHAR(20) DEFAULT 'image', -- 'image' or 'video'
  caption TEXT,
  mood TEXT,
  views_count INTEGER DEFAULT 0,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  expires_at TIMESTAMP WITH TIME ZONE DEFAULT (NOW() + INTERVAL '24 hours')
);

-- 4. Create story_viewers table for tracking who viewed each story
CREATE TABLE story_viewers (
  id TEXT PRIMARY KEY DEFAULT gen_random_uuid()::text,
  story_id TEXT NOT NULL REFERENCES stories(id) ON DELETE CASCADE,
  viewer_id TEXT NOT NULL REFERENCES users(uid) ON DELETE CASCADE,
  viewed_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  UNIQUE(story_id, viewer_id)
);

-- 5. Create indexes for better performance
CREATE INDEX idx_stories_user_id ON stories(user_id);
CREATE INDEX idx_stories_expires_at ON stories(expires_at);
CREATE INDEX idx_story_viewers_story_id ON story_viewers(story_id);
CREATE INDEX idx_story_viewers_viewer_id ON story_viewers(viewer_id);

-- 6. Create RPC function to increment story views
CREATE OR REPLACE FUNCTION increment_story_views(story_id_input TEXT, viewer_id_input TEXT)
RETURNS VOID AS $$
BEGIN
  -- Insert viewer record (ignore if already viewed)
  INSERT INTO story_viewers (story_id, viewer_id)
  VALUES (story_id_input, viewer_id_input)
  ON CONFLICT (story_id, viewer_id) DO NOTHING;
  
  -- Update view count
  UPDATE stories 
  SET views_count = (SELECT COUNT(*) FROM story_viewers WHERE story_id = story_id_input)
  WHERE id = story_id_input;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- 7. Enable Row Level Security (RLS)
ALTER TABLE stories ENABLE ROW LEVEL SECURITY;
ALTER TABLE story_viewers ENABLE ROW LEVEL SECURITY;

-- 8. RLS Policies for stories table
CREATE POLICY "Users can insert their own stories"
  ON stories FOR INSERT
  WITH CHECK (auth.uid()::text = user_id);

CREATE POLICY "Anyone can view active stories"
  ON stories FOR SELECT
  USING (expires_at > NOW());

CREATE POLICY "Users can delete their own stories"
  ON stories FOR DELETE
  USING (auth.uid()::text = user_id);

CREATE POLICY "Users can update their own stories"
  ON stories FOR UPDATE
  USING (auth.uid()::text = user_id);

-- 9. RLS Policies for story_viewers table
CREATE POLICY "Anyone can view story viewers"
  ON story_viewers FOR SELECT
  USING (true);

CREATE POLICY "Users can add story views"
  ON story_viewers FOR INSERT
  WITH CHECK (auth.uid()::text = viewer_id);

-- 10. Create function to automatically clean expired stories
CREATE OR REPLACE FUNCTION cleanup_expired_stories()
RETURNS void AS $$
BEGIN
  -- Delete stories that expired more than 1 hour ago
  DELETE FROM stories WHERE expires_at < NOW() - INTERVAL '1 hour';
  
  -- Update has_stories flag for users with no active stories
  UPDATE users 
  SET has_stories = FALSE 
  WHERE uid IN (
    SELECT DISTINCT u.uid 
    FROM users u 
    LEFT JOIN stories s ON u.uid = s.user_id AND s.expires_at > NOW()
    WHERE s.id IS NULL AND u.has_stories = TRUE
  );
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- 11. Create trigger function to update has_stories flag
CREATE OR REPLACE FUNCTION update_user_has_stories()
RETURNS TRIGGER AS $$
BEGIN
  -- When a story is inserted, set has_stories to TRUE
  IF TG_OP = 'INSERT' THEN
    UPDATE users SET has_stories = TRUE WHERE uid = NEW.user_id;
  END IF;
  
  -- When a story is deleted, check if user still has active stories
  IF TG_OP = 'DELETE' THEN
    UPDATE users 
    SET has_stories = EXISTS(
      SELECT 1 FROM stories 
      WHERE user_id = OLD.user_id 
      AND expires_at > NOW()
    )
    WHERE uid = OLD.user_id;
  END IF;
  
  RETURN NULL;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- 12. Create trigger on stories table
DROP TRIGGER IF EXISTS trigger_update_user_has_stories ON stories;
CREATE TRIGGER trigger_update_user_has_stories
  AFTER INSERT OR DELETE ON stories
  FOR EACH ROW
  EXECUTE FUNCTION update_user_has_stories();

-- Success message
DO $$
BEGIN
  RAISE NOTICE '✅ Stories system migration completed successfully!';
  RAISE NOTICE '📊 Tables created: stories, story_viewers';
  RAISE NOTICE '🔐 Row Level Security enabled with policies';
  RAISE NOTICE '⚡ Triggers created for auto-updating has_stories flag';
  RAISE NOTICE '🧹 Cleanup function created: cleanup_expired_stories()';
END $$;
