// Vibe — Social & Messaging App
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:my_project1/Custom_Widget/app_colors.dart';

/// Discover and add new friends.
/// Shows all users except the logged-in user and anyone already connected
/// (pending or accepted in either direction).
class MyAddFriends extends StatefulWidget {
  final User? user;
  const MyAddFriends({super.key, required this.user});

  @override
  State<MyAddFriends> createState() => _MyAddFriendsScreenState();
}

class _MyAddFriendsScreenState extends State<MyAddFriends> {
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

  /// Checks both directions (I sent to them, or they sent to me) so neither
  /// side can send a duplicate request.
  Future<bool> _isAlreadyConnected(String? otherId) async {
    final q1 = await FirebaseFirestore.instance
        .collection('Friends')
        .where('status', whereIn: ['pending', 'accepted'])
        .where('request_id', isEqualTo: widget.user!.uid)
        .where('receiver_id', isEqualTo: otherId)
        .get();
    if (q1.docs.isNotEmpty) return true;

    final q2 = await FirebaseFirestore.instance
        .collection('Friends')
        .where('status', whereIn: ['pending', 'accepted'])
        .where('request_id', isEqualTo: otherId)
        .where('receiver_id', isEqualTo: widget.user!.uid)
        .get();
    return q2.docs.isNotEmpty;
  }

  Future<void> _addFriend(String? receiverId, String? recUsername) async {
    await FirebaseFirestore.instance.collection('Friends').doc().set({
      'request_id': widget.user!.uid,
      'receiver_id': receiverId,
      'request_username': _loggedUsername,
      'receiver_username': recUsername,
      'status': 'pending',
    });
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
      behavior: SnackBarBehavior.floating,
      backgroundColor: AppColors.success,
      content: Text('Friend request sent!',
          style: TextStyle(color: Colors.white)),
      duration: Duration(seconds: 2),
    ));
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Container(
            width: double.infinity,
            padding: const EdgeInsets.fromLTRB(20, 60, 20, 20),
            decoration: const BoxDecoration(
                gradient: AppColors.primaryGradient),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Find Friends',
                    style: GoogleFonts.poppins(
                        fontSize: 22,
                        fontWeight: FontWeight.w700,
                        color: Colors.white)),
                Text('Discover people on Vibe',
                    style: GoogleFonts.poppins(
                        fontSize: 13,
                        color: Colors.white.withValues(alpha: 0.75))),
              ],
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
                if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
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
                      future: _isAlreadyConnected(uid),
                      builder: (context, snap) {
                        if (snap.connectionState ==
                            ConnectionState.waiting) {
                          return const SizedBox.shrink();
                        }
                        if (snap.data == true) {
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
                            trailing: Container(
                              decoration: BoxDecoration(
                                gradient: AppColors.primaryGradient,
                                borderRadius:
                                    BorderRadius.circular(10),
                              ),
                              child: IconButton(
                                icon: const Icon(Icons.person_add,
                                    color: Colors.white, size: 20),
                                onPressed: () =>
                                    _addFriend(uid, name),
                              ),
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
