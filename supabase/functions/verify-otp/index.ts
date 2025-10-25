// Supabase Edge Function: Verify OTP via Twilio Verify
import "jsr:@supabase/functions-js/edge-runtime.d.ts";

const TWILIO_ACCOUNT_SID = Deno.env.get("TWILIO_ACCOUNT_SID");
const TWILIO_AUTH_TOKEN = Deno.env.get("TWILIO_AUTH_TOKEN");
const TWILIO_VERIFY_SERVICE_SID = Deno.env.get("TWILIO_VERIFY_SERVICE_SID");

console.log("Verify OTP Function started");

Deno.serve(async (req) => {
  // Handle CORS preflight
  if (req.method === "OPTIONS") {
    return new Response(null, {
      headers: {
        "Access-Control-Allow-Origin": "*",
        "Access-Control-Allow-Methods": "POST, OPTIONS",
        "Access-Control-Allow-Headers": "authorization, content-type, x-client-info, apikey",
      },
    });
  }

  try {
    // Parse request body
    const { phone, code } = await req.json();
    console.log(`Received request to verify OTP for: ${phone}`);

    // Validate input
    if (!phone || !code) {
      console.error("Error: Phone number and code are required");
      return new Response(
        JSON.stringify({ error: "Phone number and code are required" }),
        { 
          status: 400, 
          headers: { 
            "Content-Type": "application/json",
            "Access-Control-Allow-Origin": "*",
          } 
        }
      );
    }

    // Validate Twilio credentials
    if (!TWILIO_ACCOUNT_SID || !TWILIO_AUTH_TOKEN || !TWILIO_VERIFY_SERVICE_SID) {
      console.error("Error: Twilio credentials not configured");
      return new Response(
        JSON.stringify({ error: "Server configuration error" }),
        { 
          status: 500, 
          headers: { 
            "Content-Type": "application/json",
            "Access-Control-Allow-Origin": "*",
          } 
        }
      );
    }

    // Verify OTP via Twilio Verify API
    const twilioUrl = `https://verify.twilio.com/v2/Services/${TWILIO_VERIFY_SERVICE_SID}/VerificationCheck`;
    console.log(`Calling Twilio API: ${twilioUrl}`);
    
    const response = await fetch(twilioUrl, {
      method: "POST",
      headers: {
        "Content-Type": "application/x-www-form-urlencoded",
        "Authorization": `Basic ${btoa(`${TWILIO_ACCOUNT_SID}:${TWILIO_AUTH_TOKEN}`)}`,
      },
      body: new URLSearchParams({
        To: phone,
        Code: code,
      }),
    });

    const data = await response.json();
    console.log(`Twilio response status: ${response.status}`);
    console.log(`Twilio verification status: ${data.status}`);

    if (response.ok && data.status === "approved") {
      console.log(`✅ OTP verified successfully for ${phone}`);
      return new Response(
        JSON.stringify({ 
          success: true, 
          message: "Phone verified successfully",
          valid: true,
          status: data.status,
        }),
        { 
          status: 200, 
          headers: { 
            "Content-Type": "application/json",
            "Access-Control-Allow-Origin": "*",
          } 
        }
      );
    } else {
      console.error(`❌ Verification failed: ${data.status || 'unknown'}`);
      console.error(`Twilio error: ${JSON.stringify(data)}`);
      return new Response(
        JSON.stringify({ 
          success: false,
          error: "Invalid or expired OTP code",
          valid: false,
          status: data.status || 'failed',
          message: data.message || "Verification failed",
        }),
        { 
          status: 400, 
          headers: { 
            "Content-Type": "application/json",
            "Access-Control-Allow-Origin": "*",
          } 
        }
      );
    }
  } catch (error) {
    console.error(`❌ Exception: ${error.message}`);
    return new Response(
      JSON.stringify({ 
        success: false,
        error: "Internal server error",
        message: error.message,
        valid: false,
      }),
      { 
        status: 500, 
        headers: { 
          "Content-Type": "application/json",
          "Access-Control-Allow-Origin": "*",
        } 
      }
    );
  }
});

/* To invoke locally:

  1. Run `supabase start`
  2. Set environment variables:
     supabase secrets set TWILIO_ACCOUNT_SID=ACxxx...
     supabase secrets set TWILIO_AUTH_TOKEN=your_token
     supabase secrets set TWILIO_VERIFY_SERVICE_SID=VAxxx...
  
  3. Make an HTTP request:
     curl -i --location --request POST 'http://127.0.0.1:54321/functions/v1/verify-otp' \
       --header 'Authorization: Bearer YOUR_ANON_KEY' \
       --header 'Content-Type: application/json' \
       --data '{"phone":"+919876543210","code":"123456"}'
*/
