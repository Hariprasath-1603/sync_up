-- Add cover_photo_url column to users table
-- Run this in your Supabase SQL Editor

ALTER TABLE users 
ADD COLUMN IF NOT EXISTS cover_photo_url TEXT;

-- Add comment for documentation
COMMENT ON COLUMN users.cover_photo_url IS 'URL of the user cover/banner photo';

-- Update existing users to have null cover photo (default)
UPDATE users 
SET cover_photo_url = NULL
WHERE cover_photo_url IS NULL;

-- Success message
DO $$
BEGIN
  RAISE NOTICE '========================================';
  RAISE NOTICE '✅ Cover Photo Column Added Successfully!';
  RAISE NOTICE '========================================';
  RAISE NOTICE '📸 Users can now upload cover photos';
  RAISE NOTICE '🎯 Column: cover_photo_url (TEXT, nullable)';
  RAISE NOTICE '========================================';
END $$;
