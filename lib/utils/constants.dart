import 'package:flutter/material.dart';

// Colors
class AppColors {
  static const primary = Color(0xFFA855F7);
  static const secondary = Color(0xFFEC4899);
  static const background = Color(0xFFF8FAFC);
  static const backgroundDark = Color(0xFFE2E8F0);
  static const textPrimary = Color(0xFF0F172A);
  static const textSecondary = Color(0xFF64748B);
  static const textTertiary = Color(0xFF94A3B8);
  static const border = Color(0xFFCBD5E1);
  static const borderLight = Color(0xFFE2E8F0);
  static const purpleLight = Color(0xFFF5F3FF);
  static const purpleLighter = Color(0xFFE9D5FF);
}

// Scenes data
class AppScenes {
  static const List<Map<String, String>> all = [
    {
      'id': 'beach',
      'label': 'Beach',
      'emoji': '🏖️',
      'description': 'Tropical paradise vibes',
      'prompt': 'Place this person at a beautiful tropical beach at sunset with palm trees, golden sand, and turquoise water. Professional travel photography style.',
    },
    {
      'id': 'city',
      'label': 'City',
      'emoji': '🌃',
      'description': 'Urban nightlife scene',
      'prompt': 'Place this person in a modern city at night with illuminated skyscrapers and bright lights. Urban lifestyle photography.',
    },
    {
      'id': 'mountain',
      'label': 'Mountain',
      'emoji': '⛰️',
      'description': 'Epic adventure peaks',
      'prompt': 'Place this person at a mountain peak during sunrise with stunning vistas and dramatic clouds. Epic adventure photography.',
    },
    {
      'id': 'cafe',
      'label': 'Cafe',
      'emoji': '☕',
      'description': 'Cozy aesthetic spot',
      'prompt': 'Place this person in a cozy aesthetic cafe with warm lighting and modern decor. Lifestyle blogger photography.',
    },
  ];
}