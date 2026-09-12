-- ============================================
-- ORA Phase 5.1: Notification Backend System
-- ============================================
-- This migration creates a production-ready notification system
-- with automatic triggers for likes, comments, replies, and follows.

-- ============================================
-- 1. CREATE NOTIFICATIONS TABLE
-- ============================================

CREATE TABLE IF NOT EXISTS notifications (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    recipient_id UUID NOT NULL REFERENCES profiles(user_id) ON DELETE CASCADE,
    actor_id UUID NOT NULL REFERENCES profiles(user_id) ON DELETE CASCADE,
    post_id UUID REFERENCES posts(id) ON DELETE CASCADE,
    comment_id UUID REFERENCES comments(id) ON DELETE CASCADE,
    type TEXT NOT NULL CHECK (type IN ('like', 'comment', 'reply', 'follow')),
    is_read BOOLEAN DEFAULT FALSE,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT TIMEZONE('utc'::text, NOW()) NOT NULL
);

-- ============================================
-- 2. CREATE INDEXES FOR PERFORMANCE
-- ============================================

-- Index for fetching user's notifications (most common query)
CREATE INDEX IF NOT EXISTS idx_notifications_recipient_id 
    ON notifications(recipient_id);

-- Index for ordering notifications by time
CREATE INDEX IF NOT EXISTS idx_notifications_created_at 
    ON notifications(created_at DESC);

-- Composite index for unread notifications query
CREATE INDEX IF NOT EXISTS idx_notifications_recipient_unread 
    ON notifications(recipient_id, is_read, created_at DESC);

-- Index for actor_id to prevent duplicate notifications
CREATE INDEX IF NOT EXISTS idx_notifications_actor_id 
    ON notifications(actor_id);

-- ============================================
-- 3. ENABLE ROW LEVEL SECURITY
-- ============================================

ALTER TABLE notifications ENABLE ROW LEVEL SECURITY;

-- ============================================
-- 4. CREATE RLS POLICIES
-- ============================================

-- Policy: Users can view their own notifications
CREATE POLICY "Users can view their own notifications"
    ON notifications
    FOR SELECT
    USING (auth.uid() = recipient_id);

-- Policy: Users can update (mark as read) their own notifications
CREATE POLICY "Users can update their own notifications"
    ON notifications
    FOR UPDATE
    USING (auth.uid() = recipient_id)
    WITH CHECK (auth.uid() = recipient_id);

-- Policy: Users can delete their own notifications
CREATE POLICY "Users can delete their own notifications"
    ON notifications
    FOR DELETE
    USING (auth.uid() = recipient_id);

-- Notifications are inserted by SECURITY DEFINER trigger functions below;
-- clients are not granted a direct INSERT policy.
DROP POLICY IF EXISTS "Service role can insert notifications" ON notifications;

-- ============================================
-- 5. HELPER FUNCTION TO PREVENT SELF-NOTIFICATIONS
-- ============================================

CREATE OR REPLACE FUNCTION check_notification_recipient()
RETURNS TRIGGER
LANGUAGE plpgsql
AS $$
BEGIN
    -- Prevent self-notifications
    IF NEW.recipient_id = NEW.actor_id THEN
        RETURN NULL; -- Skip the notification
    END IF;
    
    RETURN NEW;
END;
$$;

DROP TRIGGER IF EXISTS trigger_check_notification_recipient ON notifications;
CREATE TRIGGER trigger_check_notification_recipient
    BEFORE INSERT ON notifications
    FOR EACH ROW
    EXECUTE FUNCTION check_notification_recipient();

-- ============================================
-- 6. TRIGGER FUNCTION: POST LIKES
-- ============================================

CREATE OR REPLACE FUNCTION create_like_notification()
RETURNS TRIGGER
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
BEGIN
    -- Only create notification if user is liking someone else's post
    IF (SELECT user_id FROM posts WHERE id = NEW.post_id) != NEW.user_id THEN
        INSERT INTO notifications (
            recipient_id,
            actor_id,
            post_id,
            type
        ) VALUES (
            (SELECT user_id FROM posts WHERE id = NEW.post_id),
            NEW.user_id,
            NEW.post_id,
            'like'
        );
    END IF;
    
    RETURN NEW;
END;
$$;

-- Create trigger for post likes
DROP TRIGGER IF EXISTS trigger_create_like_notification ON post_likes;
CREATE TRIGGER trigger_create_like_notification
    AFTER INSERT ON post_likes
    FOR EACH ROW
    EXECUTE FUNCTION create_like_notification();

-- ============================================
-- 7. TRIGGER FUNCTION: COMMENTS
-- ============================================

CREATE OR REPLACE FUNCTION create_comment_notification()
RETURNS TRIGGER
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
BEGIN
    -- Only create notification if user is commenting on someone else's post
    IF (SELECT user_id FROM posts WHERE id = NEW.post_id) != NEW.user_id THEN
        INSERT INTO notifications (
            recipient_id,
            actor_id,
            post_id,
            comment_id,
            type
        ) VALUES (
            (SELECT user_id FROM posts WHERE id = NEW.post_id),
            NEW.user_id,
            NEW.post_id,
            NEW.id,
            'comment'
        );
    END IF;
    
    RETURN NEW;
END;
$$;

-- Create trigger for comments
DROP TRIGGER IF EXISTS trigger_create_comment_notification ON comments;
CREATE TRIGGER trigger_create_comment_notification
    AFTER INSERT ON comments
    FOR EACH ROW
    EXECUTE FUNCTION create_comment_notification();

-- ============================================
-- 8. TRIGGER FUNCTION: COMMENT REPLIES
-- ============================================
-- Note: This trigger assumes the comments table has a parent_id column
-- for threaded replies. If parent_id doesn't exist, this trigger will
-- gracefully skip reply notifications.

CREATE OR REPLACE FUNCTION create_reply_notification()
RETURNS TRIGGER
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
    parent_comment_author UUID;
    post_author UUID;
    has_parent_id BOOLEAN;
BEGIN
    -- Check if parent_id column exists in comments table
    SELECT EXISTS (
        SELECT 1 FROM information_schema.columns 
        WHERE table_name = 'comments' 
        AND column_name = 'parent_id'
    ) INTO has_parent_id;
    
    -- Only proceed if parent_id column exists and is set
    IF has_parent_id AND NEW.parent_id IS NOT NULL THEN
        -- Get the author of the parent comment
        SELECT user_id INTO parent_comment_author 
        FROM comments 
        WHERE id = NEW.parent_id;
        
        -- Notify the parent comment author (if not self)
        IF parent_comment_author IS NOT NULL AND parent_comment_author != NEW.user_id THEN
            INSERT INTO notifications (
                recipient_id,
                actor_id,
                post_id,
                comment_id,
                type
            ) VALUES (
                parent_comment_author,
                NEW.user_id,
                NEW.post_id,
                NEW.id,
                'reply'
            );
        END IF;
        
        -- Also notify the post author if they're not already notified
        SELECT user_id INTO post_author 
        FROM posts 
        WHERE id = NEW.post_id;
        
        -- Only notify post author if they're not the commenter and not the parent commenter
        IF post_author IS NOT NULL 
           AND post_author != NEW.user_id 
           AND post_author != parent_comment_author THEN
            INSERT INTO notifications (
                recipient_id,
                actor_id,
                post_id,
                comment_id,
                type
            ) VALUES (
                post_author,
                NEW.user_id,
                NEW.post_id,
                NEW.id,
                'reply'
            );
        END IF;
    END IF;
    
    RETURN NEW;
END;
$$;

-- Create trigger for replies (only fires when parent_id is not null)
DROP TRIGGER IF EXISTS trigger_create_reply_notification ON comments;
CREATE TRIGGER trigger_create_reply_notification
    AFTER INSERT ON comments
    FOR EACH ROW
    EXECUTE FUNCTION create_reply_notification();

-- ============================================
-- 9. TRIGGER FUNCTION: FOLLOWS
-- ============================================

CREATE OR REPLACE FUNCTION create_follow_notification()
RETURNS TRIGGER
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
BEGIN
    -- Create notification for the user being followed
    INSERT INTO notifications (
        recipient_id,
        actor_id,
        type
    ) VALUES (
        NEW.following_id,
        NEW.follower_id,
        'follow'
    );
    
    RETURN NEW;
END;
$$;

-- Create trigger for follows
DROP TRIGGER IF EXISTS trigger_create_follow_notification ON followers;
CREATE TRIGGER trigger_create_follow_notification
    AFTER INSERT ON followers
    FOR EACH ROW
    EXECUTE FUNCTION create_follow_notification();

-- ============================================
-- 10. GRANT PERMISSIONS
-- ============================================

-- Grant authenticated users permission to read/update/delete their notifications
GRANT SELECT, UPDATE, DELETE ON notifications TO authenticated;

-- Trigger functions run as SECURITY DEFINER, so clients do not need
-- direct INSERT privileges on notifications.

-- ============================================
-- 11. COMMENTS FOR DOCUMENTATION
-- ============================================

COMMENT ON TABLE notifications IS 'User notifications for likes, comments, replies, and follows';
COMMENT ON COLUMN notifications.recipient_id IS 'User who receives the notification';
COMMENT ON COLUMN notifications.actor_id IS 'User who triggered the notification';
COMMENT ON COLUMN notifications.post_id IS 'Related post (nullable)';
COMMENT ON COLUMN notifications.comment_id IS 'Related comment (nullable)';
COMMENT ON COLUMN notifications.type IS 'Notification type: like, comment, reply, follow';
COMMENT ON COLUMN notifications.is_read IS 'Whether the notification has been read';
COMMENT ON COLUMN notifications.created_at IS 'When the notification was created';

-- ============================================
-- MIGRATION COMPLETE
-- ============================================