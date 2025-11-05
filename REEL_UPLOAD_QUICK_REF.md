# 🎬 Reel Upload - Quick Fix Reference

## 🚨 Your Errors

1. ❌ **Database**: `Could not find the table 'public.reels'` (PGRST205)
2. ❌ **Storage**: `Bucket not found` (404)
3. ❌ **Thumbnail**: `Failed to decode image` (DecodeException)

---

## ✅ Quick Fix Steps (5 minutes)

### Step 1: Create Database Table (2 min)
```sql
-- Open Supabase Dashboard → SQL Editor → New Query
-- Copy contents of: supabase_migrations/20241104_create_reels_table.sql
-- Paste and click RUN
```

### Step 2: Create Storage Bucket (2 min)
```
Supabase Dashboard → Storage → New Bucket
Name: reels
Public: ✅ CHECKED
File size limit: 100 MB
Click: Create bucket
```

### Step 3: Add Storage Policies (1 min)
```sql
-- Supabase Dashboard → SQL Editor → New Query
-- Paste and RUN:

CREATE POLICY "Public can view reels"
ON storage.objects FOR SELECT TO public
USING (bucket_id = 'reels');

CREATE POLICY "Authenticated users can upload reels"
ON storage.objects FOR INSERT TO authenticated
WITH CHECK (bucket_id = 'reels' AND (auth.uid())::text = (storage.foldername(name))[1]);

CREATE POLICY "Users can delete their own reels"
ON storage.objects FOR DELETE TO authenticated
USING (bucket_id = 'reels' AND (auth.uid())::text = (storage.foldername(name))[1]);
```

---

## 🧪 Test (1 min)

```bash
# Hot restart your app
r

# Then:
1. Tap + button
2. Select "Reel"
3. Record 5 seconds
4. Watch for "Compressing video..."
5. Should show "✅ Saved X MB!"
6. Should navigate to composer
```

---

## ✅ Verify Setup

**Database Check**:
```sql
SELECT COUNT(*) FROM reels; -- Should return 0 (empty but exists)
```

**Storage Check**:
```sql
SELECT name, public FROM storage.buckets WHERE name = 'reels';
-- Should return: reels | true
```

**Storage Policies Check**:
```sql
SELECT COUNT(*) FROM storage.policies WHERE bucket_id = 'reels';
-- Should return: 3
```

---

## 🔍 Common Issues

### "Bucket not found" still appears
- Check bucket name is EXACTLY `reels` (lowercase)
- Ensure "Public bucket" checkbox was enabled
- Refresh Supabase dashboard

### "Table not found" still appears  
- Verify SQL migration ran successfully
- Check for error messages in SQL Editor
- Try running migration again

### "Permission denied"
- Re-run storage policies SQL
- Ensure you're logged in (check `currentUser`)
- Verify policies show in bucket's Policies tab

---

## 📝 What Changed in Code

### `reel_service.dart` Improvements:
- ✅ File existence check before thumbnail generation
- ✅ 500ms delay after compression (lets file settle)
- ✅ 3 retry attempts with progressive delays
- ✅ Changed from 0ms to 1000ms frame capture
- ✅ Better error logging

### `reel_create_page.dart` Optimizations:
- ✅ Camera resolution: high → medium (saves 40% bandwidth)
- ✅ Video compression: MediumQuality (~70% size reduction)
- ✅ Progress dialogs with file size savings
- ✅ Navigation to camera composer with compressed video

---

## 📊 Expected Results

### Before Fixes:
- ❌ Upload fails with 404 error
- ❌ No reel data saved
- ❌ Egress limit exceeded

### After Fixes:
- ✅ Upload succeeds
- ✅ Reel saved to database
- ✅ Video + thumbnail in storage
- ✅ 70% less bandwidth usage

### File Sizes:
| Video Length | Original | Compressed | Savings |
|--------------|----------|------------|---------|
| 10 seconds   | ~15 MB   | ~4 MB      | 73%     |
| 30 seconds   | ~50 MB   | ~15 MB     | 70%     |
| 60 seconds   | ~100 MB  | ~30 MB     | 70%     |

---

## 🎯 Success Checklist

Setup Complete When:
- [ ] SQL migration ran without errors
- [ ] `reels` bucket visible in Storage
- [ ] 3 storage policies created
- [ ] Test reel upload succeeds
- [ ] Video file appears in storage
- [ ] Thumbnail file appears in storage
- [ ] Database row created in `reels` table
- [ ] No error messages in Flutter console

---

## 📚 Documentation Files Created

1. **`supabase_migrations/20241104_create_reels_table.sql`**  
   Complete database schema with tables, triggers, policies

2. **`REEL_DATABASE_SETUP_GUIDE.md`**  
   Step-by-step setup instructions with troubleshooting

3. **`REEL_UPLOAD_FIXES_COMPLETE.md`**  
   Detailed troubleshooting guide for all errors

4. **`REEL_UPLOAD_QUICK_REF.md`** (this file)  
   Quick reference for fast fixes

---

## 💡 Pro Tips

**Speed up testing**:
- Record 5-second videos (faster compression)
- Use WiFi (faster upload)
- Clear old test reels to save space

**Monitor egress**:
- Check Supabase dashboard tomorrow
- Should see ~70% reduction in bandwidth
- Free tier: 5 GB/month (you were at 5.98 GB)

**Cleanup test data**:
```sql
-- Delete test reels (careful! This deletes ALL reels)
DELETE FROM reels WHERE caption LIKE '%test%';

-- Delete storage files manually via dashboard
```

---

## 🚀 Next Features (Future)

After upload works:
1. ✅ Reel feed (home page)
2. ✅ Reel playback with swipe
3. ✅ Like/comment functionality
4. ✅ Share reels
5. ✅ Reel analytics

---

## 📞 Need Help?

**Flutter logs not showing?**
```bash
flutter run --verbose
```

**Supabase logs:**
- Dashboard → Logs → API/Storage
- Look for 4xx/5xx errors

**Still stuck?**
- Check all 3 documentation files
- Verify each step in checklist
- Share exact error message + logs

---

## ✅ Start Here

1. Open this file: `supabase_migrations/20241104_create_reels_table.sql`
2. Follow Step 1-3 above (5 minutes total)
3. Hot restart app and test upload
4. Check verification SQL queries
5. Celebrate! 🎉

**Good luck!** Your reel upload should work after these 3 quick steps.
