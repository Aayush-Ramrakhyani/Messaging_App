// Vibe — Social & Messaging App
import 'package:flutter/material.dart';

/// Central colour palette for the Vibe app.
/// All screens import this file — never hard-code hex values elsewhere.
/// Primary gradient: sky-blue (#4A90D9) → deep violet (#7B2FBE).
/// Accent: coral (#FF6B6B) used for likes and destructive actions.
class AppColors {
  // ── Primary gradient ────────────────────────────────────────────────────
  static const Color gradientStart = Color(0xFF4A90D9); // Sky blue
  static const Color gradientEnd   = Color(0xFF7B2FBE); // Deep violet

  // ── Accent ──────────────────────────────────────────────────────────────
  static const Color accent = Color(0xFFFF6B6B); // Coral

  // ── Backgrounds ─────────────────────────────────────────────────────────
  static const Color bgLight    = Color(0xFFF5F7FF);
  static const Color bgDark     = Color(0xFF0A0F1E);
  static const Color cardLight  = Color(0xFFFFFFFF);
  static const Color cardDark   = Color(0xFF0F1A2E);
  static const Color elevatedDark = Color(0xFF162032);

  // ── Text ────────────────────────────────────────────────────────────────
  static const Color textPrimary   = Color(0xFF1E1B4B);
  static const Color textSecondary = Color(0xFF6B7280);
  static const Color textHint      = Color(0xFFA0AEC0);
  static const Color textOnGradient = Color(0xFFFFFFFF);

  // ── Border / Divider ────────────────────────────────────────────────────
  static const Color border   = Color(0xFFE2E8F0);
  static const Color divider  = Color(0xFFEDF2F7);

  // ── Status ──────────────────────────────────────────────────────────────
  static const Color success = Color(0xFF48BB78);
  static const Color error   = Color(0xFFFC8181);
  static const Color online  = Color(0xFF48BB78);

  // ── Chat bubbles ─────────────────────────────────────────────────────────
  static const Color sentBubbleStart = Color(0xFF4A90D9);
  static const Color sentBubbleEnd   = Color(0xFF7B2FBE);
  static const Color receivedBubble  = Color(0xFFF0F0F5);

  // ── Gradients ────────────────────────────────────────────────────────────
  static const LinearGradient primaryGradient = LinearGradient(
    colors: [gradientStart, gradientEnd],
    begin: Alignment.centerLeft,
    end: Alignment.centerRight,
  );

  static const LinearGradient primaryGradientVertical = LinearGradient(
    colors: [gradientStart, gradientEnd],
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
  );

  static const LinearGradient sentBubbleGradient = LinearGradient(
    colors: [sentBubbleStart, sentBubbleEnd],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient headerGradient = LinearGradient(
    colors: [Color(0xFF1A2980), Color(0xFF26D0CE)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  // ── Shadows ──────────────────────────────────────────────────────────────
  static List<BoxShadow> get cardShadow => [
    BoxShadow(
      color: const Color(0xFF4A90D9).withValues(alpha: 0.12),
      blurRadius: 20,
      offset: const Offset(0, 6),
    ),
  ];

  static List<BoxShadow> get buttonShadow => [
    BoxShadow(
      color: const Color(0xFF7B2FBE).withValues(alpha: 0.35),
      blurRadius: 18,
      offset: const Offset(0, 8),
    ),
  ];
}
