# 🚀 Deploy Phone Verification Edge Functions

## ✅ Your Twilio Credentials (Already Configured)

```
Account SID: AC2e939a7361144d9d318488b9b1275da5
Auth Token: 17f236cd367fb95cf583e5fc2a571e1c
Phone Number: +13208558889
Test Phone: +18777804236
```

---

## 📋 Deployment Steps

### Step 1: Run SQL Setup (CRITICAL!)

1. Open Supabase Dashboard: https://cgkexriarshbftnjftlm.supabase.co
2. Go to **SQL Editor** → **New Query**
3. Copy and paste the contents of `PHONE_VERIFICATION_SETUP.sql`
4. Click **Run** to execute

This will:
- ✅ Add `phone_verified` column to users table
- ✅ Create `phone_otps` table for storing OTP codes
- ✅ Set up security policies

---

### Step 2: Deploy Edge Functions via Dashboard

Since CLI installation is difficult on Windows, we'll use the **Supabase Dashboard** (easier!):

#### Deploy `send-otp` Function:

1. Go to: https://cgkexriarshbftnjftlm.supabase.co/project/cgkexriarshbftnjftlm/functions
2. Click **"Create a new function"**
3. **Function name**: `send-otp`
4. Copy and paste the code from: `supabase/functions/send-otp/index.ts`
5. Click **"Deploy function"**

#### Deploy `verify-otp` Function:

1. Click **"Create a new function"** again
2. **Function name**: `verify-otp`
3. Copy and paste the code from: `supabase/functions/verify-otp/index.ts`
4. Click **"Deploy function"**

---

### Step 3: Verify Functions are Running

1. In Supabase Dashboard, go to **Edge Functions**
2. You should see:
   - ✅ `send-otp` - Status: **Active**
   - ✅ `verify-otp` - Status: **Active**

---

## 🧪 Test Phone Verification

### Test in Your App:

1. **Run your Flutter app**: `flutter run`
2. **Go to Sign Up page**
3. **Enter phone number**: `+18777804236` (your test number)
4. **Click "Get OTP"**
5. **Check your phone** for SMS
6. **Enter the 6-digit code**
7. **Click "Verify"**
8. **Complete signup** ✅

### Expected Behavior:

- 📱 SMS arrives with: *"Your SyncUp verification code is: 123456. Valid for 10 minutes."*
- ✅ After verification, green checkmark appears
- ✅ Phone field becomes disabled (locked)
- ✅ Can now proceed to complete signup
- ✅ User saved with `phone_verified: true`

---

## 🐛 Troubleshooting

### SMS Not Received?

**Check Twilio Console:**
1. Go to: https://console.twilio.com/us1/monitor/logs/sms
2. Look for your SMS in the logs
3. Check status (Delivered, Failed, etc.)

**Common Issues:**
- ❌ Phone number must be **verified in Twilio** (trial mode)
- ❌ Use **E.164 format**: `+1` + area code + number (e.g., `+18777804236`)
- ❌ Check Twilio credits haven't run out

### Edge Function Errors?

**Check Function Logs:**
1. Go to: Supabase Dashboard → **Edge Functions**
2. Click on function name → **Logs** tab
3. Look for error messages

**Common Issues:**
- ❌ `phone_otps` table not created → Run the SQL setup
- ❌ Wrong Twilio credentials → Check Account SID/Auth Token
- ❌ CORS errors → Already handled in code

---

## 🔐 Security Notes

✅ **What's Secure:**
- OTP codes expire after 10 minutes
- OTP is deleted after successful verification
- Credentials are hardcoded in function (only accessible server-side)
- Users must verify phone before signup

⚠️ **For Production:**
- Move credentials to Supabase Environment Variables:
  1. Go to: Project Settings → Edge Functions → Environment Variables
  2. Add: `TWILIO_ACCOUNT_SID`, `TWILIO_AUTH_TOKEN`, `TWILIO_PHONE_NUMBER`
  3. Update code to use `Deno.env.get('TWILIO_ACCOUNT_SID')`

---

## 📊 Monitor Usage

**Check Twilio Usage:**
- Dashboard: https://console.twilio.com/us1/monitor/usage
- Track SMS sent, credits remaining, costs

**Check Supabase Storage:**
```sql
-- View recent OTPs (debugging)
SELECT * FROM phone_otps ORDER BY created_at DESC LIMIT 10;

-- View verified users
SELECT id, email, phone_number, phone_verified, created_at 
FROM users 
WHERE phone_verified = true 
ORDER BY created_at DESC;

-- Clean up expired OTPs manually
DELETE FROM phone_otps WHERE expires_at < NOW();
```

---

## ✅ Quick Checklist

Before testing, make sure:

- [ ] SQL setup completed (`phone_otps` table exists)
- [ ] Both Edge Functions deployed (`send-otp`, `verify-otp`)
- [ ] Phone number verified in Twilio Console
- [ ] Twilio has credits remaining ($15.50 free trial)
- [ ] Phone number uses E.164 format (`+1...`)

---

## 🎉 You're Ready!

Once you complete the steps above, your phone verification will be fully functional!

Test it now and let me know if you encounter any issues. 🚀
