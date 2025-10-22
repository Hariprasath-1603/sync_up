# 🔧 Google Sign-In Platform Exception Fix

## ❌ Problem Identified

Your **SHA-1 fingerprint mismatch** is causing the Google Sign-In to fail.

### Current System SHA-1:
```
FA:F9:44:33:32:EE:4C:E8:C1:D1:9F:B3:80:95:42:35:B8:28:A0:40
```

### Firebase Configured SHA-1 (in google-services.json):
```
94524464895e2de3f68e738233b7bde59d4a5ef0
```

**These don't match!** After your Windows 11 reinstallation, Android Studio generated a new debug keystore with a different SHA-1.

---

## ✅ STEP-BY-STEP FIX (5 minutes)

### Step 1: Add Your New SHA-1 to Firebase

1. **Go to Firebase Console**: https://console.firebase.google.com/
2. **Select your project**: `syncup-social-app-2025`
3. **Click the gear icon** (⚙️) next to "Project Overview" → **Project settings**
4. **Scroll down** to "Your apps" section
5. **Click on your Android app** (com.example.sync_up)
6. **Scroll to "SHA certificate fingerprints"**
7. **Click "Add fingerprint"** button
8. **Paste this SHA-1**:
   ```
   FA:F9:44:33:32:EE:4C:E8:C1:D1:9F:B3:80:95:42:35:B8:28:A0:40
   ```
9. **Click "Save"**

### Step 2: Add SHA-256 (Optional but Recommended)

10. **Click "Add fingerprint"** again
11. **Paste this SHA-256**:
    ```
    A3:CE:F9:C7:83:F3:B2:61:68:DD:C0:D7:98:6F:61:6C:2E:CD:7A:37:DA:E7:F4:08:70:70:56:C9:3A:BC:00:21
    ```
12. **Click "Save"**

### Step 3: Enable Google Sign-In Provider (If Not Already)

13. In Firebase Console, click **Authentication** (left sidebar)
14. Click **Sign-in method** tab
15. Find **Google** in the list
16. If disabled, click on it and **enable** the toggle
17. Select a **support email** from the dropdown
18. Click **Save**

### Step 4: Download Updated google-services.json

19. Back in **Project Settings** → Your Android app
20. Click **Download google-services.json** button
21. **Replace** the file at: `android/app/google-services.json`

### Step 5: Clean and Rebuild

Run these commands in PowerShell:

```powershell
# Navigate to project root (if not already there)
cd E:\sync_up

# Clean build cache
flutter clean

# Get dependencies
flutter pub get

# Run the app
flutter run
```

### Step 6: Test Google Sign-In

1. Launch the app
2. Click the **Google Sign-In** button (rainbow G icon)
3. Select your Google account
4. Should successfully sign in and navigate to home screen ✅

---

## 🔍 Why This Happened

After your **Windows 11 fresh reinstallation**:
- Android Studio created a new debug keystore at `C:\Users\harip\.android\debug.keystore`
- This new keystore has a different SHA-1 fingerprint
- Firebase still had the old SHA-1 from before the reinstall
- Google Sign-In requires the SHA-1 to match for security

---

## ✅ Verification Checklist

Before testing, make sure:

- [ ] New SHA-1 added to Firebase: `FA:F9:44:33:32:EE:4C:E8:C1:D1:9F:B3:80:95:42:35:B8:28:A0:40`
- [ ] Google Sign-In provider is **enabled** in Firebase Authentication
- [ ] Downloaded **fresh google-services.json** and replaced in `android/app/`
- [ ] Ran `flutter clean` and `flutter pub get`
- [ ] Waited 2-3 minutes for Firebase changes to propagate

---

## 🎯 Expected Success Output

When working correctly, console will show:

```
I/flutter: Starting Google Sign-In...
I/flutter: AuthService: Starting Google Sign-In flow...
I/flutter: AuthService: GoogleSignInAccount received: your@gmail.com
I/flutter: AuthService: Getting authentication details...
I/flutter: AuthService: Auth tokens received - accessToken: true, idToken: true
I/flutter: AuthService: Credential created, signing in to Firebase...
I/flutter: AuthService: Firebase sign-in successful! User: your@gmail.com
I/flutter: User signed in successfully: your@gmail.com
```

---

## 🆘 Still Getting Error?

### If error persists after adding SHA-1:

1. **Wait 5 minutes** - Firebase changes need time to propagate
2. **Check Google Cloud Console**:
   - Go to: https://console.cloud.google.com/
   - Select project: `syncup-social-app-2025`
   - Search for "Identity Toolkit API" or "Google Sign-In API"
   - Click **Enable** if not already enabled
3. **Try on a real device** instead of emulator
4. **Verify package name** matches everywhere:
   - Firebase: `com.example.sync_up` ✅
   - AndroidManifest.xml: `com.example.sync_up` ✅
   - build.gradle.kts: `com.example.sync_up` ✅

### If you see "Error 10" (Developer Error):
- This means Firebase doesn't recognize your app
- Double-check SHA-1 is correct
- Make sure you downloaded the updated google-services.json

### If you see "Error 12500" (Sign-In Cancelled):
- User cancelled the sign-in flow
- Not an error, just means they backed out

---

## 📱 Quick Command Reference

### Get SHA-1 and SHA-256 again (if needed):
```powershell
keytool -list -v -keystore "$env:USERPROFILE\.android\debug.keystore" -alias androiddebugkey -storepass android -keypass android
```

### Clean rebuild:
```powershell
flutter clean; flutter pub get; flutter run
```

---

## 🎉 After It Works

Once Google Sign-In is working, you can:
- Sign in with any Google account
- User data is stored in Firebase
- Session persists across app restarts
- Profile picture and name are automatically fetched

---

**Important**: After adding the SHA-1 to Firebase, **wait 2-3 minutes** before testing. Firebase needs time to sync the configuration globally.
