import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';

import 'package:library_management_app/registrationPage.dart';
import 'package:library_management_app/services/auth_service.dart';
import 'package:slide_to_act/slide_to_act.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final _authService = AuthService();
  final _email = TextEditingController();
  final _password = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  final GlobalKey<SlideActionState> _slideKey = GlobalKey<SlideActionState>();

  bool _busy = false;

  @override
  void dispose() {
    _email.dispose();
    _password.dispose();
    super.dispose();
  }

  Future<void> _checkUserAndNavigate(User user) async {
    // Check if user exists in Firestore
    bool exists = await _authService.isUserRegistered(user.uid);

    if (!mounted) return;

    if (exists) {
      // User already registered -> StreamBuilder in main.dart will handle navigation to HomePage
      // But for better UX we can also push replacement if we want immediate feedback,
      // however, StreamBuilder is usually fast enough.
      // We will let StreamBuilder handle it to avoid duplicate navigation.
    } else {
      // First login: needs registration
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => registerPage(uid: user.uid)),
      );
    }
  }

  Future<void> _signInWithEmail() async {
    if (!_formKey.currentState!.validate()) {
      _slideKey.currentState?.reset();
      return;
    }

    setState(() => _busy = true);
    try {
      final user = await _authService.signInWithEmail(
        _email.text.trim(),
        _password.text.trim(),
      );

      if (user != null) {
        await _checkUserAndNavigate(user);
      }
    } catch (e) {
      _slideKey.currentState?.reset();
      if (mounted) _showError(e.toString());
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _signInWithGoogle() async {
    setState(() => _busy = true);
    try {
      final user = await _authService.signInWithGoogle();
      if (user != null) {
        await _checkUserAndNavigate(user);
      }
    } catch (e) {
      if (mounted) _showError(e.toString());
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _signUpWithEmail() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _busy = true);
    try {
      final user = await _authService.signUpWithEmail(
        _email.text.trim(),
        _password.text.trim(),
      );
      if (user != null) {
        await _checkUserAndNavigate(user);
      }
    } catch (e) {
      if (mounted) _showError(e.toString());
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  void _showError(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(msg), backgroundColor: Colors.redAccent),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 420),
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Form(
                  key: _formKey,
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(
                        Icons.library_books,
                        size: 80,
                        color: Colors.white,
                      ),
                      const SizedBox(height: 16),
                      const Text(
                        'Library Login',
                        style: TextStyle(
                          fontSize: 28,
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 48),

                      // Email
                      _buildTextField(
                        controller: _email,
                        label: 'Email',
                        keyboardType: TextInputType.emailAddress,
                        validator: (v) {
                          if (v == null || v.trim().isEmpty) {
                            return 'Enter email';
                          }
                          if (!v.contains('@')) return 'Invalid email';
                          return null;
                        },
                      ),
                      const SizedBox(height: 16),

                      // Password
                      _buildTextField(
                        controller: _password,
                        label: 'Password',
                        obscureText: true,
                        validator: (v) {
                          if (v == null || v.isEmpty) return 'Enter password';
                          if (v.length < 6) return 'Min 6 characters';
                          return null;
                        },
                      ),

                      const SizedBox(height: 32),

                      // Swipe to Login
                      AbsorbPointer(
                        absorbing: _busy,
                        child: SlideAction(
                          key: _slideKey,
                          text: _busy ? 'Signing In...' : 'Swipe to Login',
                          textStyle: const TextStyle(
                            color: Colors.white,
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                          ),
                          outerColor: Colors.grey.shade900,
                          innerColor: _busy ? Colors.grey : Colors.blueAccent,
                          sliderButtonIcon: const Icon(
                            Icons.arrow_forward,
                            color: Colors.black,
                          ),
                          submittedIcon: const Icon(
                            Icons.check,
                            color: Colors.black,
                          ),
                          elevation: 0,
                          onSubmit: _signInWithEmail,
                        ),
                      ),

                      const SizedBox(height: 24),

                      Row(
                        children: const [
                          Expanded(child: Divider(color: Colors.white24)),
                          Padding(
                            padding: EdgeInsets.symmetric(horizontal: 16),
                            child: Text(
                              'OR',
                              style: TextStyle(
                                color: Colors.white54,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                          Expanded(child: Divider(color: Colors.white24)),
                        ],
                      ),

                      const SizedBox(height: 24),

                      // Google Sign-In
                      SizedBox(
                        width: double.infinity,
                        height: 50,
                        child: OutlinedButton.icon(
                          onPressed: _busy ? null : _signInWithGoogle,
                          icon: const Icon(
                            Icons.g_mobiledata,
                            size: 28,
                            color: Colors.white,
                          ),
                          style: OutlinedButton.styleFrom(
                            side: const BorderSide(color: Colors.white54),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          label: const Text(
                            'Continue with Google',
                            style: TextStyle(color: Colors.white, fontSize: 16),
                          ),
                        ),
                      ),

                      const SizedBox(height: 16),

                      TextButton(
                        onPressed: _busy ? null : _signUpWithEmail,
                        child: const Text(
                          'Create account with email',
                          style: TextStyle(color: Colors.white70, fontSize: 15),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    bool obscureText = false,
    TextInputType? keyboardType,
    String? Function(String?)? validator,
  }) {
    return TextFormField(
      controller: controller,
      obscureText: obscureText,
      keyboardType: keyboardType,
      style: const TextStyle(color: Colors.white),
      decoration: InputDecoration(
        labelText: label,
        labelStyle: const TextStyle(color: Colors.white70),
        filled: true,
        fillColor: Colors.white10,
        enabledBorder: OutlineInputBorder(
          borderSide: BorderSide.none,
          borderRadius: BorderRadius.circular(12),
        ),
        focusedBorder: OutlineInputBorder(
          borderSide: const BorderSide(color: Colors.blueAccent),
          borderRadius: BorderRadius.circular(12),
        ),
        errorBorder: OutlineInputBorder(
          borderSide: const BorderSide(color: Colors.redAccent),
          borderRadius: BorderRadius.circular(12),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderSide: const BorderSide(color: Colors.redAccent),
          borderRadius: BorderRadius.circular(12),
        ),
      ),
      validator: validator,
    );
  }
}
