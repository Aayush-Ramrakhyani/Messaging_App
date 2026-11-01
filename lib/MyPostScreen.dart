import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:my_project1/Custom_Widget/app_colors.dart';
import 'package:my_project1/dashboardscreen.dart';
import 'package:my_project1/postscreen.dart';

/// Shows all posts belonging to the logged-in user.
/// Each card has an overflow menu with Edit (opens [MyPostScreen] in edit mode)
/// and Delete (shows confirmation dialog before removing from Firestore).
// ignore: must_be_immutable
class MyAllPostScreen extends StatefulWidget {
  User? user;
  MyAllPostScreen({super.key, required this.user});

  @override
  State<MyAllPostScreen> createState() => _MyAllPostScreenState();
}

class _MyAllPostScreenState extends State<MyAllPostScreen> {
  String? username;

  @override
  void initState() {
    super.initState();
    _loadUsername();
  }

  Future<void> _loadUsername() async {
    try {
      final doc = await FirebaseFirestore.instance
          .collection('Users')
          .doc(widget.user!.uid)
          .get();
      if (!mounted) return;
      setState(() => username = doc.data()?['name'] as String? ?? '');
    } catch (_) {}
  }

  Future<void> _deletePost(String documentId) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20)),
        title: const Text('Delete Post'),
        content: const Text('Are you sure you want to delete this post?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.error,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10)),
            ),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Delete',
                style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
    if (confirmed != true) return;
    try {
      await FirebaseFirestore.instance
          .collection('MyPost')
          .doc(documentId)
          .delete();
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
        behavior: SnackBarBehavior.floating,
        backgroundColor: AppColors.error,
        content: Text('Failed to delete post.',
            style: TextStyle(color: Colors.white)),
      ));
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      body: Column(
        children: [
          // Gradient header
          Container(
            width: double.infinity,
            decoration: const BoxDecoration(
                gradient: AppColors.primaryGradient),
            child: SafeArea(
              bottom: false,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(8, 8, 16, 16),
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
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('My Posts',
                            style: GoogleFonts.poppins(
                                fontSize: 18,
                                fontWeight: FontWeight.w700,
                                color: Colors.white)),
                        if (username != null)
                          Text('Hi, $username',
                              style: GoogleFonts.poppins(
                                  fontSize: 12,
                                  color: Colors.white
                                      .withValues(alpha: 0.75))),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),

          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance
                  .collection('MyPost')
                  .where('uid', isEqualTo: widget.user!.uid)
                  .orderBy('timestamp', descending: true)
                  .snapshots(),
              builder: (context, snapshot) {
                if (snapshot.hasError) {
                  return const Center(
                      child: Text('Failed to load posts.'));
                }
                if (!snapshot.hasData) {
                  return const Center(
                      child: CircularProgressIndicator());
                }

                final docs = snapshot.data!.docs;
                if (docs.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(
                          width: 72,
                          height: 72,
                          decoration: BoxDecoration(
                            gradient: AppColors.primaryGradient,
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: const Icon(
                              Icons.photo_library_outlined,
                              color: Colors.white,
                              size: 36),
                        ),
                        const SizedBox(height: 16),
                        Text('No posts yet',
                            style: GoogleFonts.poppins(
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                                color: AppColors.textPrimary)),
                        const SizedBox(height: 4),
                        Text('Share your first moment!',
                            style: GoogleFonts.poppins(
                                fontSize: 13,
                                color: AppColors.textSecondary)),
                      ],
                    ),
                  );
                }

                return ListView.builder(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 14, vertical: 10),
                  itemCount: docs.length,
                  itemBuilder: (context, index) {
                    final doc = docs[index];
                    final data = doc.data() as Map<String, dynamic>;
                    final postPic = data['postpic'] as String? ?? '';
                    final caption = data['caption'] as String? ?? '';
                    final uname =
                        data['username'] as String? ?? username ?? '';

                    return Container(
                      margin: const EdgeInsets.only(bottom: 14),
                      decoration: BoxDecoration(
                        color: isDark
                            ? AppColors.cardDark
                            : AppColors.cardLight,
                        borderRadius: BorderRadius.circular(20),
                        boxShadow: AppColors.cardShadow,
                      ),
                      clipBehavior: Clip.antiAlias,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Header row
                          Padding(
                            padding: const EdgeInsets.fromLTRB(
                                14, 12, 8, 10),
                            child: Row(
                              children: [
                                Container(
                                  padding: const EdgeInsets.all(2),
                                  decoration: const BoxDecoration(
                                    shape: BoxShape.circle,
                                    gradient:
                                        AppColors.primaryGradient,
                                  ),
                                  child: const CircleAvatar(
                                    radius: 18,
                                    backgroundColor: Colors.white,
                                    child: Icon(Icons.person,
                                        size: 18,
                                        color: AppColors.gradientEnd),
                                  ),
                                ),
                                const SizedBox(width: 10),
                                Expanded(
                                  child: Text(
                                    uname,
                                    style: GoogleFonts.poppins(
                                      fontWeight: FontWeight.w600,
                                      fontSize: 14,
                                    ),
                                  ),
                                ),
                                PopupMenuButton<String>(
                                  icon: const Icon(
                                      Icons.more_vert,
                                      color: AppColors.textSecondary),
                                  shape: RoundedRectangleBorder(
                                      borderRadius:
                                          BorderRadius.circular(12)),
                                  onSelected: (choice) {
                                    if (choice == 'Edit') {
                                      Navigator.push(
                                        context,
                                        MaterialPageRoute(
                                          builder: (_) => MyPostScreen(
                                            user: widget.user,
                                            document1: doc.id,
                                          ),
                                        ),
                                      );
                                    } else if (choice == 'Delete') {
                                      _deletePost(doc.id);
                                    }
                                  },
                                  itemBuilder: (_) => [
                                    PopupMenuItem(
                                      value: 'Edit',
                                      child: Row(children: [
                                        const Icon(Icons.edit_outlined,
                                            size: 18,
                                            color: AppColors.gradientEnd),
                                        const SizedBox(width: 8),
                                        Text('Edit',
                                            style: GoogleFonts.poppins()),
                                      ]),
                                    ),
                                    PopupMenuItem(
                                      value: 'Delete',
                                      child: Row(children: [
                                        const Icon(Icons.delete_outline,
                                            size: 18,
                                            color: AppColors.error),
                                        const SizedBox(width: 8),
                                        Text('Delete',
                                            style: GoogleFonts.poppins(
                                                color: AppColors.error)),
                                      ]),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),

                          if (postPic.isNotEmpty)
                            Image.network(
                              postPic,
                              width: double.infinity,
                              height: 260,
                              fit: BoxFit.cover,
                              errorBuilder: (_, __, ___) => Container(
                                height: 260,
                                color: AppColors.bgLight,
                                child: const Icon(Icons.broken_image,
                                    size: 60,
                                    color: AppColors.textHint),
                              ),
                            ),

                          if (caption.isNotEmpty)
                            Padding(
                              padding: const EdgeInsets.fromLTRB(
                                  14, 10, 14, 14),
                              child: Text(caption,
                                  style: GoogleFonts.poppins(
                                      fontSize: 13,
                                      color: isDark
                                          ? Colors.white70
                                          : AppColors.textPrimary)),
                            )
                          else
                            const SizedBox(height: 10),
                        ],
                      ),
                    )
                        .animate(
                            delay: Duration(
                                milliseconds:
                                    (index * 60).clamp(0, 400)))
                        .fadeIn(duration: 300.ms)
                        .slideY(begin: 0.08);
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
