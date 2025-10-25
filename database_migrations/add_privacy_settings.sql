-- Add privacy and messaging settings columns to users table
-- Run this in your Supabase SQL Editor

-- Add is_private column (already exists from previous migration, but included for completeness)
ALTER TABLE users 
ADD COLUMN IF NOT EXISTS is_private BOOLEAN DEFAULT false;

-- Add show_activity_status column
ALTER TABLE users 
ADD COLUMN IF NOT EXISTS show_activity_status BOOLEAN DEFAULT true;

-- Add allow_messages_from_everyone column
ALTER TABLE users 
ADD COLUMN IF NOT EXISTS allow_messages_from_everyone BOOLEAN DEFAULT false;

-- Add comment for documentation
COMMENT ON COLUMN users.is_private IS 'Whether the user account is private (only approved followers can see posts)';
COMMENT ON COLUMN users.show_activity_status IS 'Whether to show when the user is online/active';
COMMENT ON COLUMN users.allow_messages_from_everyone IS 'Whether to allow messages from users they dont follow';

-- Update existing users to have default values if NULL
UPDATE users 
SET 
  is_private = COALESCE(is_private, false),
  show_activity_status = COALESCE(show_activity_status, true),
  allow_messages_from_everyone = COALESCE(allow_messages_from_everyone, false)
WHERE 
  is_private IS NULL 
  OR show_activity_status IS NULL 
  OR allow_messages_from_everyone IS NULL;
