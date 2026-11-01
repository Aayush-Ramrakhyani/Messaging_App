import 'dart:async';
import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';
import 'package:my_project1/Custom_Widget/app_colors.dart';

/// Real-time 1-to-1 chat screen.
/// Messages are stored in the "chats" collection with a participants array
/// so both sides can query with arrayContains.
/// Features: text + image messages, typing indicator, date separators.
class ChatScreen extends StatefulWidget {
  final String friendId;
  final String friendName;
  final String myId;
  final String myName;

  const ChatScreen({
    super.key,
    required this.friendId,
    required this.friendName,
    required this.myId,
    required this.myName,
  });

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final TextEditingController _controller = TextEditingController();
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final ScrollController _scrollController = ScrollController();
  final ImagePicker _picker = ImagePicker();

  bool _isSending = false;
  Timer? _typingTimer;

  @override
  void initState() {
    super.initState();
    _controller.addListener(_onTextChanged);
  }

  @override
  void dispose() {
    _controller.removeListener(_onTextChanged);
    _controller.dispose();
    _scrollController.dispose();
    _typingTimer?.cancel();
    _firestore
        .collection('typing')
        .doc(widget.myId)
        .delete()
        .catchError((_) {});
    super.dispose();
  }

  void _onTextChanged() {
    if (_controller.text.isNotEmpty) {
      _firestore.collection('typing').doc(widget.myId).set({
        'isTyping': true,
        'to': widget.friendId,
      });
      // Debounce: reset the 3 s timer on every keystroke so the indicator
      // only disappears after the user stops typing, not between letters.
      _typingTimer?.cancel();
      _typingTimer = Timer(const Duration(seconds: 3), () {
        _firestore.collection('typing').doc(widget.myId).delete();
      });
    } else {
      _typingTimer?.cancel();
      _firestore.collection('typing').doc(widget.myId).delete();
    }
  }

  /// Sends a text message and writes a notification document for the receiver.
  void _sendMessage() async {
    final text = _controller.text.trim();
    if (text.isEmpty || _isSending) return;

    _controller.clear();
    _typingTimer?.cancel();
    _firestore.collection('typing').doc(widget.myId).delete();

    setState(() => _isSending = true);
    try {
      await _firestore.collection('chats').add({
        'senderId': widget.myId,
        'receiverId': widget.friendId,
        'participants': [widget.myId, widget.friendId],
        'message': text,
        'type': 'text',
        'timestamp': FieldValue.serverTimestamp(),
      });
      await _firestore.collection('notifications').add({
        'receiverId': widget.friendId,
        'message': text,
        'senderName': widget.myName,
        'timestamp': FieldValue.serverTimestamp(),
      });
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
        content: Text('Failed to send message.'),
        duration: Duration(seconds: 2),
      ));
    } finally {
      if (mounted) setState(() => _isSending = false);
    }
  }

  /// Picks an image, uploads it to Storage under chat_images/, then sends
  /// a message with type "image" and an imageUrl field instead of message.
  void _sendImage() async {
    final picked =
        await _picker.pickImage(source: ImageSource.gallery, imageQuality: 70);
    if (picked == null) return;

    setState(() => _isSending = true);
    try {
      final ref = FirebaseStorage.instance
          .ref()
          .child('chat_images')
          .child('${widget.myId}_${DateTime.now().millisecondsSinceEpoch}');
      await ref.putFile(File(picked.path));
      final url = await ref.getDownloadURL();

      await _firestore.collection('chats').add({
        'senderId': widget.myId,
        'receiverId': widget.friendId,
        'participants': [widget.myId, widget.friendId],
        'message': '',
        'imageUrl': url,
        'type': 'image',
        'timestamp': FieldValue.serverTimestamp(),
      });
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
        content: Text('Failed to send image.'),
        duration: Duration(seconds: 2),
      ));
    } finally {
      if (mounted) setState(() => _isSending = false);
    }
  }

  /// Returns "Today", "Yesterday", or a dd/MM/yyyy string for date separators.
  String _formatDate(Timestamp timestamp) {
    final date = timestamp.toDate();
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final yesterday = today.subtract(const Duration(days: 1));
    if (date.isAfter(today)) return 'Today';
    if (date.isAfter(yesterday)) return 'Yesterday';
    return DateFormat('dd/MM/yyyy').format(date);
  }

  void _scrollToBottom() {
    if (_scrollController.hasClients) {
      _scrollController.animateTo(
        0.0,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOut,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      body: Column(
        children: [
          // ── Gradient AppBar ──────────────────────────────────────────
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
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(Icons.person,
                          color: Colors.white, size: 22),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        widget.friendName,
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

          // ── Message list ─────────────────────────────────────────────
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: _firestore
                  .collection('chats')
                  .where('participants', arrayContains: widget.myId)
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
                    .where((doc) {
                      final d = doc.data() as Map<String, dynamic>;
                      return (d['senderId'] == widget.myId &&
                              d['receiverId'] == widget.friendId) ||
                          (d['receiverId'] == widget.myId &&
                              d['senderId'] == widget.friendId);
                    })
                    .map((doc) => doc.data() as Map<String, dynamic>)
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

                WidgetsBinding.instance
                    .addPostFrameCallback((_) => _scrollToBottom());

                String previousDate = '';
                return ListView.builder(
                  controller: _scrollController,
                  reverse: true,
                  itemCount: messages.length,
                  itemBuilder: (context, index) {
                    final msg = messages[index];
                    final bool isMe = msg['senderId'] == widget.myId;
                    final timestamp = msg['timestamp'] as Timestamp?;
                    final String messageDate =
                        timestamp != null ? _formatDate(timestamp) : '';
                    final bool showDate =
                        messageDate != previousDate &&
                            messageDate.isNotEmpty;
                    previousDate = messageDate;
                    final String type =
                        msg['type'] as String? ?? 'text';
                    final String text =
                        msg['message'] as String? ?? '';
                    final String? imageUrl =
                        msg['imageUrl'] as String?;

                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
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
                                child: Text(messageDate,
                                    style: GoogleFonts.poppins(
                                        color: AppColors.textSecondary,
                                        fontSize: 12)),
                              ),
                            ),
                          ),

                        Align(
                          alignment: isMe
                              ? Alignment.centerRight
                              : Alignment.centerLeft,
                          child: Container(
                            constraints: BoxConstraints(
                              maxWidth:
                                  MediaQuery.of(context).size.width *
                                      0.72,
                            ),
                            margin: const EdgeInsets.symmetric(
                                vertical: 3, horizontal: 12),
                            padding: type == 'image'
                                ? const EdgeInsets.all(4)
                                : const EdgeInsets.symmetric(
                                    horizontal: 14, vertical: 10),
                            decoration: BoxDecoration(
                              gradient: isMe
                                  ? AppColors.sentBubbleGradient
                                  : null,
                              color: isMe
                                  ? null
                                  : (isDark
                                      ? AppColors.elevatedDark
                                      : AppColors.receivedBubble),
                              borderRadius: BorderRadius.only(
                                topLeft:
                                    const Radius.circular(18),
                                topRight:
                                    const Radius.circular(18),
                                bottomLeft:
                                    Radius.circular(isMe ? 18 : 4),
                                bottomRight:
                                    Radius.circular(isMe ? 4 : 18),
                              ),
                              boxShadow: [
                                BoxShadow(
                                  color: (isMe
                                          ? AppColors.gradientEnd
                                          : Colors.black)
                                      .withValues(alpha: 0.08),
                                  blurRadius: 8,
                                  offset: const Offset(0, 2),
                                )
                              ],
                            ),
                            child: Column(
                              crossAxisAlignment: isMe
                                  ? CrossAxisAlignment.end
                                  : CrossAxisAlignment.start,
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                if (type == 'image' &&
                                    imageUrl != null)
                                  ClipRRect(
                                    borderRadius:
                                        BorderRadius.circular(12),
                                    child: Image.network(
                                      imageUrl,
                                      width: 220,
                                      fit: BoxFit.cover,
                                      errorBuilder: (_, __, ___) =>
                                          const Icon(
                                              Icons.broken_image,
                                              size: 60),
                                    ),
                                  )
                                else
                                  Text(
                                    text,
                                    style: GoogleFonts.poppins(
                                      fontSize: 14,
                                      color: isMe
                                          ? Colors.white
                                          : (isDark
                                              ? Colors.white
                                              : AppColors.textPrimary),
                                    ),
                                  ),
                                if (timestamp != null) ...[
                                  const SizedBox(height: 4),
                                  Text(
                                    DateFormat('h:mm a')
                                        .format(timestamp.toDate()),
                                    style: TextStyle(
                                      fontSize: 10,
                                      color: isMe
                                          ? Colors.white70
                                          : AppColors.textSecondary,
                                    ),
                                  ),
                                ],
                              ],
                            ),
                          ),
                        )
                            .animate()
                            .slideX(
                              begin: isMe ? 0.15 : -0.15,
                              duration: 250.ms,
                              curve: Curves.easeOutCubic,
                            )
                            .fadeIn(duration: 200.ms),
                      ],
                    );
                  },
                );
              },
            ),
          ),

          // ── Typing indicator ─────────────────────────────────────────
          StreamBuilder<DocumentSnapshot>(
            stream: _firestore
                .collection('typing')
                .doc(widget.friendId)
                .snapshots(),
            builder: (context, snap) {
              final data =
                  snap.data?.data() as Map<String, dynamic>?;
              final isTyping = data?['isTyping'] == true &&
                  data?['to'] == widget.myId;
              if (!isTyping) return const SizedBox.shrink();
              return Padding(
                padding: const EdgeInsets.only(left: 18, bottom: 4),
                child: Text(
                  '${widget.friendName} is typing…',
                  style: GoogleFonts.poppins(
                    color: AppColors.textSecondary,
                    fontStyle: FontStyle.italic,
                    fontSize: 12,
                  ),
                ).animate().fadeIn(duration: 200.ms),
              );
            },
          ),

          // ── Input bar ────────────────────────────────────────────────
          Container(
            decoration: BoxDecoration(
              color: isDark ? AppColors.cardDark : Colors.white,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.06),
                  blurRadius: 12,
                  offset: const Offset(0, -2),
                )
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
