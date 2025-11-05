-- =====================================================
-- REEL STORAGE BUCKET PERMISSIONS FIX
-- =====================================================
-- This script creates the reels storage bucket and sets up
-- proper RLS policies to allow public read access
-- =====================================================

-- Step 1: Create the reels bucket if it doesn't exist
-- (Set public to true for easy access)
INSERT INTO storage.buckets (id, name, public, file_size_limit, allowed_mime_types)
VALUES (
  'reels',
  'reels',
  true,  -- Make bucket public
  524288000,  -- 500MB max file size
  ARRAY['video/mp4', 'video/quicktime', 'video/x-msvideo']
)
ON CONFLICT (id) 
DO UPDATE SET 
  public = true,
  file_size_limit = 524288000,
  allowed_mime_types = ARRAY['video/mp4', 'video/quicktime', 'video/x-msvideo'];

-- Step 2: Drop existing policies if any
DROP POLICY IF EXISTS "Allow public read access to reels" ON storage.objects;
DROP POLICY IF EXISTS "Allow authenticated users to upload reels" ON storage.objects;
DROP POLICY IF EXISTS "Allow users to update their own reels" ON storage.objects;
DROP POLICY IF EXISTS "Allow users to delete their own reels" ON storage.objects;

-- Step 3: Create policy for public READ access
CREATE POLICY "Allow public read access to reels"
ON storage.objects FOR SELECT
USING (bucket_id = 'reels');

-- Step 4: Create policy for authenticated users to UPLOAD
CREATE POLICY "Allow authenticated users to upload reels"
ON storage.objects FOR INSERT
WITH CHECK (
  bucket_id = 'reels' 
  AND auth.role() = 'authenticated'
  AND (storage.foldername(name))[1] = auth.uid()::TEXT
);

-- Step 5: Create policy for users to UPDATE their own reels
CREATE POLICY "Allow users to update their own reels"
ON storage.objects FOR UPDATE
USING (
  bucket_id = 'reels' 
  AND (storage.foldername(name))[1] = auth.uid()::TEXT
)
WITH CHECK (
  bucket_id = 'reels' 
  AND (storage.foldername(name))[1] = auth.uid()::TEXT
);

-- Step 6: Create policy for users to DELETE their own reels
CREATE POLICY "Allow users to delete their own reels"
ON storage.objects FOR DELETE
USING (
  bucket_id = 'reels' 
  AND (storage.foldername(name))[1] = auth.uid()::TEXT
);

-- =====================================================
-- VERIFICATION QUERIES
-- =====================================================

-- Check if bucket exists and is public
SELECT id, name, public, file_size_limit, allowed_mime_types
FROM storage.buckets
WHERE id = 'reels';

-- Check storage policies
SELECT policyname, cmd, qual, with_check
FROM pg_policies
WHERE schemaname = 'storage'
AND tablename = 'objects'
AND policyname LIKE '%reels%';

-- List all objects in reels bucket
SELECT name, bucket_id, owner, created_at
FROM storage.objects
WHERE bucket_id = 'reels'
ORDER BY created_at DESC
LIMIT 10;

-- =====================================================
-- TEST VIDEO URL
-- =====================================================
-- Your video URLs should look like:
-- https://YOUR_PROJECT.supabase.co/storage/v1/object/public/reels/USER_ID/reel_TIMESTAMP.mp4
--
-- If you get 403 Forbidden, the bucket isn't public
-- If you get 404 Not Found, the file doesn't exist
-- If you get 200 OK, the video should play
-- =====================================================
