import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shimmer/shimmer.dart';
import 'package:my_project1/Custom_Widget/app_colors.dart';
import 'package:my_project1/commentsscreen.dart';
import 'package:my_project1/Custom_Widget/app_routes.dart';

/// Social feed — streams all posts ordered by timestamp (newest first).
/// Shows a shimmer skeleton while loading, then staggered card animations.
/// Each card supports: like toggle, comment count badge, full-screen image Hero.
class MyHomeScreen extends StatefulWidget {
  const MyHomeScreen({super.key});

  @override
  State<MyHomeScreen> createState() => _MyHomeScreenState();
}

class _MyHomeScreenState extends State<MyHomeScreen> {
  final String? _myId = FirebaseAuth.instance.currentUser?.uid;

  // ── Likes ────────────────────────────────────────────────────────────────

  // arrayUnion / arrayRemove are atomic on Firestore, so concurrent likes
  // from different devices can't overwrite each other (unlike a plain set).
  Future<void> _toggleLike(String postId, List<dynamic> currentLikes) async {
    if (_myId == null) return;
    final ref =
        FirebaseFirestore.instance.collection('MyPost').doc(postId);
    if (currentLikes.contains(_myId)) {
      await ref.update({
        'likes': FieldValue.arrayRemove([_myId])
      });
    } else {
      await ref.update({
        'likes': FieldValue.arrayUnion([_myId])
      });
    }
  }

  // ── Shimmer placeholder ──────────────────────────────────────────────────

  Widget _shimmerCard() {
    return Shimmer.fromColors(
      baseColor: Colors.grey[300]!,
      highlightColor: Colors.grey[100]!,
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(14, 12, 14, 10),
              child: Row(children: [
                const CircleAvatar(radius: 22, backgroundColor: Colors.white),
                const SizedBox(width: 10),
                Container(height: 14, width: 120, color: Colors.white),
              ]),
            ),
            Container(height: 280, width: double.infinity, color: Colors.white),
            Padding(
              padding: const EdgeInsets.fromLTRB(14, 10, 14, 4),
              child: Container(height: 14, width: 180, color: Colors.white),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(14, 4, 14, 12),
              child: Container(height: 14, width: 80, color: Colors.white),
            ),
          ],
        ),
      ),
    );
  }

  // ── Full-screen image viewer (Hero destination) ─────────────────────────

  void _openFullImage(BuildContext context, String imageUrl, String heroTag) {
    Navigator.push(
      context,
      SlidePageRoute(
        page: _FullImageScreen(imageUrl: imageUrl, heroTag: heroTag),
      ),
    );
  }

  // ── Build ────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('MyPost')
            .orderBy('timestamp', descending: true)
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return const Center(child: Text('Failed to load posts.'));
          }

          // Show shimmer skeleton while waiting
          if (snapshot.connectionState == ConnectionState.waiting) {
            return ListView.builder(
              itemCount: 4,
              itemBuilder: (_, __) => _shimmerCard(),
            );
          }

          final docs = snapshot.data?.docs ?? [];
          if (docs.isEmpty) {
            return Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.photo_library_outlined,
                      size: 72, color: Colors.grey[400]),
                  const SizedBox(height: 12),
                  Text('No posts yet.',
                      style: TextStyle(color: Colors.grey[500], fontSize: 16)),
                ],
              ),
            );
          }

          return RefreshIndicator(
            onRefresh: () async {
              // StreamBuilder refreshes automatically; this just shows the UX
              await Future.delayed(const Duration(milliseconds: 400));
            },
            child: ListView.builder(
              itemCount: docs.length,
              itemBuilder: (context, index) {
                final doc = docs[index];
                final data = doc.data() as Map<String, dynamic>;
                final uid = data['uid'] as String? ?? '';
                final postPic = data['postpic'] as String? ?? '';
                final caption = data['caption'] as String? ?? '';
                final likes =
                    (data['likes'] as List<dynamic>?) ?? [];
                final bool isLiked =
                    _myId != null && likes.contains(_myId);

                return FutureBuilder<DocumentSnapshot>(
                  future: FirebaseFirestore.instance
                      .collection('Users')
                      .doc(uid)
                      .get(),
                  builder: (context, userSnap) {
                    if (userSnap.connectionState != ConnectionState.done) {
                      return _shimmerCard();
                    }
                    final userData =
                        userSnap.data?.data() as Map<String, dynamic>?;
                    final profilePic =
                        userData?['profilepic'] as String? ?? '';
                    final username = userData?['name'] as String? ?? '';
                    final avatarHero = 'avatar_$uid';
                    final postHero = 'post_${doc.id}';

                    return _PostCard(
                      docId: doc.id,
                      uid: uid,
                      username: username,
                      profilePic: profilePic,
                      postPic: postPic,
                      caption: caption,
                      likes: likes,
                      isLiked: isLiked,
                      myId: _myId ?? '',
                      avatarHeroTag: avatarHero,
                      postHeroTag: postHero,
                      myUsername: FirebaseAuth
                              .instance.currentUser?.displayName ??
                          '',
                      myProfilePic: profilePic,
                      onLikeTap: () => _toggleLike(doc.id, likes),
                      onAvatarTap: () =>
                          _openFullImage(context, profilePic, avatarHero),
                      onImageTap: () =>
                          _openFullImage(context, postPic, postHero),
                    )
                        // Staggered slide-up + fade-in per card
                        .animate(
                            delay: Duration(
                                milliseconds: (index * 80).clamp(0, 600)))
                        .slideY(
                            begin: 0.15,
                            duration: 400.ms,
                            curve: Curves.easeOutCubic)
                        .fadeIn(duration: 350.ms);
                  },
                );
              },
            ),
          );
        },
      ),
    );
  }
}

// ── Post card widget ─────────────────────────────────────────────────────────

class _PostCard extends StatefulWidget {
  final String docId;
  final String uid;
  final String username;
  final String profilePic;
  final String postPic;
  final String caption;
  final List<dynamic> likes;
  final bool isLiked;
  final String myId;
  final String myUsername;
  final String myProfilePic;
  final String avatarHeroTag;
  final String postHeroTag;
  final VoidCallback onLikeTap;
  final VoidCallback onAvatarTap;
  final VoidCallback onImageTap;

  const _PostCard({
    required this.docId,
    required this.uid,
    required this.username,
    required this.profilePic,
    required this.postPic,
    required this.caption,
    required this.likes,
    required this.isLiked,
    required this.myId,
    required this.myUsername,
    required this.myProfilePic,
    required this.avatarHeroTag,
    required this.postHeroTag,
    required this.onLikeTap,
    required this.onAvatarTap,
    required this.onImageTap,
  });

  @override
  State<_PostCard> createState() => _PostCardState();
}

class _PostCardState extends State<_PostCard>
    with SingleTickerProviderStateMixin {
  late AnimationController _heartController;
  late Animation<double> _heartScale;

  @override
  void initState() {
    super.initState();
    _heartController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );
    // TweenSequence creates a two-phase bounce: scale up then back down,
    // giving the heart icon a satisfying "pop" on tap.
    _heartScale = TweenSequence<double>([
      TweenSequenceItem(tween: Tween(begin: 1.0, end: 1.45), weight: 50),
      TweenSequenceItem(tween: Tween(begin: 1.45, end: 1.0), weight: 50),
    ]).animate(CurvedAnimation(
        parent: _heartController, curve: Curves.easeInOut));
  }

  @override
  void dispose() {
    _heartController.dispose();
    super.dispose();
  }

  void _onLike() {
    _heartController.forward(from: 0);
    widget.onLikeTap();
  }

  // Uses Firestore aggregation (count) instead of fetching all documents —
  // avoids downloading comment payloads just to display a badge number.
  Future<int> _commentCount() async {
    final snap = await FirebaseFirestore.instance
        .collection('MyPost')
        .doc(widget.docId)
        .collection('comments')
        .count()
        .get();
    return snap.count ?? 0;
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
      decoration: BoxDecoration(
        color: isDark ? AppColors.cardDark : AppColors.cardLight,
        borderRadius: BorderRadius.circular(20),
        boxShadow: AppColors.cardShadow,
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Header: avatar + username ────────────────────────────
          Padding(
            padding: const EdgeInsets.fromLTRB(14, 12, 14, 10),
            child: Row(children: [
              GestureDetector(
                onTap: widget.profilePic.isNotEmpty
                    ? widget.onAvatarTap
                    : null,
                child: Hero(
                  tag: widget.avatarHeroTag,
                  child: Container(
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: AppColors.gradientStart.withValues(alpha: 0.4),
                        width: 2,
                      ),
                    ),
                    child: CircleAvatar(
                      radius: 22,
                      backgroundColor: AppColors.bgLight,
                      backgroundImage: widget.profilePic.isNotEmpty
                          ? NetworkImage(widget.profilePic)
                          : null,
                      child: widget.profilePic.isEmpty
                          ? const Icon(Icons.person,
                              color: AppColors.textSecondary)
                          : null,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Text(
                widget.username,
                style: GoogleFonts.poppins(
                  fontWeight: FontWeight.w600,
                  fontSize: 14,
                  color: isDark ? Colors.white : AppColors.textPrimary,
                ),
              ),
            ]),
          ),

          // ── Post image ──────────────────────────────────────────
          if (widget.postPic.isNotEmpty)
            GestureDetector(
              onTap: widget.onImageTap,
              child: Hero(
                tag: widget.postHeroTag,
                child: Image.network(
                  widget.postPic,
                  width: double.infinity,
                  height: 300,
                  fit: BoxFit.cover,
                  errorBuilder: (_, __, ___) => Container(
                    height: 300,
                    color: AppColors.bgLight,
                    child: const Icon(Icons.broken_image,
                        size: 60, color: AppColors.textHint),
                  ),
                ),
              ),
            ),

          // ── Caption ─────────────────────────────────────────────
          if (widget.caption.isNotEmpty)
            Padding(
              padding: const EdgeInsets.fromLTRB(14, 10, 14, 4),
              child: Text(
                widget.caption,
                style: GoogleFonts.poppins(
                  fontSize: 13,
                  color: isDark ? Colors.white70 : AppColors.textPrimary,
                ),
              ),
            ),

          // ── Actions: like + comments ─────────────────────────────
          Padding(
            padding: const EdgeInsets.fromLTRB(6, 4, 14, 10),
            child: Row(children: [
              ScaleTransition(
                scale: _heartScale,
                child: IconButton(
                  icon: Icon(
                    widget.isLiked
                        ? Icons.favorite
                        : Icons.favorite_border,
                    color: widget.isLiked
                        ? AppColors.accent
                        : AppColors.textSecondary,
                    size: 24,
                  ),
                  onPressed: _onLike,
                ),
              ),
              Text(
                '${widget.likes.length}',
                style: GoogleFonts.poppins(
                  color: AppColors.textSecondary,
                  fontWeight: FontWeight.w500,
                  fontSize: 13,
                ),
              ),
              const SizedBox(width: 16),
              FutureBuilder<int>(
                future: _commentCount(),
                builder: (context, snap) {
                  final count = snap.data ?? 0;
                  return TextButton.icon(
                    style: TextButton.styleFrom(
                      foregroundColor: AppColors.textSecondary,
                      padding: EdgeInsets.zero,
                    ),
                    icon: const Icon(Icons.chat_bubble_outline, size: 20),
                    label: Text('$count',
                        style: GoogleFonts.poppins(fontSize: 13)),
                    onPressed: () => Navigator.push(
                      context,
                      SlidePageRoute(
                        page: CommentsScreen(
                          postId: widget.docId,
                          myId: widget.myId,
                          myUsername: widget.myUsername,
                          myProfilePic: widget.myProfilePic,
                        ),
                      ),
                    ),
                  );
                },
              ),
            ]),
          ),
        ],
      ),
    );
  }
}

// ── Full-screen image viewer ──────────────────────────────────────────────────

class _FullImageScreen extends StatelessWidget {
  final String imageUrl;
  final String heroTag;

  const _FullImageScreen(
      {required this.imageUrl, required this.heroTag});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(backgroundColor: Colors.black, foregroundColor: Colors.white),
      body: Center(
        child: Hero(
          tag: heroTag,
          child: Image.network(
            imageUrl,
            fit: BoxFit.contain,
            errorBuilder: (_, __, ___) =>
                const Icon(Icons.broken_image, color: Colors.white, size: 80),
          ),
        ),
      ),
    );
  }
}
