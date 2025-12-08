import 'package:flutter/material.dart';
import 'package:flutter/gestures.dart';
import 'package:provider/provider.dart';
import '../../services/auth_service.dart';
import '../../services/phone_auth_service.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _nameController = TextEditingController();
  final _phoneController = TextEditingController();
  final _idController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  bool _obscurePassword = true;
  bool _obscureConfirmPassword = true;
  bool _acceptedTerms = false;
  String? _selectedVillage;
  
  final _villages = [
    'Muthungue', 'Nditime', 'Maskikalini', 'Kamwiu', 'Ituusya', 'Ivitasya',
    'Kyamatu/Nzanzu', 'Nzunguni', 'Kasasi', 'Kaluasi', 'Other'
  ];

  final _otherVillageController = TextEditingController();

  // CAPTCHA State
  late int _num1;
  late int _num2;
  late int _captchaResult;
  final _captchaController = TextEditingController();

  // OTP State
  bool _otpSent = false;
  bool _otpVerified = false;
  bool _sendingOtp = false;
  bool _verifyingOtp = false;
  final _otpController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _generateCaptcha();
  }

  void _generateCaptcha() {
    setState(() {
      _num1 = DateTime.now().millisecond % 10;
      _num2 = DateTime.now().microsecond % 10;
      _captchaResult = _num1 + _num2;
      _captchaController.clear();
    });
  }

  void _showTermsDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF1a1a3e),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Terms & Privacy Policy', style: TextStyle(color: Colors.white)),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Terms of Service', style: TextStyle(color: Color(0xFF6366f1), fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              Text(
                '1. ACCEPTANCE OF TERMS\n'
                'By accessing and using the VOO Citizen platform ("the Service"), you explicitly acknowledge and agree to be bound by these Terms of Service. The Service is designed to facilitate civic engagement and community reporting.\n\n'
                '2. USER RESPONSIBILITIES & CONDUCT\n'
                'Users are strictly prohibited from submitting false, misleading, or malicious reports. You warrant that all information provided is accurate. To maintain the integrity, security, and reliability of the Service, the Administration reserves the unequivocal right to monitor all user interactions, analyze behavioral patterns, and cross-reference submitted data against internal and external databases.\n\n'
                '3. DEVICE ACCESS & DATA USAGE\n'
                'To verify the authenticity of reports and prevent fraudulent activities, the Service requires access to specific device capabilities. By continuing, you expressly grant the Service permission to access, collect, and store unique device identifiers (including but not limited to IMEI, IMSI, and MAC addresses), precise geolocation data, and multimedia files. This data is essential for the "Proof of Location" and "Proof of Device" verification protocols mandated by the security infrastructure.\n\n'
                '4. INTELLECTUAL PROPERTY\n'
                'All content submitted to the Service becomes the property of the Administration for the purpose of issue resolution and civic planning.',
                style: TextStyle(color: Colors.white.withOpacity(0.8), fontSize: 11, height: 1.4),
              ),
              const SizedBox(height: 16),
              const Text('Privacy Policy', style: TextStyle(color: Color(0xFF6366f1), fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              Text(
                '1. DATA COLLECTION FRAMEWORK\n'
                'We implement a comprehensive data collection framework to ensure service delivery. This includes Personal Identifiable Information (PII) such as National ID, Phone Number, and Biometric data where applicable. Furthermore, technical telemetry including device IMEI, hardware serial numbers, operating system version, and network carrier information is automatically aggregated to facilitate security auditing and device fingerprinting.\n\n'
                '2. DATA SECURITY & SHARING\n'
                'While we employ industry-standard encryption protocols (AES-256) to protect your data at rest and in transit, you acknowledge that no system is entirely impenetrable. Data may be shared with relevant municipal authorities, law enforcement agencies, and authorized third-party contractors for the strict purpose of valid issue resolution and investigatory compliance.\n\n'
                '3. CONSENT\n'
                'Your continued use of this application constitutes an irrevocable consent to all aforementioned data collection, processing, and monitoring activities.',
                style: TextStyle(color: Colors.white.withOpacity(0.8), fontSize: 11, height: 1.4),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close', style: TextStyle(color: Color(0xFF6366f1))),
          ),
        ],
      ),
    );
  }

  // Send OTP to phone number
  Future<void> _sendOTP() async {
    if (_phoneController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter your phone number'), backgroundColor: Colors.red),
      );
      return;
    }

    setState(() => _sendingOtp = true);

    String phoneNumber = _phoneController.text;
    if (!phoneNumber.startsWith('+254')) {
      phoneNumber = '+254$phoneNumber';
    }

    await PhoneAuthService.sendOTP(
      phoneNumber: phoneNumber,
      onCodeSent: (verificationId) {
        if (mounted) {
          setState(() {
            _otpSent = true;
            _sendingOtp = false;
          });
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('OTP sent! Check your SMS 📱'), backgroundColor: Colors.green),
          );
        }
      },
      onError: (error) {
        if (mounted) {
          setState(() => _sendingOtp = false);
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(error), backgroundColor: Colors.red),
          );
        }
      },
    );
  }

  // Verify OTP code
  Future<void> _verifyOTP() async {
    if (_otpController.text.isEmpty || _otpController.text.length != 6) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter the 6-digit OTP'), backgroundColor: Colors.red),
      );
      return;
    }

    setState(() => _verifyingOtp = true);

    final result = await PhoneAuthService.verifyOTP(otp: _otpController.text);

    if (mounted) {
      setState(() => _verifyingOtp = false);

      if (result['success'] == true) {
        setState(() => _otpVerified = true);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Phone verified! ✅'), backgroundColor: Colors.green),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(result['error'] ?? 'Verification failed'), backgroundColor: Colors.red),
        );
      }
    }
  }

  Future<void> _handleRegister() async {
    // CAPTCHA Validation
    if (_captchaController.text != _captchaResult.toString()) {
       ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Incorrect CAPTCHA. Please try again.'), backgroundColor: Colors.red),
      );
      _generateCaptcha();
      return;
    }

    // Validation
    if (_nameController.text.isEmpty || _phoneController.text.isEmpty ||
        _idController.text.isEmpty || _passwordController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please fill in all fields'), backgroundColor: Colors.red),
      );
      return;
    }

    if (_passwordController.text != _confirmPasswordController.text) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Passwords do not match'), backgroundColor: Colors.red),
      );
      return;
    }

    // Strong password validation
    final password = _passwordController.text;
    if (password.length < 8) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Password must be at least 8 characters'), backgroundColor: Colors.red),
      );
      return;
    }
    if (!RegExp(r'[a-zA-Z]').hasMatch(password)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Password must contain at least one letter'), backgroundColor: Colors.red),
      );
      return;
    }
    if (!RegExp(r'[0-9]').hasMatch(password)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Password must contain at least one number'), backgroundColor: Colors.red),
      );
      return;
    }
    if (!RegExp(r'[!@#$%^&*(),.?":{}|<>]').hasMatch(password)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Password must contain at least one special character (!@#\$%^&*)'), backgroundColor: Colors.red),
      );
      return;
    }

    // Phone verification is optional - can be enabled later when SHA-1 fingerprints are configured
    // if (!_otpVerified) {
    //   ScaffoldMessenger.of(context).showSnackBar(
    //     const SnackBar(content: Text('Please verify your phone number first'), backgroundColor: Colors.orange),
    //   );
    //   return;
    // }

    if (!_acceptedTerms) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please accept Terms & Privacy Policy'), backgroundColor: Colors.orange),
      );
      return;
    }

    final auth = context.read<AuthService>();
    final result = await auth.register(
      _nameController.text,
      _phoneController.text,
      _idController.text,
      _passwordController.text,
      village: _selectedVillage == 'Other' ? _otherVillageController.text : _selectedVillage,
    );

    if (mounted) {
      if (result['success']) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Account created successfully! ✅'), backgroundColor: Colors.green),
        );
        Navigator.pop(context);
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(result['error']), backgroundColor: Colors.red),
        );
      }
    }
  }

  InputDecoration _buildInputDecoration(String hint, IconData icon, {Widget? suffix}) {
    return InputDecoration(
      hintText: hint,
      hintStyle: TextStyle(color: Colors.white.withOpacity(0.4)),
      prefixIcon: Icon(icon, color: const Color(0xFF6366f1)),
      suffixIcon: suffix,
      filled: true,
      fillColor: const Color(0xFF0f0f23).withOpacity(0.5),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide.none,
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: Colors.white.withOpacity(0.1)),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: Color(0xFF6366f1), width: 2),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthService>();

    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Color(0xFF1a1a3e), Color(0xFF0f0f23)],
          ),
        ),
        child: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 20),
            child: Column(
              children: [
                // Back button and title
                Row(
                  children: [
                    IconButton(
                      onPressed: () => Navigator.pop(context),
                      icon: const Icon(Icons.arrow_back_ios, color: Colors.white),
                    ),
                    const Expanded(
                      child: Text(
                        'Sign Up',
                        style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Colors.white),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 20),

                // Logo with white background
                Container(
                  width: 80,
                  height: 80,
                  decoration: const BoxDecoration(
                    shape: BoxShape.circle,
                    color: Colors.white,
                  ),
                  child: ClipOval(
                    child: Image.asset(
                      'assets/images/logo.png',
                      fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) => Container(
                        color: Colors.white,
                        child: const Icon(Icons.location_city, size: 40, color: Color(0xFF6366f1)),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 32),

                // Registration Form
                Container(
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    color: const Color(0xFF2d1b69).withOpacity(0.3),
                    borderRadius: BorderRadius.circular(24),
                    border: Border.all(color: const Color(0xFF6366f1).withOpacity(0.2)),
                  ),
                  child: Column(
                    children: [
                      // Row 1: Full Name and ID Number
                      Row(
                        children: [
                          Expanded(
                            child: TextField(
                              controller: _nameController,
                              style: const TextStyle(color: Colors.white),
                              textCapitalization: TextCapitalization.words,
                              decoration: _buildInputDecoration('Full Name', Icons.person_outline),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: TextField(
                              controller: _idController,
                              keyboardType: TextInputType.number,
                              style: const TextStyle(color: Colors.white),
                              decoration: _buildInputDecoration('National ID', Icons.badge_outlined),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),

                      // Phone Number with OTP (full width for button)
                      Row(
                        children: [
                          Expanded(
                            child: TextField(
                              controller: _phoneController,
                              keyboardType: TextInputType.phone,
                              style: const TextStyle(color: Colors.white),
                              enabled: !_otpVerified,
                              decoration: _buildInputDecoration(
                                'Phone Number',
                                Icons.phone_android,
                                suffix: _otpVerified
                                    ? const Icon(Icons.check_circle, color: Colors.green)
                                    : null,
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          SizedBox(
                            width: 100,
                            height: 50,
                            child: ElevatedButton(
                              onPressed: _otpVerified || _sendingOtp ? null : _sendOTP,
                              style: ElevatedButton.styleFrom(
                                backgroundColor: _otpVerified ? Colors.green : const Color(0xFF6366f1),
                                padding: EdgeInsets.zero,
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                              ),
                              child: _sendingOtp
                                  ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                                  : Text(
                                      _otpVerified ? '✓ Verified' : (_otpSent ? 'Resend' : 'Get OTP'),
                                      style: const TextStyle(fontSize: 12, color: Colors.white),
                                    ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),

                      // OTP Input (shown after OTP is sent)
                      if (_otpSent && !_otpVerified) ...[
                        Row(
                          children: [
                            Expanded(
                              child: TextField(
                                controller: _otpController,
                                keyboardType: TextInputType.number,
                                maxLength: 6,
                                style: const TextStyle(color: Colors.white, letterSpacing: 8),
                                textAlign: TextAlign.center,
                                decoration: InputDecoration(
                                  hintText: '------',
                                  hintStyle: TextStyle(color: Colors.white.withOpacity(0.3), letterSpacing: 8),
                                  counterText: '',
                                  filled: true,
                                  fillColor: const Color(0xFF0f0f23).withOpacity(0.5),
                                  border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(12),
                                    borderSide: BorderSide.none,
                                  ),
                                  enabledBorder: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(12),
                                    borderSide: BorderSide(color: Colors.white.withOpacity(0.1)),
                                  ),
                                  focusedBorder: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(12),
                                    borderSide: const BorderSide(color: Color(0xFF6366f1)),
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(width: 8),
                            SizedBox(
                              width: 100,
                              height: 50,
                              child: ElevatedButton(
                                onPressed: _verifyingOtp ? null : _verifyOTP,
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: const Color(0xFF22c55e),
                                  padding: EdgeInsets.zero,
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                ),
                                child: _verifyingOtp
                                    ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                                    : const Text('Verify', style: TextStyle(fontSize: 12, color: Colors.white)),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),
                      ],
                      
                      // Village Selection (full width)
                      DropdownButtonFormField<String>(
                        value: _selectedVillage,
                        dropdownColor: const Color(0xFF1a1a3e),
                        style: const TextStyle(color: Colors.white),
                        decoration: _buildInputDecoration('Select Village/Location', Icons.location_on),
                        items: _villages.map((v) => DropdownMenuItem(value: v, child: Text(v))).toList(),
                        onChanged: (v) => setState(() {
                          _selectedVillage = v;
                          if (v != 'Other') _otherVillageController.clear();
                        }),
                        validator: (v) => v == null ? 'Please select your village' : null,
                      ),
                      if (_selectedVillage == 'Other') ...[
                        const SizedBox(height: 16),
                        TextField(
                          controller: _otherVillageController,
                          style: const TextStyle(color: Colors.white),
                          textCapitalization: TextCapitalization.words,
                          decoration: _buildInputDecoration('Enter Village Name', Icons.home_work),
                        ),
                      ],
                      const SizedBox(height: 16),

                      // Row 2: Password and Confirm Password
                      Row(
                        children: [
                          Expanded(
                            child: TextField(
                              controller: _passwordController,
                              obscureText: _obscurePassword,
                              style: const TextStyle(color: Colors.white),
                              decoration: _buildInputDecoration(
                                'Password',
                                Icons.lock_outline,
                                suffix: IconButton(
                                  icon: Icon(
                                    _obscurePassword ? Icons.visibility_off : Icons.visibility,
                                    color: Colors.white54,
                                    size: 20,
                                  ),
                                  onPressed: () => setState(() => _obscurePassword = !_obscurePassword),
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: TextField(
                              controller: _confirmPasswordController,
                              obscureText: _obscureConfirmPassword,
                              style: const TextStyle(color: Colors.white),
                              decoration: _buildInputDecoration(
                                'Confirm',
                                Icons.lock_outline,
                                suffix: IconButton(
                                  icon: Icon(
                                    _obscureConfirmPassword ? Icons.visibility_off : Icons.visibility,
                                    color: Colors.white54,
                                    size: 20,
                                  ),
                                  onPressed: () => setState(() => _obscureConfirmPassword = !_obscureConfirmPassword),
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 20),

                      // CAPTCHA
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: const Color(0xFF1a1a3e),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: Colors.white.withOpacity(0.1)),
                        ),
                        child: Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                              decoration: BoxDecoration(
                                color: const Color(0xFF6366f1).withOpacity(0.2),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Text(
                                '$_num1 + $_num2 = ?',
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 18,
                                ),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: TextField(
                                controller: _captchaController,
                                keyboardType: TextInputType.number,
                                style: const TextStyle(color: Colors.white),
                                decoration: const InputDecoration(
                                  hintText: 'Answer',
                                  hintStyle: TextStyle(color: Colors.white54),
                                  border: InputBorder.none,
                                  isDense: true,
                                ),
                              ),
                            ),
                            IconButton(
                              icon: const Icon(Icons.refresh, color: Color(0xFF6366f1)),
                              onPressed: _generateCaptcha,
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 20),

                      // Terms & Policy
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          SizedBox(
                            width: 24,
                            height: 24,
                            child: Checkbox(
                              value: _acceptedTerms,
                              onChanged: (v) => setState(() => _acceptedTerms = v ?? false),
                              activeColor: const Color(0xFF6366f1),
                              side: BorderSide(color: _acceptedTerms ? const Color(0xFF6366f1) : Colors.orange),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: RichText(
                              text: TextSpan(
                                text: 'I agree to the ',
                                style: TextStyle(color: Colors.white.withOpacity(0.7), fontSize: 12),
                                children: [
                                  TextSpan(
                                    text: 'Terms of Service',
                                    style: const TextStyle(color: Color(0xFF6366f1), fontWeight: FontWeight.bold),
                                    recognizer: TapGestureRecognizer()..onTap = _showTermsDialog,
                                  ),
                                  const TextSpan(text: ' and '),
                                  TextSpan(
                                    text: 'Privacy Policy',
                                    style: const TextStyle(color: Color(0xFF6366f1), fontWeight: FontWeight.bold),
                                    recognizer: TapGestureRecognizer()..onTap = _showTermsDialog,
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 24),

                      // Register Button
                      SizedBox(
                        width: double.infinity,
                        height: 52,
                        child: ElevatedButton(
                          onPressed: auth.isLoading ? null : _handleRegister,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF6366f1),
                            foregroundColor: Colors.white,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                            elevation: 0,
                          ),
                          child: auth.isLoading
                              ? const SizedBox(
                                  width: 24,
                                  height: 24,
                                  child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                                )
                              : const Text('Register', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),

                // Login Link
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: RichText(
                    text: TextSpan(
                      text: 'Already have an account? ',
                      style: TextStyle(color: Colors.white.withOpacity(0.6)),
                      children: const [
                        TextSpan(
                          text: 'Sign In',
                          style: TextStyle(color: Color(0xFF6366f1), fontWeight: FontWeight.bold),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 16),

                // Security Badge
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.verified_user, size: 16, color: Colors.green.withOpacity(0.7)),
                    const SizedBox(width: 6),
                    Text(
                      'Your data is protected',
                      style: TextStyle(color: Colors.white.withOpacity(0.4), fontSize: 11),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
