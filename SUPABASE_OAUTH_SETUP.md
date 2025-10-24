# Supabase OAuth Setup Guide

## 🚀 Complete Migration from Firebase OAuth to Supabase OAuth

### Step 1: Configure OAuth Providers in Supabase Dashboard

1. **Go to Supabase Dashboard**: https://cgkexriarshbftnjftlm.supabase.co
2. **Navigate to**: Authentication → Providers
3. **Enable the providers you want**:

---

#### 📧 **Email (Already Enabled)**
- ✅ Already configured
- Users can sign up with email/password

---

#### 🔍 **Google OAuth**

1. Click on **Google** provider
2. **Enable Google provider**
3. You'll need:
   - **Google Client ID**
   - **Google Client Secret**

**How to get Google OAuth credentials:**

1. Go to [Google Cloud Console](https://console.cloud.google.com/)
2. Create a new project or select existing
3. Navigate to **APIs & Services** → **Credentials**
4. Click **Create Credentials** → **OAuth 2.0 Client ID**
5. Configure OAuth consent screen if not done
6. Application type: **Web application**
7. **Authorized redirect URIs**, add:
   ```
   https://cgkexriarshbftnjftlm.supabase.co/auth/v1/callback
   ```
8. Copy the **Client ID** and **Client Secret**
9. Paste them in Supabase Google provider settings
10. **Save**

---

#### 🍎 **Apple OAuth**

1. Click on **Apple** provider
2. **Enable Apple provider**
3. You'll need:
   - **Apple Services ID**
   - **Apple Team ID**
   - **Apple Key ID**
   - **Apple Private Key (.p8 file)**

**How to get Apple OAuth credentials:**

1. Go to [Apple Developer Portal](https://developer.apple.com/account)
2. Navigate to **Certificates, Identifiers & Profiles**
3. Create **App ID** (if not exists)
4. Create **Services ID**:
   - Identifier: `com.yourapp.services`
   - Enable **Sign In with Apple**
   - Configure domains and return URLs:
     - Domain: `cgkexriarshbftnjftlm.supabase.co`
     - Return URL: `https://cgkexriarshbftnjftlm.supabase.co/auth/v1/callback`
5. Create **Private Key**:
   - Enable **Sign In with Apple**
   - Download the `.p8` file
   - Note the **Key ID**
6. Find your **Team ID** in membership section
7. Paste all credentials in Supabase Apple provider settings
8. **Save**

---

#### 🪟 **Microsoft OAuth**

1. Click on **Azure (Microsoft)** provider
2. **Enable Azure provider**
3. You'll need:
   - **Azure Client ID**
   - **Azure Client Secret**

**How to get Microsoft OAuth credentials:**

1. Go to [Azure Portal](https://portal.azure.com/)
2. Navigate to **Azure Active Directory** → **App registrations**
3. Click **New registration**
4. Name: Your App Name
5. Supported account types: **Accounts in any organizational directory and personal Microsoft accounts**
6. Redirect URI: Web, `https://cgkexriarshbftnjftlm.supabase.co/auth/v1/callback`
7. Click **Register**
8. Copy **Application (client) ID** → This is your Client ID
9. Go to **Certificates & secrets** → **New client secret**
10. Create secret, copy the **Value** → This is your Client Secret
11. Paste in Supabase Azure provider settings
12. **Save**

---

### Step 2: Update Flutter App to Use Supabase OAuth

Remove Google Sign-In package and use Supabase's built-in OAuth:

#### Remove from `pubspec.yaml`:
```yaml
# REMOVE THESE:
# google_sign_in: ^6.2.1
```

#### Add Supabase deep linking configuration:

**For Android** (`android/app/src/main/AndroidManifest.xml`):
```xml
<intent-filter>
    <action android:name="android.intent.action.VIEW" />
    <category android:name="android.intent.category.DEFAULT" />
    <category android:name="android.intent.category.BROWSABLE" />
    <!-- Supabase OAuth callback -->
    <data
        android:scheme="com.yourapp.syncup"
        android:host="login-callback" />
</intent-filter>
```

**For iOS** (`ios/Runner/Info.plist`):
```xml
<key>CFBundleURLTypes</key>
<array>
    <dict>
        <key>CFBundleTypeRole</key>
        <string>Editor</string>
        <key>CFBundleURLSchemes</key>
        <array>
            <string>com.yourapp.syncup</string>
        </array>
    </dict>
</array>
```

---

### Step 3: Implement Supabase OAuth in Code

See the implementation in:
- `lib/features/auth/sign_in_page.dart` - Updated OAuth buttons
- `lib/features/auth/auth_service.dart` - Supabase OAuth methods

---

### Step 4: Test OAuth Flow

1. **Build and run the app**
2. **Click Google/Apple/Microsoft sign-in button**
3. **User will be redirected to OAuth provider**
4. **After authentication, user returns to app**
5. **User data is saved to both Firebase Auth and Supabase**

---

### 📋 Checklist

- [ ] Configure Google OAuth in Supabase Dashboard
- [ ] Configure Apple OAuth in Supabase Dashboard (for iOS)
- [ ] Configure Microsoft OAuth in Supabase Dashboard
- [ ] Update Android manifest with deep link
- [ ] Update iOS Info.plist with URL scheme
- [ ] Remove `google_sign_in` package from pubspec.yaml
- [ ] Test Google OAuth flow
- [ ] Test Apple OAuth flow (on iOS device)
- [ ] Test Microsoft OAuth flow
- [ ] Verify user data is saved to Supabase

---

### 🔒 Security Notes

1. **Never commit OAuth secrets to Git**
2. **Use environment variables for sensitive keys**
3. **Enable Row Level Security (RLS) on Supabase tables**
4. **Validate user data on signup**

---

### ✅ Benefits of Supabase OAuth

- ✅ No need for separate OAuth packages
- ✅ Unified authentication system
- ✅ Automatic token refresh
- ✅ Better security
- ✅ Easier to maintain

