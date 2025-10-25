-- Add email and phone verification status columns to users table
-- Run this migration in your Supabase SQL Editor
-- URL: https://supabase.com/dashboard/project/cgkexriarshbftnjftlm/editor

-- Add is_email_verified column (defaults to false for existing users)
ALTER TABLE users 
ADD COLUMN IF NOT EXISTS is_email_verified BOOLEAN DEFAULT false;

-- Add is_phone_verified column (defaults to false for existing users)
ALTER TABLE users 
ADD COLUMN IF NOT EXISTS is_phone_verified BOOLEAN DEFAULT false;

-- Add index for faster queries on verification status
CREATE INDEX IF NOT EXISTS idx_users_email_verified ON users(is_email_verified);
CREATE INDEX IF NOT EXISTS idx_users_phone_verified ON users(is_phone_verified);

-- Optional: Update existing users to set verification status based on whether they have email/phone
-- Uncomment the following if you want to mark existing users as verified
-- UPDATE users 
-- SET is_email_verified = true 
-- WHERE email IS NOT NULL AND email != '';

-- UPDATE users 
-- SET is_phone_verified = true 
-- WHERE phone IS NOT NULL AND phone != '';

-- Display current status
SELECT 
  COUNT(*) as total_users,
  SUM(CASE WHEN is_email_verified = true THEN 1 ELSE 0 END) as email_verified_count,
  SUM(CASE WHEN is_phone_verified = true THEN 1 ELSE 0 END) as phone_verified_count
FROM users;
