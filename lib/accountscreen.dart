import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:my_project1/Custom_Widget/app_colors.dart';
import 'package:my_project1/Custom_Widget/app_routes.dart';
import 'package:my_project1/MyPostScreen.dart';
import 'package:my_project1/loginscreen.dart';
import 'package:my_project1/main.dart';
import 'package:my_project1/myfriends.dart';
import 'package:my_project1/profilescreen.dart';
import 'package:shared_preferences/shared_preferences.dart';

// ignore: must_be_immutable
class AccountScreen extends StatefulWidget {
  User? user;
  AccountScreen({super.key, required this.user});

  @override
  State<AccountScreen> createState() => _AccountScreenState();
}

class _AccountScreenState extends State<AccountScreen> {
  bool _isDark = themeModeNotifier.value == ThemeMode.dark;

  Future<void> _toggleDarkMode(bool value) async {
    setState(() => _isDark = value);
    themeModeNotifier.value = value ? ThemeMode.dark : ThemeMode.light;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('dark_mode', value);
  }

  Future<void> _confirmLogout() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20)),
        title: const Text('Log Out'),
        content: const Text('Are you sure you want to log out?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.error,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10)),
            ),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Log Out',
                style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
    if (confirmed != true) return;
    await FirebaseAuth.instance.signOut();
    if (!mounted) return;
    Navigator.pushReplacement(
        context, FadePageRoute(page: const MYLoginScreen()));
  }

  Widget _tile({
    required IconData icon,
    required String title,
    String? subtitle,
    required VoidCallback onTap,
    Widget? trailing,
  }) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 5),
      decoration: BoxDecoration(
        color: Theme.of(context).brightness == Brightness.dark
            ? AppColors.elevatedDark
            : Colors.white,
        borderRadius: BorderRadius.circular(14),
        boxShadow: AppColors.cardShadow,
      ),
      child: ListTile(
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 2),
        leading: Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            gradient: AppColors.primaryGradient,
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(icon, color: Colors.white, size: 20),
        ),
        title: Text(title,
            style: GoogleFonts.poppins(
                fontWeight: FontWeight.w500, fontSize: 14)),
        subtitle: subtitle != null
            ? Text(subtitle,
                style: GoogleFonts.poppins(
                    fontSize: 12, color: AppColors.textSecondary))
            : null,
        trailing: trailing ??
            const Icon(Icons.chevron_right,
                color: AppColors.textSecondary),
        onTap: onTap,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: ListView(
        padding: const EdgeInsets.only(top: 80, bottom: 24),
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 0, 20, 16),
            child: Text(
              'Settings',
              style: GoogleFonts.poppins(
                fontSize: 22,
                fontWeight: FontWeight.w700,
                color: AppColors.textPrimary,
              ),
            ),
          ),

          Padding(
            padding: const EdgeInsets.fromLTRB(20, 0, 20, 8),
            child: Text('Account',
                style: GoogleFonts.poppins(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textSecondary,
                    letterSpacing: 0.8)),
          ),

          _tile(
            icon: Icons.person_outlined,
            title: 'Profile',
            subtitle: 'Edit your name & photo',
            onTap: () => Navigator.push(
              context,
              SlidePageRoute(page: MyProfileScreen(user: widget.user)),
            ),
          ),
          _tile(
            icon: Icons.photo_library_outlined,
            title: 'My Posts',
            subtitle: 'View and manage your posts',
            onTap: () => Navigator.push(
              context,
              SlidePageRoute(page: MyAllPostScreen(user: widget.user)),
            ),
          ),
          _tile(
            icon: Icons.people_outlined,
            title: 'Friends',
            subtitle: 'Manage friend requests',
            onTap: () => Navigator.push(
              context,
              SlidePageRoute(page: MyFRIENDS(user: widget.user)),
            ),
          ),

          const SizedBox(height: 16),
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 0, 20, 8),
            child: Text('Preferences',
                style: GoogleFonts.poppins(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textSecondary,
                    letterSpacing: 0.8)),
          ),

          // Dark mode tile
          Container(
            margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 5),
            decoration: BoxDecoration(
              color: Theme.of(context).brightness == Brightness.dark
                  ? AppColors.elevatedDark
                  : Colors.white,
              borderRadius: BorderRadius.circular(14),
              boxShadow: AppColors.cardShadow,
            ),
            child: ListTile(
              contentPadding:
                  const EdgeInsets.symmetric(horizontal: 16, vertical: 2),
              leading: Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  gradient: AppColors.primaryGradient,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(
                  _isDark ? Icons.dark_mode : Icons.light_mode,
                  color: Colors.white,
                  size: 20,
                ),
              ),
              title: Text('Dark Mode',
                  style: GoogleFonts.poppins(
                      fontWeight: FontWeight.w500, fontSize: 14)),
              trailing: Switch(
                value: _isDark,
                activeThumbColor: AppColors.gradientEnd,
                onChanged: _toggleDarkMode,
              ),
            ),
          ),

          _tile(
            icon: Icons.notifications_outlined,
            title: 'Notifications',
            onTap: () {},
          ),
          _tile(
            icon: Icons.help_outline,
            title: 'Help & Support',
            onTap: () {},
          ),
          _tile(
            icon: Icons.person_add_outlined,
            title: 'Invite a Friend',
            onTap: () {},
          ),

          const SizedBox(height: 16),

          // Logout
          Container(
            margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 5),
            decoration: BoxDecoration(
              color: AppColors.error.withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(14),
            ),
            child: ListTile(
              contentPadding:
                  const EdgeInsets.symmetric(horizontal: 16, vertical: 2),
              leading: Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: AppColors.error,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(Icons.logout,
                    color: Colors.white, size: 20),
              ),
              title: Text('Log Out',
                  style: GoogleFonts.poppins(
                    fontWeight: FontWeight.w600,
                    fontSize: 14,
                    color: AppColors.error,
                  )),
              onTap: _confirmLogout,
            ),
          ),
        ],
      ),
    );
  }
}
