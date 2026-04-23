import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../main.dart';

class PhoneAuthScreen extends StatefulWidget {
  const PhoneAuthScreen({super.key});

  @override
  State<PhoneAuthScreen> createState() => _PhoneAuthScreenState();
}

class _PhoneAuthScreenState extends State<PhoneAuthScreen>
    with SingleTickerProviderStateMixin {
  final TextEditingController _phoneController = TextEditingController();
  final TextEditingController _smsController = TextEditingController();
  String? _verificationId;
  bool _codeSent = false;
  bool _loading = false;
  String? _error;
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeInOut),
    );
    _animationController.forward();
  }

  @override
  void dispose() {
    _phoneController.dispose();
    _smsController.dispose();
    _animationController.dispose();
    super.dispose();
  }

  Future<void> _verifyPhone() async {
    if (_phoneController.text.trim().isEmpty) {
      setState(() => _error = 'Please enter a valid phone number');
      return;
    }
    
    if (mounted) setState(() { _loading = true; _error = null; });
    
    await FirebaseAuth.instance.verifyPhoneNumber(
      phoneNumber: _phoneController.text.trim(),
      verificationCompleted: (PhoneAuthCredential credential) async {
        await FirebaseAuth.instance.signInWithCredential(credential);
        if (mounted) Navigator.of(context).popUntil((route) => route.isFirst);
      },
      verificationFailed: (FirebaseAuthException e) {
        if (mounted) {
          setState(() {
            _error = e.message ?? 'Verification failed. Please try again.';
            _loading = false;
          });
        }
      },
      codeSent: (String verificationId, int? resendToken) {
        if (mounted) {
          setState(() {
            _verificationId = verificationId;
            _codeSent = true;
            _loading = false;
          });
          _animationController.reset();
          _animationController.forward();
        }
      },
      codeAutoRetrievalTimeout: (String verificationId) {
        if (mounted) setState(() { _verificationId = verificationId; _loading = false; });
      },
    );
  }

  Future<void> _signInWithSmsCode() async {
    if (_verificationId == null || _smsController.text.trim().isEmpty) {
      setState(() => _error = 'Please enter the verification code');
      return;
    }
    
    if (mounted) setState(() { _loading = true; _error = null; });
    
    try {
      final credential = PhoneAuthProvider.credential(
        verificationId: _verificationId!,
        smsCode: _smsController.text.trim(),
      );
      await FirebaseAuth.instance.signInWithCredential(credential);
      if (mounted) {
        Navigator.of(context).pushAndRemoveUntil(
          MaterialPageRoute(builder: (_) => const AuthGate()),
          (route) => false,
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = 'Invalid verification code. Please try again.';
          _loading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Color(0xFF6366F1),
              Color(0xFF8B5CF6),
            ],
            stops: [0.0, 0.6],
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              // Top Section with gradient
              Container(
                height: MediaQuery.of(context).size.height * 0.35,
                padding: const EdgeInsets.all(24),
                child: Column(
                  children: [
                    // Back button
                    Row(
                      children: [
                        IconButton(
                          onPressed: () => Navigator.pop(context),
                          icon: const Icon(Icons.arrow_back_ios, color: Colors.white),
                        ),
                      ],
                    ),
                    
                    const Spacer(),
                    
                    // Icon and title
                    Container(
                      width: 80,
                      height: 80,
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: const Icon(
                        Icons.phone_android_rounded,
                        size: 40,
                        color: Colors.white,
                      ),
                    ),
                    
                    const SizedBox(height: 16),
                    
                    Text(
                      _codeSent ? 'Verify Your Phone' : 'Enter Your Phone',
                      style: const TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                    
                    const SizedBox(height: 8),
                    
                    Text(
                      _codeSent 
                          ? 'Enter the 6-digit code sent to\n${_phoneController.text}'
                          : 'We\'ll send you a verification code',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 16,
                        color: Colors.white.withOpacity(0.9),
                      ),
                    ),
                    
                    const Spacer(),
                  ],
                ),
              ),
              
              // Bottom Section with form
              Expanded(
                child: Container(
                  decoration: const BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.only(
                      topLeft: Radius.circular(32),
                      topRight: Radius.circular(32),
                    ),
                  ),
                  child: FadeTransition(
                    opacity: _fadeAnimation,
                    child: Padding(
                      padding: const EdgeInsets.all(24),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          const SizedBox(height: 24),
                          
                          // Error message
                          if (_error != null) ...[
                            Container(
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: const Color(0xFFEF4444).withOpacity(0.08),
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(color: const Color(0xFFEF4444).withOpacity(0.3)),
                              ),
                              child: Row(
                                children: [
                                  const Icon(Icons.error_outline, color: Color(0xFFEF4444), size: 20),
                                  const SizedBox(width: 8),
                                  Expanded(
                                    child: Text(
                                      _error!,
                                      style: const TextStyle(
                                        color: Color(0xFFEF4444),
                                        fontSize: 14,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(height: 20),
                          ],
                          
                          // Input field
                          if (!_codeSent) ...[
                            _buildPhoneInputField(),
                          ] else ...[
                            _buildCodeInputField(),
                          ],
                          
                          const SizedBox(height: 24),
                          
                          // Action button
                          Container(
                            height: 56,
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(16),
                              boxShadow: [
                                BoxShadow(
                                  color: const Color(0xFF6366F1).withOpacity(0.3),
                                  blurRadius: 20,
                                  offset: const Offset(0, 8),
                                ),
                              ],
                            ),
                            child: ElevatedButton(
                              onPressed: _loading ? null : (_codeSent ? _signInWithSmsCode : _verifyPhone),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: const Color(0xFF6366F1),
                                foregroundColor: Colors.white,
                                elevation: 0,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(16),
                                ),
                              ),
                              child: _loading 
                                  ? const SizedBox(
                                      width: 24,
                                      height: 24,
                                      child: CircularProgressIndicator(
                                        strokeWidth: 2,
                                        valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                                      ),
                                    )
                                  : Text(
                                      _codeSent ? 'Verify Code' : 'Send Code',
                                      style: const TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                            ),
                          ),
                          
                          // Additional actions
                          if (_codeSent) ...[
                            const SizedBox(height: 16),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Text(
                                  'Didn\'t receive code? ',
                                  style: TextStyle(
                                    color: const Color(0xFF6B7280),
                                    fontSize: 14,
                                  ),
                                ),
                                TextButton(
                                  onPressed: _loading ? null : () {
                                    setState(() {
                                      _codeSent = false;
                                      _smsController.clear();
                                      _error = null;
                                    });
                                    _animationController.reset();
                                    _animationController.forward();
                                  },
                                  child: const Text(
                                    'Resend',
                                    style: TextStyle(
                                      color: Color(0xFF6366F1),
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ],
                          
                          const Spacer(),
                          
                          // Terms and conditions
                          Text(
                            'By continuing, you agree to our Terms of Service\nand Privacy Policy',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              color: const Color(0xFF6B7280),
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPhoneInputField() {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE5E7EB)),
      ),
      child: TextField(
        controller: _phoneController,
        keyboardType: TextInputType.phone,
        style: const TextStyle(fontSize: 16),
        decoration: InputDecoration(
          labelText: 'Phone Number',
          hintText: '+966 5X XXX XXXX',
          prefixIcon: const Icon(Icons.phone_outlined),
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
          labelStyle: TextStyle(color: const Color(0xFF6B7280)),
        ),
      ),
    );
  }

  Widget _buildCodeInputField() {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE5E7EB)),
      ),
      child: TextField(
        controller: _smsController,
        keyboardType: TextInputType.number,
        style: const TextStyle(fontSize: 18, letterSpacing: 2),
        textAlign: TextAlign.center,
        maxLength: 6,
        decoration: InputDecoration(
          labelText: 'Verification Code',
          hintText: '●●●●●●',
          prefixIcon: const Icon(Icons.security_outlined),
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
          labelStyle: TextStyle(color: const Color(0xFF6B7280)),
          counterText: '',
        ),
      ),
    );
  }
}
