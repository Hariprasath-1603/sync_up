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
    console.log(`Twilio response data: ${JSON.stringify(data)}`);

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
      
      // Provide helpful error messages
      let errorMessage = data.message || "Failed to send OTP";
      if (data.code === 60200) {
        errorMessage = "Phone number is invalid or not reachable. Please check the number format (e.g., +1234567890)";
      } else if (data.code === 60203) {
        errorMessage = "Maximum verification attempts reached. Please try again later or contact support.";
      } else if (data.code === 60212) {
        errorMessage = "This phone number is not verified in Twilio. For testing, add it to Twilio Console → Verify → Test Phone Numbers";
      }
      
      return new Response(
        JSON.stringify({ 
          error: errorMessage,
          details: data,
          code: data.code,
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
    const errorMessage = error instanceof Error ? error.message : "Unknown error occurred";
    console.error(`❌ Exception: ${errorMessage}`);
    return new Response(
      JSON.stringify({
        error: "Internal server error",
        message: errorMessage,
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

