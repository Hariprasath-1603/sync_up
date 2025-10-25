# Profile & Auth Improvements - Implementation Tasks

## ✅ Completed
1. Profile setup flow after signup (profile picture + bio pages)
2. Database verification columns added

## 🔧 In Progress / To Do

### 1. **Add Full Name Field to Signup** ⚠️ HIGH PRIORITY
- [x] Add `_fullNameController` to state
- [ ] Add Full Name text field **ABOVE** username field in signup form
- [ ] Update signup metadata to include `full_name`
- [ ] Store `full_name` in users table during OTP completion

**Files to modify:**
- `lib/features/auth/sign_up_page.dart` - Add field in form UI (around line 500-600)
- `lib/features/auth/otp_verification_page.dart` - Include `full_name` in user data

---

### 2. **Fix Profile Picture Display** ⚠️ HIGH PRIORITY
**Problem:** Profile picture not showing on profile page

**Solution:**
- Check `MyProfilePage` (`lib/features/profile/profile_page.dart`)
- Ensure it reads `photo_url` from users table
- Use `CachedNetworkImage` or `Image.network` with proper error handling
- Show placeholder if `photo_url` is null

**Files to modify:**
- `lib/features/profile/profile_page.dart`

---

### 3. **Gray Out Fields in Edit Profile** ⚠️ MEDIUM PRIORITY
Make these fields **read-only** (grayed out) in edit profile:
- Phone number
- Email  
- Location

**Implementation:**
- Add `enabled: false` to TextFormField
- Style with gray text color
- Add info icon/tooltip explaining why locked

**Files to modify:**
- `lib/features/profile/edit_profile_page.dart`

---

### 4. **Username Change Restriction (30-day cooldown)** ⚠️ MEDIUM PRIORITY
**Requirements:**
- Track `username_last_changed` timestamp in users table
- When user clicks username field in edit profile → open new page
- New page shows:
  - Old username (grayed out, read-only)
  - New username field
  - Real-time availability check
  - Warning if username is taken
  - Enforce 30-day cooldown
  
**Database Migration:**
```sql
ALTER TABLE users 
ADD COLUMN IF NOT EXISTS username_last_changed TIMESTAMP;

-- Set initial value for existing users
UPDATE users 
SET username_last_changed = created_at 
WHERE username_last_changed IS NULL;
```

**New files to create:**
- `lib/features/profile/change_username_page.dart`

**Files to modify:**
- `lib/features/profile/edit_profile_page.dart` - Make username field clickable, navigate to change page
- Update username change logic to check cooldown and update timestamp

---

### 5. **Private/Public Profile Toggle** ⚠️ MEDIUM PRIORITY
**Requirements:**
- Switch/toggle button in edit profile or settings
- Store `is_private` boolean in users table
- When `is_private = true`:
  - Only followers can see posts
  - Profile shows "Private Account" to non-followers
  - Follow requests require approval

**Database Migration:**
```sql
ALTER TABLE users 
ADD COLUMN IF NOT EXISTS is_private BOOLEAN DEFAULT false;
```

**Files to modify:**
- `lib/features/profile/edit_profile_page.dart` or settings page
- Implement toggle UI
- Update DB on toggle change
- Add privacy logic to post visibility queries

---

### 6. **Add Logout Button in Settings → Account** ⚠️ HIGH PRIORITY
**Location:** Settings → Account → Above "Deactivate Account"

**Implementation:**
- Add "Logout" button with confirmation dialog
- Clear Supabase session: `Supabase.instance.client.auth.signOut()`
- Clear `PreferencesService` data
- Navigate to `/signin`

**Files to modify:**
- `lib/features/settings/pages/account_page.dart`

---

### 7. **Rename "Website" to "URL"** ⚠️ LOW PRIORITY
Simple text change in edit profile page.

**Files to modify:**
- `lib/features/profile/edit_profile_page.dart`

---

### 8. **Save Changes Button - Persist to DB** ⚠️ HIGH PRIORITY
**Problem:** Save Changes button doesn't update database

**Solution:**
- Wire up save button to call Supabase update
- Update all editable fields in users table
- Show success/error feedback
- Refresh UI with new data immediately

**Example:**
```dart
Future<void> _saveChanges() async {
  final user = Supabase.instance.client.auth.currentUser;
  if (user == null) return;
  
  await Supabase.instance.client.from('users').update({
    'display_name': _displayNameController.text,
    'bio': _bioController.text,
    'website': _websiteController.text,
    // ... other editable fields
    'updated_at': DateTime.now().toIso8601String(),
  }).eq('uid', user.id);
  
  // Refresh UI
  setState(() { /* reload user data */ });
}
```

**Files to modify:**
- `lib/features/profile/edit_profile_page.dart`

---

## Priority Order for Implementation

1. **Fix Profile Picture Display** - Users can't see their uploaded photo
2. **Add Logout Button** - Critical UX feature
3. **Save Changes Button** - Core functionality broken
4. **Add Full Name Field** - Required for complete profile
5. **Gray Out Fields** - Prevent confusion
6. **Username Change Page** - Better UX than inline editing
7. **Private/Public Toggle** - Privacy feature
8. **Rename Website → URL** - Minor text change

---

## Database Migrations Needed

Run these in Supabase SQL Editor:

```sql
-- Add full_name column
ALTER TABLE users 
ADD COLUMN IF NOT EXISTS full_name TEXT;

-- Add username change tracking
ALTER TABLE users 
ADD COLUMN IF NOT EXISTS username_last_changed TIMESTAMP DEFAULT NOW();

-- Add privacy setting
ALTER TABLE users 
ADD COLUMN IF NOT EXISTS is_private BOOLEAN DEFAULT false;

-- Update existing users
UPDATE users 
SET username_last_changed = created_at 
WHERE username_last_changed IS NULL;
```

---

## Testing Checklist

- [ ] Sign up with full name
- [ ] Profile picture displays correctly after upload
- [ ] Email/phone/location fields are grayed out in edit profile
- [ ] Username change opens new page
- [ ] Username change checks 30-day cooldown
- [ ] Username availability check works in real-time
- [ ] Private/public toggle updates database
- [ ] Logout button clears session and navigates to sign-in
- [ ] Save Changes updates all fields in database
- [ ] UI refreshes immediately after save

