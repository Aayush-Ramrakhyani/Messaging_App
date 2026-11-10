// Vibe — Social & Messaging App
import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';
import 'package:my_project1/Custom_Widget/app_colors.dart';

/// Group chat screen with sequential message grouping.
///
/// Messages are stored in a subcollection: groups/{groupId}/messages
/// Each send is a Firestore batch — the message doc and the group's
/// lastMessage fields are written atomically so the inbox always reflects
/// the latest activity.
///
/// Sequential grouping rules (reverse-ordered list, index 0 = newest):
///   isFirstInGroup — this message is the OLDEST in a consecutive sender run.
///                    Shows the sender name label above the bubble.
///   isLastInGroup  — this message is the NEWEST in a run (bottom of stack).
///                    Shows the sender avatar and applies the bubble "tail".
class GroupChatScreen extends StatefulWidget {
  final String groupId;
  final String groupName;
  final String myId;
  final String myName;
  final String myPic;

  const GroupChatScreen({
    super.key,
    required this.groupId,
    required this.groupName,
    required this.myId,
    required this.myName,
    required this.myPic,
  });

  @override
  State<GroupChatScreen> createState() => _GroupChatScreenState();
}

class _GroupChatScreenState extends State<GroupChatScreen> {
  final _controller = TextEditingController();
  final _firestore = FirebaseFirestore.instance;
  final _scrollController = ScrollController();
  final _picker = ImagePicker();
  bool _isSending = false;

  @override
  void dispose() {
    _controller.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  // Deterministic color per sender name so each person has a consistent label.
  Color _senderColor(String name) {
    const palette = [
      Color(0xFF4A90D9),
      Color(0xFF7B2FBE),
      Color(0xFFE67E22),
      Color(0xFF27AE60),
      Color(0xFFE74C3C),
      Color(0xFF16A085),
    ];
    return palette[name.hashCode.abs() % palette.length];
  }

  // In a reversed list (index 0 = newest), the OLDER adjacent message is at
  // index + 1. A new run starts when the sender changes or there is a 2-minute
  // gap — whichever comes first.
  bool _isFirstInGroup(List<Map<String, dynamic>> msgs, int i) {
    if (i == msgs.length - 1) return true;
    if (msgs[i]['senderId'] != msgs[i + 1]['senderId']) return true;
    final t1 = (msgs[i]['timestamp'] as Timestamp?)?.toDate();
    final t2 = (msgs[i + 1]['timestamp'] as Timestamp?)?.toDate();
    return t1 != null && t2 != null && t1.difference(t2).inMinutes >= 2;
  }

  // The NEWER adjacent message is at index - 1. This message is the bottom of
  // a run — where the avatar is shown and the bubble tail is applied.
  bool _isLastInGroup(List<Map<String, dynamic>> msgs, int i) {
    if (i == 0) return true;
    if (msgs[i]['senderId'] != msgs[i - 1]['senderId']) return true;
    final t1 = (msgs[i]['timestamp'] as Timestamp?)?.toDate();
    final t2 = (msgs[i - 1]['timestamp'] as Timestamp?)?.toDate();
    return t1 != null && t2 != null && t2.difference(t1).inMinutes >= 2;
  }

  String _formatDate(Timestamp ts) {
    final date = ts.toDate();
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    if (date.isAfter(today)) return 'Today';
    if (date.isAfter(today.subtract(const Duration(days: 1)))) {
      return 'Yesterday';
    }
    return DateFormat('dd/MM/yyyy').format(date);
  }

  // Tail only on the last bubble of a run; all others are fully rounded.
  BorderRadius _bubbleRadius(bool isMe, bool isLast) {
    const full = Radius.circular(18);
    const tail = Radius.circular(4);
    if (isMe) {
      return BorderRadius.only(
          topLeft: full,
          topRight: full,
          bottomLeft: full,
          bottomRight: isLast ? tail : full);
    }
    return BorderRadius.only(
        topLeft: full,
        topRight: full,
        bottomLeft: isLast ? tail : full,
        bottomRight: full);
  }

  Future<void> _sendMessage() async {
    final text = _controller.text.trim();
    if (text.isEmpty || _isSending) return;
    _controller.clear();
    setState(() => _isSending = true);
    try {
      final batch = _firestore.batch();
      batch.set(
        _firestore
            .collection('groups')
            .doc(widget.groupId)
            .collection('messages')
            .doc(),
        {
          'senderId': widget.myId,
          'senderName': widget.myName,
          'senderPic': widget.myPic,
          'text': text,
          'type': 'text',
          'timestamp': FieldValue.serverTimestamp(),
        },
      );
      batch.update(
        _firestore.collection('groups').doc(widget.groupId),
        {
          'lastMessage': text,
          'lastMessageTime': FieldValue.serverTimestamp(),
          'lastSenderName': widget.myName,
        },
      );
      await batch.commit();
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            behavior: SnackBarBehavior.floating,
            content: Text('Failed to send'),
            duration: Duration(seconds: 2)),
      );
    } finally {
      if (mounted) setState(() => _isSending = false);
    }
  }

  Future<void> _sendImage() async {
    final picked = await _picker.pickImage(
        source: ImageSource.gallery, imageQuality: 70);
    if (picked == null) return;
    setState(() => _isSending = true);
    try {
      final ref = FirebaseStorage.instance
          .ref()
          .child('group_images')
          .child(
              '${widget.groupId}_${DateTime.now().millisecondsSinceEpoch}');
      await ref.putFile(File(picked.path));
      final url = await ref.getDownloadURL();

      final batch = _firestore.batch();
      batch.set(
        _firestore
            .collection('groups')
            .doc(widget.groupId)
            .collection('messages')
            .doc(),
        {
          'senderId': widget.myId,
          'senderName': widget.myName,
          'senderPic': widget.myPic,
          'text': '',
          'imageUrl': url,
          'type': 'image',
          'timestamp': FieldValue.serverTimestamp(),
        },
      );
      batch.update(
        _firestore.collection('groups').doc(widget.groupId),
        {
          'lastMessage': '📷 Photo',
          'lastMessageTime': FieldValue.serverTimestamp(),
          'lastSenderName': widget.myName,
        },
      );
      await batch.commit();
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            behavior: SnackBarBehavior.floating,
            content: Text('Failed to send image'),
            duration: Duration(seconds: 2)),
      );
    } finally {
      if (mounted) setState(() => _isSending = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      body: Column(
        children: [
          // ── Gradient AppBar ───────────────────────────────────────────────
          Container(
            decoration: const BoxDecoration(
                gradient: AppColors.primaryGradient),
            child: SafeArea(
              bottom: false,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(4, 8, 16, 12),
                child: Row(
                  children: [
                    IconButton(
                      icon: const Icon(Icons.arrow_back_ios_new,
                          color: Colors.white),
                      onPressed: () => Navigator.pop(context),
                    ),
                    Container(
                      width: 38,
                      height: 38,
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.2),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Center(
                        child: Text(
                          widget.groupName.isNotEmpty
                              ? widget.groupName[0].toUpperCase()
                              : 'G',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 18,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        widget.groupName,
                        style: GoogleFonts.poppins(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),

          // ── Message list ──────────────────────────────────────────────────
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: _firestore
                  .collection('groups')
                  .doc(widget.groupId)
                  .collection('messages')
                  .orderBy('timestamp', descending: true)
                  .snapshots(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }
                if (snapshot.hasError) {
                  return const Center(
                      child: Text('Error loading messages'));
                }

                final messages = (snapshot.data?.docs ?? [])
                    .map((d) => d.data() as Map<String, dynamic>)
                    .toList();

                if (messages.isEmpty) {
                  return Center(
                    child: Text(
                      'No messages yet. Say hello! 👋',
                      style: GoogleFonts.poppins(
                          color: AppColors.textSecondary),
                    ),
                  );
                }

                String previousDate = '';
                return ListView.builder(
                  controller: _scrollController,
                  reverse: true,
                  padding: const EdgeInsets.symmetric(
                      horizontal: 12, vertical: 8),
                  itemCount: messages.length,
                  itemBuilder: (context, index) {
                    final msg = messages[index];
                    final isMe = msg['senderId'] == widget.myId;
                    final isFirst = _isFirstInGroup(messages, index);
                    final isLast = _isLastInGroup(messages, index);
                    final senderName =
                        msg['senderName'] as String? ?? '';
                    final senderPic = msg['senderPic'] as String? ?? '';
                    final type = msg['type'] as String? ?? 'text';
                    final text = msg['text'] as String? ?? '';
                    final imageUrl = msg['imageUrl'] as String?;
                    final timestamp = msg['timestamp'] as Timestamp?;

                    final dateStr = timestamp != null
                        ? _formatDate(timestamp)
                        : '';
                    final showDate =
                        dateStr.isNotEmpty && dateStr != previousDate;
                    previousDate = dateStr;

                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        // Date separator
                        if (showDate)
                          Padding(
                            padding: const EdgeInsets.symmetric(
                                vertical: 10),
                            child: Center(
                              child: Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 12, vertical: 4),
                                decoration: BoxDecoration(
                                  color: isDark
                                      ? AppColors.elevatedDark
                                      : AppColors.bgLight,
                                  borderRadius:
                                      BorderRadius.circular(12),
                                ),
                                child: Text(dateStr,
                                    style: GoogleFonts.poppins(
                                        color: AppColors.textSecondary,
                                        fontSize: 12)),
                              ),
                            ),
                          ),

                        // Message row
                        Container(
                          margin: EdgeInsets.only(
                            bottom: isLast ? 8 : 2,
                            top: isFirst && !showDate ? 4 : 0,
                          ),
                          child: Row(
                            mainAxisAlignment: isMe
                                ? MainAxisAlignment.end
                                : MainAxisAlignment.start,
                            crossAxisAlignment: CrossAxisAlignment.end,
                            children: [
                              // Avatar area (others only)
                              if (!isMe) ...[
                                if (isLast)
                                  CircleAvatar(
                                    radius: 16,
                                    backgroundImage: senderPic.isNotEmpty
                                        ? NetworkImage(senderPic)
                                        : null,
                                    child: senderPic.isEmpty
                                        ? Text(
                                            senderName.isNotEmpty
                                                ? senderName[0]
                                                    .toUpperCase()
                                                : '?',
                                            style: const TextStyle(
                                                fontSize: 12),
                                          )
                                        : null,
                                  )
                                else
                                  // Placeholder keeps bubbles aligned
                                  const SizedBox(width: 32),
                                const SizedBox(width: 6),
                              ],

                              // Bubble + optional name label
                              Flexible(
                                child: Column(
                                  crossAxisAlignment: isMe
                                      ? CrossAxisAlignment.end
                                      : CrossAxisAlignment.start,
                                  children: [
                                    // Name only on the first bubble of a run
                                    if (!isMe && isFirst)
                                      Padding(
                                        padding: const EdgeInsets.only(
                                            left: 4, bottom: 2),
                                        child: Text(
                                          senderName,
                                          style: GoogleFonts.poppins(
                                            fontSize: 11,
                                            fontWeight: FontWeight.w600,
                                            color: _senderColor(
                                                senderName),
                                          ),
                                        ),
                                      ),

                                    Container(
                                      constraints: BoxConstraints(
                                        maxWidth: MediaQuery.of(context)
                                                .size
                                                .width *
                                            0.65,
                                      ),
                                      padding: type == 'image'
                                          ? const EdgeInsets.all(4)
                                          : const EdgeInsets.symmetric(
                                              horizontal: 12,
                                              vertical: 8),
                                      decoration: BoxDecoration(
                                        gradient: isMe
                                            ? AppColors.sentBubbleGradient
                                            : null,
                                        color: isMe
                                            ? null
                                            : (isDark
                                                ? AppColors.elevatedDark
                                                : AppColors
                                                    .receivedBubble),
                                        borderRadius: _bubbleRadius(
                                            isMe, isLast),
                                        boxShadow: [
                                          BoxShadow(
                                            color: (isMe
                                                    ? AppColors.gradientEnd
                                                    : Colors.black)
                                                .withValues(alpha: 0.08),
                                            blurRadius: 6,
                                            offset: const Offset(0, 2),
                                          ),
                                        ],
                                      ),
                                      child: type == 'image' &&
                                              imageUrl != null
                                          ? ClipRRect(
                                              borderRadius:
                                                  BorderRadius.circular(
                                                      10),
                                              child: Image.network(
                                                imageUrl,
                                                width: 200,
                                                fit: BoxFit.cover,
                                                errorBuilder: (_,
                                                        __,
                                                        ___) =>
                                                    const Icon(
                                                        Icons
                                                            .broken_image,
                                                        size: 50),
                                              ),
                                            )
                                          : Column(
                                              crossAxisAlignment: isMe
                                                  ? CrossAxisAlignment.end
                                                  : CrossAxisAlignment
                                                      .start,
                                              mainAxisSize:
                                                  MainAxisSize.min,
                                              children: [
                                                Text(
                                                  text,
                                                  style:
                                                      GoogleFonts.poppins(
                                                    fontSize: 14,
                                                    color: isMe
                                                        ? Colors.white
                                                        : (isDark
                                                            ? Colors.white
                                                            : AppColors
                                                                .textPrimary),
                                                  ),
                                                ),
                                                if (timestamp !=
                                                    null) ...[
                                                  const SizedBox(
                                                      height: 2),
                                                  Text(
                                                    DateFormat('h:mm a')
                                                        .format(timestamp
                                                            .toDate()),
                                                    style: TextStyle(
                                                      fontSize: 10,
                                                      color: isMe
                                                          ? Colors.white70
                                                          : AppColors
                                                              .textSecondary,
                                                    ),
                                                  ),
                                                ],
                                              ],
                                            ),
                                    ),
                                  ],
                                ),
                              ),

                              if (isMe) const SizedBox(width: 4),
                            ],
                          ),
                        ),
                      ],
                    )
                        .animate()
                        .slideX(
                          begin: isMe ? 0.1 : -0.1,
                          duration: 200.ms,
                          curve: Curves.easeOutCubic,
                        )
                        .fadeIn(duration: 180.ms);
                  },
                );
              },
            ),
          ),

          // ── Input bar ─────────────────────────────────────────────────────
          Container(
            decoration: BoxDecoration(
              color: isDark ? AppColors.cardDark : Colors.white,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.06),
                  blurRadius: 12,
                  offset: const Offset(0, -2),
                ),
              ],
            ),
            child: SafeArea(
              top: false,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(8, 8, 8, 8),
                child: Row(
                  children: [
                    IconButton(
                      icon: const Icon(Icons.image_outlined,
                          color: AppColors.gradientStart),
                      onPressed: _isSending ? null : _sendImage,
                    ),
                    Expanded(
                      child: Container(
                        decoration: BoxDecoration(
                          color: isDark
                              ? AppColors.elevatedDark
                              : AppColors.bgLight,
                          borderRadius: BorderRadius.circular(24),
                        ),
                        child: TextField(
                          controller: _controller,
                          textInputAction: TextInputAction.send,
                          onSubmitted: (_) => _sendMessage(),
                          style: GoogleFonts.poppins(fontSize: 14),
                          decoration: InputDecoration(
                            hintText: 'Message…',
                            hintStyle: GoogleFonts.poppins(
                                color: AppColors.textHint),
                            border: InputBorder.none,
                            enabledBorder: InputBorder.none,
                            focusedBorder: InputBorder.none,
                            filled: false,
                            isDense: true,
                            contentPadding: const EdgeInsets.symmetric(
                                horizontal: 16, vertical: 10),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 6),
                    _isSending
                        ? const SizedBox(
                            width: 40,
                            height: 40,
                            child: Center(
                              child: SizedBox(
                                width: 20,
                                height: 20,
                                child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    color: AppColors.gradientEnd),
                              ),
                            ),
                          )
                        : Container(
                            width: 42,
                            height: 42,
                            decoration: const BoxDecoration(
                              gradient: AppColors.primaryGradient,
                              shape: BoxShape.circle,
                            ),
                            child: IconButton(
                              padding: EdgeInsets.zero,
                              icon: const Icon(Icons.send_rounded,
                                  color: Colors.white, size: 20),
                              onPressed: _sendMessage,
                            ),
                          ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
