// Supabase Edge Function: Send OTP via Twilio Verify
import "jsr:@supabase/functions-js/edge-runtime.d.ts";

const TWILIO_ACCOUNT_SID = Deno.env.get("TWILIO_ACCOUNT_SID");
const TWILIO_AUTH_TOKEN = Deno.env.get("TWILIO_AUTH_TOKEN");
const TWILIO_VERIFY_SERVICE_SID = Deno.env.get("TWILIO_VERIFY_SERVICE_SID");

console.log("Send OTP Function started");

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
    const { phone } = await req.json();
    console.log(`Received request to send OTP to: ${phone}`);

    // Validate input
    if (!phone) {
      console.error("Error: Phone number is required");
      return new Response(
        JSON.stringify({ error: "Phone number is required" }),
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

    // Send OTP via Twilio Verify API
    const twilioUrl = `https://verify.twilio.com/v2/Services/${TWILIO_VERIFY_SERVICE_SID}/Verifications`;
    console.log(`Calling Twilio API: ${twilioUrl}`);
    
    const response = await fetch(twilioUrl, {
      method: "POST",
      headers: {
        "Content-Type": "application/x-www-form-urlencoded",
        "Authorization": `Basic ${btoa(`${TWILIO_ACCOUNT_SID}:${TWILIO_AUTH_TOKEN}`)}`,
      },
      body: new URLSearchParams({
        To: phone,
        Channel: "sms",
      }),
    });

    const data = await response.json();
    console.log(`Twilio response status: ${response.status}`);

    if (response.ok) {
      console.log(`✅ OTP sent successfully to ${phone}`);
      return new Response(
        JSON.stringify({ 
          success: true, 
          message: "OTP sent successfully",
          status: data.status,
          to: phone,
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
      console.error(`❌ Twilio error: ${JSON.stringify(data)}`);
      return new Response(
        JSON.stringify({ 
          error: data.message || "Failed to send OTP",
          details: data,
        }),
        { 
          status: response.status, 
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
        error: "Internal server error",
        message: error.message,
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
     curl -i --location --request POST 'http://127.0.0.1:54321/functions/v1/send-otp' \
       --header 'Authorization: Bearer YOUR_ANON_KEY' \
       --header 'Content-Type: application/json' \
       --data '{"phone":"+919876543210"}'
*/

