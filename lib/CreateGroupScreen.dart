// Vibe — Social & Messaging App
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:my_project1/Custom_Widget/app_colors.dart';
import 'package:my_project1/Custom_Widget/mycustombutton.dart';
import 'package:my_project1/Custom_Widget/textfield.dart';

/// Screen for creating a new group chat.
/// Loads the current user's accepted friends from both directions of the
/// Friends collection, lets the user pick members, then writes one group
/// document and returns to the caller on success.
class CreateGroupScreen extends StatefulWidget {
  final String myId;
  final String myName;

  const CreateGroupScreen({
    super.key,
    required this.myId,
    required this.myName,
  });

  @override
  State<CreateGroupScreen> createState() => _CreateGroupScreenState();
}

class _CreateGroupScreenState extends State<CreateGroupScreen> {
  final _nameController = TextEditingController();
  final _firestore = FirebaseFirestore.instance;

  List<Map<String, dynamic>> _friends = [];
  final Set<String> _selectedIds = {};
  bool _loading = true;
  bool _creating = false;

  @override
  void initState() {
    super.initState();
    _loadFriends();
  }

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  // Queries Friends in both directions so accepted friends always appear
  // regardless of who originally sent the request.
  Future<void> _loadFriends() async {
    try {
      final results = await Future.wait([
        _firestore
            .collection('Friends')
            .where('request_id', isEqualTo: widget.myId)
            .where('status', isEqualTo: 'accepted')
            .get(),
        _firestore
            .collection('Friends')
            .where('receiver_id', isEqualTo: widget.myId)
            .where('status', isEqualTo: 'accepted')
            .get(),
      ]);

      final friendIds = <String>{
        ...results[0].docs.map((d) => d['receiver_id'] as String),
        ...results[1].docs.map((d) => d['request_id'] as String),
      };

      final userDocs = await Future.wait(
        friendIds.map((id) => _firestore.collection('Users').doc(id).get()),
      );

      if (!mounted) return;
      setState(() {
        _friends = userDocs
            .where((d) => d.exists)
            .map((d) => d.data()!)
            .toList();
        _loading = false;
      });
    } catch (_) {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _createGroup() async {
    final name = _nameController.text.trim();
    if (name.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            behavior: SnackBarBehavior.floating,
            content: Text('Enter a group name')),
      );
      return;
    }
    if (_selectedIds.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            behavior: SnackBarBehavior.floating,
            content: Text('Select at least one member')),
      );
      return;
    }

    setState(() => _creating = true);
    try {
      await _firestore.collection('groups').add({
        'name': name,
        'createdBy': widget.myId,
        'members': [widget.myId, ..._selectedIds],
        'lastMessage': '${widget.myName} created the group',
        'lastMessageTime': FieldValue.serverTimestamp(),
        'lastSenderName': widget.myName,
        'createdAt': FieldValue.serverTimestamp(),
      });
      if (!mounted) return;
      Navigator.pop(context);
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
              behavior: SnackBarBehavior.floating,
              content: Text('Failed to create group')),
        );
        setState(() => _creating = false);
      }
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
                        Text('New Group',
                            style: GoogleFonts.poppins(
                                fontSize: 18,
                                fontWeight: FontWeight.w700,
                                color: Colors.white)),
                        Text('Select members to add',
                            style: GoogleFonts.poppins(
                                fontSize: 12,
                                color:
                                    Colors.white.withValues(alpha: 0.75))),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),

          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
            child: AppTextField(
              controller: _nameController,
              hintText: 'Group name',
              prefixIcon: Icons.group_outlined,
            ),
          ),

          if (_loading)
            const Expanded(child: Center(child: CircularProgressIndicator()))
          else if (_friends.isEmpty)
            Expanded(
              child: Center(
                child: Text('No friends to add',
                    style: GoogleFonts.poppins(
                        color: AppColors.textSecondary)),
              ),
            )
          else
            Expanded(
              child: ListView.builder(
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                itemCount: _friends.length,
                itemBuilder: (context, index) {
                  final f = _friends[index];
                  final uid = f['uid'] as String? ?? '';
                  final name = f['name'] as String? ?? '';
                  final pic = f['profilepic'] as String? ?? '';
                  final selected = _selectedIds.contains(uid);

                  return GestureDetector(
                    onTap: () => setState(() {
                      selected
                          ? _selectedIds.remove(uid)
                          : _selectedIds.add(uid);
                    }),
                    child: Container(
                      margin: const EdgeInsets.only(bottom: 8),
                      decoration: BoxDecoration(
                        color: selected
                            ? AppColors.gradientStart.withValues(alpha: 0.08)
                            : (isDark ? AppColors.cardDark : Colors.white),
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(
                          color: selected
                              ? AppColors.gradientStart
                              : Colors.transparent,
                          width: 1.5,
                        ),
                        boxShadow: AppColors.cardShadow,
                      ),
                      child: ListTile(
                        contentPadding:
                            const EdgeInsets.fromLTRB(12, 4, 12, 4),
                        leading: CircleAvatar(
                          radius: 22,
                          backgroundImage:
                              pic.isNotEmpty ? NetworkImage(pic) : null,
                          child: pic.isEmpty
                              ? Text(name.isNotEmpty
                                  ? name[0].toUpperCase()
                                  : '?')
                              : null,
                        ),
                        title: Text(name,
                            style: GoogleFonts.poppins(
                                fontWeight: FontWeight.w600, fontSize: 14)),
                        trailing: selected
                            ? Container(
                                width: 28,
                                height: 28,
                                decoration: const BoxDecoration(
                                  gradient: AppColors.primaryGradient,
                                  shape: BoxShape.circle,
                                ),
                                child: const Icon(Icons.check,
                                    color: Colors.white, size: 16),
                              )
                            : Container(
                                width: 28,
                                height: 28,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  border: Border.all(
                                      color: AppColors.textHint, width: 1.5),
                                ),
                              ),
                      ),
                    ),
                  );
                },
              ),
            ),

          Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
            child: GradientButton(
              text: _selectedIds.isEmpty
                  ? 'Create Group'
                  : 'Create Group (${_selectedIds.length + 1} members)',
              onPressed: _creating ? null : _createGroup,
              isLoading: _creating,
            ),
          ),
        ],
      ),
    );
  }
}
