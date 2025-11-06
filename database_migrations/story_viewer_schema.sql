-- Story Viewer Database Schema
-- Run this in Supabase SQL Editor to set up all required tables and functions

-- ============================================================================
-- 0. CHECK EXISTING SCHEMA AND DROP IF NEEDED
-- ============================================================================
DO $$ 
DECLARE
  stories_id_type TEXT;
  users_uid_type TEXT;
BEGIN
  -- Get users.uid data type
  SELECT data_type INTO users_uid_type
  FROM information_schema.columns
  WHERE table_name = 'users' AND column_name = 'uid';
  
  RAISE NOTICE 'Users uid type: %', users_uid_type;
  
  -- Check if stories table exists
  IF EXISTS (SELECT 1 FROM information_schema.tables WHERE table_name = 'stories') THEN
    -- Drop existing stories tables to recreate with correct types
    RAISE NOTICE 'Dropping existing stories tables...';
    DROP TABLE IF EXISTS story_reactions CASCADE;
    DROP TABLE IF EXISTS story_replies CASCADE;
    DROP TABLE IF EXISTS story_viewers CASCADE;
    DROP TABLE IF EXISTS story_archive CASCADE;
    DROP TABLE IF EXISTS stories CASCADE;
  END IF;
END $$;

-- ============================================================================
-- 1. STORIES TABLE
-- ============================================================================
-- Main table for storing story content (images and videos)
-- Using TEXT for all ID fields to match existing users table
CREATE TABLE stories (
  id TEXT PRIMARY KEY DEFAULT gen_random_uuid()::TEXT,
  user_id TEXT NOT NULL REFERENCES users(uid) ON DELETE CASCADE,
  media_url TEXT NOT NULL,
  thumbnail_url TEXT,
  media_type TEXT NOT NULL CHECK (media_type IN ('image', 'video')),
  caption TEXT,
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  expires_at TIMESTAMPTZ NOT NULL DEFAULT (NOW() + INTERVAL '24 hours'),
  views_count INT NOT NULL DEFAULT 0,
  viewers TEXT[] DEFAULT '{}',
  is_archived BOOLEAN DEFAULT FALSE,
  CONSTRAINT valid_media_url CHECK (media_url <> ''),
  CONSTRAINT valid_expires_at CHECK (expires_at > created_at)
);

-- Indexes for performance
CREATE INDEX IF NOT EXISTS idx_stories_user_id ON stories(user_id);
CREATE INDEX IF NOT EXISTS idx_stories_created_at ON stories(created_at DESC);
CREATE INDEX IF NOT EXISTS idx_stories_expires_at ON stories(expires_at);
CREATE INDEX IF NOT EXISTS idx_stories_active ON stories(expires_at) WHERE is_archived = FALSE;

-- ============================================================================
-- 2. STORY VIEWERS TABLE
-- ============================================================================
-- Track who viewed each story and when
CREATE TABLE story_viewers (
  id TEXT PRIMARY KEY DEFAULT gen_random_uuid()::TEXT,
  story_id TEXT NOT NULL REFERENCES stories(id) ON DELETE CASCADE,
  viewer_id TEXT NOT NULL REFERENCES users(uid) ON DELETE CASCADE,
  viewed_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  watch_duration INT DEFAULT 0, -- seconds watched
  completed BOOLEAN DEFAULT FALSE, -- watched till end
  UNIQUE(story_id, viewer_id)
);

-- Indexes
CREATE INDEX idx_story_viewers_story_id ON story_viewers(story_id);
CREATE INDEX idx_story_viewers_viewer_id ON story_viewers(viewer_id);
CREATE INDEX idx_story_viewers_viewed_at ON story_viewers(viewed_at DESC);

-- ============================================================================
-- 3. STORY REPLIES TABLE
-- ============================================================================
-- Store text and emoji replies to stories
CREATE TABLE story_replies (
  id TEXT PRIMARY KEY DEFAULT gen_random_uuid()::TEXT,
  story_id TEXT NOT NULL REFERENCES stories(id) ON DELETE CASCADE,
  sender_id TEXT NOT NULL REFERENCES users(uid) ON DELETE CASCADE,
  receiver_id TEXT NOT NULL REFERENCES users(uid) ON DELETE CASCADE,
  message TEXT,
  emoji TEXT,
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  is_read BOOLEAN DEFAULT FALSE,
  CONSTRAINT valid_reply CHECK (message IS NOT NULL OR emoji IS NOT NULL)
);

-- Indexes
CREATE INDEX idx_story_replies_story_id ON story_replies(story_id);
CREATE INDEX idx_story_replies_sender_id ON story_replies(sender_id);
CREATE INDEX idx_story_replies_receiver_id ON story_replies(receiver_id);
CREATE INDEX idx_story_replies_created_at ON story_replies(created_at DESC);

-- ============================================================================
-- 4. STORY REACTIONS TABLE
-- ============================================================================
-- Track emoji reactions on stories
CREATE TABLE story_reactions (
  id TEXT PRIMARY KEY DEFAULT gen_random_uuid()::TEXT,
  story_id TEXT NOT NULL REFERENCES stories(id) ON DELETE CASCADE,
  user_id TEXT NOT NULL REFERENCES users(uid) ON DELETE CASCADE,
  emoji TEXT NOT NULL,
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  UNIQUE(story_id, user_id, emoji)
);

-- Indexes
CREATE INDEX idx_story_reactions_story_id ON story_reactions(story_id);
CREATE INDEX idx_story_reactions_user_id ON story_reactions(user_id);

-- ============================================================================
-- 5. STORY ARCHIVE TABLE
-- ============================================================================
-- Store archived stories (after 24 hours or manual archive)
-- UPDATED: Now includes viewers and reactions as JSONB for historical preservation
CREATE TABLE story_archive (
  id TEXT PRIMARY KEY DEFAULT gen_random_uuid()::TEXT,
  original_story_id TEXT NOT NULL, -- Reference to original story ID
  user_id TEXT NOT NULL REFERENCES users(uid) ON DELETE CASCADE,
  media_url TEXT NOT NULL,
  thumbnail_url TEXT,
  media_type TEXT NOT NULL CHECK (media_type IN ('image', 'video')),
  caption TEXT,
  created_at TIMESTAMPTZ NOT NULL,
  archived_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  views_count INT NOT NULL DEFAULT 0,
  original_expires_at TIMESTAMPTZ,
  viewers JSONB DEFAULT '[]'::JSONB, -- Preserved viewer data
  reactions JSONB DEFAULT '[]'::JSONB, -- Preserved reaction data
  restored BOOLEAN DEFAULT FALSE, -- Tracks if story was restored
  restored_at TIMESTAMPTZ -- When story was restored
);

-- Indexes
CREATE INDEX idx_story_archive_user_id ON story_archive(user_id);
CREATE INDEX idx_story_archive_archived_at ON story_archive(archived_at DESC);
CREATE INDEX idx_story_archive_original_id ON story_archive(original_story_id);
CREATE INDEX idx_story_archive_restored ON story_archive(restored);

-- ============================================================================
-- 6. USER SETTINGS TABLE
-- ============================================================================
-- Store user preferences for story features
CREATE TABLE IF NOT EXISTS user_settings (
  user_id TEXT PRIMARY KEY REFERENCES users(uid) ON DELETE CASCADE,
  auto_archive BOOLEAN DEFAULT TRUE, -- Auto-archive stories after 24h
  save_to_gallery BOOLEAN DEFAULT FALSE, -- Save stories to device (future)
  story_privacy TEXT DEFAULT 'public' CHECK (story_privacy IN ('public', 'friends', 'private')),
  allow_story_replies BOOLEAN DEFAULT TRUE,
  allow_story_reactions BOOLEAN DEFAULT TRUE,
  created_at TIMESTAMPTZ NOT NULL DEFAULT NOW(),
  updated_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

-- Index
CREATE INDEX idx_user_settings_user_id ON user_settings(user_id);

-- ============================================================================
-- 7. RPC FUNCTIONS
-- ============================================================================

-- Function to increment story views atomically
CREATE OR REPLACE FUNCTION increment_story_views(story_id TEXT)
RETURNS VOID AS $$
BEGIN
  UPDATE stories
  SET views_count = views_count + 1
  WHERE id = story_id;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Function to add a viewer to story's viewers array
CREATE OR REPLACE FUNCTION add_story_viewer(story_id TEXT, viewer_id TEXT)
RETURNS VOID AS $$
BEGIN
  UPDATE stories
  SET viewers = array_append(viewers, viewer_id)
  WHERE id = story_id
    AND NOT (viewers @> ARRAY[viewer_id]);
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Function to get story analytics
CREATE OR REPLACE FUNCTION get_story_analytics(story_id TEXT)
RETURNS JSON AS $$
DECLARE
  result JSON;
BEGIN
  SELECT json_build_object(
    'story_id', story_id,
    'views_count', (SELECT views_count FROM stories WHERE id = story_id),
    'unique_viewers', (SELECT COUNT(*) FROM story_viewers WHERE story_viewers.story_id = get_story_analytics.story_id),
    'replies_count', (SELECT COUNT(*) FROM story_replies WHERE story_replies.story_id = get_story_analytics.story_id),
    'reactions_count', (SELECT COUNT(*) FROM story_reactions WHERE story_reactions.story_id = get_story_analytics.story_id),
    'completion_rate', (
      SELECT ROUND(
        (COUNT(*) FILTER (WHERE completed = TRUE)::DECIMAL / NULLIF(COUNT(*), 0)) * 100,
        2
      )
      FROM story_viewers WHERE story_viewers.story_id = get_story_analytics.story_id
    ),
    'avg_watch_duration', (
      SELECT ROUND(AVG(watch_duration), 1)
      FROM story_viewers
      WHERE story_viewers.story_id = get_story_analytics.story_id AND watch_duration > 0
    )
  ) INTO result;
  
  RETURN result;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Function to archive expired stories (run via cron or manually)
CREATE OR REPLACE FUNCTION archive_expired_stories()
RETURNS INT AS $$
DECLARE
  archived_count INT;
BEGIN
  -- Insert expired stories into archive
  INSERT INTO story_archive (
    id, user_id, media_url, thumbnail_url, media_type,
    caption, created_at, views_count, original_expires_at
  )
  SELECT
    id, user_id, media_url, thumbnail_url, media_type,
    caption, created_at, views_count, expires_at
  FROM stories
  WHERE expires_at < NOW() AND is_archived = FALSE;

  GET DIAGNOSTICS archived_count = ROW_COUNT;

  -- Mark as archived (or delete if you prefer)
  UPDATE stories
  SET is_archived = TRUE
  WHERE expires_at < NOW() AND is_archived = FALSE;

  RETURN archived_count;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Function to delete a story (creator only)
CREATE OR REPLACE FUNCTION delete_story(story_id TEXT, requesting_user_id TEXT)
RETURNS BOOLEAN AS $$
DECLARE
  story_owner TEXT;
BEGIN
  -- Get story owner
  SELECT user_id INTO story_owner FROM stories WHERE id = story_id;
  
  -- Check if requester is the owner
  IF story_owner = requesting_user_id THEN
    DELETE FROM stories WHERE id = story_id;
    RETURN TRUE;
  ELSE
    RETURN FALSE;
  END IF;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- ============================================================================
-- 8. ROW LEVEL SECURITY (RLS) POLICIES
-- ============================================================================

-- Enable RLS on all tables
ALTER TABLE stories ENABLE ROW LEVEL SECURITY;
ALTER TABLE story_viewers ENABLE ROW LEVEL SECURITY;
ALTER TABLE story_replies ENABLE ROW LEVEL SECURITY;
ALTER TABLE story_reactions ENABLE ROW LEVEL SECURITY;
ALTER TABLE story_archive ENABLE ROW LEVEL SECURITY;
ALTER TABLE user_settings ENABLE ROW LEVEL SECURITY;

-- Stories policies
CREATE POLICY "Users can view non-expired stories"
  ON stories FOR SELECT
  USING (expires_at > NOW() AND is_archived = FALSE);

CREATE POLICY "Users can insert their own stories"
  ON stories FOR INSERT
  WITH CHECK (auth.uid()::TEXT = user_id);

CREATE POLICY "Users can update their own stories"
  ON stories FOR UPDATE
  USING (auth.uid()::TEXT = user_id);

CREATE POLICY "Users can delete their own stories"
  ON stories FOR DELETE
  USING (auth.uid()::TEXT = user_id);

-- Story viewers policies
CREATE POLICY "Users can view story viewers if they're the story owner"
  ON story_viewers FOR SELECT
  USING (
    EXISTS (
      SELECT 1 FROM stories
      WHERE stories.id = story_viewers.story_id
        AND stories.user_id = auth.uid()::TEXT
    )
  );

CREATE POLICY "Users can insert story views"
  ON story_viewers FOR INSERT
  WITH CHECK (auth.uid()::TEXT = viewer_id);

-- Story replies policies
CREATE POLICY "Users can view replies to their own stories"
  ON story_replies FOR SELECT
  USING (
    EXISTS (
      SELECT 1 FROM stories
      WHERE stories.id = story_replies.story_id
        AND stories.user_id = auth.uid()::TEXT
    )
  );

CREATE POLICY "Users can send replies"
  ON story_replies FOR INSERT
  WITH CHECK (auth.uid()::TEXT = sender_id);

CREATE POLICY "Users can view their sent replies"
  ON story_replies FOR SELECT
  USING (auth.uid()::TEXT = sender_id);

-- Story reactions policies
CREATE POLICY "Users can view reactions on any story"
  ON story_reactions FOR SELECT
  USING (TRUE);

CREATE POLICY "Users can add their own reactions"
  ON story_reactions FOR INSERT
  WITH CHECK (auth.uid()::TEXT = user_id);

CREATE POLICY "Users can delete their own reactions"
  ON story_reactions FOR DELETE
  USING (auth.uid()::TEXT = user_id);

-- Story archive policies
CREATE POLICY "Users can view their own archived stories"
  ON story_archive FOR SELECT
  USING (auth.uid()::TEXT = user_id);

CREATE POLICY "Users can insert their own archived stories"
  ON story_archive FOR INSERT
  WITH CHECK (auth.uid()::TEXT = user_id);

CREATE POLICY "Users can update their own archived stories"
  ON story_archive FOR UPDATE
  USING (auth.uid()::TEXT = user_id);

CREATE POLICY "Users can delete their own archived stories"
  ON story_archive FOR DELETE
  USING (auth.uid()::TEXT = user_id);

-- User settings policies
CREATE POLICY "Users can view their own settings"
  ON user_settings FOR SELECT
  USING (auth.uid()::TEXT = user_id);

CREATE POLICY "Users can insert their own settings"
  ON user_settings FOR INSERT
  WITH CHECK (auth.uid()::TEXT = user_id);

CREATE POLICY "Users can update their own settings"
  ON user_settings FOR UPDATE
  USING (auth.uid()::TEXT = user_id);

-- ============================================================================
-- 9. TRIGGERS
-- ============================================================================

-- Trigger to auto-create user_settings for new users
CREATE OR REPLACE FUNCTION create_user_settings()
RETURNS TRIGGER AS $$
BEGIN
  INSERT INTO user_settings (user_id)
  VALUES (NEW.uid)
  ON CONFLICT (user_id) DO NOTHING;
  RETURN NEW;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Apply trigger to users table
CREATE TRIGGER on_user_created
  AFTER INSERT ON users
  FOR EACH ROW
  EXECUTE FUNCTION create_user_settings();

-- Trigger to update updated_at timestamp
CREATE OR REPLACE FUNCTION update_updated_at()
RETURNS TRIGGER AS $$
BEGIN
  NEW.updated_at = NOW();
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Apply to user_settings table
CREATE TRIGGER update_user_settings_updated_at
  BEFORE UPDATE ON user_settings
  FOR EACH ROW
  EXECUTE FUNCTION update_updated_at();

-- Trigger to auto-archive expired stories (optional)
-- You can also run archive_expired_stories() via cron
CREATE OR REPLACE FUNCTION trigger_archive_expired_stories()
RETURNS TRIGGER AS $$
BEGIN
  PERFORM archive_expired_stories();
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Create trigger (optional - can cause performance issues with high volume)
-- Uncomment if you want automatic archiving
-- CREATE TRIGGER auto_archive_expired_stories
--   AFTER INSERT OR UPDATE ON stories
--   EXECUTE FUNCTION trigger_archive_expired_stories();

-- ============================================================================
-- 10. SAMPLE QUERIES (FOR TESTING)
-- ============================================================================

-- Get all active stories with user info
-- SELECT
--   s.*,
--   u.username,
--   u.photo_url
-- FROM stories s
-- JOIN users u ON s.user_id = u.uid
-- WHERE s.expires_at > NOW()
--   AND s.is_archived = FALSE
-- ORDER BY s.created_at DESC;

-- Get stories grouped by user (for story bar)
-- SELECT
--   u.uid AS user_id,
--   u.username,
--   u.photo_url,
--   json_agg(
--     json_build_object(
--       'id', s.id,
--       'media_url', s.media_url,
--       'thumbnail_url', s.thumbnail_url,
--       'media_type', s.media_type,
--       'caption', s.caption,
--       'created_at', s.created_at,
--       'expires_at', s.expires_at,
--       'views_count', s.views_count
--     )
--     ORDER BY s.created_at ASC
--   ) AS segments
-- FROM users u
-- JOIN stories s ON u.uid = s.user_id
-- WHERE s.expires_at > NOW()
--   AND s.is_archived = FALSE
-- GROUP BY u.uid, u.username, u.photo_url
-- ORDER BY MAX(s.created_at) DESC;

-- Get story analytics
-- SELECT get_story_analytics('story-uuid-here');

-- Get viewers for a story
-- SELECT
--   sv.*,
--   u.username,
--   u.photo_url
-- FROM story_viewers sv
-- JOIN users u ON sv.viewer_id = u.uid
-- WHERE sv.story_id = 'story-uuid-here'
-- ORDER BY sv.viewed_at DESC;

-- ============================================================================
-- 11. MAINTENANCE QUERIES
-- ============================================================================

-- Manually archive expired stories
-- SELECT archive_expired_stories();

-- Delete all archived stories older than 30 days
-- DELETE FROM story_archive
-- WHERE archived_at < NOW() - INTERVAL '30 days';

-- Get storage size of stories
-- SELECT pg_size_pretty(pg_total_relation_size('stories'));

-- Get most viewed stories
-- SELECT
--   s.id,
--   s.caption,
--   s.views_count,
--   u.username
-- FROM stories s
-- JOIN users u ON s.user_id = u.uid
-- ORDER BY s.views_count DESC
-- LIMIT 10;

-- Get archive statistics for a user
-- SELECT
--   COUNT(*) as total_archives,
--   COUNT(*) FILTER (WHERE media_type = 'image') as image_count,
--   COUNT(*) FILTER (WHERE media_type = 'video') as video_count,
--   COUNT(*) FILTER (WHERE restored = TRUE) as restored_count
-- FROM story_archive
-- WHERE user_id = 'user-uid-here';

-- Get user settings
-- SELECT * FROM user_settings WHERE user_id = 'user-uid-here';

-- ============================================================================
-- SETUP COMPLETE!
-- ============================================================================
-- 
-- Next steps:
-- 1. Run this entire file in Supabase SQL Editor
-- 2. Verify tables created: SELECT * FROM stories, story_archive, user_settings;
-- 3. Update Supabase storage bucket 'stories' to allow video/image uploads
-- 4. Test with Flutter app
-- 5. Set up cron job to run archive_expired_stories() daily (optional)
--
-- Archive Features:
-- - Automatically saves expired stories with viewers/reactions data
-- - User settings control auto-archive behavior
-- - Restore functionality brings stories back with new 24h expiration
-- - Private archive - only user can see their own archived stories
--
-- ============================================================================
