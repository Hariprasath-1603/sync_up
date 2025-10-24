-- =====================================================
-- SUPABASE STORAGE POLICIES FOR FIREBASE AUTH USERS
-- =====================================================
-- Run these in: Supabase Dashboard → SQL Editor → New Query
-- https://cgkexriarshbftnjftlm.supabase.co

-- Since you're using Firebase Auth (not Supabase Auth),
-- we need to make storage buckets publicly accessible
-- or disable RLS on the storage buckets

-- =====================================================
-- OPTION 1: Public Access (RECOMMENDED FOR TESTING)
-- =====================================================

-- 1. Allow public uploads to profile-photos bucket
CREATE POLICY "Allow public uploads to profile photos"
ON storage.objects FOR INSERT
TO public
WITH CHECK (bucket_id = 'profile-photos');

-- 2. Allow public reads from profile-photos bucket
CREATE POLICY "Allow public reads from profile photos"
ON storage.objects FOR SELECT
TO public
USING (bucket_id = 'profile-photos');

-- 3. Allow public updates to profile-photos bucket
CREATE POLICY "Allow public updates to profile photos"
ON storage.objects FOR UPDATE
TO public
USING (bucket_id = 'profile-photos');

-- 4. Allow public deletes from profile-photos bucket
CREATE POLICY "Allow public deletes from profile photos"
ON storage.objects FOR DELETE
TO public
USING (bucket_id = 'profile-photos');

-- Repeat for posts bucket
CREATE POLICY "Allow public uploads to posts"
ON storage.objects FOR INSERT
TO public
WITH CHECK (bucket_id = 'posts');

CREATE POLICY "Allow public reads from posts"
ON storage.objects FOR SELECT
TO public
USING (bucket_id = 'posts');

CREATE POLICY "Allow public updates to posts"
ON storage.objects FOR UPDATE
TO public
USING (bucket_id = 'posts');

CREATE POLICY "Allow public deletes from posts"
ON storage.objects FOR DELETE
TO public
USING (bucket_id = 'posts');

-- Repeat for stories bucket
CREATE POLICY "Allow public uploads to stories"
ON storage.objects FOR INSERT
TO public
WITH CHECK (bucket_id = 'stories');

CREATE POLICY "Allow public reads from stories"
ON storage.objects FOR SELECT
TO public
USING (bucket_id = 'stories');

CREATE POLICY "Allow public updates to stories"
ON storage.objects FOR UPDATE
TO public
USING (bucket_id = 'stories');

CREATE POLICY "Allow public deletes from stories"
ON storage.objects FOR DELETE
TO public
USING (bucket_id = 'stories');

-- =====================================================
-- VERIFY POLICIES
-- =====================================================
-- Run this to check if policies are created:
SELECT * FROM pg_policies WHERE schemaname = 'storage';

-- =====================================================
-- DONE! Now try uploading a profile photo again
-- =====================================================

-- =====================================================
-- ADD PHONE VERIFICATION COLUMN
-- =====================================================
-- Run this to add phone_verified column to users table:
ALTER TABLE users ADD COLUMN IF NOT EXISTS phone_verified BOOLEAN DEFAULT false;
