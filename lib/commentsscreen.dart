// Vibe — Social & Messaging App
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:intl/intl.dart';

/// Full-screen comments view for a single post.
/// Comments are stored as a subcollection: MyPost/{postId}/comments,
/// ordered by timestamp so they appear chronologically.
class CommentsScreen extends StatefulWidget {
  final String postId;
  final String myId;
  final String myUsername;
  final String myProfilePic;

  const CommentsScreen({
    super.key,
    required this.postId,
    required this.myId,
    required this.myUsername,
    required this.myProfilePic,
  });

  @override
  State<CommentsScreen> createState() => _CommentsScreenState();
}

class _CommentsScreenState extends State<CommentsScreen> {
  final TextEditingController _commentController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  bool _isPosting = false;

  @override
  void dispose() {
    _commentController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _postComment() async {
    final text = _commentController.text.trim();
    if (text.isEmpty || _isPosting) return;

    setState(() => _isPosting = true);
    try {
      await FirebaseFirestore.instance
          .collection('MyPost')
          .doc(widget.postId)
          .collection('comments')
          .add({
        'uid': widget.myId,
        'username': widget.myUsername,
        'profilepic': widget.myProfilePic,
        'text': text,
        'timestamp': FieldValue.serverTimestamp(),
      });
      _commentController.clear();

      // Scroll to bottom after posting
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (_scrollController.hasClients) {
          _scrollController.animateTo(
            _scrollController.position.maxScrollExtent,
            duration: const Duration(milliseconds: 300),
            curve: Curves.easeOut,
          );
        }
      });
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Failed to post comment.')),
      );
    } finally {
      if (mounted) setState(() => _isPosting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Comments')),
      body: Column(
        children: [
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance
                  .collection('MyPost')
                  .doc(widget.postId)
                  .collection('comments')
                  .orderBy('timestamp', descending: false)
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
                        Icon(Icons.chat_bubble_outline,
                            size: 64, color: Colors.grey[400]),
                        const SizedBox(height: 12),
                        Text('No comments yet. Be the first!',
                            style: TextStyle(color: Colors.grey[500])),
                      ],
                    ),
                  );
                }

                final docs = snapshot.data!.docs;
                return ListView.builder(
                  controller: _scrollController,
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  itemCount: docs.length,
                  itemBuilder: (context, index) {
                    final data =
                        docs[index].data() as Map<String, dynamic>;
                    final profilePic =
                        data['profilepic'] as String? ?? '';
                    final username =
                        data['username'] as String? ?? 'User';
                    final text = data['text'] as String? ?? '';
                    final timestamp = data['timestamp'] as Timestamp?;
                    final timeStr = timestamp != null
                        ? DateFormat('MMM d, h:mm a')
                            .format(timestamp.toDate())
                        : '';

                    return Padding(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 4),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          CircleAvatar(
                            radius: 18,
                            backgroundImage: profilePic.isNotEmpty
                                ? NetworkImage(profilePic)
                                : null,
                            child: profilePic.isEmpty
                                ? const Icon(Icons.person, size: 18)
                                : null,
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 12, vertical: 8),
                              decoration: BoxDecoration(
                                color: Theme.of(context)
                                    .colorScheme
                                    .surfaceContainerHighest,
                                borderRadius: BorderRadius.circular(14),
                              ),
                              child: Column(
                                crossAxisAlignment:
                                    CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    mainAxisAlignment:
                                        MainAxisAlignment.spaceBetween,
                                    children: [
                                      Text(username,
                                          style: const TextStyle(
                                              fontWeight:
                                                  FontWeight.w600,
                                              fontSize: 13)),
                                      Text(timeStr,
                                          style: TextStyle(
                                              fontSize: 11,
                                              color: Colors.grey[500])),
                                    ],
                                  ),
                                  const SizedBox(height: 2),
                                  Text(text,
                                      style:
                                          const TextStyle(fontSize: 14)),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                    ).animate(delay: Duration(milliseconds: index * 40))
                        .fadeIn(duration: 300.ms)
                        .slideX(begin: -0.08, curve: Curves.easeOutCubic);
                  },
                );
              },
            ),
          ),

          // Comment input bar
          SafeArea(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: Theme.of(context).scaffoldBackgroundColor,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.08),
                    blurRadius: 8,
                    offset: const Offset(0, -2),
                  ),
                ],
              ),
              child: Row(
                children: [
                  CircleAvatar(
                    radius: 18,
                    backgroundImage: widget.myProfilePic.isNotEmpty
                        ? NetworkImage(widget.myProfilePic)
                        : null,
                    child: widget.myProfilePic.isEmpty
                        ? const Icon(Icons.person, size: 18)
                        : null,
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: TextField(
                      controller: _commentController,
                      textInputAction: TextInputAction.send,
                      onSubmitted: (_) => _postComment(),
                      decoration: InputDecoration(
                        hintText: 'Add a comment…',
                        isDense: true,
                        contentPadding: const EdgeInsets.symmetric(
                            horizontal: 14, vertical: 10),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(24),
                          borderSide: BorderSide.none,
                        ),
                        filled: true,
                        fillColor: Theme.of(context)
                            .colorScheme
                            .surfaceContainerHighest,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  _isPosting
                      ? const SizedBox(
                          width: 24,
                          height: 24,
                          child:
                              CircularProgressIndicator(strokeWidth: 2))
                      : IconButton(
                          icon: const Icon(Icons.send_rounded,
                              color: Colors.deepPurple),
                          onPressed: _postComment,
                        ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
