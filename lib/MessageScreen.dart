import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:my_project1/Custom_Widget/app_colors.dart';
import 'package:my_project1/Custom_Widget/app_routes.dart';
import 'package:my_project1/FriendListScreen.dart';
import 'ChatScreen.dart';
import 'dashboardscreen.dart';

/// Inbox screen — lists the most-recent message per conversation.
/// Reads the flat "chats" collection and deduplicates into one row per friend,
/// showing online status dot, last message preview, and timestamp.
class MessgaeScreenPage extends StatefulWidget {
  final User? user;

  const MessgaeScreenPage({super.key, required this.user});

  @override
  State<MessgaeScreenPage> createState() => _MessgaeScreenPageScreenState();
}

class _MessgaeScreenPageScreenState extends State<MessgaeScreenPage> {
  String? loggedUsername;

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
      setState(
          () => loggedUsername = doc.data()?['name'] as String? ?? '');
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
                      onPressed: () =>
                          Navigator.of(context).pushAndRemoveUntil(
                        MaterialPageRoute(
                            builder: (_) =>
                                Dashboard(user: widget.user)),
                        (route) => false,
                      ),
                    ),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Messages',
                              style: GoogleFonts.poppins(
                                  fontSize: 18,
                                  fontWeight: FontWeight.w700,
                                  color: Colors.white)),
                          if (loggedUsername != null)
                            Text('Hi, $loggedUsername 👋',
                                style: GoogleFonts.poppins(
                                    fontSize: 12,
                                    color: Colors.white
                                        .withValues(alpha: 0.75))),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),

          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance
                  .collection('chats')
                  .where('participants',
                      arrayContains: widget.user!.uid)
                  .orderBy('timestamp', descending: true)
                  .snapshots(),
              builder: (context, snapshot) {
                if (snapshot.connectionState ==
                    ConnectionState.waiting) {
                  return const Center(
                      child: CircularProgressIndicator());
                }
                if (snapshot.hasError) {
                  return const Center(
                      child: Text('Failed to load chats.'));
                }
                if (!snapshot.hasData ||
                    snapshot.data!.docs.isEmpty) {
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
                              Icons.chat_bubble_outline,
                              color: Colors.white,
                              size: 36),
                        ),
                        const SizedBox(height: 16),
                        Text('No chats yet',
                            style: GoogleFonts.poppins(
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                                color: AppColors.textPrimary)),
                        const SizedBox(height: 4),
                        Text('Start a conversation!',
                            style: GoogleFonts.poppins(
                                fontSize: 13,
                                color: AppColors.textSecondary)),
                      ],
                    ),
                  );
                }

                final chats = snapshot.data!.docs;
                final Map<String, Map<String, dynamic>> latestChats =
                    {};

                // Collapse the flat chats stream into one entry per friend,
                // keeping only the most-recent message for the preview row.
                for (final chat in chats) {
                  final data = chat.data() as Map<String, dynamic>;
                  final timestamp = data['timestamp'];
                  if (timestamp == null) continue;
                  final String friendId =
                      data['senderId'] == widget.user!.uid
                          ? data['receiverId'] as String
                          : data['senderId'] as String;
                  final existing = latestChats[friendId];
                  if (existing == null ||
                      (timestamp as Timestamp).toDate().isAfter(
                          (existing['timestamp'] as Timestamp)
                              .toDate())) {
                    latestChats[friendId] = data;
                  }
                }

                final sortedChats = latestChats.values.toList()
                  ..sort((a, b) => (b['timestamp'] as Timestamp)
                      .compareTo(a['timestamp'] as Timestamp));

                return ListView.builder(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 14, vertical: 10),
                  itemCount: sortedChats.length,
                  itemBuilder: (context, index) {
                    final chat = sortedChats[index];
                    final String friendId =
                        chat['senderId'] == widget.user!.uid
                            ? chat['receiverId'] as String
                            : chat['senderId'] as String;

                    return FutureBuilder<DocumentSnapshot>(
                      future: FirebaseFirestore.instance
                          .collection('Users')
                          .doc(friendId)
                          .get(),
                      builder: (context, userSnapshot) {
                        if (userSnapshot.connectionState ==
                            ConnectionState.waiting) {
                          return const SizedBox.shrink();
                        }
                        final userData = userSnapshot.data?.data()
                            as Map<String, dynamic>?;
                        if (userData == null) {
                          return const SizedBox.shrink();
                        }

                        final profilePic =
                            userData['profilepic'] as String? ?? '';
                        final friendName =
                            userData['name'] as String? ?? '';
                        final isOnline =
                            userData['isOnline'] as bool? ?? false;
                        final latestMessage =
                            chat['type'] == 'image'
                                ? '📷 Photo'
                                : (chat['message'] as String? ?? '');
                        final timestamp =
                            chat['timestamp'] as Timestamp;
                        final time = DateFormat('h:mm a')
                            .format(timestamp.toDate());

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
                                const EdgeInsets.fromLTRB(
                                    12, 8, 12, 8),
                            onTap: () => Navigator.push(
                              context,
                              SlidePageRoute(
                                page: ChatScreen(
                                  friendId: friendId,
                                  friendName: friendName,
                                  myId: widget.user!.uid,
                                  myName: loggedUsername ?? '',
                                ),
                              ),
                            ),
                            leading: Stack(
                              clipBehavior: Clip.none,
                              children: [
                                CircleAvatar(
                                  radius: 26,
                                  backgroundImage:
                                      profilePic.isNotEmpty
                                          ? NetworkImage(profilePic)
                                          : null,
                                  child: profilePic.isEmpty
                                      ? const Icon(Icons.person)
                                      : null,
                                ),
                                if (isOnline)
                                  Positioned(
                                    right: -1,
                                    bottom: -1,
                                    child: Container(
                                      width: 13,
                                      height: 13,
                                      decoration: BoxDecoration(
                                        color: AppColors.online,
                                        shape: BoxShape.circle,
                                        border: Border.all(
                                            color: Colors.white,
                                            width: 2),
                                      ),
                                    ),
                                  ),
                              ],
                            ),
                            title: Text(friendName,
                                style: GoogleFonts.poppins(
                                    fontWeight: FontWeight.w600,
                                    fontSize: 14)),
                            subtitle: Text(
                              latestMessage,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: GoogleFonts.poppins(
                                  fontSize: 12,
                                  color: AppColors.textSecondary),
                            ),
                            trailing: Text(time,
                                style: GoogleFonts.poppins(
                                    fontSize: 11,
                                    color: AppColors.textSecondary)),
                          ),
                        )
                            .animate(
                                delay: Duration(
                                    milliseconds:
                                        (index * 50).clamp(0, 400)))
                            .fadeIn(duration: 300.ms)
                            .slideX(
                                begin: 0.08,
                                curve: Curves.easeOutCubic);
                      },
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
      floatingActionButton: Container(
        decoration: const BoxDecoration(
          gradient: AppColors.primaryGradient,
          shape: BoxShape.circle,
        ),
        child: FloatingActionButton(
          backgroundColor: Colors.transparent,
          elevation: 0,
          onPressed: () => Navigator.push(
            context,
            SlidePageRoute(
              page: FriendListScreen(
                myId: widget.user!.uid,
                myName: loggedUsername ?? '',
              ),
            ),
          ),
          child: const Icon(Icons.edit_outlined, color: Colors.white),
        ),
      ),
    );
  }
}
