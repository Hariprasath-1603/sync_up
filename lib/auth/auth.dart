import 'package:flutter/material.dart';
import 'package:lottie/lottie.dart';
import 'package:country_code_picker/country_code_picker.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'otp_screen.dart';
import '../home/home_screen.dart';

// ---------- 1. SERVICES (Firebase Logic) ----------

Future<void> saveUserData(User user, String username, String dob, String gender, String phone, String location) async {
  DocumentReference userDoc = FirebaseFirestore.instance.collection('users').doc(user.uid);
  await userDoc.set({
    'uid': user.uid,
    'username': username,
    'email': user.email,
    'dob': dob,
    'gender': gender,
    'phone': phone,
    'location': location,
    'createdAt': FieldValue.serverTimestamp(),
    'emailVerified': user.emailVerified,
  });
}

// ---------- 2. REUSABLE WIDGETS ----------

enum TextFieldType { text, password, phone }

class CustomTextField extends StatefulWidget {
  final TextEditingController? controller;
  final String hintText;
  final IconData? icon;
  final TextFieldType fieldType;
  final String? Function(String?)? validator;
  final Function(CountryCode)? onCountryChanged;
  final VoidCallback? onTap;
  final bool readOnly;
  final void Function(String)? onChanged;

  const CustomTextField({
    super.key,
    this.controller,
    required this.hintText,
    this.icon,
    this.fieldType = TextFieldType.text,
    this.validator,
    this.onCountryChanged,
    this.onTap,
    this.readOnly = false,
    this.onChanged,
  });

  @override
  State<CustomTextField> createState() => _CustomTextFieldState();
}

class _CustomTextFieldState extends State<CustomTextField> {
  bool _obscureText = true;

  @override
  Widget build(BuildContext context) {
    if (widget.fieldType == TextFieldType.phone) {
      return Padding(
        padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 10),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              decoration: BoxDecoration(
                color: Colors.grey[200],
                borderRadius: BorderRadius.circular(12),
              ),
              child: CountryCodePicker(
                onChanged: widget.onCountryChanged,
                initialSelection: 'IN',
                favorite: const ['+91', 'IN'],
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: TextFormField(
                controller: widget.controller,
                keyboardType: TextInputType.phone,
                style: const TextStyle(color: Colors.black87),
                validator: widget.validator,
                decoration: InputDecoration(
                  hintText: widget.hintText,
                  hintStyle: const TextStyle(color: Colors.black54),
                  filled: true,
                  fillColor: Colors.grey[200],
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide.none,
                  ),
                  errorStyle: const TextStyle(color: Colors.redAccent),
                ),
              ),
            ),
          ],
        ),
      );
    }

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 10),
      child: TextFormField(
        controller: widget.controller,
        obscureText: widget.fieldType == TextFieldType.password ? _obscureText : false,
        style: const TextStyle(color: Colors.black87),
        validator: widget.validator,
        onTap: widget.onTap,
        readOnly: widget.readOnly,
        onChanged: widget.onChanged,
        decoration: InputDecoration(
          prefixIcon: widget.icon != null ? Icon(widget.icon, color: Colors.grey[600]) : null,
          hintText: widget.hintText,
          hintStyle: const TextStyle(color: Colors.black54),
          filled: true,
          fillColor: Colors.grey[200],
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide.none,
          ),
          errorStyle: const TextStyle(color: Colors.redAccent),
          suffixIcon: widget.fieldType == TextFieldType.password
              ? IconButton(
            icon: Icon(
              _obscureText ? Icons.visibility_off : Icons.visibility,
              color: Colors.grey[600],
            ),
            onPressed: () {
              setState(() {
                _obscureText = !_obscureText;
              });
            },
          )
              : null,
        ),
      ),
    );
  }
}

class CustomDropdownField extends StatelessWidget {
  final String hintText;
  final IconData icon;
  final List<String> items;
  final TextEditingController controller;
  final String? Function(String?)? validator;

  const CustomDropdownField({
    super.key,
    required this.hintText,
    required this.icon,
    required this.items,
    required this.controller,
    this.validator,
  });

  void _showOptions(BuildContext context) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return SimpleDialog(
          title: Text('Select $hintText'),
          children: items.map((String item) {
            return SimpleDialogOption(
              onPressed: () {
                controller.text = item;
                Navigator.pop(context);
              },
              child: Text(item),
            );
          }).toList(),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 10),
      child: TextFormField(
        controller: controller,
        readOnly: true,
        onTap: () => _showOptions(context),
        validator: validator,
        decoration: InputDecoration(
          prefixIcon: Icon(icon, color: Colors.grey[600]),
          hintText: hintText,
          hintStyle: const TextStyle(color: Colors.black54),
          filled: true,
          fillColor: Colors.grey[200],
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide.none,
          ),
          errorStyle: const TextStyle(color: Colors.redAccent),
          suffixIcon: Icon(Icons.arrow_drop_down, color: Colors.grey[600]),
        ),
      ),
    );
  }
}

enum PasswordStrength { None, Weak, Normal, Strong }

class PasswordStrengthIndicator extends StatelessWidget {
  final PasswordStrength strength;

  const PasswordStrengthIndicator({super.key, required this.strength});

  Color _getColor() {
    switch (strength) {
      case PasswordStrength.Weak:
        return Colors.red;
      case PasswordStrength.Normal:
        return Colors.orange;
      case PasswordStrength.Strong:
        return Colors.green;
      default:
        return Colors.transparent;
    }
  }

  @override
  Widget build(BuildContext context) {
    if (strength == PasswordStrength.None) {
      return const SizedBox.shrink();
    }
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 8),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(8),
        child: Row(
          children: [
            Expanded(
              child: Container(
                height: 8,
                color: strength.index >= 1 ? _getColor() : Colors.grey[300],
              ),
            ),
            const SizedBox(width: 4),
            Expanded(
              child: Container(
                height: 8,
                color: strength.index >= 2 ? _getColor() : Colors.grey[300],
              ),
            ),
            const SizedBox(width: 4),
            Expanded(
              child: Container(
                height: 8,
                color: strength.index >= 3 ? _getColor() : Colors.grey[300],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class SocialLoginButton extends StatelessWidget {
  final String assetPath;
  final VoidCallback onTap;

  const SocialLoginButton({
    super.key,
    required this.assetPath,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          border: Border.all(color: Colors.grey[300]!),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Image.asset(assetPath, height: 30, width: 30),
      ),
    );
  }
}

// ---------- 3. MAIN SCREENS ----------

class AuthScreen extends StatelessWidget {
  const AuthScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      backgroundColor: Colors.white,
      body: LoginComponent(),
    );
  }
}

class LoginComponent extends StatefulWidget {
  const LoginComponent({super.key});

  @override
  State<LoginComponent> createState() => _LoginComponentState();
}

class _LoginComponentState extends State<LoginComponent> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _isLoading = false;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _signInWithEmail() async {
    if (_emailController.text.trim().isEmpty || _passwordController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Please enter both email and password.")),
      );
      return;
    }

    setState(() => _isLoading = true);
    try {
      await FirebaseAuth.instance.signInWithEmailAndPassword(
        email: _emailController.text.trim(),
        password: _passwordController.text.trim(),
      );

      if (mounted) {
        Navigator.of(context).pushAndRemoveUntil(
            MaterialPageRoute(builder: (context) => const HomeScreen()),
                (route) => false
        );
      }

    } on FirebaseAuthException catch (e) {
      String errorMessage = "An error occurred. Please try again.";
      if (e.code == 'invalid-credential' || e.code == 'user-not-found' || e.code == 'wrong-password') {
        errorMessage = "Incorrect email or password. Please try again.";
      } else if (e.code == 'invalid-email') {
        errorMessage = "The email address is badly formatted.";
      } else if (e.code == 'too-many-requests') {
        errorMessage = "Too many login attempts. Please try again later.";
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(errorMessage)),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("An unexpected error occurred: $e")),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _signInWithGoogle(BuildContext context) async {
    setState(() => _isLoading = true);
    try {
      final GoogleSignInAccount? googleUser = await GoogleSignIn().signIn();
      if (googleUser == null) {
        setState(() => _isLoading = false);
        return;
      }

      final GoogleSignInAuthentication googleAuth = await googleUser.authentication;
      final AuthCredential credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );

      final UserCredential userCredential = await FirebaseAuth.instance.signInWithCredential(credential);

      if (userCredential.additionalUserInfo!.isNewUser) {
        if(mounted) {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => const SignUpFlowScreen(isNewGoogleUser: true),
            ),
          );
        }
      } else {
        if (mounted) {
          Navigator.of(context).pushAndRemoveUntil(
              MaterialPageRoute(builder: (context) => const HomeScreen()),
                  (route) => false
          );
        }
      }
    } catch (e) {
      if(mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Failed to sign in with Google: $e")),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  void _showForgotPasswordSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (BuildContext context) {
        return Container(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                "Forgot Password?",
                style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              const Text(
                "Select how you'd like to reset your password.",
                style: TextStyle(fontSize: 16, color: Colors.grey),
              ),
              const SizedBox(height: 24),
              ListTile(
                leading: const Icon(Icons.email_outlined, color: Colors.blue),
                title: const Text("Reset with Email"),
                onTap: () {
                  Navigator.of(context).pop();
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const ForgotPasswordScreen(verificationType: "Email"),
                    ),
                  );
                },
              ),
              const Divider(),
              ListTile(
                leading: const Icon(Icons.phone_outlined, color: Colors.blue),
                title: const Text("Reset with Phone"),
                onTap: () {
                  Navigator.of(context).pop();
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const ForgotPasswordScreen(verificationType: "Mobile"),
                    ),
                  );
                },
              ),
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const SizedBox(height: 100),
          Lottie.asset('assets/lottie/Login.json', height: 250, width: 350),
          const Text(
            "Welcome Back!",
            style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 10),
          const Text(
            "Log in to your account",
            style: TextStyle(fontSize: 16, color: Colors.grey),
          ),
          const SizedBox(height: 30),
          CustomTextField(controller: _emailController, hintText: "Email", icon: Icons.email_outlined),
          CustomTextField(
            controller: _passwordController,
            hintText: "Password",
            icon: Icons.lock_outline,
            fieldType: TextFieldType.password,
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 30.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                TextButton(
                  onPressed: () => _showForgotPasswordSheet(context),
                  child: const Text("Forgot Password?"),
                ),
              ],
            ),
          ),
          const SizedBox(height: 10),
          _isLoading
              ? const CircularProgressIndicator()
              : ElevatedButton(
            onPressed: _signInWithEmail,
            style: ButtonStyle(
              backgroundColor: MaterialStateProperty.all(Colors.blue),
              foregroundColor: MaterialStateProperty.all(Colors.white),
              padding: MaterialStateProperty.all(
                const EdgeInsets.symmetric(horizontal: 80, vertical: 15),
              ),
              shape: MaterialStateProperty.all(
                RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
            child: const Text("Login", style: TextStyle(fontSize: 16)),
          ),
          const SizedBox(height: 20),
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 40.0, vertical: 10.0),
            child: Row(
              children: [
                Expanded(child: Divider()),
                Padding(
                  padding: EdgeInsets.symmetric(horizontal: 8.0),
                  child: Text("Or continue with", style: TextStyle(color: Colors.grey)),
                ),
                Expanded(child: Divider()),
              ],
            ),
          ),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              SocialLoginButton(
                assetPath: 'assets/logos/google.png',
                onTap: () => _signInWithGoogle(context),
              ),
              const SizedBox(width: 20),
              SocialLoginButton(
                assetPath: 'assets/logos/apple.png',
                onTap: () {
                  // TODO: Implement Apple Sign-In
                },
              ),
              const SizedBox(width: 20),
              SocialLoginButton(
                assetPath: 'assets/logos/microsoft.png',
                onTap: () {
                  // TODO: Implement Microsoft Sign-In
                },
              ),
            ],
          ),
          const SizedBox(height: 20),
          TextButton(
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const SignUpFlowScreen(),
                ),
              );
            },
            child: const Text.rich(
              TextSpan(
                style: TextStyle(color: Colors.black, fontSize: 14),
                children: [
                  TextSpan(text: "Don't have an account? "),
                  TextSpan(
                    text: "Sign Up",
                    style: TextStyle(
                      color: Colors.blue,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class EmailLinkSentScreen extends StatelessWidget {
  const EmailLinkSentScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Lottie.asset(
                'assets/lottie/email_sent.json',
                height: 250,
                width: 250,
              ),
              const SizedBox(height: 30),
              const Text(
                "Check Your Inbox!",
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 16),
              const Text(
                "We've sent a password reset link to your email address.",
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 16, color: Colors.grey),
              ),
              const SizedBox(height: 40),
              ElevatedButton(
                onPressed: () {
                  Navigator.pushAndRemoveUntil(
                    context,
                    MaterialPageRoute(builder: (context) => const AuthScreen()),
                        (route) => false,
                  );
                },
                style: ButtonStyle(
                  backgroundColor: MaterialStateProperty.all(Colors.blue),
                  foregroundColor: MaterialStateProperty.all(Colors.white),
                  padding: MaterialStateProperty.all(
                    const EdgeInsets.symmetric(horizontal: 80, vertical: 15),
                  ),
                  shape: MaterialStateProperty.all(
                    RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
                child: const Text("Continue", style: TextStyle(fontSize: 16)),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class ForgotPasswordScreen extends StatefulWidget {
  final String verificationType;
  const ForgotPasswordScreen({super.key, required this.verificationType});

  @override
  State<ForgotPasswordScreen> createState() => _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState extends State<ForgotPasswordScreen> {
  final _formKey = GlobalKey<FormState>();
  final _contactController = TextEditingController();
  String _countryCode = "+91";
  bool _isLoading = false;

  @override
  void dispose() {
    _contactController.dispose();
    super.dispose();
  }

  // ##################################################################
  // ##                                                              ##
  // ##      THIS IS THE FUNCTION THAT HAS BEEN UPDATED              ##
  // ##                                                              ##
  // ##################################################################
  void _sendVerification() async {
    if (_formKey.currentState!.validate()) {
      setState(() => _isLoading = true);
      String contactInfo = _contactController.text.trim();

      try {
        if (widget.verificationType == "Email") {
          // FIX: Removed the manual user check. Let Firebase handle it.
          await FirebaseAuth.instance.sendPasswordResetEmail(email: contactInfo);

          if (mounted) {
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(
                builder: (context) => const EmailLinkSentScreen(),
              ),
            );
          }
        } else { // Mobile verification logic remains the same
          await FirebaseAuth.instance.verifyPhoneNumber(
            phoneNumber: _countryCode + contactInfo,
            verificationCompleted: (PhoneAuthCredential credential) async {},
            verificationFailed: (FirebaseAuthException e) {
              throw e;
            },
            codeSent: (String verificationId, int? resendToken) async {
              if (mounted) {
                final result = await Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => OtpScreen(
                      verificationType: "Mobile",
                      contactInfo: _countryCode + contactInfo,
                      verificationId: verificationId,
                      resendToken: resendToken,
                    ),
                  ),
                );
                if (result == true) {
                  Navigator.pushReplacement(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const ResetPasswordScreen(),
                    ),
                  );
                }
              }
            },
            codeAutoRetrievalTimeout: (String verificationId) {},
          );
        }
      } on FirebaseAuthException catch (e) {
        if (mounted) {
          String errorMessage = "An error occurred. Please try again.";
          // FIX: This now correctly catches the error from sendPasswordResetEmail
          if (e.code == 'user-not-found') {
            errorMessage = "No account found with this email.";
          } else if (e.code == 'invalid-email') {
            errorMessage = "Please enter a valid email address.";
          }
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(errorMessage)),
          );
        }
      } finally {
        if (mounted) {
          setState(() => _isLoading = false);
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    bool isMobile = widget.verificationType == "Mobile";
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text("Reset Password", style: TextStyle(color: Colors.black)),
        backgroundColor: Colors.white,
        elevation: 0,
      ),
      body: Form(
        key: _formKey,
        child: SingleChildScrollView(
          child: Column(
            children: [
              const SizedBox(height: 50),
              Lottie.asset('assets/lottie/Verify_otp.json', height: 200),
              const SizedBox(height: 20),
              Text(
                "Enter your ${isMobile ? 'phone number' : 'email'}",
                style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 20),
              if (isMobile)
                CustomTextField(
                  controller: _contactController,
                  hintText: "Phone Number",
                  fieldType: TextFieldType.phone,
                  onCountryChanged: (country) {
                    setState(() {
                      _countryCode = country.dialCode!;
                    });
                  },
                  validator: (value) => value == null || value.isEmpty ? 'Please enter your phone number' : null,
                )
              else
                CustomTextField(
                  controller: _contactController,
                  hintText: "Email",
                  icon: Icons.email_outlined,
                  validator: (value) {
                    if (value == null || value.isEmpty) return 'Please enter your email';
                    if (!RegExp(r'^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$').hasMatch(value)) return 'Please enter a valid email';
                    return null;
                  },
                ),
              const SizedBox(height: 30),
              _isLoading
                  ? const CircularProgressIndicator()
                  : ElevatedButton(
                onPressed: _sendVerification,
                style: ButtonStyle(
                  backgroundColor: MaterialStateProperty.all(Colors.blue),
                  foregroundColor: MaterialStateProperty.all(Colors.white),
                  padding: MaterialStateProperty.all(
                    const EdgeInsets.symmetric(horizontal: 80, vertical: 15),
                  ),
                  shape: MaterialStateProperty.all(
                    RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
                child: const Text("Send Link/OTP", style: TextStyle(fontSize: 16)),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class SignUpFlowScreen extends StatefulWidget {
  final bool isNewGoogleUser;
  const SignUpFlowScreen({super.key, this.isNewGoogleUser = false});

  @override
  State<SignUpFlowScreen> createState() => _SignUpFlowScreenState();
}

class _SignUpFlowScreenState extends State<SignUpFlowScreen> {
  final PageController _pageController = PageController();
  final _formKey1 = GlobalKey<FormState>();
  final _formKey2 = GlobalKey<FormState>();

  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  final _dobController = TextEditingController();
  final _locationController = TextEditingController();
  final _phoneController = TextEditingController();
  final _genderController = TextEditingController();
  String _countryCode = "+91";

  PasswordStrength _passwordStrength = PasswordStrength.None;
  bool _isEmailVerified = false;
  bool _isPhoneVerified = false;
  bool _isLoading = false;

  static const Map<String, List<String>> _locationSuggestions = {
    '+91': ['Mumbai', 'Delhi', 'Bangalore', 'Chennai', 'Kolkata', 'Hyderabad','Coimbatore'],
    '+61': ['Sydney', 'Melbourne', 'Brisbane', 'Perth', 'Adelaide', 'Canberra'],
    '+1': ['New York', 'Los Angeles', 'Chicago', 'Houston', 'Phoenix', 'Philadelphia'],
    '+44': ['London', 'Manchester', 'Birmingham', 'Glasgow', 'Liverpool', 'Bristol'],
  };

  static const Map<String, int> _phoneLengthByCountry = {
    '+1': 10,
    '+44': 10,
    '+61': 9,
    '+81': 10,
    '+86': 11,
    '+91': 10,
  };

  @override
  void initState() {
    super.initState();
    _passwordController.addListener(_checkPasswordStrength);
    if (widget.isNewGoogleUser) {
      final user = FirebaseAuth.instance.currentUser;
      if (user != null) {
        _nameController.text = user.displayName ?? "";
        _emailController.text = user.email ?? "";
        _isEmailVerified = true;
      }
    }
  }

  @override
  void dispose() {
    _pageController.dispose();
    _nameController.dispose();
    _emailController.dispose();
    _passwordController.removeListener(_checkPasswordStrength);
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    _dobController.dispose();
    _locationController.dispose();
    _phoneController.dispose();
    _genderController.dispose();
    super.dispose();
  }

  void _checkPasswordStrength() {
    String password = _passwordController.text;
    if (password.isEmpty) {
      setState(() => _passwordStrength = PasswordStrength.None);
      return;
    }
    bool hasLetters = password.contains(RegExp(r'[a-zA-Z]'));
    bool hasNumbers = password.contains(RegExp(r'[0-9]'));
    bool hasSpecialChars = password.contains(RegExp(r'[!@#$%^&*(),.?":{}|<>]'));
    if (password.length < 8) {
      setState(() => _passwordStrength = PasswordStrength.Weak);
    } else if (hasLetters && hasNumbers && hasSpecialChars) {
      setState(() => _passwordStrength = PasswordStrength.Strong);
    } else if (hasLetters && hasNumbers) {
      setState(() => _passwordStrength = PasswordStrength.Normal);
    } else {
      setState(() => _passwordStrength = PasswordStrength.Weak);
    }
  }

  void _onSignUp() async {
    if (_formKey2.currentState!.validate()) {
      if (!_isPhoneVerified) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Please verify your phone number.")),
        );
        return;
      }
      if (_dobController.text.isNotEmpty) {
        final dob = DateTime.parse(_dobController.text);
        final eightYearsAgo = DateTime.now().subtract(const Duration(days: 365 * 8));
        if (dob.isAfter(eightYearsAgo)) {
          _showAgeRestrictionDialog();
          return;
        }
      }

      setState(() => _isLoading = true);

      try {
        User? user;
        if (!widget.isNewGoogleUser) {
          UserCredential userCredential = await FirebaseAuth.instance.createUserWithEmailAndPassword(
            email: _emailController.text.trim(),
            password: _passwordController.text,
          );
          user = userCredential.user;

          if (user != null && !user.emailVerified) {
            await user.sendEmailVerification();
          }

        } else {
          user = FirebaseAuth.instance.currentUser;
        }
        if (user != null) {
          await saveUserData(
            user,
            _nameController.text.trim(),
            _dobController.text,
            _genderController.text,
            _countryCode + _phoneController.text.trim(),
            _locationController.text.trim(),
          );
          if (mounted) {
            Navigator.pushAndRemoveUntil(
              context,
              MaterialPageRoute(builder: (context) => const SignUpSuccessScreen()),
                  (Route<dynamic> route) => false,
            );
          }
        }
      } on FirebaseAuthException catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text("Failed to create account: ${e.message}")),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text("An unexpected error occurred: $e")),
          );
        }
      } finally {
        if (mounted) {
          setState(() => _isLoading = false);
        }
      }
    }
  }

  void _showAgeRestrictionDialog() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text("Age Restriction"),
          content: const Text("You must be at least 8 years old. Parental access is required."),
          actions: <Widget>[
            TextButton(
              child: const Text("OK"),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
          ],
        );
      },
    );
  }

  Future<void> _selectDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now().subtract(const Duration(days: 365 * 8)),
      firstDate: DateTime(1900),
      lastDate: DateTime.now(),
    );
    if (picked != null) {
      final DateTime eightYearsAgo = DateTime.now().subtract(const Duration(days: 365 * 8));
      if (picked.isAfter(eightYearsAgo)) {
        _showAgeRestrictionDialog();
        setState(() {
          _dobController.clear();
        });
      } else {
        setState(() {
          _dobController.text = "${picked.toLocal()}".split(' ')[0];
        });
      }
    }
  }

  Future<void> _verifyPhone() async {
    final phone = _phoneController.text.trim();
    int? expectedLength = _phoneLengthByCountry[_countryCode];

    if (phone.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Please enter a phone number.")),
      );
      return;
    }
    if (expectedLength != null && phone.length != expectedLength) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Phone number for $_countryCode must be $expectedLength digits.")),
      );
      return;
    }

    setState(() => _isLoading = true);

    await FirebaseAuth.instance.verifyPhoneNumber(
      phoneNumber: _countryCode + phone,
      verificationCompleted: (PhoneAuthCredential credential) {
        setState(() {
          _isLoading = false;
          _isPhoneVerified = true;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Phone number verified automatically.")),
        );
      },
      verificationFailed: (FirebaseAuthException e) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Phone verification failed: ${e.message}")),
        );
      },
      codeSent: (String verificationId, int? resendToken) async {
        setState(() => _isLoading = false);
        final result = await Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => OtpScreen(
              verificationType: "Mobile",
              contactInfo: _countryCode + phone,
              verificationId: verificationId,
              resendToken: resendToken,
            ),
          ),
        );
        if (result == true) {
          setState(() {
            _isPhoneVerified = true;
          });
        }
      },
      codeAutoRetrievalTimeout: (String verificationId) {},
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text("Create Account", style: TextStyle(color: Colors.black)),
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () {
            if (_pageController.page == 1.0) {
              _pageController.previousPage(
                duration: const Duration(milliseconds: 400),
                curve: Curves.easeInOut,
              );
            } else {
              Navigator.of(context).pop();
            }
          },
        ),
      ),
      body: PageView(
        controller: _pageController,
        physics: const NeverScrollableScrollPhysics(),
        children: [_buildPage1(), _buildPage2()],
      ),
    );
  }

  Widget _buildPage1() {
    return Form(
      key: _formKey1,
      child: SingleChildScrollView(
        child: Column(
          children: [
            Lottie.asset('assets/lottie/register.json', height: 250, width: 350),
            const Text("Account Details (1/2)",
                style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
            const SizedBox(height: 20),
            CustomTextField(
              controller: _nameController,
              hintText: "Username",
              icon: Icons.person_outline,
              validator: (value) => value == null || value.isEmpty ? 'Please enter your username' : null,
            ),
            CustomTextField(
              controller: _emailController,
              hintText: "Email",
              icon: Icons.email_outlined,
              readOnly: widget.isNewGoogleUser,
              validator: (value) {
                if (value == null || value.isEmpty) return 'Please enter your email';
                if (!RegExp(r'^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$').hasMatch(value)) return 'Please enter a valid email';
                return null;
              },
            ),
            if (!widget.isNewGoogleUser) ...[
              CustomTextField(
                controller: _passwordController,
                hintText: "Password",
                icon: Icons.lock_outline,
                fieldType: TextFieldType.password,
                validator: (value) {
                  if (value == null || value.isEmpty) return 'Please enter a password';
                  if (_passwordStrength == PasswordStrength.Weak) return 'Password is too weak';
                  return null;
                },
              ),
              PasswordStrengthIndicator(strength: _passwordStrength),
              const SizedBox(height: 10),
              CustomTextField(
                controller: _confirmPasswordController,
                hintText: "Confirm Password",
                icon: Icons.lock_outline,
                fieldType: TextFieldType.password,
                validator: (value) {
                  if (value == null || value.isEmpty) return 'Please confirm your password';
                  if (value != _passwordController.text) return 'Passwords do not match';
                  return null;
                },
              ),
            ],
            const SizedBox(height: 30),
            ElevatedButton(
              onPressed: () {
                if (_formKey1.currentState!.validate()) {
                  _pageController.nextPage(
                    duration: const Duration(milliseconds: 400),
                    curve: Curves.easeInOut,
                  );
                }
              },
              style: ButtonStyle(
                backgroundColor: MaterialStateProperty.all(Colors.blue),
                foregroundColor: MaterialStateProperty.all(Colors.white),
                padding: MaterialStateProperty.all(
                  const EdgeInsets.symmetric(horizontal: 80, vertical: 15),
                ),
                shape: MaterialStateProperty.all(
                  RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
              child: const Text("Next", style: TextStyle(fontSize: 16)),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPage2() {
    return Form(
      key: _formKey2,
      child: SingleChildScrollView(
        child: Column(
          children: [
            Lottie.asset('assets/lottie/register.json', height: 250, width: 350),
            const Text("Personal Details (2/2)",
                style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
            const SizedBox(height: 20),
            CustomTextField(
              controller: _dobController,
              hintText: "Date of Birth",
              icon: Icons.cake_outlined,
              readOnly: true,
              onTap: () => _selectDate(context),
              validator: (value) {
                if (value == null || value.isEmpty) return 'Please select your date of birth';
                return null;
              },
            ),
            CustomDropdownField(
              controller: _genderController,
              hintText: "Gender",
              icon: Icons.person,
              items: const ["Male", "Female", "Other", "Prefer not to say"],
              validator: (value) => value == null || value.isEmpty ? 'Please select your gender' : null,
            ),
            Column(
              children: [
                CustomTextField(
                  controller: _phoneController,
                  hintText: "Phone Number",
                  fieldType: TextFieldType.phone,
                  onCountryChanged: (country) {
                    setState(() {
                      _countryCode = country.dialCode!;
                      _locationController.text = country.name ?? '';
                    });
                  },
                  validator: (value) => value == null || value.isEmpty ? 'Please enter your phone' : null,
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 40.0),
                  child: Align(
                    alignment: Alignment.centerRight,
                    child: _isPhoneVerified
                        ? const Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text("Verified", style: TextStyle(color: Colors.green)),
                        Icon(Icons.check_circle, color: Colors.green, size: 16),
                      ],
                    )
                        : _isLoading
                        ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(strokeWidth: 2))
                        : TextButton(onPressed: _verifyPhone, child: const Text("Verify")),
                  ),
                ),
              ],
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 10),
              child: Autocomplete<String>(
                optionsBuilder: (TextEditingValue textEditingValue) {
                  if (textEditingValue.text.isEmpty) {
                    return const Iterable<String>.empty();
                  }
                  List<String> suggestions = _locationSuggestions[_countryCode] ?? [];
                  return suggestions.where((String option) {
                    return option.toLowerCase().startsWith(textEditingValue.text.toLowerCase());
                  });
                },
                onSelected: (String selection) {
                  _locationController.text = selection;
                },
                fieldViewBuilder: (BuildContext context, TextEditingController fieldController, FocusNode fieldFocusNode, VoidCallback onFieldSubmitted) {
                  WidgetsBinding.instance.addPostFrameCallback((_) {
                    fieldController.text = _locationController.text;
                  });
                  return TextFormField(
                    controller: fieldController,
                    focusNode: fieldFocusNode,
                    onChanged: (String value) {
                      _locationController.text = value;
                    },
                    style: const TextStyle(color: Colors.black87),
                    validator: (value) => value == null || value.isEmpty ? 'Please enter your location' : null,
                    decoration: InputDecoration(
                      prefixIcon: Icon(Icons.location_on_outlined, color: Colors.grey[600]),
                      hintText: "Location",
                      hintStyle: TextStyle(color: Colors.grey[700]),
                      filled: true,
                      fillColor: Colors.grey[200],
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide.none,
                      ),
                      errorStyle: const TextStyle(color: Colors.redAccent),
                    ),
                  );
                },
                optionsViewBuilder: (BuildContext context, AutocompleteOnSelected<String> onSelected, Iterable<String> options) {
                  return Align(
                    alignment: Alignment.topLeft,
                    child: Material(
                      elevation: 4.0,
                      child: SizedBox(
                        height: 200.0,
                        child: ListView.builder(
                          padding: EdgeInsets.zero,
                          itemCount: options.length,
                          itemBuilder: (BuildContext context, int index) {
                            final String option = options.elementAt(index);
                            return GestureDetector(
                              onTap: () {
                                onSelected(option);
                              },
                              child: ListTile(
                                title: Text(option),
                              ),
                            );
                          },
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
            const SizedBox(height: 30),
            _isLoading
                ? const CircularProgressIndicator()
                : ElevatedButton(
              onPressed: _onSignUp,
              style: ButtonStyle(
                backgroundColor: MaterialStateProperty.all(Colors.blue),
                foregroundColor: MaterialStateProperty.all(Colors.white),
                padding: MaterialStateProperty.all(
                  const EdgeInsets.symmetric(horizontal: 80, vertical: 15),
                ),
                shape: MaterialStateProperty.all(
                  RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
              child: const Text("Sign Up", style: TextStyle(fontSize: 16)),
            ),
          ],
        ),
      ),
    );
  }
}

class SignUpSuccessScreen extends StatefulWidget {
  const SignUpSuccessScreen({super.key});

  @override
  State<SignUpSuccessScreen> createState() => _SignUpSuccessScreenState();
}

class _SignUpSuccessScreenState extends State<SignUpSuccessScreen> {
  bool _privacyPolicyAccepted = false;

  void _showPrivacyPolicy(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (BuildContext context) {
        return StatefulBuilder(
          builder: (BuildContext context, StateSetter setSheetState) {
            return Container(
              height: MediaQuery.of(context).size.height * 0.8,
              padding: const EdgeInsets.all(24),
              child: Column(
                children: [
                  const Text("Privacy Policy", style: TextStyle(
                      fontSize: 22, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 16),
                  Expanded(
                    child: SingleChildScrollView(
                      child: Text(
                        "Here is the full text of the privacy policy for SyncUp..." * 20, // Placeholder
                        style: const TextStyle(fontSize: 14),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Checkbox(
                        value: _privacyPolicyAccepted,
                        onChanged: (bool? value) {
                          setSheetState(() {
                            _privacyPolicyAccepted = value!;
                          });
                          setState(() {
                            _privacyPolicyAccepted = value!;
                          });
                        },
                      ),
                      const Expanded(
                          child: Text("I have read and agree to the terms.")),
                    ],
                  ),
                  const SizedBox(height: 10),
                  ElevatedButton(
                    onPressed: () => Navigator.of(context).pop(),
                    child: const Text("Close"),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Lottie.asset(
                'assets/lottie/celebration.json',
                height: 300,
                width: 300,
                repeat: false,
              ),
              const SizedBox(height: 20),
              const Text(
                "Ready to Go!",
                style: TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 10),
              const Text(
                "Please check your email to verify your account.",
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 16, color: Colors.grey),
              ),
              const SizedBox(height: 40),
              ElevatedButton(
                onPressed: () {
                  if (_privacyPolicyAccepted) {
                    Navigator.pushAndRemoveUntil(
                      context,
                      MaterialPageRoute(builder: (context) => const HomeScreen()),
                          (route) => false,
                    );
                  } else {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text(
                          "Please accept the privacy policy to continue.")),
                    );
                  }
                },
                style: ButtonStyle(
                  backgroundColor: MaterialStateProperty.all(Colors.blue),
                  foregroundColor: MaterialStateProperty.all(Colors.white),
                  padding: MaterialStateProperty.all(
                    const EdgeInsets.symmetric(horizontal: 80, vertical: 15),
                  ),
                  shape: MaterialStateProperty.all(
                    RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
                child: const Text(
                    "Let's Start", style: TextStyle(fontSize: 16)),
              ),
              const SizedBox(height: 20),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Checkbox(
                    value: _privacyPolicyAccepted,
                    onChanged: (bool? value) {
                      setState(() {
                        _privacyPolicyAccepted = value!;
                      });
                    },
                  ),
                  Flexible(
                    child: GestureDetector(
                      onTap: () => _showPrivacyPolicy(context),
                      child: RichText(
                        text: const TextSpan(
                          style: TextStyle(fontSize: 12, color: Colors.black),
                          children: [
                            TextSpan(text: "I agree to the "),
                            TextSpan(
                              text: "Privacy Policy and Terms of Service.",
                              style: TextStyle(color: Colors.blue,
                                  decoration: TextDecoration.underline),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class ResetPasswordScreen extends StatefulWidget {
  const ResetPasswordScreen({super.key});

  @override
  State<ResetPasswordScreen> createState() => _ResetPasswordScreenState();
}

class _ResetPasswordScreenState extends State<ResetPasswordScreen> {
  final _formKey = GlobalKey<FormState>();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  PasswordStrength _passwordStrength = PasswordStrength.None;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _passwordController.addListener(_checkPasswordStrength);
  }

  @override
  void dispose() {
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  void _checkPasswordStrength() {
    String password = _passwordController.text;
    if (password.isEmpty) {
      setState(() => _passwordStrength = PasswordStrength.None);
      return;
    }
    bool hasLetters = password.contains(RegExp(r'[a-zA-Z]'));
    bool hasNumbers = password.contains(RegExp(r'[0-9]'));
    bool hasSpecialChars = password.contains(RegExp(r'[!@#$%^&*(),.?":{}|<>]'));
    if (password.length < 8) {
      setState(() => _passwordStrength = PasswordStrength.Weak);
    } else if (hasLetters && hasNumbers && hasSpecialChars) {
      setState(() => _passwordStrength = PasswordStrength.Strong);
    } else if (hasLetters && hasNumbers) {
      setState(() => _passwordStrength = PasswordStrength.Normal);
    } else {
      setState(() => _passwordStrength = PasswordStrength.Weak);
    }
  }

  void _resetPassword() async {
    if (_formKey.currentState!.validate()) {
      setState(() => _isLoading = true);
      try {
        await FirebaseAuth.instance.currentUser?.updatePassword(_passwordController.text.trim());
        if(mounted) {
          Navigator.pushAndRemoveUntil(
            context,
            MaterialPageRoute(builder: (context) => const ResetSuccessScreen()),
                (route) => false,
          );
        }
      } on FirebaseAuthException catch (e) {
        if(mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text("Error: ${e.message}")),
          );
        }
      } finally {
        if(mounted) {
          setState(() => _isLoading = false);
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text("Create New Password", style: TextStyle(color: Colors.black)),
        backgroundColor: Colors.white,
        elevation: 0,
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Form(
            key: _formKey,
            child: Column(
              children: [
                const SizedBox(height: 50),
                const Text(
                  "Your new password must be different from previously used passwords.",
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 16, color: Colors.grey),
                ),
                const SizedBox(height: 30),
                CustomTextField(
                  controller: _passwordController,
                  hintText: "New Password",
                  icon: Icons.lock_outline,
                  fieldType: TextFieldType.password,
                  validator: (value) {
                    if (value == null || value.isEmpty) return 'Please enter a password';
                    if (_passwordStrength == PasswordStrength.Weak) return 'Password is too weak';
                    return null;
                  },
                ),
                PasswordStrengthIndicator(strength: _passwordStrength),
                const SizedBox(height: 10),
                CustomTextField(
                  controller: _confirmPasswordController,
                  hintText: "Confirm New Password",
                  icon: Icons.lock_outline,
                  fieldType: TextFieldType.password,
                  validator: (value) {
                    if (value == null || value.isEmpty) return 'Please confirm your password';
                    if (value != _passwordController.text) return 'Passwords do not match';
                    return null;
                  },
                ),
                const SizedBox(height: 40),
                _isLoading
                    ? const CircularProgressIndicator()
                    : ElevatedButton(
                  onPressed: _resetPassword,
                  style: ButtonStyle(
                    backgroundColor: MaterialStateProperty.all(Colors.blue),
                    foregroundColor: MaterialStateProperty.all(Colors.white),
                    padding: MaterialStateProperty.all(
                      const EdgeInsets.symmetric(horizontal: 80, vertical: 15),
                    ),
                    shape: MaterialStateProperty.all(
                      RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),
                  child: const Text("Reset Password", style: TextStyle(fontSize: 16)),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class ResetSuccessScreen extends StatelessWidget {
  const ResetSuccessScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Lottie.asset(
                'assets/lottie/otp_success.json',
                height: 300,
                width: 300,
                repeat: false,
              ),
              const SizedBox(height: 20),
              const Text(
                "Password Reset Successful!",
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 40),
              ElevatedButton(
                onPressed: () {
                  Navigator.pushAndRemoveUntil(
                    context,
                    MaterialPageRoute(builder: (context) => const AuthScreen()),
                        (route) => false,
                  );
                },
                style: ButtonStyle(
                  backgroundColor: MaterialStateProperty.all(Colors.blue),
                  foregroundColor: MaterialStateProperty.all(Colors.white),
                  padding: MaterialStateProperty.all(
                    const EdgeInsets.symmetric(horizontal: 80, vertical: 15),
                  ),
                  shape: MaterialStateProperty.all(
                    RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
                child: const Text("Continue", style: TextStyle(fontSize: 16)),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
