# 🔧 Supabase Email OTP Configuration

## ⚠️ CRITICAL: Configure These Settings in Supabase Dashboard

To use **Email OTP instead of Magic Links**, you need to update your Supabase Auth settings.

---

## 📍 Step 1: Open Auth Settings

Go to: **https://supabase.com/dashboard/project/cgkexriarshbftnjftlm/auth/url-configuration**

---

## 📍 Step 2: Enable Email Confirmations

1. Scroll to **"Email Auth"** section
2. Find **"Enable email confirmations"**
3. **TURN IT ON** (enable it) - This ensures users must verify email via OTP before they can sign in
4. Click **Save**

This ensures that users created with `signUp()` must verify their email OTP before the account is fully activated.

---

## 📍 Step 3: Configure Email Template for OTP

1. Go to: **https://supabase.com/dashboard/project/cgkexriarshbftnjftlm/auth/templates**

2. Click **"Magic Link"** template (this is used for OTP emails)

3. Replace the email body with:

```html
<h2>Welcome to Sync Up! 🎉</h2>
<p>Your email verification code is:</p>

<h1 style="background-color: #4F46E5; color: white; padding: 20px; text-align: center; border-radius: 8px; letter-spacing: 8px; font-family: monospace;">
  {{ .Token }}
</h1>

<p>This code will expire in <strong>60 minutes</strong>.</p>

<p style="color: #666; font-size: 14px;">
  If you didn't request this code, please ignore this email.
</p>

<br>
<p>Best regards,<br>The Sync Up Team</p>
```

4. **Set OTP Expiry**: `3600` seconds (60 minutes)

5. Click **Save**

---

## ✅ Why This Matters

**New Flow** (with email confirmations enabled):
- `signUp(email, password)` → Creates user account with password AND sends OTP email ✅
- `verifyOTP()` → Verifies email and activates account ✅
- User can then `signInWithPassword()` for future logins ✅
- **Result**: User gets ONE OTP email, password is set from the start!

**Old problematic flow** (disabled confirmations):
- Would create unverified accounts that could sign in immediately ❌
- No email verification enforcement ❌

---

## 🧪 Test After Configuration

1. Open your app
2. Try to sign up
3. You should receive **ONLY ONE email with a 6-digit OTP**
4. No more magic links!

---

**Done!** Your app will now send OTP emails instead of magic links. 🎉
