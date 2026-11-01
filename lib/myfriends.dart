import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:my_project1/Custom_Widget/app_colors.dart';
import 'package:my_project1/dashboardscreen.dart';

/// Shows incoming friend requests (status = "pending") for the logged-in user.
/// Accept → updates document status to "accepted".
/// Decline → deletes the document entirely so it no longer appears.
class MyFRIENDS extends StatefulWidget {
  final User? user;
  const MyFRIENDS({super.key, required this.user});

  @override
  State<MyFRIENDS> createState() => _MyFRIENDSScreenState();
}

class _MyFRIENDSScreenState extends State<MyFRIENDS> {
  String? _loggedUsername;

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
      setState(() => _loggedUsername = doc.data()?['name'] as String?);
    } catch (_) {}
  }

  /// Checks if [senderId] has sent a pending request TO the logged-in user.
  Future<bool> _hasPendingRequest(String senderId) async {
    final snap = await FirebaseFirestore.instance
        .collection('Friends')
        .where('receiver_id', isEqualTo: widget.user!.uid)
        .where('request_id', isEqualTo: senderId)
        .where('status', isEqualTo: 'pending')
        .get();
    return snap.docs.isNotEmpty;
  }

  /// Accepts or declines a friend request.
  /// Accepted → sets status field. Declined → deletes the document.
  Future<void> _respondToRequest(String senderId, String status) async {
    final snap = await FirebaseFirestore.instance
        .collection('Friends')
        .where('receiver_id', isEqualTo: widget.user!.uid)
        .where('request_id', isEqualTo: senderId)
        .get();

    for (final doc in snap.docs) {
      if (status == 'accepted') {
        await doc.reference.update({'status': status});
      } else {
        await doc.reference.delete();
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Gradient header
          Container(
            width: double.infinity,
            decoration: const BoxDecoration(
                gradient: AppColors.primaryGradient),
            child: SafeArea(
              bottom: false,
              child: Padding(
                padding:
                    const EdgeInsets.fromLTRB(8, 8, 16, 16),
                child: Row(
                  children: [
                    IconButton(
                      icon: const Icon(Icons.arrow_back_ios_new,
                          color: Colors.white),
                      onPressed: () =>
                          Navigator.pushAndRemoveUntil(
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
                        Text('Friend Requests',
                            style: GoogleFonts.poppins(
                                fontSize: 18,
                                fontWeight: FontWeight.w700,
                                color: Colors.white)),
                        if (_loggedUsername != null)
                          Text('Hi, $_loggedUsername',
                              style: GoogleFonts.poppins(
                                  fontSize: 12,
                                  color: Colors.white.withValues(
                                      alpha: 0.75))),
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
                  .collection('Users')
                  .snapshots(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(
                      child: CircularProgressIndicator());
                }
                if (!snapshot.hasData) {
                  return Center(
                      child: Text('No users found',
                          style: GoogleFonts.poppins()));
                }

                final docs = snapshot.data!.docs
                    .where((d) => d.id != widget.user!.uid)
                    .toList();

                return ListView.builder(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 16, vertical: 12),
                  itemCount: docs.length,
                  itemBuilder: (context, index) {
                    final userData =
                        docs[index].data() as Map<String, dynamic>;
                    final profilePic =
                        userData['profilepic'] as String? ?? '';
                    final name = userData['name'] as String? ?? '';
                    final email = userData['email'] as String? ?? '';
                    final uid = userData['uid'] as String? ?? '';

                    return FutureBuilder<bool>(
                      future: _hasPendingRequest(uid),
                      builder: (context, snap) {
                        if (snap.connectionState ==
                            ConnectionState.waiting) {
                          return const SizedBox.shrink();
                        }
                        if (snap.data != true) {
                          return const SizedBox.shrink();
                        }

                        return Container(
                          margin: const EdgeInsets.only(bottom: 10),
                          decoration: BoxDecoration(
                            color: isDark
                                ? AppColors.cardDark
                                : Colors.white,
                            borderRadius: BorderRadius.circular(16),
                            boxShadow: AppColors.cardShadow,
                          ),
                          child: ListTile(
                            contentPadding: const EdgeInsets.fromLTRB(
                                12, 6, 12, 6),
                            leading: CircleAvatar(
                              radius: 24,
                              backgroundImage: profilePic.isNotEmpty
                                  ? NetworkImage(profilePic)
                                  : null,
                              child: profilePic.isEmpty
                                  ? const Icon(Icons.person)
                                  : null,
                            ),
                            title: Text(name,
                                style: GoogleFonts.poppins(
                                    fontWeight: FontWeight.w600,
                                    fontSize: 14)),
                            subtitle: Text(email,
                                style: GoogleFonts.poppins(
                                    fontSize: 12,
                                    color: AppColors.textSecondary),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis),
                            trailing: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                // Accept
                                Container(
                                  decoration: BoxDecoration(
                                    color: AppColors.success,
                                    borderRadius:
                                        BorderRadius.circular(10),
                                  ),
                                  child: IconButton(
                                    icon: const Icon(
                                        Icons.check_circle_outline,
                                        color: Colors.white,
                                        size: 20),
                                    onPressed: () => _respondToRequest(
                                        uid, 'accepted'),
                                  ),
                                ),
                                const SizedBox(width: 8),
                                // Decline
                                Container(
                                  decoration: BoxDecoration(
                                    color: AppColors.error,
                                    borderRadius:
                                        BorderRadius.circular(10),
                                  ),
                                  child: IconButton(
                                    icon: const Icon(
                                        Icons.cancel_outlined,
                                        color: Colors.white,
                                        size: 20),
                                    onPressed: () => _respondToRequest(
                                        uid, 'rejected'),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        )
                            .animate(
                                delay: Duration(
                                    milliseconds:
                                        (index * 50).clamp(0, 400)))
                            .fadeIn(duration: 300.ms)
                            .slideX(begin: 0.08);
                      },
                    );
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
