-- ========================================
-- Phone Verification Setup for Supabase
-- ========================================
-- This SQL sets up everything needed for phone verification with OTP

-- 1. Add phone_verified column to users table
ALTER TABLE users 
ADD COLUMN IF NOT EXISTS phone_verified BOOLEAN DEFAULT false;

-- 2. Create phone_otps table to store temporary OTP codes
CREATE TABLE IF NOT EXISTS phone_otps (
  phone TEXT PRIMARY KEY,
  otp TEXT NOT NULL,
  expires_at TIMESTAMP NOT NULL,
  created_at TIMESTAMP DEFAULT NOW()
);

-- 3. Add index for faster OTP lookups and cleanup
CREATE INDEX IF NOT EXISTS idx_phone_otps_expires_at 
ON phone_otps(expires_at);

-- 4. Enable Row Level Security on phone_otps
ALTER TABLE phone_otps ENABLE ROW LEVEL SECURITY;

-- 5. Create policy to allow service role to manage OTPs
-- (Edge Functions use service role to read/write OTPs)
CREATE POLICY "Service role can manage OTPs"
ON phone_otps
FOR ALL
TO service_role
USING (true)
WITH CHECK (true);

-- 6. Optional: Create function to clean up expired OTPs
CREATE OR REPLACE FUNCTION cleanup_expired_otps()
RETURNS void AS $$
BEGIN
  DELETE FROM phone_otps WHERE expires_at < NOW();
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- 7. Optional: Schedule automatic cleanup (runs every hour)
-- You can enable this in Supabase Dashboard -> Database -> Cron Jobs
-- Or run manually: SELECT cron.schedule('cleanup-otps', '0 * * * *', 'SELECT cleanup_expired_otps();');

-- ========================================
-- VERIFICATION QUERIES
-- ========================================

-- Check if tables exist
SELECT table_name 
FROM information_schema.tables 
WHERE table_schema = 'public' 
AND table_name IN ('users', 'phone_otps');

-- Check if phone_verified column exists
SELECT column_name, data_type, column_default
FROM information_schema.columns 
WHERE table_name = 'users' 
AND column_name = 'phone_verified';

-- View phone_otps structure
SELECT column_name, data_type, is_nullable
FROM information_schema.columns 
WHERE table_name = 'phone_otps'
ORDER BY ordinal_position;

-- Check RLS policies
SELECT schemaname, tablename, policyname, permissive, roles, cmd, qual
FROM pg_policies 
WHERE tablename = 'phone_otps';

-- ========================================
-- TESTING QUERIES (for development)
-- ========================================

-- View all OTPs (for debugging)
-- SELECT * FROM phone_otps;

-- Manually insert test OTP (for testing)
-- INSERT INTO phone_otps (phone, otp, expires_at) 
-- VALUES ('+1234567890', '123456', NOW() + INTERVAL '10 minutes')
-- ON CONFLICT (phone) 
-- DO UPDATE SET otp = EXCLUDED.otp, expires_at = EXCLUDED.expires_at;

-- Delete expired OTPs manually
-- DELETE FROM phone_otps WHERE expires_at < NOW();

-- View users with phone verification status
-- SELECT id, email, phone_number, phone_verified, created_at 
-- FROM users 
-- ORDER BY created_at DESC;
