-- Add Video Support to Posts Table
-- Run this in Supabase SQL Editor

-- 1. Add media_type column if it doesn't exist
ALTER TABLE posts ADD COLUMN IF NOT EXISTS media_type TEXT DEFAULT 'image' CHECK (media_type IN ('image', 'video', 'carousel'));

-- 2. Add video_url column if it doesn't exist  
ALTER TABLE posts ADD COLUMN IF NOT EXISTS video_url TEXT;

-- 3. Add thumbnail_url column if it doesn't exist
ALTER TABLE posts ADD COLUMN IF NOT EXISTS thumbnail_url TEXT;

-- 4. Add duration column for videos (in seconds)
ALTER TABLE posts ADD COLUMN IF NOT EXISTS duration INTEGER DEFAULT 0;

-- 5. Add metadata column for additional video info
ALTER TABLE posts ADD COLUMN IF NOT EXISTS metadata JSONB DEFAULT '{}'::jsonb;

-- 6. Create index for media_type
CREATE INDEX IF NOT EXISTS idx_posts_media_type ON posts(media_type);

-- 7. Create index for user_id and media_type (for faster queries)
CREATE INDEX IF NOT EXISTS idx_posts_user_media_type ON posts(user_id, media_type);

-- 8. Update posts to set media_type based on existing data
-- (Run this only if you have existing posts)
UPDATE posts 
SET media_type = 'image' 
WHERE media_type IS NULL AND media_urls IS NOT NULL;

-- 9. Verify the changes
SELECT 
  column_name, 
  data_type, 
  is_nullable, 
  column_default
FROM information_schema.columns 
WHERE table_name = 'posts' 
AND column_name IN ('media_type', 'video_url', 'thumbnail_url', 'duration', 'metadata')
ORDER BY column_name;

-- 10. Count posts by media type
SELECT 
  media_type,
  COUNT(*) as post_count
FROM posts
GROUP BY media_type
ORDER BY post_count DESC;
