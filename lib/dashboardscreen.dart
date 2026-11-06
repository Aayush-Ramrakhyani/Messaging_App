// Vibe — Social & Messaging App
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:curved_navigation_bar/curved_navigation_bar.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:my_project1/Custom_Widget/app_colors.dart';
import 'package:my_project1/Custom_Widget/app_routes.dart';
import 'package:my_project1/MessageScreen.dart';
import 'package:my_project1/accountscreen.dart';
import 'package:my_project1/addfriends.dart';
import 'package:my_project1/homescreen.dart';
import 'package:my_project1/postscreen.dart';

// ignore: must_be_immutable
/// Main shell of the app.
/// Hosts four pages in a PageView (Home, AddFriends, Post, Account) and
/// uses WidgetsBindingObserver to keep the user's isOnline flag accurate
/// whenever the app moves to background / foreground.
class Dashboard extends StatefulWidget {
  final User? user;
  const Dashboard({super.key, required this.user});

  @override
  State<Dashboard> createState() => _DashboardState();
}

class _DashboardState extends State<Dashboard> with WidgetsBindingObserver {
  final PageController _pageController = PageController();
  int _currentIndex = 0;
  String? username;

  static const _navIcons = [
    Icons.home_outlined,
    Icons.group_outlined,
    Icons.add_a_photo_outlined,
    Icons.person_outlined,
  ];
  static const _navIconsFilled = [
    Icons.home,
    Icons.group,
    Icons.add_a_photo,
    Icons.person,
  ];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _loadUsername();
    _setOnline(true);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _setOnline(false);
    _pageController.dispose();
    super.dispose();
  }

  // Tracks app foreground/background transitions to keep isOnline accurate
  // without requiring explicit logout — WidgetsBindingObserver fires these.
  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      _setOnline(true);
    } else if (state == AppLifecycleState.paused ||
        state == AppLifecycleState.detached) {
      _setOnline(false);
    }
  }

  Future<void> _setOnline(bool isOnline) async {
    if (widget.user == null) return;
    try {
      await FirebaseFirestore.instance
          .collection('Users')
          .doc(widget.user!.uid)
          .update({
        'isOnline': isOnline,
        'lastSeen': FieldValue.serverTimestamp(),
      });
    } catch (_) {}
  }

  Future<void> _loadUsername() async {
    try {
      final doc = await FirebaseFirestore.instance
          .collection('Users')
          .doc(widget.user!.uid)
          .get();
      if (!mounted) return;
      setState(() => username = doc.data()?['name'] as String? ?? '');
    } catch (_) {}
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: PreferredSize(
        preferredSize: const Size.fromHeight(kToolbarHeight + 10),
        child: Container(
          decoration: const BoxDecoration(
            gradient: AppColors.primaryGradient,
            boxShadow: [
              BoxShadow(
                color: Color(0x284A90D9),
                blurRadius: 12,
                offset: Offset(0, 4),
              )
            ],
          ),
          child: SafeArea(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8),
              child: Row(
                children: [
                  const SizedBox(width: 8),
                  const Icon(Icons.waves_rounded,
                      color: Colors.white, size: 26),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Text(
                          'Vibe',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 18,
                            fontWeight: FontWeight.w700,
                            letterSpacing: 0.5,
                          ),
                        ),
                        if (username != null)
                          Text(
                            'Hi, $username 👋',
                            style: const TextStyle(
                              color: Colors.white70,
                              fontSize: 12,
                            ),
                          ),
                      ],
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.message_outlined,
                        color: Colors.white),
                    onPressed: () => Navigator.push(
                      context,
                      SlidePageRoute(
                          page: MessgaeScreenPage(user: widget.user)),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
      body: PageView(
        controller: _pageController,
        physics: const NeverScrollableScrollPhysics(),
        children: [
          const MyHomeScreen(),
          MyAddFriends(user: widget.user),
          MyPostScreen(user: widget.user),
          AccountScreen(user: widget.user),
        ],
      ),
      bottomNavigationBar: CurvedNavigationBar(
        index: _currentIndex,
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
        buttonBackgroundColor: AppColors.gradientEnd,
        color: Colors.white,
        height: 60,
        animationDuration: const Duration(milliseconds: 320),
        animationCurve: Curves.easeOutCubic,
        items: List.generate(4, (i) {
          final isActive = _currentIndex == i;
          return Icon(
            isActive ? _navIconsFilled[i] : _navIcons[i],
            size: 28,
            color: isActive ? Colors.white : AppColors.gradientEnd,
          );
        }),
        onTap: (index) {
          setState(() => _currentIndex = index);
          _pageController.animateToPage(
            index,
            duration: const Duration(milliseconds: 350),
            curve: Curves.easeOutCubic,
          );
        },
      ),
    );
  }
}
