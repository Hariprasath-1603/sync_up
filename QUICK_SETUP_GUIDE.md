# 🚀 Quick Setup Guide - User Registration System

## ⚡ 5-Minute Setup

### Step 1: Enable Firestore in Firebase Console

1. Go to: https://console.firebase.google.com/
2. Select your project: **syncup-social-app-2025**
3. Click **"Firestore Database"** in the left sidebar
4. Click **"Create database"** button
5. Select **"Start in production mode"** (we'll add rules next)
6. Choose a location (e.g., **us-central** or closest to you)
7. Click **"Enable"**

### Step 2: Set Firestore Security Rules

1. In Firestore Database, click the **"Rules"** tab
2. Replace the default rules with:

```javascript
rules_version = '2';
service cloud.firestore {
  match /databases/{database}/documents {
    
    // Users collection
    match /users/{userId} {
      // Anyone can read user profiles
      allow read: if true;
      
      // Only the user themselves can create their profile
      allow create: if request.auth != null && request.auth.uid == userId;
      
      // Only the user themselves can update their profile
      allow update: if request.auth != null && request.auth.uid == userId;
      
      // Only the user themselves can delete their profile
      allow delete: if request.auth != null && request.auth.uid == userId;
    }
    
    // Default deny all other collections
    match /{document=**} {
      allow read, write: if false;
    }
  }
}
```

3. Click **"Publish"** button

### Step 3: Create Firestore Indexes (Optional but Recommended)

1. In Firestore Database, click the **"Indexes"** tab
2. Click **"Add Index"** button
3. Add these indexes:

**Index 1: Username Search**
- Collection ID: `users`
- Field 1: `username` → Ascending
- Click **"Create"**

**Index 2: Email Search**
- Collection ID: `users`
- Field 1: `email` → Ascending
- Click **"Create"**

### Step 4: Update Firestore Rules File (Local)

Your `firestore.rules` file at project root should contain:

```javascript
rules_version = '2';
service cloud.firestore {
  match /databases/{database}/documents {
    match /users/{userId} {
      allow read: if true;
      allow create: if request.auth != null && request.auth.uid == userId;
      allow update: if request.auth != null && request.auth.uid == userId;
      allow delete: if request.auth != null && request.auth.uid == userId;
    }
    match /{document=**} {
      allow read, write: if false;
    }
  }
}
```

### Step 5: Run the App

```powershell
# Clean and rebuild
flutter clean
flutter pub get

# Run on your device
flutter run
```

---

## ✅ Testing the Features

### Test 1: Username Validation

1. Launch app → Click **"Sign Up"**
2. Type username: `john_doe`
   - Should show **loading spinner** for a moment
   - Then show **green checkmark** ✅ and "Username is available"
3. Type username: `a` (too short)
   - Should show error: "Username must be at least 3 characters"
4. Type username with your existing account
   - Should show **red X** ❌ and "Username is already taken"

### Test 2: Complete Signup

1. Fill in all fields:
   - Username: `testuser123` (unique)
   - Email: `testuser@example.com`
   - Password: `Test@1234` (strong)
   - Confirm Password: `Test@1234`
   - Click **"Next"**
2. Fill Page 2:
   - Date of Birth: Select a date
   - Gender: Select one
   - Phone: Enter your phone
   - Location: Enter your city (optional)
   - Click **"Sign Up"**
3. Should show **"Account created successfully!"** green message
4. Should navigate to **Sign In page**

### Test 3: Verify in Firebase

1. Go to Firebase Console → **Firestore Database**
2. You should see a new document in `users` collection
3. Click on the document to view all fields
4. Verify:
   - ✅ username is lowercase
   - ✅ usernameDisplay has your original casing
   - ✅ All personal details are saved
   - ✅ createdAt timestamp is present

### Test 4: Forgot Password (Email)

1. On Sign In page, click **"Forgot Password?"**
2. Make sure **"Email"** tab is selected
3. Enter email: `testuser@example.com`
4. Click **"Send Reset Link"**
5. Should show success dialog
6. Check your email inbox for reset link

### Test 5: Forgot Password (Username)

1. On Forgot Password page, click **"Username"** tab
2. Enter username: `testuser123`
3. Click **"Send Reset Link"**
4. Should show success dialog
5. Check email (associated with that username) for reset link

---

## 🔧 Troubleshooting

### Problem: "Permission denied" error when creating user

**Solution:**
- Make sure you published the Firestore security rules
- Check that rules allow `create: if request.auth != null && request.auth.uid == userId`
- Verify user is signed in to Firebase Auth before creating Firestore document

### Problem: Username check always shows "available" even for taken usernames

**Solution:**
- Check Firebase Console → Firestore Database
- Verify `users` collection exists with documents
- Check that `username` field exists and is lowercase
- Wait 1-2 minutes for indexes to build

### Problem: "Index not found" error

**Solution:**
- Go to Firebase Console → Firestore → Indexes tab
- Firebase will suggest creating missing indexes
- Click the link in the error message to auto-create index
- Wait 2-3 minutes for index to build

### Problem: Password reset email not received

**Solution:**
- Check spam/junk folder
- Verify email is correct in Firestore database
- Check Firebase Console → Authentication → Templates
- Make sure email is verified with Firebase (check Authentication settings)

### Problem: App crashes on signup

**Solution:**
```powershell
# Clean and rebuild
flutter clean
flutter pub get
flutter run
```

---

## 📊 Firebase Console Checklist

Before testing, verify these in Firebase Console:

- [ ] Firestore Database is **enabled**
- [ ] Firestore **rules** are published
- [ ] Authentication **Email/Password** provider is **enabled**
- [ ] Authentication **Google** provider is **enabled** (with SHA-1)
- [ ] Firestore **indexes** are created (optional but recommended)
- [ ] Test user created in **Authentication** tab
- [ ] Test user document exists in **Firestore** → `users` collection

---

## 🎯 Expected Results

### After Successful Setup:

✅ **Username validation works in real-time**
- Shows spinner while checking
- Shows green checkmark for available usernames
- Shows red X for taken usernames
- Shows error text for invalid format

✅ **Signup creates complete user profile**
- Creates Firebase Auth account
- Creates Firestore user document
- All fields properly saved
- Username is unique and case-insensitive

✅ **Forgot password works with email or username**
- Toggles between email and username input
- Finds user in database
- Sends reset email to registered email
- Shows success dialog

---

## 🚀 Next Steps

After successful setup, you can:

1. **Customize user profile fields** (add more fields to UserModel)
2. **Add profile photo upload** (Firebase Storage integration)
3. **Implement email verification** (require email verification)
4. **Add username change feature** (allow users to update username)
5. **Build user profile page** (display user information)
6. **Implement follow/unfollow** (social features)

---

## 📝 Quick Commands Reference

```powershell
# Clean and rebuild
flutter clean
flutter pub get

# Run app
flutter run

# Check for errors
flutter analyze

# Deploy Firestore rules (if using Firebase CLI)
firebase deploy --only firestore:rules

# Deploy Firestore indexes (if using Firebase CLI)
firebase deploy --only firestore:indexes
```

---

**🎉 You're all set! Start testing your new user registration system!**
