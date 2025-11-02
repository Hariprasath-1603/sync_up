-- ===================================================================
-- INTERACTION AND MODERATION SYSTEM TABLES
-- ===================================================================
-- This migration adds full support for:
-- 1. Likes
-- 2. Comments and Replies
-- 3. Saved Posts
-- 4. Block/Mute/Report functionality
-- 5. Post views tracking
-- ===================================================================

-- ===================================================================
-- LIKES TABLE
-- ===================================================================
CREATE TABLE IF NOT EXISTS likes (
    id TEXT PRIMARY KEY DEFAULT gen_random_uuid()::TEXT,
    user_id TEXT NOT NULL REFERENCES users(uid) ON DELETE CASCADE,
    post_id TEXT NOT NULL REFERENCES posts(id) ON DELETE CASCADE,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    UNIQUE(user_id, post_id)
);

CREATE INDEX IF NOT EXISTS idx_likes_user_id ON likes(user_id);
CREATE INDEX IF NOT EXISTS idx_likes_post_id ON likes(post_id);
CREATE INDEX IF NOT EXISTS idx_likes_created_at ON likes(created_at);

-- ===================================================================
-- COMMENTS TABLE
-- ===================================================================
CREATE TABLE IF NOT EXISTS comments (
    id TEXT PRIMARY KEY DEFAULT gen_random_uuid()::TEXT,
    post_id TEXT NOT NULL REFERENCES posts(id) ON DELETE CASCADE,
    user_id TEXT NOT NULL REFERENCES users(uid) ON DELETE CASCADE,
    parent_comment_id TEXT REFERENCES comments(id) ON DELETE CASCADE,
    content TEXT NOT NULL,
    likes_count INTEGER DEFAULT 0,
    replies_count INTEGER DEFAULT 0,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

CREATE INDEX IF NOT EXISTS idx_comments_post_id ON comments(post_id);
CREATE INDEX IF NOT EXISTS idx_comments_user_id ON comments(user_id);
CREATE INDEX IF NOT EXISTS idx_comments_parent_id ON comments(parent_comment_id);
CREATE INDEX IF NOT EXISTS idx_comments_created_at ON comments(created_at DESC);

-- ===================================================================
-- COMMENT LIKES TABLE
-- ===================================================================
CREATE TABLE IF NOT EXISTS comment_likes (
    id TEXT PRIMARY KEY DEFAULT gen_random_uuid()::TEXT,
    user_id TEXT NOT NULL REFERENCES users(uid) ON DELETE CASCADE,
    comment_id TEXT NOT NULL REFERENCES comments(id) ON DELETE CASCADE,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    UNIQUE(user_id, comment_id)
);

CREATE INDEX IF NOT EXISTS idx_comment_likes_user_id ON comment_likes(user_id);
CREATE INDEX IF NOT EXISTS idx_comment_likes_comment_id ON comment_likes(comment_id);

-- ===================================================================
-- SAVED POSTS TABLE
-- ===================================================================
CREATE TABLE IF NOT EXISTS saved_posts (
    id TEXT PRIMARY KEY DEFAULT gen_random_uuid()::TEXT,
    user_id TEXT NOT NULL REFERENCES users(uid) ON DELETE CASCADE,
    post_id TEXT NOT NULL REFERENCES posts(id) ON DELETE CASCADE,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    UNIQUE(user_id, post_id)
);

CREATE INDEX IF NOT EXISTS idx_saved_posts_user_id ON saved_posts(user_id);
CREATE INDEX IF NOT EXISTS idx_saved_posts_post_id ON saved_posts(post_id);
CREATE INDEX IF NOT EXISTS idx_saved_posts_created_at ON saved_posts(created_at DESC);

-- ===================================================================
-- BLOCKED USERS TABLE
-- ===================================================================
CREATE TABLE IF NOT EXISTS blocked_users (
    id TEXT PRIMARY KEY DEFAULT gen_random_uuid()::TEXT,
    blocker_id TEXT NOT NULL REFERENCES users(uid) ON DELETE CASCADE,
    blocked_id TEXT NOT NULL REFERENCES users(uid) ON DELETE CASCADE,
    reason TEXT,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    UNIQUE(blocker_id, blocked_id),
    CHECK (blocker_id != blocked_id)
);

CREATE INDEX IF NOT EXISTS idx_blocked_users_blocker_id ON blocked_users(blocker_id);
CREATE INDEX IF NOT EXISTS idx_blocked_users_blocked_id ON blocked_users(blocked_id);

-- ===================================================================
-- MUTED USERS TABLE
-- ===================================================================
CREATE TABLE IF NOT EXISTS muted_users (
    id TEXT PRIMARY KEY DEFAULT gen_random_uuid()::TEXT,
    muter_id TEXT NOT NULL REFERENCES users(uid) ON DELETE CASCADE,
    muted_id TEXT NOT NULL REFERENCES users(uid) ON DELETE CASCADE,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    UNIQUE(muter_id, muted_id),
    CHECK (muter_id != muted_id)
);

CREATE INDEX IF NOT EXISTS idx_muted_users_muter_id ON muted_users(muter_id);
CREATE INDEX IF NOT EXISTS idx_muted_users_muted_id ON muted_users(muted_id);

-- ===================================================================
-- REPORTS TABLE
-- ===================================================================
CREATE TABLE IF NOT EXISTS reports (
    id TEXT PRIMARY KEY DEFAULT gen_random_uuid()::TEXT,
    reporter_id TEXT NOT NULL REFERENCES users(uid) ON DELETE CASCADE,
    reported_user_id TEXT REFERENCES users(uid) ON DELETE CASCADE,
    reported_post_id TEXT REFERENCES posts(id) ON DELETE CASCADE,
    report_type TEXT NOT NULL CHECK (report_type IN ('spam', 'harassment', 'inappropriate', 'impersonation', 'violence', 'hate_speech', 'false_info', 'self_harm', 'other')),
    description TEXT,
    status TEXT DEFAULT 'pending' CHECK (status IN ('pending', 'reviewed', 'resolved', 'dismissed')),
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    reviewed_at TIMESTAMP WITH TIME ZONE,
    reviewed_by TEXT REFERENCES users(uid) ON DELETE SET NULL,
    CHECK (reported_user_id IS NOT NULL OR reported_post_id IS NOT NULL)
);

CREATE INDEX IF NOT EXISTS idx_reports_reporter_id ON reports(reporter_id);
CREATE INDEX IF NOT EXISTS idx_reports_reported_user_id ON reports(reported_user_id);
CREATE INDEX IF NOT EXISTS idx_reports_reported_post_id ON reports(reported_post_id);
CREATE INDEX IF NOT EXISTS idx_reports_status ON reports(status);
CREATE INDEX IF NOT EXISTS idx_reports_created_at ON reports(created_at DESC);

-- ===================================================================
-- POST VIEWS TABLE (for analytics)
-- ===================================================================
CREATE TABLE IF NOT EXISTS post_views (
    id TEXT PRIMARY KEY DEFAULT gen_random_uuid()::TEXT,
    post_id TEXT NOT NULL REFERENCES posts(id) ON DELETE CASCADE,
    viewer_id TEXT REFERENCES users(uid) ON DELETE SET NULL,
    viewed_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    duration_seconds INTEGER DEFAULT 0
);

CREATE INDEX IF NOT EXISTS idx_post_views_post_id ON post_views(post_id);
CREATE INDEX IF NOT EXISTS idx_post_views_viewer_id ON post_views(viewer_id);
CREATE INDEX IF NOT EXISTS idx_post_views_viewed_at ON post_views(viewed_at DESC);

-- ===================================================================
-- FOLLOWERS TABLE (if not exists)
-- ===================================================================
CREATE TABLE IF NOT EXISTS followers (
    id TEXT PRIMARY KEY DEFAULT gen_random_uuid()::TEXT,
    follower_id TEXT NOT NULL REFERENCES users(uid) ON DELETE CASCADE,
    following_id TEXT NOT NULL REFERENCES users(uid) ON DELETE CASCADE,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    UNIQUE(follower_id, following_id),
    CHECK (follower_id != following_id)
);

CREATE INDEX IF NOT EXISTS idx_followers_follower_id ON followers(follower_id);
CREATE INDEX IF NOT EXISTS idx_followers_following_id ON followers(following_id);

-- ===================================================================
-- RLS POLICIES
-- ===================================================================

-- Likes policies
ALTER TABLE likes ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Users can view all likes"
    ON likes FOR SELECT
    USING (true);

CREATE POLICY "Users can like posts"
    ON likes FOR INSERT
    WITH CHECK (auth.uid()::TEXT = user_id);

CREATE POLICY "Users can unlike their own likes"
    ON likes FOR DELETE
    USING (auth.uid()::TEXT = user_id);

-- Comments policies
ALTER TABLE comments ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Users can view all comments"
    ON comments FOR SELECT
    USING (true);

CREATE POLICY "Users can create comments"
    ON comments FOR INSERT
    WITH CHECK (auth.uid()::TEXT = user_id);

CREATE POLICY "Users can update their own comments"
    ON comments FOR UPDATE
    USING (auth.uid()::TEXT = user_id);

CREATE POLICY "Users can delete their own comments"
    ON comments FOR DELETE
    USING (auth.uid()::TEXT = user_id);

-- Comment likes policies
ALTER TABLE comment_likes ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Users can view all comment likes"
    ON comment_likes FOR SELECT
    USING (true);

CREATE POLICY "Users can like comments"
    ON comment_likes FOR INSERT
    WITH CHECK (auth.uid()::TEXT = user_id);

CREATE POLICY "Users can unlike comments"
    ON comment_likes FOR DELETE
    USING (auth.uid()::TEXT = user_id);

-- Saved posts policies
ALTER TABLE saved_posts ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Users can view their own saved posts"
    ON saved_posts FOR SELECT
    USING (auth.uid()::TEXT = user_id);

CREATE POLICY "Users can save posts"
    ON saved_posts FOR INSERT
    WITH CHECK (auth.uid()::TEXT = user_id);

CREATE POLICY "Users can unsave posts"
    ON saved_posts FOR DELETE
    USING (auth.uid()::TEXT = user_id);

-- Blocked users policies
ALTER TABLE blocked_users ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Users can view their own blocks"
    ON blocked_users FOR SELECT
    USING (auth.uid()::TEXT = blocker_id);

CREATE POLICY "Users can block others"
    ON blocked_users FOR INSERT
    WITH CHECK (auth.uid()::TEXT = blocker_id);

CREATE POLICY "Users can unblock others"
    ON blocked_users FOR DELETE
    USING (auth.uid()::TEXT = blocker_id);

-- Muted users policies
ALTER TABLE muted_users ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Users can view their own mutes"
    ON muted_users FOR SELECT
    USING (auth.uid()::TEXT = muter_id);

CREATE POLICY "Users can mute others"
    ON muted_users FOR INSERT
    WITH CHECK (auth.uid()::TEXT = muter_id);

CREATE POLICY "Users can unmute others"
    ON muted_users FOR DELETE
    USING (auth.uid()::TEXT = muter_id);

-- Reports policies
ALTER TABLE reports ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Users can view their own reports"
    ON reports FOR SELECT
    USING (auth.uid()::TEXT = reporter_id);

CREATE POLICY "Users can create reports"
    ON reports FOR INSERT
    WITH CHECK (auth.uid()::TEXT = reporter_id);

-- Post views policies
ALTER TABLE post_views ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Anyone can record post views"
    ON post_views FOR INSERT
    WITH CHECK (true);

CREATE POLICY "Post owners can view their post analytics"
    ON post_views FOR SELECT
    USING (
        post_id IN (
            SELECT id FROM posts WHERE user_id = auth.uid()::TEXT
        )
    );

-- Followers policies
ALTER TABLE followers ENABLE ROW LEVEL SECURITY;

CREATE POLICY "Users can view all follows"
    ON followers FOR SELECT
    USING (true);

CREATE POLICY "Users can follow others"
    ON followers FOR INSERT
    WITH CHECK (auth.uid()::TEXT = follower_id);

CREATE POLICY "Users can unfollow others"
    ON followers FOR DELETE
    USING (auth.uid()::TEXT = follower_id);

-- ===================================================================
-- FUNCTIONS TO UPDATE COUNTS
-- ===================================================================

-- Function to update likes count on posts
CREATE OR REPLACE FUNCTION update_post_likes_count()
RETURNS TRIGGER AS $$
BEGIN
    IF TG_OP = 'INSERT' THEN
        UPDATE posts SET likes_count = likes_count + 1 WHERE id = NEW.post_id;
    ELSIF TG_OP = 'DELETE' THEN
        UPDATE posts SET likes_count = GREATEST(0, likes_count - 1) WHERE id = OLD.post_id;
    END IF;
    RETURN NULL;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER trigger_update_post_likes_count
AFTER INSERT OR DELETE ON likes
FOR EACH ROW EXECUTE FUNCTION update_post_likes_count();

-- Function to update comments count on posts
CREATE OR REPLACE FUNCTION update_post_comments_count()
RETURNS TRIGGER AS $$
BEGIN
    IF TG_OP = 'INSERT' THEN
        -- Only count top-level comments (not replies)
        IF NEW.parent_comment_id IS NULL THEN
            UPDATE posts SET comments_count = comments_count + 1 WHERE id = NEW.post_id;
        ELSE
            -- Update replies count on parent comment
            UPDATE comments SET replies_count = replies_count + 1 WHERE id = NEW.parent_comment_id;
        END IF;
    ELSIF TG_OP = 'DELETE' THEN
        IF OLD.parent_comment_id IS NULL THEN
            UPDATE posts SET comments_count = GREATEST(0, comments_count - 1) WHERE id = OLD.post_id;
        ELSE
            UPDATE comments SET replies_count = GREATEST(0, replies_count - 1) WHERE id = OLD.parent_comment_id;
        END IF;
    END IF;
    RETURN NULL;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER trigger_update_post_comments_count
AFTER INSERT OR DELETE ON comments
FOR EACH ROW EXECUTE FUNCTION update_post_comments_count();

-- Function to update comment likes count
CREATE OR REPLACE FUNCTION update_comment_likes_count()
RETURNS TRIGGER AS $$
BEGIN
    IF TG_OP = 'INSERT' THEN
        UPDATE comments SET likes_count = likes_count + 1 WHERE id = NEW.comment_id;
    ELSIF TG_OP = 'DELETE' THEN
        UPDATE comments SET likes_count = GREATEST(0, likes_count - 1) WHERE id = OLD.comment_id;
    END IF;
    RETURN NULL;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER trigger_update_comment_likes_count
AFTER INSERT OR DELETE ON comment_likes
FOR EACH ROW EXECUTE FUNCTION update_comment_likes_count();

-- Function to update views count on posts
CREATE OR REPLACE FUNCTION update_post_views_count()
RETURNS TRIGGER AS $$
BEGIN
    UPDATE posts SET views_count = views_count + 1 WHERE id = NEW.post_id;
    RETURN NULL;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER trigger_update_post_views_count
AFTER INSERT ON post_views
FOR EACH ROW EXECUTE FUNCTION update_post_views_count();

-- ===================================================================
-- COMPLETE!
-- ===================================================================
-- Run this migration on your Supabase database
-- All interaction and moderation features are now ready to use
-- ===================================================================
