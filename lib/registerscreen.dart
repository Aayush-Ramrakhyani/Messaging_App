import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';
import 'package:my_project1/Custom_Widget/app_colors.dart';
import 'package:my_project1/Custom_Widget/mycustombutton.dart';
import 'package:my_project1/Custom_Widget/textfield.dart';
import 'package:my_project1/loginscreen.dart';

/// New user registration screen.
/// Collects username, email, password, and optional profile picture.
/// Creates a Firebase Auth account then writes a Firestore Users document.
/// If the Firestore write fails the Auth account is deleted (rollback).
class MyRegistrationScreen extends StatefulWidget {
  const MyRegistrationScreen({super.key});

  @override
  State<MyRegistrationScreen> createState() => _MyRegistrationScreenState();
}

class _MyRegistrationScreenState extends State<MyRegistrationScreen> {
  final _usernameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  final _picker = ImagePicker();

  static const String _defaultAvatar =
      'https://static.vecteezy.com/system/resources/thumbnails/009/734/564/small_2x/default-avatar-profile-icon-of-social-media-user-vector.jpg';

  File? _pic;
  bool _isLoading = false;

  @override
  void dispose() {
    _usernameController.dispose();
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

  /// Creates the account in three steps: Auth → Storage (if pic picked) → Firestore.
  Future<void> _register() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);
    User? createdUser;

    try {
      final cred = await FirebaseAuth.instance.createUserWithEmailAndPassword(
        email: _emailController.text.trim(),
        password: _passwordController.text,
      );
      createdUser = cred.user;

      String imageURL = _defaultAvatar;
      if (_pic != null) {
        final ref = FirebaseStorage.instance
            .ref()
            .child('users')
            .child(createdUser!.uid);
        await ref.putFile(_pic!);
        imageURL = await ref.getDownloadURL();
      }

      await FirebaseFirestore.instance
          .collection('Users')
          .doc(createdUser!.uid)
          .set({
        'uid': createdUser.uid,
        'name': _usernameController.text.trim(),
        'email': _emailController.text.trim(),
        'profilepic': imageURL,
      });

      if (!mounted) return;
      Navigator.pushReplacement(context,
          MaterialPageRoute(builder: (_) => const MYLoginScreen()));
    } on FirebaseAuthException catch (e) {
      if (!mounted) return;
      _showError(e.code == 'email-already-in-use'
          ? 'An account with this email already exists.'
          : e.code == 'network-request-failed'
              ? 'No internet connection.'
              : 'Registration failed. Please try again.');
    } catch (_) {
      // Roll back the Auth account if Firestore write or Storage upload fails,
      // so the user isn't left with a partially-created account they can't log into.
      await createdUser?.delete();
      if (!mounted) return;
      _showError('Registration failed. Please try again.');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _selectPic() async {
    final picked = await _picker.pickImage(source: ImageSource.gallery);
    if (picked != null) setState(() => _pic = File(picked.path));
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
              height: size.height * 0.38,
              decoration: const BoxDecoration(
                  gradient: AppColors.primaryGradient),
            ),
            Positioned(
              bottom: 0,
              left: 0,
              right: 0,
              height: size.height * 0.65,
              child: Container(color: Colors.white),
            ),
            SafeArea(
              child: SingleChildScrollView(
                physics: const BouncingScrollPhysics(),
                child: Column(
                  children: [
                    SizedBox(height: size.height * 0.04),
                    Text(
                      'Create Account',
                      style: GoogleFonts.poppins(
                        fontSize: 28,
                        fontWeight: FontWeight.w700,
                        color: Colors.white,
                      ),
                    ).animate().fadeIn(delay: 100.ms).slideY(begin: 0.3),
                    Text(
                      'Join the Vibe community',
                      style: GoogleFonts.poppins(
                        fontSize: 13,
                        color: Colors.white.withValues(alpha: 0.8),
                      ),
                    ).animate().fadeIn(delay: 200.ms),
                    const SizedBox(height: 20),

                    // ── Avatar picker ──────────────────────────────────
                    GestureDetector(
                      onTap: _selectPic,
                      child: Stack(
                        children: [
                          Container(
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              border: Border.all(
                                  color: Colors.white, width: 3),
                              boxShadow: AppColors.cardShadow,
                            ),
                            child: CircleAvatar(
                              radius: 44,
                              backgroundColor: Colors.white.withValues(alpha: 0.2),
                              backgroundImage:
                                  _pic != null ? FileImage(_pic!) : null,
                              child: _pic == null
                                  ? const Icon(Icons.person,
                                      size: 44, color: Colors.white)
                                  : null,
                            ),
                          ),
                          Positioned(
                            bottom: 0,
                            right: 0,
                            child: Container(
                              padding: const EdgeInsets.all(5),
                              decoration: const BoxDecoration(
                                color: Colors.white,
                                shape: BoxShape.circle,
                              ),
                              child: const Icon(Icons.camera_alt,
                                  size: 16,
                                  color: AppColors.gradientEnd),
                            ),
                          ),
                        ],
                      ),
                    ).animate().scale(
                          duration: 400.ms,
                          curve: Curves.elasticOut,
                          begin: const Offset(0.5, 0.5),
                          delay: 150.ms,
                        ),

                    const SizedBox(height: 24),

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
                          children: [
                            AppTextField(
                              controller: _usernameController,
                              hintText: 'Username',
                              prefixIcon: Icons.person_outlined,
                              validator: (v) => (v == null || v.trim().isEmpty)
                                  ? 'Enter a username'
                                  : null,
                            ),
                            const SizedBox(height: 14),
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
                                  (v == null || v.length < 6)
                                      ? 'Minimum 6 characters'
                                      : null,
                            ),
                            const SizedBox(height: 24),
                            GradientButton(
                              text: 'Sign Up',
                              onPressed: _isLoading ? null : _register,
                              isLoading: _isLoading,
                            ),
                            const SizedBox(height: 20),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Text(
                                  'Already have an account? ',
                                  style: GoogleFonts.poppins(
                                      fontSize: 13,
                                      color: AppColors.textSecondary),
                                ),
                                GestureDetector(
                                  onTap: () => Navigator.pushReplacement(
                                    context,
                                    MaterialPageRoute(
                                        builder: (_) =>
                                            const MYLoginScreen()),
                                  ),
                                  child: Text(
                                    'Log In',
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
