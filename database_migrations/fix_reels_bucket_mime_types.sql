-- ========================================
-- FIX REELS BUCKET MIME TYPE CONFIGURATION
-- ========================================
-- This fixes the "mime type video/mp4 is not supported" error

-- Step 1: Check current bucket configuration
SELECT 
  id,
  name,
  public,
  file_size_limit,
  allowed_mime_types
FROM storage.buckets
WHERE name = 'reels';

-- Step 2: Update the reels bucket to allow video files
-- NOTE: This requires direct database access or Supabase Dashboard
-- You can also use the Dashboard: Storage > reels bucket > Settings

UPDATE storage.buckets
SET 
  allowed_mime_types = ARRAY[
    'video/mp4',
    'video/quicktime',
    'video/x-msvideo',
    'video/x-matroska',
    'video/webm',
    'video/mpeg',
    'image/jpeg',
    'image/jpg',
    'image/png'
  ]::text[],
  file_size_limit = 104857600  -- 100 MB in bytes
WHERE name = 'reels';

-- Step 3: Verify the changes
SELECT 
  id,
  name,
  public,
  file_size_limit,
  allowed_mime_types
FROM storage.buckets
WHERE name = 'reels';

-- ========================================
-- ALTERNATIVE: If bucket doesn't exist, create it
-- ========================================
-- Run this only if the bucket needs to be created from scratch

INSERT INTO storage.buckets (id, name, public, file_size_limit, allowed_mime_types)
VALUES (
  'reels',
  'reels',
  true,
  104857600,  -- 100 MB
  ARRAY[
    'video/mp4',
    'video/quicktime',
    'video/x-msvideo',
    'video/x-matroska',
    'video/webm',
    'video/mpeg',
    'image/jpeg',
    'image/jpg',
    'image/png'
  ]::text[]
)
ON CONFLICT (id) DO UPDATE
SET 
  allowed_mime_types = EXCLUDED.allowed_mime_types,
  file_size_limit = EXCLUDED.file_size_limit;

-- ========================================
-- VERIFICATION
-- ========================================

-- Check all storage buckets and their MIME type configurations
SELECT 
  name,
  public,
  ROUND(file_size_limit / 1048576.0, 2) as size_limit_mb,
  allowed_mime_types
FROM storage.buckets
ORDER BY name;
