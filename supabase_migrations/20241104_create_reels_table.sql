-- Create reels table
-- Run this in Supabase SQL Editor

-- 1. Create reels table
CREATE TABLE IF NOT EXISTS public.reels (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    user_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
    video_url TEXT NOT NULL,
    thumbnail_url TEXT,
    caption TEXT,
    duration INTEGER, -- duration in seconds
    likes_count INTEGER DEFAULT 0,
    comments_count INTEGER DEFAULT 0,
    views_count INTEGER DEFAULT 0,
    shares_count INTEGER DEFAULT 0,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- 2. Create reel_likes table
CREATE TABLE IF NOT EXISTS public.reel_likes (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    reel_id UUID NOT NULL REFERENCES public.reels(id) ON DELETE CASCADE,
    user_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    UNIQUE(reel_id, user_id)
);

-- 3. Create reel_views table
CREATE TABLE IF NOT EXISTS public.reel_views (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    reel_id UUID NOT NULL REFERENCES public.reels(id) ON DELETE CASCADE,
    user_id UUID REFERENCES auth.users(id) ON DELETE CASCADE, -- nullable for anonymous views
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    UNIQUE(reel_id, user_id)
);

-- 4. Create reel_comments table (optional for future)
CREATE TABLE IF NOT EXISTS public.reel_comments (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    reel_id UUID NOT NULL REFERENCES public.reels(id) ON DELETE CASCADE,
    user_id UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
    comment TEXT NOT NULL,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- 5. Create indexes for better query performance
CREATE INDEX IF NOT EXISTS idx_reels_user_id ON public.reels(user_id);
CREATE INDEX IF NOT EXISTS idx_reels_created_at ON public.reels(created_at DESC);
CREATE INDEX IF NOT EXISTS idx_reels_likes_count ON public.reels(likes_count DESC);
CREATE INDEX IF NOT EXISTS idx_reels_views_count ON public.reels(views_count DESC);
CREATE INDEX IF NOT EXISTS idx_reel_likes_user_id ON public.reel_likes(user_id);
CREATE INDEX IF NOT EXISTS idx_reel_likes_reel_id ON public.reel_likes(reel_id);
CREATE INDEX IF NOT EXISTS idx_reel_views_reel_id ON public.reel_views(reel_id);

-- 6. Create trigger to update likes_count automatically
CREATE OR REPLACE FUNCTION update_reel_likes_count()
RETURNS TRIGGER AS $$
BEGIN
    IF TG_OP = 'INSERT' THEN
        UPDATE public.reels 
        SET likes_count = likes_count + 1 
        WHERE id = NEW.reel_id;
    ELSIF TG_OP = 'DELETE' THEN
        UPDATE public.reels 
        SET likes_count = GREATEST(likes_count - 1, 0) 
        WHERE id = OLD.reel_id;
    END IF;
    RETURN NULL;
END;
$$ LANGUAGE plpgsql;

DROP TRIGGER IF EXISTS trigger_update_reel_likes_count ON public.reel_likes;
CREATE TRIGGER trigger_update_reel_likes_count
AFTER INSERT OR DELETE ON public.reel_likes
FOR EACH ROW
EXECUTE FUNCTION update_reel_likes_count();

-- 7. Create trigger to update views_count automatically
CREATE OR REPLACE FUNCTION update_reel_views_count()
RETURNS TRIGGER AS $$
BEGIN
    IF TG_OP = 'INSERT' THEN
        UPDATE public.reels 
        SET views_count = views_count + 1 
        WHERE id = NEW.reel_id;
    END IF;
    RETURN NULL;
END;
$$ LANGUAGE plpgsql;

DROP TRIGGER IF EXISTS trigger_update_reel_views_count ON public.reel_views;
CREATE TRIGGER trigger_update_reel_views_count
AFTER INSERT ON public.reel_views
FOR EACH ROW
EXECUTE FUNCTION update_reel_views_count();

-- 8. Create trigger to update comments_count automatically
CREATE OR REPLACE FUNCTION update_reel_comments_count()
RETURNS TRIGGER AS $$
BEGIN
    IF TG_OP = 'INSERT' THEN
        UPDATE public.reels 
        SET comments_count = comments_count + 1 
        WHERE id = NEW.reel_id;
    ELSIF TG_OP = 'DELETE' THEN
        UPDATE public.reels 
        SET comments_count = GREATEST(comments_count - 1, 0) 
        WHERE id = OLD.reel_id;
    END IF;
    RETURN NULL;
END;
$$ LANGUAGE plpgsql;

DROP TRIGGER IF EXISTS trigger_update_reel_comments_count ON public.reel_comments;
CREATE TRIGGER trigger_update_reel_comments_count
AFTER INSERT OR DELETE ON public.reel_comments
FOR EACH ROW
EXECUTE FUNCTION update_reel_comments_count();

-- 9. Create trigger for updated_at timestamp
CREATE OR REPLACE FUNCTION update_updated_at_column()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = NOW();
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

DROP TRIGGER IF EXISTS trigger_update_reels_timestamp ON public.reels;
CREATE TRIGGER trigger_update_reels_timestamp
BEFORE UPDATE ON public.reels
FOR EACH ROW
EXECUTE FUNCTION update_updated_at_column();

-- 10. Enable Row Level Security (RLS)
ALTER TABLE public.reels ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.reel_likes ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.reel_views ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.reel_comments ENABLE ROW LEVEL SECURITY;

-- 11. Create RLS Policies

-- Reels policies: Anyone can view, only owner can insert/update/delete
DROP POLICY IF EXISTS "Reels are viewable by everyone" ON public.reels;
CREATE POLICY "Reels are viewable by everyone"
    ON public.reels FOR SELECT
    TO authenticated, anon
    USING (true);

DROP POLICY IF EXISTS "Users can insert their own reels" ON public.reels;
CREATE POLICY "Users can insert their own reels"
    ON public.reels FOR INSERT
    TO authenticated
    WITH CHECK (auth.uid() = user_id);

DROP POLICY IF EXISTS "Users can update their own reels" ON public.reels;
CREATE POLICY "Users can update their own reels"
    ON public.reels FOR UPDATE
    TO authenticated
    USING (auth.uid() = user_id)
    WITH CHECK (auth.uid() = user_id);

DROP POLICY IF EXISTS "Users can delete their own reels" ON public.reels;
CREATE POLICY "Users can delete their own reels"
    ON public.reels FOR DELETE
    TO authenticated
    USING (auth.uid() = user_id);

-- Reel likes policies
DROP POLICY IF EXISTS "Reel likes are viewable by everyone" ON public.reel_likes;
CREATE POLICY "Reel likes are viewable by everyone"
    ON public.reel_likes FOR SELECT
    TO authenticated, anon
    USING (true);

DROP POLICY IF EXISTS "Users can insert their own likes" ON public.reel_likes;
CREATE POLICY "Users can insert their own likes"
    ON public.reel_likes FOR INSERT
    TO authenticated
    WITH CHECK (auth.uid() = user_id);

DROP POLICY IF EXISTS "Users can delete their own likes" ON public.reel_likes;
CREATE POLICY "Users can delete their own likes"
    ON public.reel_likes FOR DELETE
    TO authenticated
    USING (auth.uid() = user_id);

-- Reel views policies
DROP POLICY IF EXISTS "Reel views are viewable by everyone" ON public.reel_views;
CREATE POLICY "Reel views are viewable by everyone"
    ON public.reel_views FOR SELECT
    TO authenticated, anon
    USING (true);

DROP POLICY IF EXISTS "Anyone can insert reel views" ON public.reel_views;
CREATE POLICY "Anyone can insert reel views"
    ON public.reel_views FOR INSERT
    TO authenticated, anon
    WITH CHECK (true);

-- Reel comments policies
DROP POLICY IF EXISTS "Reel comments are viewable by everyone" ON public.reel_comments;
CREATE POLICY "Reel comments are viewable by everyone"
    ON public.reel_comments FOR SELECT
    TO authenticated, anon
    USING (true);

DROP POLICY IF EXISTS "Users can insert their own comments" ON public.reel_comments;
CREATE POLICY "Users can insert their own comments"
    ON public.reel_comments FOR INSERT
    TO authenticated
    WITH CHECK (auth.uid() = user_id);

DROP POLICY IF EXISTS "Users can update their own comments" ON public.reel_comments;
CREATE POLICY "Users can update their own comments"
    ON public.reel_comments FOR UPDATE
    TO authenticated
    USING (auth.uid() = user_id)
    WITH CHECK (auth.uid() = user_id);

DROP POLICY IF EXISTS "Users can delete their own comments" ON public.reel_comments;
CREATE POLICY "Users can delete their own comments"
    ON public.reel_comments FOR DELETE
    TO authenticated
    USING (auth.uid() = user_id);

-- 12. Grant necessary permissions
GRANT USAGE ON SCHEMA public TO anon, authenticated;
GRANT ALL ON public.reels TO authenticated;
GRANT ALL ON public.reel_likes TO authenticated;
GRANT ALL ON public.reel_views TO authenticated, anon;
GRANT ALL ON public.reel_comments TO authenticated;

-- Success message
DO $$
BEGIN
    RAISE NOTICE '✅ Reels table structure created successfully!';
    RAISE NOTICE '📝 Next steps:';
    RAISE NOTICE '   1. Create "reels" storage bucket in Supabase Storage';
    RAISE NOTICE '   2. Set bucket to public access';
    RAISE NOTICE '   3. Set storage policies (see next migration file)';
END $$;
