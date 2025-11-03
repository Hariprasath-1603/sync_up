-- Fix Posts Table and Add Missing Columns
-- Run this in Supabase SQL Editor

-- 1. Add archived column if it doesn't exist
ALTER TABLE posts ADD COLUMN IF NOT EXISTS archived BOOLEAN DEFAULT FALSE;

-- 2. Add comments_enabled column if it doesn't exist
ALTER TABLE posts ADD COLUMN IF NOT EXISTS comments_enabled BOOLEAN DEFAULT TRUE;

-- 3. Add hide_like_count column if it doesn't exist  
ALTER TABLE posts ADD COLUMN IF NOT EXISTS hide_like_count BOOLEAN DEFAULT FALSE;

-- 4. Add is_pinned column if it doesn't exist
ALTER TABLE posts ADD COLUMN IF NOT EXISTS is_pinned BOOLEAN DEFAULT FALSE;

-- 5. Add updated_at column if it doesn't exist
ALTER TABLE posts ADD COLUMN IF NOT EXISTS updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW();

-- 6. Create index for archived posts
CREATE INDEX IF NOT EXISTS idx_posts_archived ON posts(archived);

-- 7. Create index for user_id and archived (for faster queries)
CREATE INDEX IF NOT EXISTS idx_posts_user_archived ON posts(user_id, archived);

-- 8. Update RLS policies to exclude archived posts from public feeds
DROP POLICY IF EXISTS "Posts are viewable by everyone" ON posts;
CREATE POLICY "Posts are viewable by everyone" ON posts
  FOR SELECT USING (
    archived = FALSE OR auth.uid()::text = user_id
  );

-- 9. List all posts to identify hardcoded/test posts
SELECT 
  id,
  user_id,
  caption,
  media_urls,
  created_at,
  (SELECT username FROM users WHERE uid = posts.user_id) as username
FROM posts
ORDER BY created_at DESC;

-- 10. OPTIONAL: Delete posts with picsum.photos URLs (test/hardcoded posts)
-- UNCOMMENT THE LINES BELOW TO RUN THIS DELETION
-- DELETE FROM posts 
-- WHERE media_urls::text LIKE '%picsum.photos%';

-- 11. Verify the changes
SELECT 
  column_name, 
  data_type, 
  is_nullable, 
  column_default
FROM information_schema.columns 
WHERE table_name = 'posts' 
AND column_name IN ('archived', 'comments_enabled', 'hide_like_count', 'is_pinned', 'updated_at')
ORDER BY column_name;

-- 12. Count posts by user
SELECT 
  u.username,
  u.uid as user_id,
  COUNT(p.id) as post_count
FROM users u
LEFT JOIN posts p ON u.uid = p.user_id
GROUP BY u.uid, u.username
ORDER BY post_count DESC;
