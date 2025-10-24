# 🚀 Supabase Setup Guide for SyncUp

## ✅ What's Done:
1. ✅ Added `supabase_flutter: ^2.3.4` to pubspec.yaml
2. ✅ Removed Firebase Storage and Firestore dependencies
3. ✅ Created `SupabaseConfig` file
4. ✅ Created `SupabaseStorageService` for file uploads
5. ✅ Updated `main.dart` to initialize Supabase
6. ✅ Updated `edit_profile_page.dart` to use Supabase

## 📋 Setup Steps (Takes 10 minutes):

### Step 1: Create Supabase Account & Project
1. Go to [supabase.com](https://supabase.com)
2. Click "Start your project" → Sign up (FREE, no credit card)
3. Click "New Project":
   - Name: `syncup-social`
   - Database Password: (SAVE THIS!) Example: `YourSecurePassword123!`
   - Region: Choose closest to you (e.g., `Asia Southeast (Singapore)`)
4. Click "Create new project" (takes ~2 minutes)

### Step 2: Get Your API Keys
1. Go to **Settings** (⚙️ icon) → **API**
2. Copy these values:
   - **Project URL**: `https://xxxxx.supabase.co`
   - **anon/public key**: (long string starting with `eyJ...`)

### Step 3: Update Config File
Open `lib/core/config/supabase_config.dart` and replace:
```dart
static const String supabase URL = 'YOUR_SUPABASE_URL'; // ← Paste Project URL here
static const String supabaseAnonKey = 'YOUR_SUPABASE_ANON_KEY'; // ← Paste anon key here
```

### Step 4: Create Database Tables
1. Go to **SQL Editor** in Supabase dashboard
2. Click "New query"
3. Paste this SQL:

```sql
-- Create users table
CREATE TABLE public.users (
  uid TEXT PRIMARY KEY,
  username TEXT UNIQUE NOT NULL,
  username_display TEXT NOT NULL,
  email TEXT UNIQUE NOT NULL,
  display_name TEXT,
  photo_url TEXT,
  bio TEXT,
  date_of_birth TEXT,
  gender TEXT,
  phone TEXT,
  location TEXT,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  last_active TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  followers_count INTEGER DEFAULT 0,
  following_count INTEGER DEFAULT 0,
  posts_count INTEGER DEFAULT 0,
  followers TEXT[] DEFAULT '{}',
  following TEXT[] DEFAULT '{}'
);

-- Create posts table
CREATE TABLE public.posts (
  id TEXT PRIMARY KEY,
  user_id TEXT NOT NULL REFERENCES public.users(uid),
  username TEXT NOT NULL,
  user_photo TEXT,
  caption TEXT,
  media_url TEXT NOT NULL,
  media_type TEXT NOT NULL,
  likes INTEGER DEFAULT 0,
  comments INTEGER DEFAULT 0,
  shares INTEGER DEFAULT 0,
  saves INTEGER DEFAULT 0,
  timestamp TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
  location TEXT,
  is_archived BOOLEAN DEFAULT FALSE,
  is_pinned BOOLEAN DEFAULT FALSE
);

-- Create indexes for better performance
CREATE INDEX idx_posts_user_id ON public.posts(user_id);
CREATE INDEX idx_posts_timestamp ON public.posts(timestamp DESC);
CREATE INDEX idx_users_username ON public.users(username);

-- Enable Row Level Security (RLS)
ALTER TABLE public.users ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.posts ENABLE ROW LEVEL SECURITY;

-- RLS Policies for users table
CREATE POLICY "Users are viewable by everyone" ON public.users
  FOR SELECT USING (true);

CREATE POLICY "Users can update own data" ON public.users
  FOR UPDATE USING (auth.uid()::text = uid);

CREATE POLICY "Users can insert own data" ON public.users
  FOR INSERT WITH CHECK (auth.uid()::text = uid);

-- RLS Policies for posts table
CREATE POLICY "Posts are viewable by everyone" ON public.posts
  FOR SELECT USING (true);

CREATE POLICY "Users can insert own posts" ON public.posts
  FOR INSERT WITH CHECK (auth.uid()::text = user_id);

CREATE POLICY "Users can update own posts" ON public.posts
  FOR UPDATE USING (auth.uid()::text = user_id);

CREATE POLICY "Users can delete own posts" ON public.posts
  FOR DELETE USING (auth.uid()::text = user_id);
```

4. Click **RUN** (or press F5)
5. You should see: "Success. No rows returned"

### Step 5: Create Storage Buckets
1. Go to **Storage** in Supabase dashboard
2. Click "New bucket":
   - Name: `profile-photos`
   - Public bucket: ☑️ **Checked**
   - Click "Create bucket"

3. Repeat for:
   - `posts` (public bucket)
   - `stories` (public bucket)

### Step 6: Set Storage Policies
For each bucket (`profile-photos`, `posts`, `stories`):
1. Click on the bucket
2. Go to **Policies** tab
3. Click "New policy" → "For full customization"
4. Policy name: `Allow public read`
   - Operation: `SELECT`
   - Policy definition: `true`
   - Click "Save"

5. Click "New policy" again
   - Policy name: `Allow authenticated users to upload`
   - Operation: `INSERT`
   - Policy definition: `(auth.role() = 'authenticated'::text)`
   - Click "Save"

6. Click "New policy" again
   - Policy name: `Allow users to update own files`
   - Operation: `UPDATE`
   - Policy definition: `(auth.uid() = owner)`
   - Click "Save"

7. Click "New policy" again
   - Policy name: `Allow users to delete own files`
   - Operation: `DELETE`
   - Policy definition: `(auth.uid() = owner)`
   - Click "Save"

### Step 7: Test the App!
1. Run `flutter pub get` (if not already done)
2. Run your app: `flutter run`
3. Try uploading a profile photo - it should work now! 🎉

## 🔄 What Still Needs Migration:

### Files that still use Firestore (need to be updated):
- ✅ `edit_profile_page.dart` - DONE (uses Supabase)
- ⏳ `database_service.dart` - Needs Supabase version
- ⏳ `auth_service.dart` - Needs Supabase queries
- ⏳ `post_service.dart` - Needs Supabase queries
- ⏳ `comment_service.dart` - Needs Supabase queries
- ⏳ `post_fetch_service.dart` - Needs Supabase queries
- ⏳ `sign_up_page.dart` - Needs to save to Supabase table

## 🎯 Quick Migration Steps:

### To migrate a service file:
1. Replace `FirebaseFirestore.instance` with `Supabase.instance.client`
2. Replace `.collection('users')` with `.from('users')`
3. Replace `.doc(id)` with `.select().eq('uid', id).single()`
4. Replace `.update({})` with `.update({}).eq('uid', id)`
5. Replace `.set({})` with `.insert({})`
6. Replace `FieldValue.serverTimestamp()` with `DateTime.now().toIso8601String()`
7. Replace snake_case for column names (photoURL → photo_url)

## 📊 Cost Comparison:

| Feature | Firebase (Blaze) | Supabase (Free) |
|---------|------------------|-----------------|
| Storage | $0.026/GB | 1GB FREE |
| Database | $0.06/100K reads | Unlimited |
| Auth | FREE | FREE |
| Bandwidth | $0.12/GB | 2GB/month |
| **Monthly Cost** | **~$25-50** | **$0** |

## ✅ Testing Checklist:
- [ ] Supabase project created
- [ ] API keys added to config
- [ ] Database tables created
- [ ] Storage buckets created
- [ ] Storage policies set
- [ ] `flutter pub get` completed
- [ ] App runs without errors
- [ ] Profile photo upload works
- [ ] Profile data saves correctly

## 🆘 Troubleshooting:

### "Target of URI doesn't exist: 'package:supabase_flutter'"
**Fix:** Run `flutter pub get`

### "Undefined name 'Supabase'"
**Fix:** Import at top of file:
```dart
import 'package:supabase_flutter/supabase_flutter.dart';
```

### "Row Level Security policy violation"
**Fix:** Make sure you created the RLS policies in Step 4

### "Storage bucket not found"
**Fix:** Create the buckets in Step 5

### "Permission denied"
**Fix:** Set the storage policies in Step 6

## 🎉 Next Steps:
1. Complete Step 1-7 above
2. Test profile photo upload
3. Let me know if you want me to migrate the remaining files!

---
**Note:** Keep Firebase Auth (it's free and works great!). We're only replacing Storage and Database with Supabase.
