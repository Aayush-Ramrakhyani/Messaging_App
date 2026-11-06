// Vibe — Social & Messaging App
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:my_project1/Custom_Widget/app_routes.dart';
import 'package:my_project1/dashboardscreen.dart';
import 'package:my_project1/loginscreen.dart';

/// Animated launch screen shown for ~2.8 s before navigating.
/// If a Firebase user session exists → Dashboard; otherwise → LoginScreen.
class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scale;
  late Animation<double> _fade;
  late Animation<double> _taglineFade;
  late Animation<Offset> _taglineSlide;

  @override
  void initState() {
    super.initState();

    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2000),
    );

    // Intervals stagger the animations within a single 2 s controller:
    // logo fades + bounces in (0–65 %), tagline slides up after it settles (55–100 %).
    _scale = Tween<double>(begin: 0.3, end: 1.0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.0, 0.65, curve: Curves.elasticOut),
      ),
    );

    _fade = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.0, 0.4, curve: Curves.easeIn),
      ),
    );

    _taglineFade = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.55, 1.0, curve: Curves.easeIn),
      ),
    );

    _taglineSlide =
        Tween<Offset>(begin: const Offset(0, 0.5), end: Offset.zero).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.55, 1.0, curve: Curves.easeOutCubic),
      ),
    );

    _controller.forward();
    Future.delayed(const Duration(milliseconds: 2800), _navigate);
  }

  void _navigate() {
    if (!mounted) return;
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      Navigator.pushReplacement(
          context, FadePageRoute(page: Dashboard(user: user)));
    } else {
      Navigator.pushReplacement(
          context, FadePageRoute(page: const MYLoginScreen()));
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Color(0xFF1A2980),
              Color(0xFF4A90D9),
              Color(0xFF7B2FBE),
            ],
          ),
        ),
        child: AnimatedBuilder(
          animation: _controller,
          builder: (_, __) => Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Logo + app name — scales up with elastic bounce
              FadeTransition(
                opacity: _fade,
                child: ScaleTransition(
                  scale: _scale,
                  child: Column(
                    children: [
                      Container(
                        width: 110,
                        height: 110,
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.15),
                          shape: BoxShape.circle,
                          border: Border.all(
                              color: Colors.white30, width: 2),
                        ),
                        child: const Icon(
                          Icons.waves_rounded,
                          size: 64,
                          color: Colors.white,
                        ),
                      ),
                      const SizedBox(height: 20),
                      Text(
                        'Vibe',
                        style: GoogleFonts.poppins(
                          fontSize: 56,
                          fontWeight: FontWeight.w700,
                          color: Colors.white,
                          letterSpacing: 6,
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 12),

              // Tagline slides up after logo settles
              SlideTransition(
                position: _taglineSlide,
                child: FadeTransition(
                  opacity: _taglineFade,
                  child: Text(
                    'Connect  ·  Share  ·  Vibe',
                    style: GoogleFonts.poppins(
                      fontSize: 15,
                      color: Colors.white60,
                      letterSpacing: 2.5,
                      fontWeight: FontWeight.w400,
                    ),
                  ),
                ),
              ),

              const SizedBox(height: 80),

              // Pulsing dots appear after tagline
              FadeTransition(
                opacity: _taglineFade,
                child: const _PulseDots(),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Three dots that pulse sequentially to show loading activity.
class _PulseDots extends StatefulWidget {
  const _PulseDots();

  @override
  State<_PulseDots> createState() => _PulseDotsState();
}

class _PulseDotsState extends State<_PulseDots>
    with SingleTickerProviderStateMixin {
  late AnimationController _dotController;

  @override
  void initState() {
    super.initState();
    _dotController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    )..repeat();
  }

  @override
  void dispose() {
    _dotController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _dotController,
      builder: (_, __) => Row(
        mainAxisSize: MainAxisSize.min,
        children: List.generate(3, (i) {
          final progress =
              ((_dotController.value - i * 0.25) % 1.0).clamp(0.0, 1.0);
          final scale = 1.0 +
              0.5 *
                  (progress < 0.5 ? progress * 2 : (1.0 - progress) * 2);
          return Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4),
            child: Transform.scale(
              scale: scale,
              child: Container(
                width: 8,
                height: 8,
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.7),
                  shape: BoxShape.circle,
                ),
              ),
            ),
          );
        }),
      ),
    );
  }
}
