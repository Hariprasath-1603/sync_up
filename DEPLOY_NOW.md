# 🚨 DEPLOY PHONE VERIFICATION NOW - Step by Step

## Why OTP Isn't Working
Your Flutter app is trying to call Edge Functions that **DON'T EXIST YET** in Supabase!

---

## ✅ Step-by-Step Fix (15 minutes)

### STEP 1: Create Database Table (3 minutes)

1. ✅ **I just opened**: SQL Editor in your browser
2. **Copy ALL the code** from `PHONE_VERIFICATION_SETUP.sql` (the file in your project)
3. **Paste it** into the SQL editor
4. **Click "RUN"** button (bottom right)
5. **Wait for**: "Success. No rows returned" message

---

### STEP 2: Deploy send-otp Function (5 minutes)

1. ✅ **I just opened**: Edge Functions page in your browser
2. **Click**: "Create a new function" button
3. **Function name**: Type exactly: `send-otp`
4. **Copy the code below** and paste it into the editor:

```typescript
import { serve } from 'https://deno.land/std@0.168.0/http/server.ts'

const TWILIO_ACCOUNT_SID = 'AC2e939a7361144d9d318488b9b1275da5'
const TWILIO_AUTH_TOKEN = '17f236cd367fb95cf583e5fc2a571e1c'
const TWILIO_PHONE_NUMBER = '+13208558889'

serve(async (req) => {
  const corsHeaders = {
    'Access-Control-Allow-Origin': '*',
    'Access-Control-Allow-Headers': 'authorization, x-client-info, apikey, content-type',
  }

  if (req.method === 'OPTIONS') {
    return new Response('ok', { headers: corsHeaders })
  }

  try {
    const { phone } = await req.json()

    if (!phone) {
      throw new Error('Phone number is required')
    }

    // Generate 6-digit OTP
    const otp = Math.floor(100000 + Math.random() * 900000).toString()

    console.log(`Sending OTP ${otp} to ${phone}`)

    // Send OTP via Twilio
    const auth = btoa(`${TWILIO_ACCOUNT_SID}:${TWILIO_AUTH_TOKEN}`)
    const twilioUrl = `https://api.twilio.com/2010-04-01/Accounts/${TWILIO_ACCOUNT_SID}/Messages.json`

    const formData = new URLSearchParams()
    formData.append('To', phone)
    formData.append('From', TWILIO_PHONE_NUMBER)
    formData.append('Body', `Your SyncUp verification code is: ${otp}. Valid for 10 minutes.`)

    const twilioResponse = await fetch(twilioUrl, {
      method: 'POST',
      headers: {
        'Authorization': `Basic ${auth}`,
        'Content-Type': 'application/x-www-form-urlencoded',
      },
      body: formData,
    })

    if (!twilioResponse.ok) {
      const error = await twilioResponse.json()
      console.error('Twilio error:', error)
      throw new Error(`Twilio error: ${JSON.stringify(error)}`)
    }

    console.log('SMS sent successfully via Twilio')

    // Store OTP in Supabase
    const { createClient } = await import('https://esm.sh/@supabase/supabase-js@2')
    const supabaseUrl = Deno.env.get('SUPABASE_URL')!
    const supabaseKey = Deno.env.get('SUPABASE_SERVICE_ROLE_KEY')!
    const supabase = createClient(supabaseUrl, supabaseKey)

    const expiresAt = new Date(Date.now() + 10 * 60 * 1000).toISOString()

    const { error: dbError } = await supabase.from('phone_otps').upsert({
      phone: phone,
      otp: otp,
      expires_at: expiresAt,
      created_at: new Date().toISOString(),
    })

    if (dbError) {
      console.error('Database error:', dbError)
      throw new Error(`Database error: ${dbError.message}`)
    }

    return new Response(
      JSON.stringify({ 
        success: true, 
        message: 'OTP sent successfully',
        debug: process.env.NODE_ENV === 'development' ? { otp, phone } : undefined
      }),
      { headers: { ...corsHeaders, 'Content-Type': 'application/json' }, status: 200 }
    )
  } catch (error) {
    console.error('Error in send-otp function:', error)
    return new Response(
      JSON.stringify({ error: error.message }),
      { headers: { ...corsHeaders, 'Content-Type': 'application/json' }, status: 400 }
    )
  }
})
```

5. **Click**: "Deploy function"
6. **Wait**: Until status shows "Active"

---

### STEP 3: Deploy verify-otp Function (5 minutes)

1. **Click**: "Create a new function" button again
2. **Function name**: Type exactly: `verify-otp`
3. **Copy the code below** and paste it into the editor:

```typescript
import { serve } from 'https://deno.land/std@0.168.0/http/server.ts'

serve(async (req) => {
  const corsHeaders = {
    'Access-Control-Allow-Origin': '*',
    'Access-Control-Allow-Headers': 'authorization, x-client-info, apikey, content-type',
  }

  if (req.method === 'OPTIONS') {
    return new Response('ok', { headers: corsHeaders })
  }

  try {
    const { phone, code } = await req.json()

    if (!phone || !code) {
      throw new Error('Phone and code are required')
    }

    // Get OTP from Supabase
    const { createClient } = await import('https://esm.sh/@supabase/supabase-js@2')
    const supabaseUrl = Deno.env.get('SUPABASE_URL')!
    const supabaseKey = Deno.env.get('SUPABASE_SERVICE_ROLE_KEY')!
    const supabase = createClient(supabaseUrl, supabaseKey)

    const { data, error } = await supabase
      .from('phone_otps')
      .select('*')
      .eq('phone', phone)
      .single()

    if (error || !data) {
      console.error('OTP lookup error:', error)
      throw new Error('OTP not found or expired')
    }

    // Check if OTP is expired
    if (new Date(data.expires_at) < new Date()) {
      await supabase.from('phone_otps').delete().eq('phone', phone)
      throw new Error('OTP has expired')
    }

    // Verify OTP
    if (data.otp !== code) {
      throw new Error('Invalid OTP code')
    }

    // Delete OTP after successful verification
    await supabase.from('phone_otps').delete().eq('phone', phone)

    console.log(`Phone ${phone} verified successfully`)

    return new Response(
      JSON.stringify({ success: true, verified: true }),
      { headers: { ...corsHeaders, 'Content-Type': 'application/json' }, status: 200 }
    )
  } catch (error) {
    console.error('Error in verify-otp function:', error)
    return new Response(
      JSON.stringify({ error: error.message }),
      { headers: { ...corsHeaders, 'Content-Type': 'application/json' }, status: 400 }
    )
  }
})
```

4. **Click**: "Deploy function"
5. **Wait**: Until status shows "Active"

---

### STEP 4: Verify in Twilio (2 minutes)

Your test phone number **must be verified** in Twilio (trial mode):

1. Go to: https://console.twilio.com/us1/develop/phone-numbers/manage/verified
2. Check if `+18777804236` is listed
3. If NOT listed:
   - Click "Add a new Caller ID"
   - Enter `+18777804236`
   - Complete verification

---

## 🧪 Test It Now!

1. **Run your app**: `flutter run`
2. **Go to**: Sign Up page
3. **Enter phone**: `+18777804236`
4. **Click**: "Get OTP" button
5. **Check your phone** for SMS
6. **Enter the 6-digit code**
7. **Click**: "Verify"
8. ✅ **Success!** Green checkmark appears

---

## 🐛 Troubleshooting

### "Failed to send OTP" Error?

**Check Function Logs:**
1. Go to: Edge Functions → `send-otp` → Logs tab
2. Look for errors in red

**Common Issues:**
- ❌ Phone number not in E.164 format → Use `+18777804236`
- ❌ Twilio phone not verified → Verify in Twilio Console
- ❌ `phone_otps` table missing → Run SQL setup again

### SMS Not Received?

**Check Twilio Logs:**
1. Go to: https://console.twilio.com/us1/monitor/logs/sms
2. Look for your SMS
3. Check status (Delivered, Failed, Queued)

**Common Issues:**
- ❌ Wrong phone number format
- ❌ Phone not verified in Twilio (trial mode)
- ❌ Twilio credits exhausted ($15.50 free trial)

---

## ✅ Checklist

Before testing:
- [ ] SQL executed (phone_otps table created)
- [ ] send-otp function deployed and Active
- [ ] verify-otp function deployed and Active
- [ ] Test phone verified in Twilio Console
- [ ] Using correct phone format: +18777804236

---

## 🎉 You're Done!

Once all 4 steps are complete, OTP will work perfectly!

**Need help?** Check the function logs in Supabase Dashboard.
