# ✅ OAuth Fixed - Simple Setup Guide

## 🎯 The Issue
Google OAuth redirect URIs **cannot use custom schemes** like `com.syncup.app://...`

## ✅ The Fix
Only use the **Supabase callback URL** in Google Cloud Console.

---

## 📋 Step-by-Step Setup

### 1️⃣ Google Cloud Console

**Go to**: https://console.cloud.google.com/apis/credentials

1. Click your OAuth Client ID
2. Find "Authorized redirect URIs"
3. **Add ONLY this**:
   ```
   https://cgkexriarshbftnjftlm.supabase.co/auth/v1/callback
   ```
4. **Remove** any custom URLs like `com.syncup.app://...`
5. Click **Save**

---

### 2️⃣ Supabase Dashboard

**Go to**: https://supabase.com/dashboard/project/cgkexriarshbftnjftlm/auth/providers

1. Click **Google** provider
2. **Enable** it
3. Enter:
   - **Client ID**: `792629822847-es5iiofm4e563qb01uis7752a7d4m1h0.apps.googleusercontent.com`
   - **Client Secret**: `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`
4. Under **Additional Settings** → **Redirect URLs**, add:
   ```
   com.example.sync_up://login-callback
   ```
5. Click **Save**

---

### 3️⃣ Rebuild App

```powershell
flutter clean
flutter pub get
flutter run
```

---

## 🧪 Test OAuth

1. Open app → Sign In page
2. Click "Sign in with Google"
3. Browser opens
4. Select Google account
5. Click "Continue"
6. **App should open automatically** ✅
7. Navigate to home screen ✅

---

## 📝 What Changed in Code

### ✅ AndroidManifest.xml
```xml
<!-- Correct deep link format -->
<data 
    android:scheme="com.example.sync_up"
    android:host="login-callback" />
```

### ✅ sign_in_page.dart
```dart
// Removed custom redirectTo - Supabase handles it automatically
await Supabase.instance.client.auth.signInWithOAuth(
  OAuthProvider.google,
  authScreenLaunchMode: LaunchMode.externalApplication,
);
```

---

## 🎉 That's It!

Just configure Google Cloud Console and Supabase, rebuild, and test! 🚀
