-- ===================================================================
-- NOTIFICATIONS TABLE
-- ===================================================================
-- This migration adds the notifications table for follow requests,
-- likes, comments, and other user interactions
-- ===================================================================

CREATE TABLE IF NOT EXISTS notifications (
    id TEXT PRIMARY KEY DEFAULT gen_random_uuid()::TEXT,
    from_user_id TEXT NOT NULL REFERENCES users(uid) ON DELETE CASCADE,
    to_user_id TEXT NOT NULL REFERENCES users(uid) ON DELETE CASCADE,
    post_id TEXT REFERENCES posts(id) ON DELETE CASCADE,
    type TEXT NOT NULL CHECK (type IN ('follow', 'follow_request', 'like', 'comment')),
    comment_text TEXT, -- For comment notifications
    is_read BOOLEAN DEFAULT FALSE,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Indexes for performance
CREATE INDEX IF NOT EXISTS idx_notifications_to_user ON notifications(to_user_id);
CREATE INDEX IF NOT EXISTS idx_notifications_from_user ON notifications(from_user_id);
CREATE INDEX IF NOT EXISTS idx_notifications_type ON notifications(type);
CREATE INDEX IF NOT EXISTS idx_notifications_created_at ON notifications(created_at DESC);
CREATE INDEX IF NOT EXISTS idx_notifications_unread ON notifications(to_user_id, is_read) WHERE is_read = FALSE;

-- ===================================================================
-- ROW LEVEL SECURITY (RLS) POLICIES
-- ===================================================================

ALTER TABLE notifications ENABLE ROW LEVEL SECURITY;

-- Users can view notifications sent to them
CREATE POLICY notifications_select_policy ON notifications
    FOR SELECT
    USING (to_user_id = auth.uid()::TEXT);

-- Users can create notifications (for sending to others)
CREATE POLICY notifications_insert_policy ON notifications
    FOR INSERT
    WITH CHECK (from_user_id = auth.uid()::TEXT);

-- Users can update their own notifications (mark as read)
CREATE POLICY notifications_update_policy ON notifications
    FOR UPDATE
    USING (to_user_id = auth.uid()::TEXT);

-- Users can delete notifications sent to them
CREATE POLICY notifications_delete_policy ON notifications
    FOR DELETE
    USING (to_user_id = auth.uid()::TEXT);
