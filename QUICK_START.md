# 🚀 Quick Start Guide - OTP Verification Setup

## ✅ What You've Already Done

1. ✅ **Logged into Supabase CLI** - Successfully authenticated
2. ✅ **Created Edge Functions** - Both `send-otp` and `verify-otp` functions created  
3. ✅ **Deployed send-otp** - First function deployed successfully
4. ✅ **Project Linked** - Project ID: `cgkexriarshbftnjftlm`

---

## 📋 Next Steps (5-10 minutes)

### Step 1: Deploy the verify-otp Function

Run this command in PowerShell (from where you have supabase CLI):

```powershell
supabase functions deploy verify-otp --project-ref cgkexriarshbftnjftlm
```

**OR** use the deployment script:

```powershell
.\deploy-functions.ps1
```

---

### Step 2: Set Up Twilio Account

#### A. Create Twilio Account
1. Go to https://www.twilio.com/console
2. Sign up for a free account
3. Verify your email and phone

#### B. Create Verify Service
1. In Twilio Console → **Verify** → **Services**
2. Click **Create new Service**
3. Name it: **Sync Up OTP**
4. Set code length: **6 digits**
5. Set expiration: **10 minutes**
6. Click **Save**

#### C. Get Your Credentials

You'll need these 3 credentials:

1. **Account SID**: Found in Console Dashboard
   - Format: `ACxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx`

2. **Auth Token**: Click "Show" in Console Dashboard
   - Format: `xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx`

3. **Verify Service SID**: From the Verify Service you created
   - Format: `VAxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx`

---

### Step 3: Set Twilio Secrets in Supabase

Run these commands (replace with your actual credentials):

```powershell
supabase secrets set TWILIO_ACCOUNT_SID=ACxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx --project-ref cgkexriarshbftnjftlm

supabase secrets set TWILIO_AUTH_TOKEN=xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx --project-ref cgkexriarshbftnjftlm

supabase secrets set TWILIO_VERIFY_SERVICE_SID=VAxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx --project-ref cgkexriarshbftnjftlm
```

---

### Step 4: Configure Supabase Email OTP

1. Go to https://supabase.com/dashboard/project/cgkexriarshbftnjftlm
2. Navigate to **Authentication** → **Email Templates**
3. Click **Signup Confirmation** template
4. Update the email body to include OTP code:

```html
<h2>Welcome to Sync Up!</h2>
<p>Your verification code is:</p>
<h1 style="background-color: #4F46E5; color: white; padding: 20px; text-align: center; border-radius: 8px; letter-spacing: 8px;">{{ .Token }}</h1>
<p>This code will expire in <strong>60 minutes</strong>.</p>
<p>If you didn't request this code, please ignore this email.</p>
```

5. Set **OTP Expiry**: 3600 seconds (60 minutes)
6. Click **Save**

---

### Step 5: Update Database Schema

Run this SQL in Supabase SQL Editor:

```sql
-- Add verification columns if not exists
ALTER TABLE users 
ADD COLUMN IF NOT EXISTS email_verified BOOLEAN DEFAULT FALSE,
ADD COLUMN IF NOT EXISTS phone_verified BOOLEAN DEFAULT FALSE;

-- Create RLS policy for user insertion
CREATE POLICY IF NOT EXISTS "Users can insert their own profile"
  ON users FOR INSERT
  WITH CHECK (auth.uid() = uid);
```

---

### Step 6: Test the Complete Flow

1. **Run your Flutter app**:
   ```powershell
   flutter run
   ```

2. **Test Signup**:
   - Fill signup form with:
     - Valid email (you have access to)
     - Valid phone (you can receive SMS) 
     - All required fields
   
3. **Verify OTPs**:
   - Check email for 6-digit code
   - Check SMS for 6-digit code
   - Enter both codes in the app
   
4. **Complete Signup**:
   - Click "Complete Signup & Continue"
   - Should navigate to home page
   - Profile should be populated

---

## 🎯 Verification Checklist

Use this to track your progress:

- [ ] `verify-otp` function deployed
- [ ] Twilio account created
- [ ] Twilio Verify Service created
- [ ] Twilio credentials saved (Account SID, Auth Token, Service SID)
- [ ] Supabase secrets set (all 3 credentials)
- [ ] Supabase email template updated with OTP code
- [ ] Database schema updated (email_verified, phone_verified columns)
- [ ] RLS policy created
- [ ] Tested signup with real email
- [ ] Received email OTP
- [ ] Received phone OTP (requires Twilio credits)
- [ ] Successfully verified both OTPs
- [ ] Navigated to home page after verification

---

## 🔍 Testing Without Twilio (Email Only)

If you don't have Twilio credits yet, you can still test email OTP:

1. Temporarily modify `sign_up_page.dart` to skip phone verification:
   ```dart
   // Comment out phone OTP sending
   // final phoneOtpResponse = await Supabase.instance.client.functions
   //     .invoke('send-otp', body: {'phone': phoneNumber});
   ```

2. Test email OTP only
3. Add Twilio later when ready

---

## 📊 Monitor Your Functions

### View Function Logs

```powershell
# Watch send-otp logs
supabase functions logs send-otp --tail --project-ref cgkexriarshbftnjftlm

# Watch verify-otp logs
supabase functions logs verify-otp --tail --project-ref cgkexriarshbftnjftlm
```

### Dashboard

View functions in Supabase Dashboard:
https://supabase.com/dashboard/project/cgkexriarshbftnjftlm/functions

---

## 🐛 Troubleshooting

### Issue: "send-otp function not found"

**Solution**: Redeploy the function
```powershell
supabase functions deploy send-otp --project-ref cgkexriarshbftnjftlm
```

### Issue: "Twilio credentials not configured"

**Solution**: Check if secrets are set
```powershell
supabase secrets list --project-ref cgkexriarshbftnjftlm
```

### Issue: "Email OTP not received"

**Solutions**:
1. Check spam folder
2. Verify email template is saved in Supabase
3. Check Supabase auth logs

### Issue: "Phone OTP not sent"

**Solutions**:
1. Verify Twilio account has credits
2. Check phone number format: `+919876543210` (with country code)
3. Check Twilio Geo Permissions for your country
4. View function logs: `supabase functions logs send-otp --tail`

### Issue: "Invalid OTP error"

**Solutions**:
1. Make sure OTP hasn't expired (60 min for email, 10 min for phone)
2. Check OTP code is exactly 6 digits
3. Try resending OTP

---

## 💰 Twilio Pricing

- **SMS OTP**: ~$0.075 per SMS (varies by country)
- **Free Trial**: $15-20 credit
- **Estimation**: ~200 OTPs with free trial

### Get More Credits:
1. Twilio Console → **Billing**
2. Add payment method
3. Buy credits as needed

---

## 🎉 Success Indicators

You'll know everything is working when:

1. ✅ Email OTP arrives in seconds
2. ✅ Phone OTP SMS arrives in seconds
3. ✅ OTP verification succeeds
4. ✅ User redirected to home page
5. ✅ Profile data shows correctly
6. ✅ No errors in function logs
7. ✅ User record created in `users` table

---

## 📞 Support

If you're stuck:

1. Check function logs for errors
2. Verify all secrets are set correctly
3. Test Twilio API directly in Twilio Console
4. Review `OTP_VERIFICATION_SETUP.md` for detailed troubleshooting

---

**Project ID**: `cgkexriarshbftnjftlm`  
**Functions Dashboard**: https://supabase.com/dashboard/project/cgkexriarshbftnjftlm/functions

**Last Updated**: October 24, 2025  
**Status**: Ready for deployment ✅
