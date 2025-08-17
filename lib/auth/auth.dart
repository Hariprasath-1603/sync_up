import 'package:flutter/material.dart';
import 'package:lottie/lottie.dart';
import 'package:country_code_picker/country_code_picker.dart';
import 'otp_screen.dart'; // Assuming otp_screen.dart is in the same directory

// ---------- ENUMS FOR CUSTOM WIDGETS ----------
enum TextFieldType { text, password, phone }
enum PasswordStrength { None, Weak, Normal, Strong }

// ---------- UNIFIED REUSABLE TEXTFIELD WIDGET ----------
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
    // Build the phone field layout
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

    // Build the regular/password field layout
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

// ---------- CUSTOM DROPDOWN WIDGET FOR GENDER ----------
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

// ---------- PASSWORD STRENGTH INDICATOR WIDGET ----------
class PasswordStrengthIndicator extends StatelessWidget {
  final PasswordStrength strength;

  const PasswordStrengthIndicator({super.key, required this.strength});

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
}


// ---------- MAIN AUTH SCREEN ----------
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

// ---------- LOGIN COMPONENT ----------
class LoginComponent extends StatelessWidget {
  const LoginComponent({super.key});

  // --- Forgot Password Bottom Sheet ---
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
                  Navigator.of(context).pop(); // Close the sheet
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
                  Navigator.of(context).pop(); // Close the sheet
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
          const CustomTextField(hintText: "Email", icon: Icons.email_outlined),
          const CustomTextField(
            hintText: "Password",
            icon: Icons.lock_outline,
            fieldType: TextFieldType.password,
          ),
          // Forgot Password Button
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 30.0),
            child: Align(
              alignment: Alignment.centerRight,
              child: TextButton(
                onPressed: () => _showForgotPasswordSheet(context),
                child: const Text("Forgot Password?"),
              ),
            ),
          ),
          const SizedBox(height: 10),
          ElevatedButton(
            onPressed: () {
              Navigator.pushReplacement(
                context,
                MaterialPageRoute(
                  builder: (context) => const OtpFlowScreen(verificationType: "Login", contactInfo: ""), // Placeholder
                ),
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
            child: const Text("Login", style: TextStyle(fontSize: 16)),
          ),
          const SizedBox(height: 20),
          // --- Social Login Section ---
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
                onTap: () {
                  // TODO: Implement Google Sign-In
                },
              ),
              const SizedBox(width: 20),
              SocialLoginButton(
                assetPath: 'assets/logos/facebook.png',
                onTap: () {
                  // TODO: Implement Facebook Sign-In
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

// ---------- SOCIAL LOGIN BUTTON WIDGET ----------
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
        child: Image.asset(assetPath, height: 50, width: 50), // FIX: Increased size
      ),
    );
  }
}


// ---------- FORGOT PASSWORD SCREEN ----------
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

  @override
  void dispose() {
    _contactController.dispose();
    super.dispose();
  }

  void _sendOtp() {
    if (_formKey.currentState!.validate()) {
      String contactInfo = widget.verificationType == "Mobile"
          ? _countryCode + _contactController.text
          : _contactController.text;

      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => OtpScreen(
            verificationType: widget.verificationType,
            contactInfo: contactInfo,
          ),
        ),
      );
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
              ElevatedButton(
                onPressed: _sendOtp,
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
                child: const Text("Send OTP", style: TextStyle(fontSize: 16)),
              ),
            ],
          ),
        ),
      ),
    );
  }
}


// ---------- POST-LOGIN OTP FLOW ----------
class OtpFlowScreen extends StatelessWidget {
  final String verificationType;
  final String contactInfo;
  const OtpFlowScreen({super.key, required this.verificationType, required this.contactInfo});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: PageView(
        physics: const NeverScrollableScrollPhysics(),
        children: [
          OtpScreen(verificationType: verificationType, contactInfo: contactInfo),
        ],
      ),
    );
  }
}

// ---------- SIGNUP FLOW WITH TWO PAGES ----------
class SignUpFlowScreen extends StatefulWidget {
  const SignUpFlowScreen({super.key});

  @override
  State<SignUpFlowScreen> createState() => _SignUpFlowScreenState();
}

class _SignUpFlowScreenState extends State<SignUpFlowScreen> {
  final PageController _pageController = PageController();
  final _formKey1 = GlobalKey<FormState>();
  final _formKey2 = GlobalKey<FormState>();

  // Page 1 Controllers
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();

  // Page 2 Controllers
  final _dobController = TextEditingController();
  final _locationController = TextEditingController();
  final _phoneController = TextEditingController();
  final _genderController = TextEditingController();
  String _countryCode = "+91";

  PasswordStrength _passwordStrength = PasswordStrength.None;
  bool _isEmailVerified = false;
  bool _isPhoneVerified = false;

  // --- Sample Location Data ---
  static const Map<String, List<String>> _locationSuggestions = {
    '+91': ['Mumbai', 'Delhi', 'Bangalore', 'Chennai', 'Kolkata', 'Hyderabad','Coimbatore'],
    '+61': ['Sydney', 'Melbourne', 'Brisbane', 'Perth', 'Adelaide', 'Canberra'],
    '+1': ['New York', 'Los Angeles', 'Chicago', 'Houston', 'Phoenix', 'Philadelphia'],
    '+44': ['London', 'Manchester', 'Birmingham', 'Glasgow', 'Liverpool', 'Bristol'],
  };

  // --- Phone Number Lengths by Country Code ---
  static const Map<String, int> _phoneLengthByCountry = {
    '+1': 10,  // USA/Canada
    '+44': 10, // UK
    '+61': 9,  // Australia
    '+81': 10, // Japan
    '+86': 11, // China
    '+91': 10, // India
  };

  @override
  void initState() {
    super.initState();
    _passwordController.addListener(_checkPasswordStrength);
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

  void _onSignUp() {
    if (_formKey2.currentState!.validate()) {
      if (!_isEmailVerified || !_isPhoneVerified) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Please verify both email and phone number.")),
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

      // If all checks pass, navigate to the final success screen
      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(builder: (context) => const SignUpSuccessScreen()),
            (Route<dynamic> route) => false,
      );
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

  // --- Verification Methods ---
  Future<void> _verifyEmail() async {
    // First, validate the email field
    if (_emailController.text.isEmpty || !RegExp(r'^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$').hasMatch(_emailController.text)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Please enter a valid email before verifying.")),
      );
      return;
    }

    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => OtpScreen(
          verificationType: "Email",
          contactInfo: _emailController.text,
        ),
      ),
    );
    if (result == true) {
      setState(() {
        _isEmailVerified = true;
      });
    }
  }

  Future<void> _verifyPhone() async {
    // Validate phone number length
    int? expectedLength = _phoneLengthByCountry[_countryCode];
    if (expectedLength != null && _phoneController.text.length != expectedLength) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Phone number for $_countryCode must be $expectedLength digits.")),
      );
      return;
    }

    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => OtpScreen(
          verificationType: "Mobile",
          contactInfo: _countryCode + _phoneController.text,
        ),
      ),
    );
    if (result == true) {
      setState(() {
        _isPhoneVerified = true;
      });
    }
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
            // Email Field with Verification
            Column(
              children: [
                CustomTextField(
                  controller: _emailController,
                  hintText: "Email",
                  icon: Icons.email_outlined,
                  validator: (value) {
                    if (value == null || value.isEmpty) return 'Please enter your email';
                    if (!RegExp(r'^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$').hasMatch(value)) return 'Please enter a valid email';
                    return null;
                  },
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 40.0),
                  child: Align(
                    alignment: Alignment.centerRight,
                    child: _isEmailVerified
                        ? const Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text("Verified", style: TextStyle(color: Colors.green)),
                        Icon(Icons.check_circle, color: Colors.green, size: 16),
                      ],
                    )
                        : TextButton(onPressed: _verifyEmail, child: const Text("Verify")),
                  ),
                ),
              ],
            ),
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
            const SizedBox(height: 30),
            ElevatedButton(
              onPressed: () {
                if (_formKey1.currentState!.validate()) {
                  if (_isEmailVerified) {
                    _pageController.nextPage(
                      duration: const Duration(milliseconds: 400),
                      curve: Curves.easeInOut,
                    );
                  } else {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text("Please verify your email first.")),
                    );
                  }
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
            // Phone Field with Verification
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
                  return TextFormField(
                    controller: _locationController, // Use the main controller
                    focusNode: fieldFocusNode,
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
            ElevatedButton(
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

// ---------- SIGNUP SUCCESS SCREEN ----------
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
              height: MediaQuery
                  .of(context)
                  .size
                  .height * 0.8,
              padding: const EdgeInsets.all(24),
              child: Column(
                children: [
                  const Text("Privacy Policy", style: TextStyle(
                      fontSize: 22, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 16),
                  Expanded(
                    child: SingleChildScrollView(
                      child: Text(
                        "Here is the full text of the privacy policy for SyncUp..." *
                            20, // Placeholder
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
                          // Also update the main screen's state
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
                'assets/lottie/celebration.json', // New celebration Lottie
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
              const SizedBox(height: 40),
              ElevatedButton(
                onPressed: () {
                  if (_privacyPolicyAccepted) {
                    // TODO: Navigate to the main app screen
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