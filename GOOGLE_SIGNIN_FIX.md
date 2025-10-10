# Google Sign-In Error 7 Fix

## Error You're Seeing:
```
PlatformException(network_error, com.google.android.gms.common.api.ApiException: 7: , null, null)
```

This is **Error Code 7** which means configuration issue, not actual network error.

## ✅ What You've Already Done:
- ✅ Added SHA-1 and SHA-256 to Firebase
- ✅ Updated google-services.json
- ✅ Installed google_sign_in package
- ✅ Gradle configuration is correct

## 🔧 Required Steps to Fix:

### Step 1: Enable Google Sign-In in Firebase Console

1. Go to: https://console.firebase.google.com/
2. Select project: **syncup-social-app-2025**
3. Click **Authentication** (left sidebar)
4. Click **Sign-in method** tab
5. Find **Google** in the providers list
6. Click on **Google**
7. **Enable** the toggle switch (turn it ON)
8. Select your **Support email** from dropdown
9. Click **Save**

### Step 2: Verify SHA-1 is Added Correctly

1. In Firebase Console → **Project Settings** (gear icon)
2. Scroll to **Your apps** section
3. Click on your Android app
4. Under **SHA certificate fingerprints**, verify:
   - SHA-1: `94524464895e2de3f68e738233b7bde59d4a5ef0` (from your google-services.json)
5. If not there, click **Add fingerprint** and paste it

### Step 3: Enable Google Sign-In API in Google Cloud Console

This is often the missing step!

1. Go to: https://console.cloud.google.com/
2. Select project: **syncup-social-app-2025**
3. In the search bar, type: **"Google Sign-In API"** or **"Google+ API"**
4. Click on **Google Sign-In API** or **Identity Toolkit API**
5. Click **Enable**
6. Wait for it to enable (takes 1-2 minutes)

### Step 4: Rebuild the App Completely

After making the above changes, do a complete clean build:

```powershell
# Stop the running app (Ctrl+C in terminal)

# Clean all build files
flutter clean

# Get dependencies
flutter pub get

# Rebuild and run
flutter run
```

### Step 5: Wait for Configuration to Propagate

Sometimes Firebase configuration changes take **5-10 minutes** to propagate. If it still doesn't work:

1. Wait 5-10 minutes after making changes in Firebase Console
2. Close and restart the app completely
3. Try again

## 🔍 Alternative: Get Your Current SHA-1

If you're not sure if your SHA-1 is correct, run this command:

```powershell
# In project root
cd android
./gradlew signingReport
```

Look for the **debug** variant SHA-1:
```
Variant: debug
Config: debug
Store: C:\Users\PREDATOR\.android\debug.keystore
Alias: AndroidDebugKey
MD5: ...
SHA1: YOUR_SHA1_HERE
SHA-256: YOUR_SHA256_HERE
```

Copy the SHA1 value and add it to Firebase.

## 🔐 Alternative Method: Use keytool

```powershell
keytool -list -v -keystore "%USERPROFILE%\.android\debug.keystore" -alias androiddebugkey -storepass android -keypass android
```

## ✅ Verification Checklist

Before running the app again, verify:

- [ ] Google Sign-In is **enabled** in Firebase Authentication
- [ ] SHA-1 fingerprint is added in Firebase Project Settings
- [ ] google-services.json is **up-to-date** (download fresh from Firebase)
- [ ] Google Sign-In API or Identity Toolkit API is **enabled** in Google Cloud Console
- [ ] You've run `flutter clean` and `flutter pub get`
- [ ] You've waited 5-10 minutes after making Firebase changes

## 🎯 Expected Success Output

When it works, you should see in the console:

```
I/flutter: Starting Google Sign-In...
I/flutter: AuthService: Starting Google Sign-In flow...
I/flutter: AuthService: GoogleSignInAccount received: your@email.com
I/flutter: AuthService: Getting authentication details...
I/flutter: AuthService: Auth tokens received - accessToken: true, idToken: true
I/flutter: AuthService: Credential created, signing in to Firebase...
I/flutter: AuthService: Firebase sign-in successful! User: your@email.com
I/flutter: User signed in successfully: your@email.com
```

## 🆘 Still Not Working?

If you've tried everything above and it still fails:

1. **Download fresh google-services.json**:
   - Firebase Console → Project Settings → Your Android app
   - Click "Download google-services.json"
   - Replace `android/app/google-services.json`

2. **Verify package name matches**:
   - Firebase: `com.example.sync_up`
   - AndroidManifest.xml: `com.example.sync_up`
   - build.gradle.kts: `applicationId = "com.example.sync_up"`

3. **Check Firebase project has billing enabled** (for production):
   - Some Firebase features require Blaze plan
   - For testing, Spark (free) plan should work

4. **Try on a real device instead of emulator**:
   - Some emulators have issues with Google Play Services
   - Connect a physical Android device and test

## 📱 Testing Steps

1. Stop the app if running (Ctrl+C)
2. Run: `flutter clean`
3. Run: `flutter pub get`
4. Run: `flutter run`
5. Wait for app to launch
6. Tap the Google Sign-In button (rainbow G)
7. Select a Google account
8. Check the console logs
9. Should navigate to home screen with success message

---

**Remember**: Configuration changes in Firebase can take 5-10 minutes to propagate globally!
