# 🔐 Twilio Configuration - Ready to Deploy

## ✅ Your Twilio Credentials

```
Verify Service SID: VA90137c49c17a5ced3419273219c22976
Account SID:        AC2e939a7361144d9d318488b9b1275da5
Auth Token:         17f236cd367fb95cf583e5fc2a571e1c
```

---

## 📋 Commands to Run

**Copy and paste these commands** into the terminal where you successfully ran `supabase login`:

### 1️⃣ Set Twilio Secrets

```bash
supabase secrets set TWILIO_ACCOUNT_SID=AC2e939a7361144d9d318488b9b1275da5 --project-ref cgkexriarshbftnjftlm

supabase secrets set TWILIO_AUTH_TOKEN=17f236cd367fb95cf583e5fc2a571e1c --project-ref cgkexriarshbftnjftlm

supabase secrets set TWILIO_VERIFY_SERVICE_SID=VA90137c49c17a5ced3419273219c22976 --project-ref cgkexriarshbftnjftlm
```

### 2️⃣ Verify Secrets (Optional)

```bash
supabase secrets list --project-ref cgkexriarshbftnjftlm
```

Should show:
- `TWILIO_ACCOUNT_SID`
- `TWILIO_AUTH_TOKEN`
- `TWILIO_VERIFY_SERVICE_SID`

### 3️⃣ Deploy verify-otp Function

```bash
supabase functions deploy verify-otp --project-ref cgkexriarshbftnjftlm
```

### 4️⃣ Redeploy send-otp Function

```bash
supabase functions deploy send-otp --project-ref cgkexriarshbftnjftlm
```

---

## ✅ After Deployment

Once all commands complete successfully:

1. ✅ Twilio credentials configured
2. ✅ Both Edge Functions deployed
3. ✅ Ready to test phone OTP!

---

## 🧪 Next: Configure Email OTP in Supabase

1. Go to: https://supabase.com/dashboard/project/cgkexriarshbftnjftlm/auth/templates
2. Click **Signup Confirmation** template
3. Update the email body:

```html
<h2>Welcome to Sync Up!</h2>
<p>Your verification code is:</p>
<h1 style="background-color: #4F46E5; color: white; padding: 20px; text-align: center; border-radius: 8px; letter-spacing: 8px;">
  {{ .Token }}
</h1>
<p>This code will expire in <strong>60 minutes</strong>.</p>
<p>If you didn't request this code, please ignore this email.</p>
<br>
<p>Best regards,<br>The Sync Up Team</p>
```

4. Set **OTP Expiry**: `3600` seconds (60 minutes)
5. Click **Save**

---

## 🚀 Test Your Implementation

```powershell
flutter run
```

### Testing Steps:

1. **Sign Up** with:
   - Valid email (you have access to)
   - Valid phone number (can receive SMS)
   - Fill all required fields

2. **Check for OTPs**:
   - ✅ Email inbox for 6-digit code
   - ✅ SMS for 6-digit code

3. **Enter OTPs**:
   - Go to **Email tab**, enter email OTP
   - Go to **Phone tab**, enter phone OTP

4. **Complete Signup**:
   - Click "Complete Signup & Continue"
   - Should navigate to home page
   - Profile auto-populated

---

## 📊 Monitor Function Logs

While testing, watch the logs in real-time:

```bash
# Watch send-otp logs
supabase functions logs send-otp --tail --project-ref cgkexriarshbftnjftlm

# Watch verify-otp logs
supabase functions logs verify-otp --tail --project-ref cgkexriarshbftnjftlm
```

---

## 🎉 Success Indicators

You'll know it's working when:

1. ✅ Email OTP arrives in inbox
2. ✅ SMS OTP arrives on phone
3. ✅ Both OTPs verify successfully
4. ✅ Green checkmarks appear on both tabs
5. ✅ "Complete Signup & Continue" button appears
6. ✅ Navigation to home page works
7. ✅ Profile data displays correctly

---

## 🐛 Troubleshooting

### Email OTP not received?
- Check spam folder
- Verify email template saved in Supabase
- Check Supabase auth logs

### Phone OTP not received?
- Verify Twilio has credits (check console)
- Check phone number format: `+919876543210`
- View function logs: `supabase functions logs send-otp --tail`
- Check Twilio Geo Permissions for your country

### "Invalid OTP" error?
- OTP expired? (Email: 60 min, Phone: 10 min)
- Check code is exactly 6 digits
- Try resending OTP

---

**Project ID**: `cgkexriarshbftnjftlm`  
**Twilio Console**: https://www.twilio.com/console  
**Supabase Dashboard**: https://supabase.com/dashboard/project/cgkexriarshbftnjftlm

**Ready to deploy!** 🚀
