// Vibe — Social & Messaging App
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:my_project1/CreateGroupScreen.dart';
import 'package:my_project1/GroupChatScreen.dart';
import 'package:my_project1/Custom_Widget/app_colors.dart';
import 'package:my_project1/Custom_Widget/app_routes.dart';

/// Lists all groups the current user belongs to, ordered by most recent activity.
/// Each row shows the group initial, name, member count, last message preview,
/// and timestamp. The FAB opens CreateGroupScreen.
class GroupListScreen extends StatefulWidget {
  final User? user;
  const GroupListScreen({super.key, required this.user});

  @override
  State<GroupListScreen> createState() => _GroupListScreenState();
}

class _GroupListScreenState extends State<GroupListScreen> {
  String _myName = '';
  String _myPic = '';

  @override
  void initState() {
    super.initState();
    _loadMyProfile();
  }

  Future<void> _loadMyProfile() async {
    try {
      final doc = await FirebaseFirestore.instance
          .collection('Users')
          .doc(widget.user!.uid)
          .get();
      if (!mounted) return;
      setState(() {
        _myName = doc.data()?['name'] as String? ?? '';
        _myPic = doc.data()?['profilepic'] as String? ?? '';
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
            decoration:
                const BoxDecoration(gradient: AppColors.primaryGradient),
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
                        Text('Group Chats',
                            style: GoogleFonts.poppins(
                                fontSize: 18,
                                fontWeight: FontWeight.w700,
                                color: Colors.white)),
                        Text('Stay connected with everyone',
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
                  .collection('groups')
                  .where('members', arrayContains: widget.user!.uid)
                  .orderBy('lastMessageTime', descending: true)
                  .snapshots(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }
                if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
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
                          child: const Icon(Icons.group_outlined,
                              color: Colors.white, size: 36),
                        ),
                        const SizedBox(height: 16),
                        Text('No groups yet',
                            style: GoogleFonts.poppins(
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                                color: AppColors.textPrimary)),
                        const SizedBox(height: 4),
                        Text('Tap + to create one',
                            style: GoogleFonts.poppins(
                                fontSize: 13,
                                color: AppColors.textSecondary)),
                      ],
                    ),
                  );
                }

                final groups = snapshot.data!.docs;
                return ListView.builder(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 14, vertical: 10),
                  itemCount: groups.length,
                  itemBuilder: (context, index) {
                    final data =
                        groups[index].data() as Map<String, dynamic>;
                    final groupId = groups[index].id;
                    final groupName = data['name'] as String? ?? '';
                    final lastMessage =
                        data['lastMessage'] as String? ?? '';
                    final lastSender =
                        data['lastSenderName'] as String? ?? '';
                    final lastTime =
                        data['lastMessageTime'] as Timestamp?;
                    final memberCount =
                        (data['members'] as List?)?.length ?? 0;

                    final timeStr = lastTime != null
                        ? DateFormat('h:mm a').format(lastTime.toDate())
                        : '';

                    return Container(
                      margin: const EdgeInsets.only(bottom: 10),
                      decoration: BoxDecoration(
                        color: isDark ? AppColors.cardDark : Colors.white,
                        borderRadius: BorderRadius.circular(16),
                        boxShadow: AppColors.cardShadow,
                      ),
                      child: ListTile(
                        contentPadding:
                            const EdgeInsets.fromLTRB(12, 8, 12, 8),
                        onTap: () => Navigator.push(
                          context,
                          SlidePageRoute(
                            page: GroupChatScreen(
                              groupId: groupId,
                              groupName: groupName,
                              myId: widget.user!.uid,
                              myName: _myName,
                              myPic: _myPic,
                            ),
                          ),
                        ),
                        leading: Container(
                          width: 48,
                          height: 48,
                          decoration: BoxDecoration(
                            gradient: AppColors.primaryGradient,
                            borderRadius: BorderRadius.circular(14),
                          ),
                          child: Center(
                            child: Text(
                              groupName.isNotEmpty
                                  ? groupName[0].toUpperCase()
                                  : 'G',
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 20,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ),
                        ),
                        title: Row(
                          children: [
                            Expanded(
                              child: Text(groupName,
                                  style: GoogleFonts.poppins(
                                      fontWeight: FontWeight.w600,
                                      fontSize: 14)),
                            ),
                            Text('$memberCount members',
                                style: GoogleFonts.poppins(
                                    fontSize: 11,
                                    color: AppColors.textSecondary)),
                          ],
                        ),
                        subtitle: Text(
                          lastSender.isNotEmpty
                              ? '$lastSender: $lastMessage'
                              : lastMessage,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: GoogleFonts.poppins(
                              fontSize: 12,
                              color: AppColors.textSecondary),
                        ),
                        trailing: Text(timeStr,
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
              page: CreateGroupScreen(
                myId: widget.user!.uid,
                myName: _myName,
              ),
            ),
          ),
          child: const Icon(Icons.group_add_outlined, color: Colors.white),
        ),
      ),
    );
  }
}
