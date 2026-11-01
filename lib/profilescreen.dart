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
import 'package:my_project1/dashboardscreen.dart';

// ignore: must_be_immutable
class MyProfileScreen extends StatefulWidget {
  User? user;
  MyProfileScreen({super.key, required this.user});

  @override
  State<MyProfileScreen> createState() => _MyProfileScreenState();
}

class _MyProfileScreenState extends State<MyProfileScreen> {
  final _emailController = TextEditingController();
  final _usernameController = TextEditingController();
  final _picker = ImagePicker();

  String? username;
  String? _currentProfilePic;
  File? _newPic;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  @override
  void dispose() {
    _emailController.dispose();
    _usernameController.dispose();
    super.dispose();
  }

  Future<void> _loadData() async {
    try {
      final doc = await FirebaseFirestore.instance
          .collection('Users')
          .doc(widget.user!.uid)
          .get();
      if (!mounted) return;
      final data = doc.data();
      setState(() {
        _usernameController.text = data?['name'] as String? ?? '';
        _emailController.text = data?['email'] as String? ?? '';
        username = data?['name'] as String?;
        _currentProfilePic = data?['profilepic'] as String?;
      });
    } catch (_) {}
  }

  Future<void> _pickImage() async {
    final picked =
        await _picker.pickImage(source: ImageSource.gallery, imageQuality: 80);
    if (picked != null) setState(() => _newPic = File(picked.path));
  }

  Future<void> _updateProfile() async {
    final newName = _usernameController.text.trim();
    if (newName.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
        behavior: SnackBarBehavior.floating,
        backgroundColor: AppColors.error,
        content: Text('Username cannot be empty.',
            style: TextStyle(color: Colors.white)),
      ));
      return;
    }

    setState(() => _isLoading = true);
    try {
      String? picUrl = _currentProfilePic;
      if (_newPic != null) {
        final ref = FirebaseStorage.instance
            .ref()
            .child('users')
            .child(widget.user!.uid);
        await ref.putFile(_newPic!);
        picUrl = await ref.getDownloadURL();
      }

      await FirebaseFirestore.instance
          .collection('Users')
          .doc(widget.user!.uid)
          .update({'name': newName, 'profilepic': picUrl ?? ''});

      if (!mounted) return;
      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(builder: (_) => Dashboard(user: widget.user)),
        (route) => false,
      );
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
        behavior: SnackBarBehavior.floating,
        backgroundColor: AppColors.error,
        content: Text('Failed to update profile.',
            style: TextStyle(color: Colors.white)),
      ));
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final heroTag = 'avatar_${widget.user!.uid}';
    final size = MediaQuery.of(context).size;

    ImageProvider? avatarImage = _newPic != null
        ? FileImage(_newPic!) as ImageProvider
        : (_currentProfilePic?.isNotEmpty == true
            ? NetworkImage(_currentProfilePic!)
            : null);

    return Scaffold(
      body: SizedBox(
        height: size.height,
        width: size.width,
        child: Stack(
          children: [
            // Gradient header
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
              child: Container(
                  color: Theme.of(context).scaffoldBackgroundColor),
            ),

            SafeArea(
              child: Column(
                children: [
                  // AppBar row
                  Padding(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 8, vertical: 4),
                    child: Row(
                      children: [
                        IconButton(
                          icon: const Icon(Icons.arrow_back_ios_new,
                              color: Colors.white),
                          onPressed: () => Navigator.pushAndRemoveUntil(
                            context,
                            MaterialPageRoute(
                                builder: (_) =>
                                    Dashboard(user: widget.user)),
                            (r) => false,
                          ),
                        ),
                        Text(
                          'Edit Profile',
                          style: GoogleFonts.poppins(
                            fontSize: 18,
                            fontWeight: FontWeight.w600,
                            color: Colors.white,
                          ),
                        ),
                      ],
                    ),
                  ),

                  // Avatar
                  const SizedBox(height: 8),
                  GestureDetector(
                    onTap: _pickImage,
                    child: Stack(
                      children: [
                        Container(
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            border:
                                Border.all(color: Colors.white, width: 3),
                            boxShadow: AppColors.cardShadow,
                          ),
                          child: Hero(
                            tag: heroTag,
                            child: CircleAvatar(
                              radius: 50,
                              backgroundColor:
                                  Colors.white.withValues(alpha: 0.2),
                              backgroundImage: avatarImage,
                              child: avatarImage == null
                                  ? const Icon(Icons.person,
                                      size: 50, color: Colors.white)
                                  : null,
                            ),
                          ),
                        ),
                        Positioned(
                          bottom: 0,
                          right: 0,
                          child: Container(
                            padding: const EdgeInsets.all(6),
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
                        begin: const Offset(0.6, 0.6),
                      ),

                  Text(
                    username ?? '',
                    style: GoogleFonts.poppins(
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                      color: Colors.white,
                    ),
                  ).animate().fadeIn(delay: 150.ms),

                  const SizedBox(height: 28),

                  // Form card
                  Expanded(
                    child: SingleChildScrollView(
                      physics: const BouncingScrollPhysics(),
                      child: Container(
                        margin:
                            const EdgeInsets.symmetric(horizontal: 20),
                        decoration: BoxDecoration(
                          color: Theme.of(context).brightness ==
                                  Brightness.dark
                              ? AppColors.cardDark
                              : Colors.white,
                          borderRadius: BorderRadius.circular(28),
                          boxShadow: AppColors.cardShadow,
                        ),
                        padding:
                            const EdgeInsets.fromLTRB(24, 28, 24, 28),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Account Info',
                              style: GoogleFonts.poppins(
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                                color: AppColors.textPrimary,
                              ),
                            ),
                            const SizedBox(height: 16),
                            AppTextField(
                              controller: _emailController,
                              hintText: 'Email address',
                              prefixIcon: Icons.email_outlined,
                              readOnly: true,
                            ),
                            const SizedBox(height: 14),
                            AppTextField(
                              controller: _usernameController,
                              hintText: 'Username',
                              prefixIcon: Icons.person_outlined,
                            ),
                            const SizedBox(height: 24),
                            GradientButton(
                              text: 'Save Changes',
                              onPressed: _isLoading ? null : _updateProfile,
                              isLoading: _isLoading,
                              icon: Icons.check_circle_outline,
                            ),
                          ],
                        ),
                      ).animate().fadeIn(delay: 250.ms).slideY(begin: 0.1),
                    ),
                  ),
                  const SizedBox(height: 24),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
