# Twilio OTP Setup with Supabase Edge Functions

## 📱 Phone Verification with Twilio

Your app now has inline phone verification in the signup page. Users must verify their phone before they can sign up.

---

## 🚀 Setup Instructions

### Step 1: Create Twilio Account

1. Go to [Twilio](https://www.twilio.com/)
2. Sign up for a free account
3. Get your **Account SID** and **Auth Token** from the dashboard
4. Get a **Twilio Phone Number** (for sending SMS)

### Step 2: Create Supabase Edge Functions

#### Function 1: Send OTP

Create file: `supabase/functions/send-otp/index.ts`

```typescript
import { serve } from 'https://deno.land/std@0.168.0/http/server.ts'

const TWILIO_ACCOUNT_SID = Deno.env.get('TWILIO_ACCOUNT_SID')
const TWILIO_AUTH_TOKEN = Deno.env.get('TWILIO_AUTH_TOKEN')
const TWILIO_PHONE_NUMBER = Deno.env.get('TWILIO_PHONE_NUMBER')

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

    // Send OTP via Twilio
    const auth = btoa(`${TWILIO_ACCOUNT_SID}:${TWILIO_AUTH_TOKEN}`)
    const twilioUrl = `https://api.twilio.com/2010-04-01/Accounts/${TWILIO_ACCOUNT_SID}/Messages.json`

    const formData = new URLSearchParams()
    formData.append('To', phone)
    formData.append('From', TWILIO_PHONE_NUMBER!)
    formData.append('Body', `Your OTP code is: ${otp}. Valid for 10 minutes.`)

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
      throw new Error(`Twilio error: ${JSON.stringify(error)}`)
    }

    // Store OTP in Supabase with expiration (10 minutes)
    const { createClient } = await import('https://esm.sh/@supabase/supabase-js@2')
    const supabaseUrl = Deno.env.get('SUPABASE_URL')!
    const supabaseKey = Deno.env.get('SUPABASE_SERVICE_ROLE_KEY')!
    const supabase = createClient(supabaseUrl, supabaseKey)

    const expiresAt = new Date(Date.now() + 10 * 60 * 1000).toISOString()

    await supabase.from('phone_otps').upsert({
      phone: phone,
      otp: otp,
      expires_at: expiresAt,
      created_at: new Date().toISOString(),
    })

    return new Response(
      JSON.stringify({ success: true, message: 'OTP sent successfully' }),
      { headers: { ...corsHeaders, 'Content-Type': 'application/json' }, status: 200 }
    )
  } catch (error) {
    return new Response(
      JSON.stringify({ error: error.message }),
      { headers: { ...corsHeaders, 'Content-Type': 'application/json' }, status: 400 }
    )
  }
})
```

#### Function 2: Verify OTP

Create file: `supabase/functions/verify-otp/index.ts`

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
      throw new Error('OTP not found or expired')
    }

    // Check if OTP is expired
    if (new Date(data.expires_at) < new Date()) {
      // Delete expired OTP
      await supabase.from('phone_otps').delete().eq('phone', phone)
      throw new Error('OTP has expired')
    }

    // Verify OTP
    if (data.otp !== code) {
      throw new Error('Invalid OTP code')
    }

    // Delete OTP after successful verification
    await supabase.from('phone_otps').delete().eq('phone', phone)

    return new Response(
      JSON.stringify({ success: true, verified: true }),
      { headers: { ...corsHeaders, 'Content-Type': 'application/json' }, status: 200 }
    )
  } catch (error) {
    return new Response(
      JSON.stringify({ error: error.message }),
      { headers: { ...corsHeaders, 'Content-Type': 'application/json' }, status: 400 }
    )
  }
})
```

### Step 3: Create phone_otps Table in Supabase

Run this SQL in Supabase SQL Editor:

```sql
-- Create table to store OTPs temporarily
CREATE TABLE IF NOT EXISTS phone_otps (
  phone TEXT PRIMARY KEY,
  otp TEXT NOT NULL,
  expires_at TIMESTAMP NOT NULL,
  created_at TIMESTAMP DEFAULT NOW()
);

-- Add index for faster lookups
CREATE INDEX IF NOT EXISTS idx_phone_otps_expires_at ON phone_otps(expires_at);

-- Enable Row Level Security
ALTER TABLE phone_otps ENABLE ROW LEVEL SECURITY;

-- Create policy to allow service role to manage OTPs
CREATE POLICY "Service role can manage OTPs"
ON phone_otps
FOR ALL
TO service_role
USING (true)
WITH CHECK (true);
```

### Step 4: Deploy Edge Functions to Supabase

```bash
# Install Supabase CLI
npm install -g supabase

# Login to Supabase
supabase login

# Link your project
supabase link --project-ref cgkexriarshbftnjftlm

# Set environment variables (secrets)
supabase secrets set TWILIO_ACCOUNT_SID=your_account_sid
supabase secrets set TWILIO_AUTH_TOKEN=your_auth_token
supabase secrets set TWILIO_PHONE_NUMBER=your_twilio_phone

# Deploy the functions
supabase functions deploy send-otp
supabase functions deploy verify-otp
```

---

## 🎯 How It Works

### User Flow:

1. **User enters phone number** → Clicks "Get OTP"
2. **Twilio sends SMS** with 6-digit code
3. **OTP field appears** below phone input
4. **User enters OTP** → Clicks "Verify"
5. **Code verified** → Green checkmark appears
6. **User can now proceed** to sign up

### Without Verification:
- ❌ "Get OTP" button must be clicked
- ❌ OTP must be verified
- ❌ Cannot proceed to page 2 without verification
- ❌ Cannot sign up without verification

---

## 🔒 Security Features

- ✅ OTP expires after 10 minutes
- ✅ OTP is deleted after successful verification
- ✅ Phone number is disabled after verification (can't change)
- ✅ Must re-verify if phone number changes
- ✅ Stored securely in Supabase with RLS

---

## 💰 Twilio Pricing

**Free Trial:**
- $15.50 free credit
- Can send ~500 SMS messages for testing

**After Trial:**
- ~$0.0075 per SMS (varies by country)
- Monthly phone number: ~$1-2/month

---

## 🧪 Testing

### Test in Development:

1. Use your real phone number for testing
2. You'll receive actual SMS messages
3. Enter the OTP code to verify

### Alternative for Testing (Mock):

If you want to test without real SMS, you can modify the edge function to always return a specific OTP in development mode.

---

## ✅ Verification Status

The `phone_verified` field in Supabase shows:
- `true` - Phone verified during signup
- `false` - Phone not verified or not provided

---

## 🔧 Troubleshooting

### OTP Not Received:
- Check Twilio account has credits
- Verify phone number format (+CountryCode + Number)
- Check Twilio logs in dashboard

### Function Errors:
- Check Supabase function logs
- Verify environment variables are set
- Test functions in Supabase dashboard

---

## 📱 Next Steps

1. **Create Twilio account** and get credentials
2. **Run the SQL** to create phone_otps table
3. **Create the Edge Functions** in Supabase
4. **Deploy** the functions with Twilio credentials
5. **Test** the signup flow with real phone number

Your phone verification is now ready to use! 🎉
