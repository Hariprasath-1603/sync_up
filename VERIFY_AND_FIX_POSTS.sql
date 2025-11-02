-- =====================================================
-- Verify and Fix Posts Table
-- Run this in Supabase SQL Editor
-- =====================================================

-- 1. Check if comments_count column exists
SELECT column_name, data_type, column_default
FROM information_schema.columns
WHERE table_name = 'posts' 
  AND table_schema = 'public'
ORDER BY ordinal_position;

-- 2. If comments_count doesn't exist, add it (safe to run multiple times)
ALTER TABLE posts ADD COLUMN IF NOT EXISTS comments_count INTEGER DEFAULT 0;
ALTER TABLE posts ADD COLUMN IF NOT EXISTS comments_enabled BOOLEAN DEFAULT true;

-- 3. Update existing posts to have comments_count = 0 if NULL
UPDATE posts SET comments_count = 0 WHERE comments_count IS NULL;
UPDATE posts SET comments_enabled = true WHERE comments_enabled IS NULL;

-- 4. Verify the posts table structure
SELECT 
  column_name,
  data_type,
  is_nullable,
  column_default
FROM information_schema.columns
WHERE table_name = 'posts'
  AND table_schema = 'public'
ORDER BY ordinal_position;

-- 5. Test insert (replace with actual user_id)
-- Uncomment and run after verifying structure:
-- INSERT INTO posts (
--   user_id, 
--   caption, 
--   media_urls, 
--   likes_count, 
--   comments_count, 
--   shares_count, 
--   views_count,
--   comments_enabled
-- ) VALUES (
--   'your-user-id-here',
--   'Test post',
--   ARRAY['https://example.com/image.jpg'],
--   0,
--   0,
--   0,
--   0,
--   true
-- ) RETURNING *;

-- 6. Force PostgREST schema cache reload
NOTIFY pgrst, 'reload schema';

-- Success message
DO $$
BEGIN
  RAISE NOTICE '✅ Posts table verified and fixed!';
  RAISE NOTICE '📊 Check the column list above to verify comments_count exists';
  RAISE NOTICE '🔄 Schema cache reload notification sent';
END $$;
