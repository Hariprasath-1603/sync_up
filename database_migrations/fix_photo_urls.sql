-- ========================================
-- COMPLETE DATABASE CLEANUP FOR TESTING
-- ========================================
-- WARNING: This will delete ALL user content!
-- Run this in Supabase SQL Editor

-- 1. DELETE ALL REELS
DELETE FROM reels;

-- 2. DELETE ALL POSTS
DELETE FROM posts;

-- 3. DELETE ALL STORIES (if table exists)
DELETE FROM stories WHERE true;

-- 4. DELETE ALL COMMENTS (if table exists)
DELETE FROM comments WHERE true;

-- 5. DELETE ALL FOLLOWS/FOLLOWERS
DELETE FROM followers;

-- 6. RESET USER PROFILE PHOTOS AND COVER PHOTOS
UPDATE users
SET 
  photo_url = NULL,
  cover_photo_url = NULL,
  bio = NULL,
  posts_count = 0,
  followers_count = 0,
  following_count = 0;

-- 8. KEEP USERS BUT RESET THEIR CONTENT COUNTS
-- (This preserves authentication but removes all content)

-- ========================================
-- VERIFICATION QUERIES
-- ========================================

-- Check remaining data
SELECT 'Reels' as table_name, COUNT(*) as count FROM reels
UNION ALL
SELECT 'Posts', COUNT(*) FROM posts
UNION ALL
SELECT 'Followers', COUNT(*) FROM followers;

-- Verify users still exist but have no content
SELECT 
  uid,
  username,
  email,
  photo_url,
  cover_photo_url,
  followers_count,
  following_count
FROM users
ORDER BY created_at DESC
LIMIT 10;

-- ========================================
-- OPTIONAL: DELETE ALL USERS TOO
-- ========================================
-- Uncomment below if you want to delete users as well
-- WARNING: This will break authentication!

-- DELETE FROM users;
-- VACUUM users;
