import 'dart:convert';
import 'package:http/http.dart' as http;

// Quick test script to verify Twilio credentials
// Run this to check if Twilio is working before deploying Edge Functions

void main() async {
  const twilioAccountSid = 'AC2e939a7361144d9d318488b9b1275da5';
  const twilioAuthToken = '17f236cd367fb95cf583e5fc2a571e1c';
  const twilioPhoneNumber = '+13208558889';
  const testPhoneNumber = '+18777804236'; // Your test phone

  print('🧪 Testing Twilio credentials...\n');

  try {
    // Create Basic Auth header
    final auth = base64Encode(
      utf8.encode('$twilioAccountSid:$twilioAuthToken'),
    );
    final twilioUrl =
        'https://api.twilio.com/2010-04-01/Accounts/$twilioAccountSid/Messages.json';

    // Send test SMS
    final response = await http.post(
      Uri.parse(twilioUrl),
      headers: {
        'Authorization': 'Basic $auth',
        'Content-Type': 'application/x-www-form-urlencoded',
      },
      body: {
        'To': testPhoneNumber,
        'From': twilioPhoneNumber,
        'Body': 'Test SMS from SyncUp app. Your Twilio is working! 🎉',
      },
    );

    print('Status Code: ${response.statusCode}');
    print('Response: ${response.body}\n');

    if (response.statusCode == 201) {
      final data = json.decode(response.body);
      print('✅ SUCCESS! SMS sent successfully!');
      print('   Message SID: ${data['sid']}');
      print('   Status: ${data['status']}');
      print('   To: ${data['to']}');
      print('   From: ${data['from']}');
      print('\n📱 Check your phone for the test SMS!');
    } else {
      final error = json.decode(response.body);
      print('❌ FAILED: ${error['message']}');
      print('   Error Code: ${error['code']}');
      print('   More Info: ${error['more_info']}');

      if (error['code'] == 21608) {
        print('\n🔧 FIX: Verify $testPhoneNumber in Twilio Console');
        print(
          '   https://console.twilio.com/us1/develop/phone-numbers/manage/verified',
        );
      }
    }
  } catch (e) {
    print('❌ ERROR: $e');
  }
}
