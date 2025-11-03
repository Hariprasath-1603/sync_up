-- Add Video Support Columns to Posts Table
-- Run this in Supabase SQL Editor

-- 1. Add video_url column
ALTER TABLE posts 
ADD COLUMN IF NOT EXISTS video_url TEXT;

-- 2. Add thumbnail_url column
ALTER TABLE posts 
ADD COLUMN IF NOT EXISTS thumbnail_url TEXT;

-- 3. Add duration column (in seconds)
ALTER TABLE posts 
ADD COLUMN IF NOT EXISTS duration INTEGER;

-- 4. Add media_type column (if not exists)
ALTER TABLE posts 
ADD COLUMN IF NOT EXISTS media_type TEXT DEFAULT 'image';

-- 5. Create index for video posts
CREATE INDEX IF NOT EXISTS idx_posts_media_type ON posts(media_type);

-- 6. Create index for video_url for faster queries
CREATE INDEX IF NOT EXISTS idx_posts_video_url ON posts(video_url) WHERE video_url IS NOT NULL;

-- 7. Add comment for documentation
COMMENT ON COLUMN posts.video_url IS 'URL of the video file in Supabase Storage';
COMMENT ON COLUMN posts.thumbnail_url IS 'URL of the video thumbnail image';
COMMENT ON COLUMN posts.duration IS 'Video duration in seconds';
COMMENT ON COLUMN posts.media_type IS 'Type of media: image, video, or carousel';

-- 8. Verify the changes
SELECT 
  column_name, 
  data_type, 
  is_nullable, 
  column_default
FROM information_schema.columns 
WHERE table_name = 'posts' 
AND column_name IN ('video_url', 'thumbnail_url', 'duration', 'media_type')
ORDER BY column_name;

-- 9. Update existing posts to have media_type = 'image' if NULL
UPDATE posts 
SET media_type = 'image' 
WHERE media_type IS NULL;

-- 10. Check the updated schema
SELECT 
  id,
  user_id,
  media_type,
  video_url,
  thumbnail_url,
  duration,
  created_at
FROM posts
ORDER BY created_at DESC
LIMIT 5;
