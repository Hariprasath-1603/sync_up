-- =====================================================
-- REELS TABLE MIGRATION
-- =====================================================
-- This migration creates the reels table for storing user-uploaded reels
-- with video URLs, thumbnails, captions, and engagement metrics.
-- 
-- Run this in Supabase SQL Editor
-- =====================================================

-- Enable UUID extension if not already enabled
CREATE EXTENSION IF NOT EXISTS "uuid-ossp";

-- Drop existing table if it exists (for clean migration)
DROP TABLE IF EXISTS public.reels CASCADE;

-- Create reels table
CREATE TABLE public.reels (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    user_id UUID NOT NULL REFERENCES public.users(uid) ON DELETE CASCADE,
    video_url TEXT NOT NULL,
    thumbnail_url TEXT,
    caption TEXT,
    likes_count INTEGER DEFAULT 0 NOT NULL,
    comments_count INTEGER DEFAULT 0 NOT NULL,
    views_count INTEGER DEFAULT 0 NOT NULL,
    shares_count INTEGER DEFAULT 0 NOT NULL,
    duration INTEGER, -- Video duration in seconds
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW() NOT NULL,
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW() NOT NULL
);

-- Add indexes for performance
CREATE INDEX idx_reels_user_id ON public.reels(user_id);
CREATE INDEX idx_reels_created_at ON public.reels(created_at DESC);
CREATE INDEX idx_reels_likes_count ON public.reels(likes_count DESC);
CREATE INDEX idx_reels_views_count ON public.reels(views_count DESC);

-- Add comments for documentation
COMMENT ON TABLE public.reels IS 'Stores user-uploaded reels with video content and engagement metrics';
COMMENT ON COLUMN public.reels.id IS 'Unique identifier for the reel';
COMMENT ON COLUMN public.reels.user_id IS 'Foreign key to users table (creator of the reel)';
COMMENT ON COLUMN public.reels.video_url IS 'URL of the uploaded video in Supabase Storage';
COMMENT ON COLUMN public.reels.thumbnail_url IS 'URL of the video thumbnail in Supabase Storage';
COMMENT ON COLUMN public.reels.caption IS 'Caption/description of the reel';
COMMENT ON COLUMN public.reels.likes_count IS 'Number of likes on the reel';
COMMENT ON COLUMN public.reels.comments_count IS 'Number of comments on the reel';
COMMENT ON COLUMN public.reels.views_count IS 'Number of views on the reel';
COMMENT ON COLUMN public.reels.shares_count IS 'Number of shares on the reel';
COMMENT ON COLUMN public.reels.duration IS 'Video duration in seconds';
COMMENT ON COLUMN public.reels.created_at IS 'Timestamp when the reel was created';
COMMENT ON COLUMN public.reels.updated_at IS 'Timestamp when the reel was last updated';

-- =====================================================
-- ROW LEVEL SECURITY (RLS) POLICIES
-- =====================================================

-- Enable RLS
ALTER TABLE public.reels ENABLE ROW LEVEL SECURITY;

-- Policy: Anyone can view reels (public content)
CREATE POLICY "Anyone can view reels"
ON public.reels
FOR SELECT
USING (true);

-- Policy: Users can insert their own reels
CREATE POLICY "Users can insert their own reels"
ON public.reels
FOR INSERT
WITH CHECK (auth.uid() = user_id);

-- Policy: Users can update their own reels
CREATE POLICY "Users can update their own reels"
ON public.reels
FOR UPDATE
USING (auth.uid() = user_id)
WITH CHECK (auth.uid() = user_id);

-- Policy: Users can delete their own reels
CREATE POLICY "Users can delete their own reels"
ON public.reels
FOR DELETE
USING (auth.uid() = user_id);

-- =====================================================
-- FUNCTIONS & TRIGGERS
-- =====================================================

-- Function to update updated_at timestamp
CREATE OR REPLACE FUNCTION public.update_reels_updated_at()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = NOW();
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Trigger to auto-update updated_at
CREATE TRIGGER reels_updated_at_trigger
BEFORE UPDATE ON public.reels
FOR EACH ROW
EXECUTE FUNCTION public.update_reels_updated_at();

-- =====================================================
-- REEL LIKES TABLE (for tracking who liked what)
-- =====================================================

DROP TABLE IF EXISTS public.reel_likes CASCADE;

CREATE TABLE public.reel_likes (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    reel_id UUID NOT NULL REFERENCES public.reels(id) ON DELETE CASCADE,
    user_id UUID NOT NULL REFERENCES public.users(uid) ON DELETE CASCADE,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW() NOT NULL,
    UNIQUE(reel_id, user_id)
);

-- Add indexes
CREATE INDEX idx_reel_likes_reel_id ON public.reel_likes(reel_id);
CREATE INDEX idx_reel_likes_user_id ON public.reel_likes(user_id);

-- Enable RLS
ALTER TABLE public.reel_likes ENABLE ROW LEVEL SECURITY;

-- Policies for reel_likes
CREATE POLICY "Anyone can view reel likes"
ON public.reel_likes
FOR SELECT
USING (true);

CREATE POLICY "Users can like reels"
ON public.reel_likes
FOR INSERT
WITH CHECK (auth.uid() = user_id);

CREATE POLICY "Users can unlike their own likes"
ON public.reel_likes
FOR DELETE
USING (auth.uid() = user_id);

-- =====================================================
-- REEL VIEWS TABLE (for tracking views)
-- =====================================================

DROP TABLE IF EXISTS public.reel_views CASCADE;

CREATE TABLE public.reel_views (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    reel_id UUID NOT NULL REFERENCES public.reels(id) ON DELETE CASCADE,
    user_id UUID REFERENCES public.users(uid) ON DELETE CASCADE, -- Nullable for anonymous views
    viewed_at TIMESTAMP WITH TIME ZONE DEFAULT NOW() NOT NULL,
    UNIQUE(reel_id, user_id)
);

-- Add indexes
CREATE INDEX idx_reel_views_reel_id ON public.reel_views(reel_id);
CREATE INDEX idx_reel_views_user_id ON public.reel_views(user_id);

-- Enable RLS
ALTER TABLE public.reel_views ENABLE ROW LEVEL SECURITY;

-- Policies for reel_views
CREATE POLICY "Anyone can view reel views"
ON public.reel_views
FOR SELECT
USING (true);

CREATE POLICY "Anyone can record views"
ON public.reel_views
FOR INSERT
WITH CHECK (true);

-- =====================================================
-- FUNCTIONS TO UPDATE COUNTERS
-- =====================================================

-- Function to increment likes count when a like is added
CREATE OR REPLACE FUNCTION public.increment_reel_likes_count()
RETURNS TRIGGER AS $$
BEGIN
    UPDATE public.reels
    SET likes_count = likes_count + 1
    WHERE id = NEW.reel_id;
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Trigger for like count increment
CREATE TRIGGER reel_likes_increment_trigger
AFTER INSERT ON public.reel_likes
FOR EACH ROW
EXECUTE FUNCTION public.increment_reel_likes_count();

-- Function to decrement likes count when a like is removed
CREATE OR REPLACE FUNCTION public.decrement_reel_likes_count()
RETURNS TRIGGER AS $$
BEGIN
    UPDATE public.reels
    SET likes_count = GREATEST(0, likes_count - 1)
    WHERE id = OLD.reel_id;
    RETURN OLD;
END;
$$ LANGUAGE plpgsql;

-- Trigger for like count decrement
CREATE TRIGGER reel_likes_decrement_trigger
AFTER DELETE ON public.reel_likes
FOR EACH ROW
EXECUTE FUNCTION public.decrement_reel_likes_count();

-- Function to increment views count when a view is recorded
CREATE OR REPLACE FUNCTION public.increment_reel_views_count()
RETURNS TRIGGER AS $$
BEGIN
    UPDATE public.reels
    SET views_count = views_count + 1
    WHERE id = NEW.reel_id;
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Trigger for view count increment
CREATE TRIGGER reel_views_increment_trigger
AFTER INSERT ON public.reel_views
FOR EACH ROW
EXECUTE FUNCTION public.increment_reel_views_count();

-- =====================================================
-- STORAGE BUCKET SETUP (Run this in Supabase Storage)
-- =====================================================

-- Create 'reels' storage bucket if it doesn't exist
-- This should be done via Supabase Dashboard or Storage API:
-- 1. Go to Storage in Supabase Dashboard
-- 2. Create new bucket named 'reels'
-- 3. Set it to PUBLIC (or configure policies as needed)

-- Storage policies (if using SQL):
-- INSERT INTO storage.buckets (id, name, public) VALUES ('reels', 'reels', true);

-- =====================================================
-- VERIFICATION QUERIES
-- =====================================================

-- Check if tables were created
SELECT table_name 
FROM information_schema.tables 
WHERE table_schema = 'public' 
AND table_name IN ('reels', 'reel_likes', 'reel_views');

-- Check if indexes were created
SELECT indexname, tablename 
FROM pg_indexes 
WHERE schemaname = 'public' 
AND tablename IN ('reels', 'reel_likes', 'reel_views');

-- Check if RLS is enabled
SELECT tablename, rowsecurity 
FROM pg_tables 
WHERE schemaname = 'public' 
AND tablename IN ('reels', 'reel_likes', 'reel_views');

-- =====================================================
-- SAMPLE DATA (for testing only - remove in production)
-- =====================================================

-- Insert a test reel (replace user_id with actual UUID from your users table)
-- INSERT INTO public.reels (user_id, video_url, thumbnail_url, caption, duration)
-- VALUES (
--     'your-user-uuid-here',
--     'https://your-supabase-url.supabase.co/storage/v1/object/public/reels/user_id/video.mp4',
--     'https://your-supabase-url.supabase.co/storage/v1/object/public/reels/user_id/thumb.jpg',
--     'My first reel! 🎬',
--     30
-- );

-- =====================================================
-- MIGRATION COMPLETE
-- =====================================================
-- Next steps:
-- 1. Create 'reels' storage bucket in Supabase Dashboard
-- 2. Configure storage policies for the reels bucket
-- 3. Test insertion, update, and deletion
-- 4. Integrate with Flutter app
-- =====================================================
