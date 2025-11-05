-- 🔧 REEL DATABASE FIX - Foreign Key Missing
-- Run this in Supabase SQL Editor

-- Step 1: Check if reels table exists
SELECT table_name 
FROM information_schema.tables 
WHERE table_schema = 'public' 
AND table_name = 'reels';

-- Step 2: Check current foreign keys
SELECT
    tc.constraint_name, 
    tc.table_name, 
    kcu.column_name, 
    ccu.table_name AS foreign_table_name,
    ccu.column_name AS foreign_column_name 
FROM information_schema.table_constraints AS tc 
JOIN information_schema.key_column_usage AS kcu
  ON tc.constraint_name = kcu.constraint_name
JOIN information_schema.constraint_column_usage AS ccu
  ON ccu.constraint_name = tc.constraint_name
WHERE tc.table_name = 'reels' 
AND tc.constraint_type = 'FOREIGN KEY';

-- Step 3: Check data types - THIS IS THE PROBLEM!
SELECT 
    table_name,
    column_name,
    data_type
FROM information_schema.columns
WHERE table_name IN ('reels', 'users')
AND column_name IN ('user_id', 'uid')
ORDER BY table_name, column_name;

-- Step 4: Drop all RLS policies on reels table (temporarily)
DROP POLICY IF EXISTS "Reels are viewable by everyone" ON reels;
DROP POLICY IF EXISTS "Users can insert their own reels" ON reels;
DROP POLICY IF EXISTS "Users can update their own reels" ON reels;
DROP POLICY IF EXISTS "Users can delete their own reels" ON reels;

-- Step 5: Drop existing foreign keys
ALTER TABLE reels DROP CONSTRAINT IF EXISTS reels_user_id_fkey CASCADE;
ALTER TABLE reels DROP CONSTRAINT IF EXISTS fk_reels_user CASCADE;
ALTER TABLE reels DROP CONSTRAINT IF EXISTS reels_user_fkey CASCADE;

-- Step 6: Fix the data type mismatch
-- Change reels.user_id from UUID to TEXT (to match users.uid)
ALTER TABLE reels ALTER COLUMN user_id TYPE TEXT USING user_id::TEXT;

-- Step 7: Add the correct foreign key constraint (NOW TYPES MATCH!)
ALTER TABLE reels 
ADD CONSTRAINT reels_user_id_fkey 
FOREIGN KEY (user_id) 
REFERENCES users(uid) 
ON DELETE CASCADE;

-- Step 8: Recreate RLS policies with correct types
CREATE POLICY "Reels are viewable by everyone"
ON reels FOR SELECT
USING (true);

CREATE POLICY "Users can insert their own reels"
ON reels FOR INSERT
WITH CHECK (auth.uid()::TEXT = user_id);

CREATE POLICY "Users can update their own reels"
ON reels FOR UPDATE
USING (auth.uid()::TEXT = user_id);

CREATE POLICY "Users can delete their own reels"
ON reels FOR DELETE
USING (auth.uid()::TEXT = user_id);

-- Step 7: Verify the foreign key was created
SELECT
    tc.constraint_name, 
    tc.table_name, 
    kcu.column_name, 
    ccu.table_name AS foreign_table_name,
    ccu.column_name AS foreign_column_name 
FROM information_schema.table_constraints AS tc 
JOIN information_schema.key_column_usage AS kcu
  ON tc.constraint_name = kcu.constraint_name
JOIN information_schema.constraint_column_usage AS ccu
  ON ccu.constraint_name = tc.constraint_name
WHERE tc.table_name = 'reels' 
AND tc.constraint_type = 'FOREIGN KEY';

-- Step 8: Verify data types match now
SELECT 
    table_name,
    column_name,
    data_type
FROM information_schema.columns
WHERE table_name IN ('reels', 'users')
AND column_name IN ('user_id', 'uid')
ORDER BY table_name, column_name;

-- Step 9: Check if there are any reels in the table
SELECT COUNT(*) as total_reels FROM reels;

-- Step 10: Verify RLS policies recreated
SELECT schemaname, tablename, policyname, cmd 
FROM pg_policies 
WHERE tablename = 'reels';

-- Step 11: Show recent reels with user info (should work now!)
SELECT 
    r.id,
    r.user_id,
    r.caption,
    r.video_url,
    r.thumbnail_url,
    r.created_at,
    u.username,
    u.full_name
FROM reels r
LEFT JOIN users u ON r.user_id = u.uid
ORDER BY r.created_at DESC
LIMIT 5;

-- ✅ SUCCESS! If Step 11 shows reels with usernames, you're done!
-- Now hot restart your Flutter app and reels will appear!
