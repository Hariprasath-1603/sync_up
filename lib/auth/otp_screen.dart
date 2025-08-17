import 'package:flutter/material.dart';
import 'package:lottie/lottie.dart';

class OtpScreen extends StatefulWidget {
  final String verificationType; // "Email" or "Mobile"
  final String contactInfo;      // The actual email or phone number

  const OtpScreen({
    super.key,
    required this.verificationType,
    required this.contactInfo,
  });

  @override
  State<OtpScreen> createState() => _OtpScreenState();
}

class _OtpScreenState extends State<OtpScreen> {
  final _formKey = GlobalKey<FormState>();
  final List<TextEditingController> _otpControllers =
  List.generate(6, (_) => TextEditingController());

  final String _defaultOtp = "123456"; // Default OTP for testing

  void _verifyOtp() {
    if (_formKey.currentState!.validate()) {
      String enteredOtp = _otpControllers.map((c) => c.text).join();
      if (enteredOtp == _defaultOtp) {
        // Return 'true' to indicate successful verification
        Navigator.of(context).pop(true);
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("Invalid OTP!"),
            backgroundColor: Colors.redAccent,
          ),
        );
      }
    }
  }

  Widget _buildOtpBox(int index) {
    return SizedBox(
      width: 50,
      child: TextFormField(
        controller: _otpControllers[index],
        keyboardType: TextInputType.number,
        textAlign: TextAlign.center,
        maxLength: 1,
        decoration: InputDecoration(
          counterText: '',
          filled: true,
          fillColor: Colors.grey[200],
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide.none,
          ),
        ),
        style: const TextStyle(
          fontSize: 20,
          fontWeight: FontWeight.bold,
          color: Colors.black87,
        ),
        validator: (value) {
          if (value == null || value.isEmpty) return '';
          return null;
        },
        onChanged: (value) {
          if (value.isNotEmpty && index < 5) {
            FocusScope.of(context).nextFocus();
          }
          if (value.isEmpty && index > 0) {
            FocusScope.of(context).previousFocus();
          }
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: Text(
          "${widget.verificationType} OTP Verification",
          style: const TextStyle(color: Colors.black),
        ),
        centerTitle: true,
        backgroundColor: Colors.white,
        elevation: 0,
      ),
      body: Form(
        key: _formKey,
        child: SingleChildScrollView(
          child: Center(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24.0),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Lottie.asset(
                    'assets/lottie/Verify_otp.json',
                    height: 200,
                    width: 200,
                    repeat: true,
                  ),
                  const SizedBox(height: 20),
                  Text(
                    "Enter the 6-digit code sent to your ${widget.verificationType.toLowerCase()}",
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w500,
                      color: Colors.black87,
                    ),
                  ),
                  const SizedBox(height: 10),
                  // Display the contact info with an edit button
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        widget.contactInfo,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.edit, size: 20, color: Colors.blue),
                        onPressed: () {
                          // Go back to the previous screen (sign-up or forgot password)
                          Navigator.of(context).pop();
                        },
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: List.generate(6, (index) => _buildOtpBox(index)),
                  ),
                  const SizedBox(height: 30),
                  ElevatedButton(
                    onPressed: _verifyOtp,
                    style: ButtonStyle(
                      backgroundColor: MaterialStateProperty.all(Colors.blueAccent),
                      padding: MaterialStateProperty.all(
                        const EdgeInsets.symmetric(horizontal: 100, vertical: 15),
                      ),
                      shape: MaterialStateProperty.all(
                        RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                    ),
                    child: const Text(
                      "Verify OTP",
                      style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Colors.white),
                    ),
                  ),
                  const SizedBox(height: 20),
                  TextButton(
                    onPressed: () {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          backgroundColor: Colors.blueAccent,
                          content: Text(
                            "OTP resent to your ${widget.verificationType.toLowerCase()}",
                          ),
                        ),
                      );
                    },
                    child: const Text(
                      "Resend OTP",
                      style: TextStyle(
                        fontSize: 16,
                        color: Colors.blueAccent,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
