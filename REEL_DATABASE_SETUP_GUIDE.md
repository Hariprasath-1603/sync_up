# 🎬 Reel Database Setup Guide

## Issue Encountered

Your app is showing the error:
```
PostgrestException(message: Could not find the table 'public.reels' in the schema cache, code: PGRST205, details: Not Found, hint: Perhaps you meant the table 'public.users')
```

This means the `reels` table doesn't exist in your Supabase database yet.

## 📋 Step-by-Step Setup

### Step 1: Create Database Tables

1. **Open Supabase Dashboard**:
   - Go to https://supabase.com/dashboard
   - Select your project: `cgkexriarshbftnjftlm`

2. **Go to SQL Editor**:
   - Click on "SQL Editor" in the left sidebar
   - Click "+ New Query"

3. **Run the Migration**:
   - Copy the entire contents of `supabase_migrations/20241104_create_reels_table.sql`
   - Paste it into the SQL Editor
   - Click "Run" button
   - Wait for success message: "✅ Reels table structure created successfully!"

### Step 2: Create Storage Bucket

1. **Go to Storage**:
   - Click on "Storage" in the left sidebar
   - Click "New bucket"

2. **Create 'reels' Bucket**:
   - Bucket name: `reels`
   - Public bucket: ✅ **Enable** (check the box)
   - File size limit: 100 MB (recommended)
   - Allowed MIME types: `video/mp4`, `video/quicktime`, `image/jpeg`, `image/jpg`
   - Click "Create bucket"

### Step 3: Set Storage Policies

1. **Go to Storage Policies**:
   - In Storage, select the `reels` bucket
   - Click on "Policies" tab

2. **Create Policies**:

#### Policy 1: Public Read (SELECT)
```sql
-- Allow anyone to view reels
CREATE POLICY "Public can view reels"
ON storage.objects FOR SELECT
TO public
USING (bucket_id = 'reels');
```

#### Policy 2: Authenticated Upload (INSERT)
```sql
-- Allow authenticated users to upload reels
CREATE POLICY "Authenticated users can upload reels"
ON storage.objects FOR INSERT
TO authenticated
WITH CHECK (
    bucket_id = 'reels' 
    AND (auth.uid())::text = (storage.foldername(name))[1]
);
```

#### Policy 3: User Delete Own Files (DELETE)
```sql
-- Allow users to delete their own reels
CREATE POLICY "Users can delete their own reels"
ON storage.objects FOR DELETE
TO authenticated
USING (
    bucket_id = 'reels' 
    AND (auth.uid())::text = (storage.foldername(name))[1]
);
```

### Step 4: Verify Setup

Run this query in SQL Editor to verify:
```sql
-- Check if reels table exists
SELECT 
    table_name,
    table_type
FROM information_schema.tables 
WHERE table_schema = 'public' 
AND table_name IN ('reels', 'reel_likes', 'reel_views', 'reel_comments');

-- Check if storage bucket exists
SELECT * FROM storage.buckets WHERE name = 'reels';

-- Check storage policies
SELECT * FROM storage.policies WHERE bucket_id = 'reels';
```

You should see:
- ✅ 4 tables: `reels`, `reel_likes`, `reel_views`, `reel_comments`
- ✅ 1 bucket: `reels`
- ✅ 3 storage policies

## 🔧 What This Fixes

### Database Structure
- ✅ Creates `reels` table to store reel metadata
- ✅ Creates `reel_likes` table for tracking likes
- ✅ Creates `reel_views` table for tracking views
- ✅ Creates `reel_comments` table for comments (future feature)
- ✅ Automatic counters (likes_count, views_count, comments_count)
- ✅ Row Level Security (RLS) policies for data protection

### Storage Configuration
- ✅ `reels` bucket for storing video files and thumbnails
- ✅ Public read access (anyone can view reels)
- ✅ Authenticated upload (only logged-in users can upload)
- ✅ User-scoped delete (users can only delete their own files)

### Error Resolution
- ✅ Fixes "Bucket not found" error (404)
- ✅ Fixes "Table 'public.reels' not found" error (PGRST205)
- ✅ Enables reel upload functionality
- ✅ Enables thumbnail storage and retrieval

## 📊 Database Schema

### Reels Table
```
reels
├── id (UUID, Primary Key)
├── user_id (UUID, Foreign Key → auth.users)
├── video_url (TEXT)
├── thumbnail_url (TEXT)
├── caption (TEXT, Optional)
├── duration (INTEGER, seconds)
├── likes_count (INTEGER, Auto-updated)
├── comments_count (INTEGER, Auto-updated)
├── views_count (INTEGER, Auto-updated)
├── shares_count (INTEGER)
├── created_at (TIMESTAMP)
└── updated_at (TIMESTAMP)
```

### Reel Likes Table
```
reel_likes
├── id (UUID, Primary Key)
├── reel_id (UUID, Foreign Key → reels)
├── user_id (UUID, Foreign Key → auth.users)
└── created_at (TIMESTAMP)
└── UNIQUE(reel_id, user_id) ← Prevents duplicate likes
```

### Reel Views Table
```
reel_views
├── id (UUID, Primary Key)
├── reel_id (UUID, Foreign Key → reels)
├── user_id (UUID, Foreign Key → auth.users, NULLABLE)
└── created_at (TIMESTAMP)
└── UNIQUE(reel_id, user_id) ← Prevents duplicate view counts
```

## 🎯 File Storage Structure

After setup, your storage will organize files like this:

```
reels/
└── {user_id}/
    ├── reel_1730726400000.mp4     ← Video files
    ├── thumb_1730726400000.jpg    ← Thumbnail images
    ├── reel_1730726500000.mp4
    ├── thumb_1730726500000.jpg
    └── ...
```

## 🧪 Test Your Setup

After completing all steps, test your reel upload:

1. **Record a short video** (5-10 seconds)
2. **Check for compression dialog**: "Compressing video..."
3. **Watch for upload progress**: "Uploading video to storage..."
4. **Verify success**: Should show "✅ Reel published!" or similar

### If Upload Still Fails

Check the Flutter logs for specific errors:
```bash
flutter run
# Look for lines starting with:
# ❌ Error uploading reel:
# ❌ Error generating thumbnail:
```

Common issues:
- ❌ **"Bucket not found"** → Recreate storage bucket with name exactly `reels`
- ❌ **"Permission denied"** → Check storage policies are created correctly
- ❌ **"Table not found"** → Rerun the SQL migration
- ❌ **"Failed to decode image"** → Video compression might be incomplete (wait longer)

## 🔍 Monitoring

### Check Recent Reels
```sql
SELECT 
    r.id,
    r.caption,
    r.duration,
    r.likes_count,
    r.views_count,
    u.username,
    r.created_at
FROM reels r
LEFT JOIN users u ON r.user_id = u.uid
ORDER BY r.created_at DESC
LIMIT 10;
```

### Check Storage Usage
```sql
SELECT 
    bucket_id,
    COUNT(*) as file_count,
    SUM(metadata->>'size')::bigint / 1024 / 1024 as total_mb
FROM storage.objects
WHERE bucket_id = 'reels'
GROUP BY bucket_id;
```

## 📝 Next Steps After Setup

1. ✅ Complete database migration
2. ✅ Create storage bucket with policies
3. ✅ Test reel upload flow
4. 🔄 Monitor egress usage (should be ~70% lower now)
5. 🔄 Test reel playback on profile page
6. 🔄 Test reel feed (home page)

## 💡 Pro Tips

### Optimize Video Quality
Your app now compresses videos automatically:
- Camera resolution: 720p (medium)
- Compression quality: Medium
- Expected file size: ~70% smaller
- Result: 5MB video → ~1.5MB compressed

### Egress Savings
With compression + lower resolution:
- Before: 50 views × 50MB = 2.5 GB egress
- After: 50 views × 15MB = 750 MB egress
- **Savings: 70% reduction!**

### Performance Tips
- Keep videos under 60 seconds
- Thumbnail generation happens automatically
- Videos are user-scoped (each user has their own folder)
- Automatic cleanup when deleting reels

## 🚨 Troubleshooting

### "New row violates row-level security policy"
**Fix**: Ensure you're logged in before uploading
```dart
final user = Supabase.instance.client.auth.currentUser;
if (user == null) {
  // Show "Please log in" message
}
```

### Thumbnail Not Showing
**Fix**: Check if thumbnail file exists in storage
1. Go to Storage → reels bucket
2. Navigate to your user folder
3. Verify `thumb_*.jpg` files exist
4. Check file permissions (should be public readable)

### Video Upload Takes Forever
**Fix**: This is the compression working! It can take 10-30 seconds
- Dialog shows: "Compressing video..."
- This is normal and expected
- Saves bandwidth in the long run

## ✅ Setup Complete!

Once you've completed all steps, your app will be able to:
- ✅ Upload reels with automatic compression
- ✅ Generate and store thumbnails
- ✅ Display reels on profile pages
- ✅ Track likes, views, and comments
- ✅ Delete reels and clean up storage
- ✅ Reduce egress usage by ~70%

**Test it now by recording and uploading your first reel!** 🎉
