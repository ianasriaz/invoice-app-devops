import 'package:flutter/material.dart';

class AppColors {
  // Premium Palette (Indigo + Teal accents)
  static const Color primary = Color(0xFF4F46E5); // Indigo 600
  static const Color primaryLight = Color(0xFF6366F1); // Indigo 500/700 mix
  static const Color secondary = Color(0xFF14B8A6); // Teal 500

  // Dark Theme Neutrals
  static const Color darkBackground = Color(0xFF0B1220); // Deep ink
  static const Color darkSurface = Color(0xFF111827); // Gray 900
  static const Color darkCard = Color(0xFF1F2937); // Gray 800
  static const Color darkBorder = Color(0xFF334155); // Slate 700

  // Light Theme Neutrals
  static const Color lightBackground = Color(0xFFF8FAFC); // Slate 50
  static const Color lightSurface = Color(0xFFFFFFFF);
  static const Color lightCard = Color(0xFFFFFFFF);
  static const Color lightBorder = Color(0xFFE2E8F0); // Slate 200

  // Text colors
  static const Color darkText = Color(0xFFF8FAFC); // Lightest for dark
  static const Color lightText = Color(0xFF0F172A); // Slate 900
  static const Color darkTextSecondary = Color(0xFFCBD5E1); // Slate 300
  static const Color lightTextSecondary = Color(0xFF475569); // Slate 600

  // Status colors
  static const Color statusDraft = Color(0xFF94A3B8); // Slate 400
  static const Color statusSent = primary;
  static const Color statusPaid = Color(0xFF22C55E); // Green 500
  static const Color statusOverdue = Color(0xFFEF4444); // Red 500
  static const Color statusCancelled = Color(0xFFF59E0B); // Amber 500

  // Neutral colors
  static const Color white = Colors.white;
  static const Color black = Colors.black;
  static const Color grey = Color(0xFF64748B); // Slate 500
  static const Color lightGrey = Color(0xFFE2E8F0); // Slate 200
  static const Color divider = Color(0xFF334155); // Slate 700

  // Semantic colors
  static const Color success = Color(0xFF22C55E);
  static const Color error = Color(0xFFEF4444);
  static const Color warning = Color(0xFFF59E0B);
}
