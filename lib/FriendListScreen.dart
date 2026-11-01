import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:my_project1/Custom_Widget/app_colors.dart';
import 'ChatScreen.dart';

class FriendListScreen extends StatefulWidget {
  final String myId;
  final String myName;

  const FriendListScreen({super.key, required this.myId, required this.myName});

  @override
  State<FriendListScreen> createState() => _FriendListScreenState();
}

class _FriendListScreenState extends State<FriendListScreen> {
  String? _loggedUsername;
  List<String> _friendIds = [];

  @override
  void initState() {
    super.initState();
    _loadFriends();
  }

  Future<void> _loadFriends() async {
    try {
      final userDoc = await FirebaseFirestore.instance
          .collection('Users')
          .doc(widget.myId)
          .get();
      if (!mounted) return;
      setState(
          () => _loggedUsername = userDoc.data()?['name'] as String?);

      final snap = await FirebaseFirestore.instance
          .collection('Friends')
          .where('request_id', isEqualTo: widget.myId)
          .where('status', isEqualTo: 'accepted')
          .get();

      if (!mounted) return;
      setState(() {
        _friendIds =
            snap.docs.map((d) => d['receiver_id'] as String).toList();
      });
    } catch (_) {}
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
                      onPressed: () => Navigator.pop(context),
                    ),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Start a Chat',
                            style: GoogleFonts.poppins(
                                fontSize: 18,
                                fontWeight: FontWeight.w700,
                                color: Colors.white)),
                        if (_loggedUsername != null)
                          Text('Choose a friend',
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
                  .collection('Users')
                  .snapshots(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(
                      child: CircularProgressIndicator());
                }
                if (!snapshot.hasData) {
                  return Center(
                      child: Text('No users found.',
                          style: GoogleFonts.poppins()));
                }

                final friends = snapshot.data!.docs
                    .where((d) =>
                        _friendIds.contains(d['uid']) &&
                        d['uid'] != widget.myId)
                    .toList();

                if (friends.isEmpty) {
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
                          child: const Icon(Icons.people_outlined,
                              color: Colors.white, size: 36),
                        ),
                        const SizedBox(height: 16),
                        Text('No friends yet',
                            style: GoogleFonts.poppins(
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                                color: AppColors.textPrimary)),
                        const SizedBox(height: 4),
                        Text('Add friends to start chatting!',
                            style: GoogleFonts.poppins(
                                fontSize: 13,
                                color: AppColors.textSecondary)),
                      ],
                    ),
                  );
                }

                return ListView.builder(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 16, vertical: 12),
                  itemCount: friends.length,
                  itemBuilder: (context, index) {
                    final user =
                        friends[index].data() as Map<String, dynamic>;
                    final profilePic =
                        user['profilepic'] as String? ?? '';
                    final name = user['name'] as String? ?? '';
                    final email = user['email'] as String? ?? '';
                    final uid = user['uid'] as String? ?? '';

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
                        contentPadding:
                            const EdgeInsets.fromLTRB(12, 6, 16, 6),
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
                          width: 36,
                          height: 36,
                          decoration: const BoxDecoration(
                            gradient: AppColors.primaryGradient,
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(
                              Icons.chat_bubble_outline,
                              color: Colors.white,
                              size: 18),
                        ),
                        onTap: () => Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => ChatScreen(
                              friendId: uid,
                              friendName: name,
                              myId: widget.myId,
                              myName: widget.myName,
                            ),
                          ),
                        ),
                      ),
                    )
                        .animate(
                            delay: Duration(
                                milliseconds:
                                    (index * 50).clamp(0, 300)))
                        .fadeIn(duration: 280.ms)
                        .slideX(begin: 0.08);
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
