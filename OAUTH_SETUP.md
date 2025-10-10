# OAuth Authentication Setup Guide

## ✅ Completed Steps

1. **Added OAuth Dependencies**
   - ✅ `google_sign_in: ^6.2.1` added to `pubspec.yaml`
   - ✅ Run `flutter pub get` to install packages

2. **Implemented OAuth Methods**
   - ✅ `auth_service.dart` updated with:
     - `signInWithGoogle()` - Google Sign-In flow
     - `signInWithMicrosoft()` - Microsoft Azure AD OAuth
     - `signInWithApple()` - Apple Sign-In
   - ✅ All methods include proper error handling

3. **Connected UI to Auth Service**
   - ✅ `sign_in_page.dart` OAuth buttons now call:
     - `_signInWithGoogle()` → Google authentication
     - `_signInWithMicrosoft()` → Microsoft authentication
     - `_signInWithApple()` → Apple authentication (iOS only)
   - ✅ Loading states and error handling implemented
   - ✅ Success navigation to `/home` route
   - ✅ Welcome messages with user display name/email

## 🔧 Required Firebase Console Configuration

### 1. Enable Google Sign-In

1. Go to [Firebase Console](https://console.firebase.google.com/)
2. Select your project: **sync_up**
3. Navigate to **Authentication** → **Sign-in method**
4. Click on **Google** provider
5. Enable the toggle
6. Enter your support email
7. Click **Save**

### 2. Android Configuration (Google Sign-In)

1. Get your SHA-1 certificate fingerprint:
   ```powershell
   # For debug builds:
   cd android
   ./gradlew signingReport
   ```
   Or use:
   ```powershell
   keytool -list -v -keystore "%USERPROFILE%\.android\debug.keystore" -alias androiddebugkey -storepass android -keypass android
   ```

2. In Firebase Console:
   - Go to **Project Settings** → **General**
   - Scroll to **Your apps** section
   - Click on your Android app
   - Add SHA-1 fingerprint
   - Click **Save**

3. Download updated `google-services.json`:
   - Click **Download google-services.json**
   - Replace the file in `android/app/google-services.json`

### 3. iOS Configuration (Google Sign-In)

1. In Firebase Console:
   - Go to **Project Settings** → **General**
   - Click on your iOS app
   - Download `GoogleService-Info.plist`
   - Add it to `ios/Runner/GoogleService-Info.plist` (replace if exists)

2. Update `ios/Runner/Info.plist`:
   ```xml
   <key>CFBundleURLTypes</key>
   <array>
     <dict>
       <key>CFBundleTypeRole</key>
       <string>Editor</string>
       <key>CFBundleURLSchemes</key>
       <array>
         <!-- Copy REVERSED_CLIENT_ID from GoogleService-Info.plist -->
         <string>YOUR_REVERSED_CLIENT_ID</string>
       </array>
     </dict>
   </array>
   ```

### 4. Microsoft Sign-In Setup (Optional)

1. Register app in [Azure Portal](https://portal.azure.com/):
   - Go to **Azure Active Directory** → **App registrations**
   - Click **New registration**
   - Name: "Syncup App"
   - Supported account types: Choose appropriate option
   - Redirect URI: Leave blank for now
   - Click **Register**

2. Note your **Application (client) ID** and **Directory (tenant) ID**

3. In Firebase Console:
   - Navigate to **Authentication** → **Sign-in method**
   - Click **Microsoft**
   - Enable the toggle
   - Enter Client ID and Client Secret from Azure
   - Copy the redirect URI from Firebase
   - Add this redirect URI to your Azure app registration

4. In Azure Portal:
   - Go to your app → **Authentication**
   - Click **Add a platform** → **Web**
   - Paste the Firebase redirect URI
   - Save

### 5. Apple Sign-In Setup (Optional, iOS only)

1. In [Apple Developer Console](https://developer.apple.com/):
   - Go to **Certificates, Identifiers & Profiles**
   - Select **Identifiers**
   - Find your app identifier
   - Enable **Sign In with Apple**
   - Save

2. Add sign_in_with_apple package:
   - Uncomment in `pubspec.yaml`:
     ```yaml
     sign_in_with_apple: ^5.0.0
     ```
   - Run `flutter pub get`

3. In Firebase Console:
   - Navigate to **Authentication** → **Sign-in method**
   - Click **Apple**
   - Enable the toggle
   - Enter your Apple Service ID and other required info

4. Update `ios/Runner/Info.plist`:
   ```xml
   <key>NSAppleEventsUsageDescription</key>
   <string>This app needs to access Apple Sign In</string>
   ```

## 🧪 Testing OAuth Flows

### Test Google Sign-In:
1. Run the app: `flutter run`
2. Click the Google button (rainbow G logo)
3. Select a Google account
4. Grant permissions
5. Should redirect to home screen with welcome message

### Test Microsoft Sign-In:
1. Click the Microsoft button (4-color grid)
2. Enter Microsoft credentials
3. Grant permissions
4. Should redirect to home screen

### Test Apple Sign-In (iOS only):
1. Click the Apple button (black with apple icon)
2. Authenticate with Face ID/Touch ID or password
3. Choose to share or hide email
4. Should redirect to home screen

## 🐛 Common Issues

### Google Sign-In Not Working:
- ✅ Verify SHA-1 fingerprint is added in Firebase Console
- ✅ Ensure `google-services.json` is up-to-date
- ✅ Check package name matches Firebase project
- ✅ Run `flutter clean` and rebuild

### Microsoft Sign-In Not Working:
- ✅ Verify redirect URI matches between Firebase and Azure
- ✅ Check client ID and secret are correct
- ✅ Ensure app is registered in Azure AD

### Apple Sign-In Not Working:
- ✅ Verify capability is enabled in Xcode
- ✅ Check bundle identifier matches
- ✅ Test on real iOS device (simulator may have issues)

## 📝 Code Summary

### AuthService Methods:
```dart
// Google Sign-In
Future<User?> signInWithGoogle() async

// Microsoft Sign-In
Future<User?> signInWithMicrosoft({String? tenant}) async

// Apple Sign-In
Future<User?> signInWithApple() async
```

### Sign-In Page Methods:
```dart
// Handlers with loading states and error handling
Future<void> _signInWithGoogle() async
Future<void> _signInWithMicrosoft() async
Future<void> _signInWithApple() async
```

## 🎯 Next Steps

1. **Install packages**: Run `flutter pub get`
2. **Configure Firebase**: Follow steps above for each provider
3. **Test on devices**: Android and iOS
4. **Add to sign_up_page.dart**: Implement same OAuth buttons for registration
5. **Production setup**: 
   - Generate release SHA-1 fingerprint
   - Update Firebase with production credentials
   - Test OAuth flows thoroughly

## 📚 Resources

- [Firebase Authentication Docs](https://firebase.google.com/docs/auth)
- [Google Sign-In Flutter Plugin](https://pub.dev/packages/google_sign_in)
- [Microsoft Azure AD Docs](https://docs.microsoft.com/en-us/azure/active-directory/)
- [Apple Sign-In Docs](https://developer.apple.com/sign-in-with-apple/)
