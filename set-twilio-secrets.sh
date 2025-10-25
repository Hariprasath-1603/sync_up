# Twilio Secrets Configuration
# Copy and paste these commands into the terminal where you ran `supabase login`

# Step 1: Set Twilio Account SID
supabase secrets set TWILIO_ACCOUNT_SID=AC2e939a7361144d9d318488b9b1275da5 --project-ref cgkexriarshbftnjftlm

# Step 2: Set Twilio Auth Token
supabase secrets set TWILIO_AUTH_TOKEN=17f236cd367fb95cf583e5fc2a571e1c --project-ref cgkexriarshbftnjftlm

# Step 3: Set Twilio Verify Service SID
supabase secrets set TWILIO_VERIFY_SERVICE_SID=VA90137c49c17a5ced3419273219c22976 --project-ref cgkexriarshbftnjftlm

# Step 4: Verify secrets are set correctly
supabase secrets list --project-ref cgkexriarshbftnjftlm

# Step 5: Deploy verify-otp function
supabase functions deploy verify-otp --project-ref cgkexriarshbftnjftlm

# Step 6: Redeploy send-otp function with updated code
supabase functions deploy send-otp --project-ref cgkexriarshbftnjftlm

# Step 7: View deployed functions
supabase functions list --project-ref cgkexriarshbftnjftlm

# Done! Both functions are now deployed with Twilio credentials configured ✅
