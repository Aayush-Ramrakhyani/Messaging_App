import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:my_project1/Custom_Widget/app_colors.dart';
import 'package:my_project1/Custom_Widget/mycustombutton.dart';
import 'package:my_project1/Custom_Widget/textfield.dart';
import 'package:my_project1/dashboardscreen.dart';
import 'package:my_project1/forgotpassword_screen.dart';
import 'package:my_project1/registerscreen.dart';

class MYLoginScreen extends StatefulWidget {
  const MYLoginScreen({super.key});

  @override
  State<MYLoginScreen> createState() => _MYLoginScreenState();
}

class _MYLoginScreenState extends State<MYLoginScreen> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  bool _isLoading = false;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  void _showError(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      behavior: SnackBarBehavior.floating,
      backgroundColor: AppColors.error,
      content: Text(msg, style: const TextStyle(color: Colors.white)),
      duration: const Duration(seconds: 3),
    ));
  }

  Future<void> _login() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isLoading = true);
    try {
      final cred = await FirebaseAuth.instance.signInWithEmailAndPassword(
        email: _emailController.text.trim(),
        password: _passwordController.text,
      );
      if (!mounted) return;
      Navigator.pushReplacement(context,
          MaterialPageRoute(builder: (_) => Dashboard(user: cred.user)));
    } on FirebaseAuthException catch (e) {
      if (!mounted) return;
      _showError(e.code == 'network-request-failed'
          ? 'No internet connection.'
          : 'Invalid email or password.');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;

    return Scaffold(
      body: SizedBox(
        height: size.height,
        width: size.width,
        child: Stack(
          children: [
            // ── Gradient top half ──────────────────────────────────────
            Container(
              height: size.height * 0.48,
              decoration: const BoxDecoration(
                gradient: AppColors.primaryGradient,
              ),
            ),
            // ── Bottom fill so no white gap ────────────────────────────
            Positioned(
              bottom: 0,
              left: 0,
              right: 0,
              height: size.height * 0.55,
              child: Container(color: Colors.white),
            ),
            // ── Scrollable content ─────────────────────────────────────
            SafeArea(
              child: SingleChildScrollView(
                physics: const BouncingScrollPhysics(),
                child: Column(
                  children: [
                    // Logo + brand in gradient zone
                    SizedBox(height: size.height * 0.06),
                    Container(
                      width: 76,
                      height: 76,
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.2),
                        shape: BoxShape.circle,
                        border: Border.all(
                            color: Colors.white.withValues(alpha: 0.4),
                            width: 2),
                      ),
                      child: const Icon(Icons.waves_rounded,
                          color: Colors.white, size: 38),
                    ).animate().scale(
                          duration: 500.ms,
                          curve: Curves.elasticOut,
                          begin: const Offset(0.5, 0.5),
                        ),
                    const SizedBox(height: 14),
                    Text(
                      'Vibe',
                      style: GoogleFonts.poppins(
                        fontSize: 36,
                        fontWeight: FontWeight.w700,
                        color: Colors.white,
                        letterSpacing: 1.5,
                      ),
                    ).animate().fadeIn(delay: 150.ms).slideY(begin: 0.3),
                    Text(
                      'Connect. Share. Vibe.',
                      style: GoogleFonts.poppins(
                        fontSize: 14,
                        color: Colors.white.withValues(alpha: 0.8),
                      ),
                    ).animate().fadeIn(delay: 250.ms),

                    const SizedBox(height: 32),

                    // ── White card ─────────────────────────────────────
                    Container(
                      margin: const EdgeInsets.symmetric(horizontal: 20),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(28),
                        boxShadow: AppColors.cardShadow,
                      ),
                      padding: const EdgeInsets.fromLTRB(24, 28, 24, 28),
                      child: Form(
                        key: _formKey,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Welcome back!',
                              style: GoogleFonts.poppins(
                                fontSize: 22,
                                fontWeight: FontWeight.w700,
                                color: AppColors.textPrimary,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              'Sign in to continue',
                              style: GoogleFonts.poppins(
                                fontSize: 13,
                                color: AppColors.textSecondary,
                              ),
                            ),
                            const SizedBox(height: 24),
                            AppTextField(
                              controller: _emailController,
                              hintText: 'Email address',
                              prefixIcon: Icons.email_outlined,
                              keyboardType: TextInputType.emailAddress,
                              validator: (v) => (v == null || v.trim().isEmpty)
                                  ? 'Enter your email'
                                  : null,
                            ),
                            const SizedBox(height: 14),
                            AppTextField(
                              controller: _passwordController,
                              hintText: 'Password',
                              prefixIcon: Icons.lock_outlined,
                              isPassword: true,
                              validator: (v) =>
                                  (v == null || v.isEmpty) ? 'Enter your password' : null,
                            ),
                            Align(
                              alignment: Alignment.centerRight,
                              child: TextButton(
                                onPressed: () => Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                      builder: (_) =>
                                          const MyForgotPasswordScreen()),
                                ),
                                child: Text(
                                  'Forgot Password?',
                                  style: GoogleFonts.poppins(
                                    fontSize: 13,
                                    color: AppColors.gradientEnd,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(height: 4),
                            GradientButton(
                              text: 'Log In',
                              onPressed: _isLoading ? null : _login,
                              isLoading: _isLoading,
                            ),
                            const SizedBox(height: 20),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Text(
                                  "Don't have an account? ",
                                  style: GoogleFonts.poppins(
                                      fontSize: 13,
                                      color: AppColors.textSecondary),
                                ),
                                GestureDetector(
                                  onTap: () => Navigator.pushReplacement(
                                    context,
                                    MaterialPageRoute(
                                        builder: (_) =>
                                            const MyRegistrationScreen()),
                                  ),
                                  child: Text(
                                    'Register',
                                    style: GoogleFonts.poppins(
                                      fontSize: 13,
                                      fontWeight: FontWeight.w700,
                                      color: AppColors.gradientEnd,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ).animate().fadeIn(delay: 300.ms).slideY(begin: 0.12),
                    const SizedBox(height: 32),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
