import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:my_project1/Custom_Widget/app_colors.dart';
import 'package:my_project1/Custom_Widget/mycustombutton.dart';
import 'package:my_project1/Custom_Widget/textfield.dart';
import 'package:my_project1/loginscreen.dart';
import 'package:my_project1/registerscreen.dart';

class MyForgotPasswordScreen extends StatefulWidget {
  const MyForgotPasswordScreen({super.key});

  @override
  State<MyForgotPasswordScreen> createState() =>
      _MyForgotPasswordScreenState();
}

class _MyForgotPasswordScreenState extends State<MyForgotPasswordScreen> {
  final _emailController = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  bool _isLoading = false;

  @override
  void dispose() {
    _emailController.dispose();
    super.dispose();
  }

  Future<void> _sendLink() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isLoading = true);
    try {
      await FirebaseAuth.instance
          .sendPasswordResetEmail(email: _emailController.text.trim());
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
        behavior: SnackBarBehavior.floating,
        backgroundColor: AppColors.success,
        content: Text('Reset link sent! Check your inbox.',
            style: TextStyle(color: Colors.white)),
        duration: Duration(seconds: 4),
      ));
    } on FirebaseAuthException catch (e) {
      if (!mounted) return;
      final msg = e.code == 'user-not-found'
          ? 'No account found with that email.'
          : e.code == 'network-request-failed'
              ? 'No internet connection.'
              : 'Failed to send reset email.';
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        behavior: SnackBarBehavior.floating,
        backgroundColor: AppColors.error,
        content: Text(msg, style: const TextStyle(color: Colors.white)),
        duration: const Duration(seconds: 3),
      ));
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
            Container(
              height: size.height * 0.42,
              decoration: const BoxDecoration(
                  gradient: AppColors.primaryGradient),
            ),
            Positioned(
              bottom: 0,
              left: 0,
              right: 0,
              height: size.height * 0.62,
              child: Container(color: Colors.white),
            ),
            SafeArea(
              child: SingleChildScrollView(
                physics: const BouncingScrollPhysics(),
                child: Column(
                  children: [
                    SizedBox(height: size.height * 0.06),
                    Container(
                      width: 70,
                      height: 70,
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.2),
                        shape: BoxShape.circle,
                        border: Border.all(
                            color: Colors.white.withValues(alpha: 0.4),
                            width: 2),
                      ),
                      child: const Icon(Icons.lock_reset,
                          color: Colors.white, size: 34),
                    ).animate().scale(
                          duration: 500.ms,
                          curve: Curves.elasticOut,
                          begin: const Offset(0.5, 0.5),
                        ),
                    const SizedBox(height: 14),
                    Text(
                      'Reset Password',
                      style: GoogleFonts.poppins(
                        fontSize: 28,
                        fontWeight: FontWeight.w700,
                        color: Colors.white,
                      ),
                    ).animate().fadeIn(delay: 150.ms).slideY(begin: 0.3),
                    const SizedBox(height: 6),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 40),
                      child: Text(
                        "We'll send a reset link to your email",
                        textAlign: TextAlign.center,
                        style: GoogleFonts.poppins(
                          fontSize: 13,
                          color: Colors.white.withValues(alpha: 0.8),
                        ),
                      ),
                    ).animate().fadeIn(delay: 220.ms),

                    const SizedBox(height: 36),

                    // ── Card ───────────────────────────────────────────
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
                              'Enter your email',
                              style: GoogleFonts.poppins(
                                fontSize: 18,
                                fontWeight: FontWeight.w600,
                                color: AppColors.textPrimary,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              "We'll send you a link to reset your password",
                              style: GoogleFonts.poppins(
                                fontSize: 12,
                                color: AppColors.textSecondary,
                              ),
                            ),
                            const SizedBox(height: 20),
                            AppTextField(
                              controller: _emailController,
                              hintText: 'Email address',
                              prefixIcon: Icons.email_outlined,
                              keyboardType: TextInputType.emailAddress,
                              validator: (v) =>
                                  (v == null || v.trim().isEmpty)
                                      ? 'Enter your email'
                                      : null,
                            ),
                            const SizedBox(height: 24),
                            GradientButton(
                              text: 'Send Reset Link',
                              onPressed: _isLoading ? null : _sendLink,
                              isLoading: _isLoading,
                              icon: Icons.send_outlined,
                            ),
                            const SizedBox(height: 20),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Text('Remember it? ',
                                    style: GoogleFonts.poppins(
                                        fontSize: 13,
                                        color: AppColors.textSecondary)),
                                GestureDetector(
                                  onTap: () => Navigator.pushReplacement(
                                    context,
                                    MaterialPageRoute(
                                        builder: (_) =>
                                            const MYLoginScreen()),
                                  ),
                                  child: Text('Log In',
                                      style: GoogleFonts.poppins(
                                        fontSize: 13,
                                        fontWeight: FontWeight.w700,
                                        color: AppColors.gradientEnd,
                                      )),
                                ),
                              ],
                            ),
                            const SizedBox(height: 8),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Text("New here? ",
                                    style: GoogleFonts.poppins(
                                        fontSize: 13,
                                        color: AppColors.textSecondary)),
                                GestureDetector(
                                  onTap: () => Navigator.pushReplacement(
                                    context,
                                    MaterialPageRoute(
                                        builder: (_) =>
                                            const MyRegistrationScreen()),
                                  ),
                                  child: Text('Register',
                                      style: GoogleFonts.poppins(
                                        fontSize: 13,
                                        fontWeight: FontWeight.w700,
                                        color: AppColors.gradientEnd,
                                      )),
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
