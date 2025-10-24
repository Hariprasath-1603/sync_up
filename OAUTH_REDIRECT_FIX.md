# 🔧 Fix Google OAuth Redirect Issue - UPDATED

## Problem
After clicking "Continue" in Google sign-in, the page shows "Could not find webpage" instead of redirecting back to your app.

## ✅ Solution

I've fixed the code! Now you only need to add **ONE redirect URI** to Google Cloud Console.

---

## 📋 Step 1: Update Google Cloud Console

1. **Go to**: [Google Cloud Console](https://console.cloud.google.com/)
2. **Select your project**
3. **Go to**: APIs & Services → Credentials
4. **Click** on your OAuth 2.0 Client ID: `792629822847-es5iiofm4e563qb01uis7752a7d4m1h0.apps.googleusercontent.com`
5. **Scroll to**: "Authorized redirect URIs"
6. **Add ONLY this URI** (remove any custom scheme URLs):

```
https://cgkexriarshbftnjftlm.supabase.co/auth/v1/callback
```

7. **Remove** any URIs like `com.syncup.app://...` (these are invalid)
8. **Click "Save"**

---

## 📋 Step 2: Configure Supabase OAuth Settings

1. **Go to**: [Supabase Dashboard](https://supabase.com/dashboard/project/cgkexriarshbftnjftlm/auth/providers)
2. **Click on**: "Google" provider
3. **Enable** Google Auth
4. **Add your credentials**:
   - Client ID: `792629822847-es5iiofm4e563qb01uis7752a7d4m1h0.apps.googleusercontent.com`
   - Client Secret: `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`
5. **Site URL**: `https://cgkexriarshbftnjftlm.supabase.co`
6. **Redirect URLs** (add your deep link for mobile):
   ```
   com.example.sync_up://login-callback
   ```
7. **Click "Save"**

---

## 📋 Step 3: Test OAuth Flow

1. **Rebuild your app** (important!):
   ```bash
   flutter clean
   flutter pub get
   flutter run
   ```

2. **Test the flow**:
   - Open sign-in page
   - Click "Sign in with Google"
   - Browser opens → Select Google account
   - Grant permissions → Click "Continue"
   - **Should redirect back to app** ✅
   - App navigates to home screen

---

## 🔍 What I Changed

### 1. **AndroidManifest.xml**
Added deep link support for OAuth callback:
```xml
<intent-filter>
    <action android:name="android.intent.action.VIEW" />
    <category android:name="android.intent.category.DEFAULT" />
    <category android:name="android.intent.category.BROWSABLE" />
    <data android:scheme="com.syncup.app" />
</intent-filter>
```

### 2. **sign_in_page.dart**
Fixed redirect URL from:
- ❌ `com.yourapp.syncup://login-callback`
- ✅ `com.syncup.app://login-callback`

---

## 🐛 Troubleshooting

### Still shows "Could not find webpage"?

**Check:**
1. ✅ Google Cloud Console has both redirect URIs added
2. ✅ Supabase Google provider is enabled with correct credentials
3. ✅ App was rebuilt with `flutter clean` and `flutter run`
4. ✅ Deep link is correctly configured in AndroidManifest.xml

### OAuth flow opens but doesn't return to app?

**Check logs:**
```bash
flutter run
# Look for:
# "Starting Supabase Google OAuth..."
# "OAuth flow initiated, waiting for callback..."
# "OAuth callback received! User: email@example.com"
```

### "Invalid redirect URI" error?

**Make sure:**
- Google Cloud Console has `https://cgkexriarshbftnjftlm.supabase.co/auth/v1/callback`
- The URI matches exactly (no trailing slash)
- You clicked "Save" in Google Cloud Console

---

## 📱 How OAuth Flow Works Now

1. User clicks "Sign in with Google"
2. App opens browser with Google sign-in
3. User selects account and grants permissions
4. Google redirects to: `https://cgkexriarshbftnjftlm.supabase.co/auth/v1/callback?code=...`
5. Supabase processes the OAuth and redirects to: `com.syncup.app://login-callback`
6. Android deep link captures the callback
7. App receives auth session
8. User is logged in and navigated to home screen ✅

---

## ✅ Checklist

Before testing:
- [ ] Google Cloud Console redirect URIs updated
- [ ] Supabase Google provider configured
- [ ] App rebuilt with `flutter clean && flutter run`
- [ ] AndroidManifest.xml has deep link (already done ✅)

---

## 🎉 You're Done!

Once you complete the configuration steps, Google OAuth will work perfectly! 🚀
