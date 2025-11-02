# 🗄️ Database Migration Guide - SyncUp App

## 📋 Quick Start

### **Single File Migration (Recommended)**
Run this ONE file in Supabase SQL Editor:
```
database_migrations/COMPLETE_DATABASE_MIGRATION.sql
```

This file contains EVERYTHING you need!

---

## 🎯 What Gets Created/Updated

### **New Tables Created:**
1. ✅ `notifications` - For follow requests, likes, comments
2. ✅ `blocked_users` - For user blocking functionality
3. ✅ `muted_users` - For muting users from feed

### **Columns Added to Existing Tables:**

**users table:**
- `cover_photo_url` - User's cover/banner photo
- `is_private` - Whether account is private
- `has_stories` - Whether user has active stories

**posts table:**
- `type` - Distinguish between posts, reels, stories
- `thumbnail_url` - Thumbnail for video posts
- `views_count` - View count for reels

---

## 🚀 How to Apply Migration

### **Step 1: Open Supabase Dashboard**
1. Go to https://supabase.com
2. Sign in to your project
3. Click **SQL Editor** in left sidebar

### **Step 2: Run the Migration**
1. Click **"+ New query"**
2. Open file: `database_migrations/COMPLETE_DATABASE_MIGRATION.sql`
3. Copy ALL contents (Ctrl+A, Ctrl+C)
4. Paste into SQL Editor
5. Click **"Run"** button (or press Ctrl+Enter)

### **Step 3: Verify Success**
You should see messages like:
```
✅ Database migration completed successfully!

Created tables:
  - notifications (with 5 indexes)
  - blocked_users (with 3 indexes)
  - muted_users (with 3 indexes)

...

🎉 Your database is now ready for the SyncUp app!
```

---

## 🔍 Verification Queries

Run these in SQL Editor to verify everything worked:

### **Check Tables Created:**
```sql
SELECT table_name FROM information_schema.tables 
WHERE table_schema = 'public' 
AND table_name IN ('notifications', 'blocked_users', 'muted_users')
ORDER BY table_name;
```

Should return:
- blocked_users
- muted_users
- notifications

### **Check Row Level Security:**
```sql
SELECT tablename, rowsecurity 
FROM pg_tables 
WHERE schemaname = 'public'
AND tablename IN ('notifications', 'blocked_users', 'muted_users')
ORDER BY tablename;
```

All should have `rowsecurity = true`

### **Check Indexes Created:**
```sql
SELECT tablename, indexname 
FROM pg_indexes 
WHERE schemaname = 'public'
AND tablename IN ('notifications', 'blocked_users', 'muted_users')
ORDER BY tablename, indexname;
```

Should show multiple indexes per table.

---

## 📁 Individual Migration Files (If Needed)

If you prefer to run migrations separately:

### **1. Notifications System**
```
database_migrations/add_notifications_table.sql
```
- Creates notifications table
- Adds RLS policies
- Creates indexes

### **2. Moderation Tables**
```
database_migrations/create_moderation_tables.sql
```
- Creates blocked_users table
- Creates muted_users table
- Adds RLS policies
- Adds helper functions

### **3. Cover Photo Support**
```
database_migrations/add_cover_photo_column.sql
```
- Adds cover_photo_url to users table

---

## 🔧 What Each Table Does

### **notifications**
```sql
id              UUID      - Notification ID
from_user_id    UUID      - Who triggered the notification
to_user_id      UUID      - Who receives the notification
post_id         UUID      - Related post (optional)
type            VARCHAR   - follow, follow_request, like, comment
comment_text    TEXT      - Comment content (if type=comment)
is_read         BOOLEAN   - Whether user has read it
created_at      TIMESTAMP - When notification was created
```

**Used for:**
- Follow requests
- Like notifications
- Comment notifications
- Follow confirmations

---

### **blocked_users**
```sql
id          UUID      - Block record ID
blocker_id  UUID      - User who blocked someone
blocked_id  UUID      - User who got blocked
created_at  TIMESTAMP - When block occurred
```

**Used for:**
- Preventing blocked users from seeing your content
- Hiding blocked users from your feed
- Preventing interactions between blocked users

---

### **muted_users**
```sql
id          UUID      - Mute record ID
muter_id    UUID      - User who muted someone
muted_id    UUID      - User who got muted
created_at  TIMESTAMP - When mute occurred
```

**Used for:**
- Hiding muted users' posts from your feed
- Private action (muted user doesn't know)
- Can still see their profile if you visit directly

---

## 🛡️ Security Features

### **Row Level Security (RLS)**
All tables have RLS enabled to protect user data:

**Notifications:**
- ✅ Users can only view their own notifications
- ✅ Users can only create notifications they send
- ✅ Users can mark their own notifications as read
- ✅ Users can delete their own notifications

**Blocked Users:**
- ✅ Users can only view their own block list
- ✅ Users can only block/unblock from their own account
- ✅ Blocked users cannot see blocker's data

**Muted Users:**
- ✅ Users can only view their own mute list
- ✅ Users can only mute/unmute from their own account
- ✅ Completely private (muted user doesn't know)

---

## 🔨 Helper Functions Created

### **1. is_user_blocked(blocker, blocked)**
```sql
SELECT public.is_user_blocked(
  'user-a-uuid'::uuid, 
  'user-b-uuid'::uuid
);
```
Returns `true` if user A has blocked user B.

### **2. is_user_muted(muter, muted)**
```sql
SELECT public.is_user_muted(
  'user-a-uuid'::uuid, 
  'user-b-uuid'::uuid
);
```
Returns `true` if user A has muted user B.

### **3. get_unread_notification_count(user_id)**
```sql
SELECT public.get_unread_notification_count('user-uuid'::uuid);
```
Returns count of unread notifications for a user.

---

## 🐛 Troubleshooting

### **Error: "relation already exists"**
This is normal if you run the script multiple times. The script uses `IF NOT EXISTS` to prevent errors.

### **Error: "permission denied"**
Make sure you're logged into the correct Supabase project with owner/admin privileges.

### **Error: "could not find table users"**
Your users table needs to exist first. Make sure you've created it in a previous migration.

### **No error but nothing happens**
Check the Messages panel in Supabase SQL Editor for success/error messages.

---

## ✅ Post-Migration Checklist

After running the migration:

- [ ] Check console output shows success message
- [ ] Run verification queries to confirm tables exist
- [ ] Hot reload your Flutter app (`r` in terminal)
- [ ] Check Flutter console - no more PostgrestException errors
- [ ] Test notification button in app
- [ ] Test viewing other user profiles
- [ ] Test explore page with real posts/reels
- [ ] Verify profile photos show correctly
- [ ] Verify stats show real numbers (not 87/523/45.2k)

---

## 📞 Support

If you encounter issues:
1. Check the error message in Supabase SQL Editor
2. Verify your Supabase project is active
3. Check that auth is properly configured
4. Look at the verification queries section above

---

## 🎉 Success!

Once complete, your app will have:
- ✅ Working notification system
- ✅ User blocking functionality
- ✅ User muting functionality
- ✅ Cover photo support
- ✅ Private account support
- ✅ Story status tracking
- ✅ Post type differentiation (posts vs reels)
- ✅ Video thumbnail support
- ✅ View count tracking

**All with proper security policies!**
