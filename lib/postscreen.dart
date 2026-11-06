// Vibe — Social & Messaging App
import 'dart:io';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';
import 'package:my_project1/Custom_Widget/app_colors.dart';
import 'package:my_project1/Custom_Widget/mycustombutton.dart';
import 'package:my_project1/dashboardscreen.dart';

/// Create or edit a post.
/// [document1] == null → create mode (new Firestore doc + timestamp + empty likes).
/// [document1] != null → edit mode (loads existing caption/image, calls .update()).
// ignore: must_be_immutable
class MyPostScreen extends StatefulWidget {
  User? user;
  String? document1;
  MyPostScreen({super.key, required this.user, this.document1});

  @override
  State<MyPostScreen> createState() => _MyPostScreenState();
}

class _MyPostScreenState extends State<MyPostScreen> {
  final _captionController = TextEditingController();
  final _picker = ImagePicker();

  File? _pic;
  String? username;
  String? _existingPostPic;
  bool _isLoading = false;
  bool get _isEditMode => widget.document1 != null;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  @override
  void dispose() {
    _captionController.dispose();
    super.dispose();
  }

  Future<void> _loadData() async {
    final userDoc = await FirebaseFirestore.instance
        .collection('Users')
        .doc(widget.user!.uid)
        .get();
    if (!mounted) return;
    setState(() => username = userDoc.data()?['name'] as String? ?? '');

    if (_isEditMode) {
      final postDoc = await FirebaseFirestore.instance
          .collection('MyPost')
          .doc(widget.document1)
          .get();
      if (!mounted) return;
      final data = postDoc.data();
      if (data != null) {
        setState(() {
          _captionController.text = data['caption'] as String? ?? '';
          _existingPostPic = data['postpic'] as String?;
        });
      }
    }
  }

  Future<void> _selectPic() async {
    final picked = await _picker.pickImage(source: ImageSource.gallery);
    if (picked != null) setState(() => _pic = File(picked.path));
  }

  Future<void> _uploadPost() async {
    if (_pic == null && !_isEditMode) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
        behavior: SnackBarBehavior.floating,
        backgroundColor: AppColors.error,
        content: Text('Please select an image.',
            style: TextStyle(color: Colors.white)),
      ));
      return;
    }
    if (_captionController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
        behavior: SnackBarBehavior.floating,
        backgroundColor: AppColors.error,
        content: Text('Please add a caption.',
            style: TextStyle(color: Colors.white)),
      ));
      return;
    }

    setState(() => _isLoading = true);
    try {
      String? imageURL = _existingPostPic;
      if (_pic != null) {
        final docId = _isEditMode
            ? widget.document1!
            : DateTime.now().millisecondsSinceEpoch.toString();
        final ref =
            FirebaseStorage.instance.ref().child('post').child(docId);
        await ref.putFile(_pic!);
        imageURL = await ref.getDownloadURL();
      }

      final postData = {
        'uid': widget.user!.uid,
        'username': username ?? '',
        'caption': _captionController.text.trim(),
        'postpic': imageURL ?? '',
      };

      if (_isEditMode) {
        await FirebaseFirestore.instance
            .collection('MyPost')
            .doc(widget.document1)
            .update(postData);
      } else {
        await FirebaseFirestore.instance.collection('MyPost').doc().set({
          ...postData,
          'timestamp': FieldValue.serverTimestamp(),
          'likes': [],
        });
      }

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
        content: Text('Failed to save post.',
            style: TextStyle(color: Colors.white)),
      ));
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    Widget imagePreview;
    if (_pic != null) {
      imagePreview = Image.file(_pic!, fit: BoxFit.cover);
    } else if (_existingPostPic?.isNotEmpty == true) {
      imagePreview = Image.network(_existingPostPic!, fit: BoxFit.cover,
          errorBuilder: (_, __, ___) => _imagePlaceholder());
    } else {
      imagePreview = _imagePlaceholder();
    }

    return Scaffold(
      body: CustomScrollView(
        slivers: [
          SliverToBoxAdapter(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Gradient header
                Container(
                  height: 100,
                  decoration: const BoxDecoration(
                      gradient: AppColors.primaryGradient),
                  child: SafeArea(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 8),
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
                            _isEditMode ? 'Edit Post' : 'New Post',
                            style: GoogleFonts.poppins(
                              fontSize: 18,
                              fontWeight: FontWeight.w600,
                              color: Colors.white,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),

                const SizedBox(height: 20),

                // Image picker
                GestureDetector(
                  onTap: _selectPic,
                  child: Container(
                    margin: const EdgeInsets.symmetric(horizontal: 20),
                    height: 260,
                    decoration: BoxDecoration(
                      color: isDark
                          ? AppColors.elevatedDark
                          : AppColors.bgLight,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: AppColors.border,
                        width: 1.5,
                      ),
                    ),
                    clipBehavior: Clip.antiAlias,
                    child: (_pic != null || _existingPostPic?.isNotEmpty == true)
                        ? ClipRRect(
                            borderRadius: BorderRadius.circular(20),
                            child: imagePreview,
                          )
                        : imagePreview,
                  ),
                ).animate().fadeIn(delay: 100.ms).slideY(begin: 0.08),

                const SizedBox(height: 20),

                // Caption field
                Container(
                  margin: const EdgeInsets.symmetric(horizontal: 20),
                  decoration: BoxDecoration(
                    color: isDark ? AppColors.elevatedDark : Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: AppColors.cardShadow,
                  ),
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Caption',
                          style: GoogleFonts.poppins(
                            fontWeight: FontWeight.w600,
                            fontSize: 14,
                            color: AppColors.textPrimary,
                          )),
                      const SizedBox(height: 10),
                      TextField(
                        controller: _captionController,
                        maxLines: 4,
                        style: GoogleFonts.poppins(fontSize: 14),
                        decoration: InputDecoration(
                          hintText: 'Write something about your post...',
                          hintStyle: GoogleFonts.poppins(
                              color: AppColors.textHint, fontSize: 14),
                          border: InputBorder.none,
                          enabledBorder: InputBorder.none,
                          focusedBorder: InputBorder.none,
                          filled: false,
                          contentPadding: EdgeInsets.zero,
                        ),
                      ),
                    ],
                  ),
                ).animate().fadeIn(delay: 180.ms).slideY(begin: 0.08),

                const SizedBox(height: 24),

                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: GradientButton(
                    text: _isEditMode ? 'Update Post' : 'Share Post',
                    onPressed: _isLoading ? null : _uploadPost,
                    isLoading: _isLoading,
                    icon: _isEditMode
                        ? Icons.check_circle_outline
                        : Icons.send_outlined,
                  ),
                ).animate().fadeIn(delay: 250.ms),

                const SizedBox(height: 32),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _imagePlaceholder() {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Container(
          width: 64,
          height: 64,
          decoration: BoxDecoration(
            gradient: AppColors.primaryGradient,
            borderRadius: BorderRadius.circular(16),
          ),
          child: const Icon(Icons.add_photo_alternate_outlined,
              color: Colors.white, size: 32),
        ),
        const SizedBox(height: 12),
        Text('Tap to choose a photo',
            style: GoogleFonts.poppins(
                color: AppColors.textSecondary, fontSize: 14)),
      ],
    );
  }
}
