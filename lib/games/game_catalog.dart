import 'package:flutter/material.dart';

class GameEntry {
  const GameEntry({
    required this.id,
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.color,
  });

  final String id;
  final String title;
  final String subtitle;
  final IconData icon;
  final Color color;
}

/// First-party MIT senior-friendly games (original implementations).
class GameCatalog {
  GameCatalog._();

  static const entries = <GameEntry>[
    GameEntry(
      id: 'tube-sort',
      title: 'Colour Tube Sort',
      subtitle: 'Sort coloured balls into tubes',
      icon: Icons.science_outlined,
      color: Color(0xFF6366F1),
    ),
    GameEntry(
      id: 'memory-match',
      title: 'Memory Match',
      subtitle: 'Find matching flower pairs',
      icon: Icons.grid_view_rounded,
      color: Color(0xFFEC4899),
    ),
    GameEntry(
      id: 'color-path',
      title: 'Colour Path',
      subtitle: 'Connect matching dots',
      icon: Icons.timeline,
      color: Color(0xFF14B8A6),
    ),
    GameEntry(
      id: 'pattern-repeat',
      title: 'Pattern Repeat',
      subtitle: 'Repeat the light sequence',
      icon: Icons.lightbulb_outline,
      color: Color(0xFFF59E0B),
    ),
    GameEntry(
      id: 'number-order',
      title: 'Number Order',
      subtitle: 'Tap numbers 1 to 9',
      icon: Icons.pin_outlined,
      color: Color(0xFF3B82F6),
    ),
    GameEntry(
      id: 'spot-difference',
      title: 'Spot the Difference',
      subtitle: 'Find what changed',
      icon: Icons.compare,
      color: Color(0xFF8B5CF6),
    ),
    GameEntry(
      id: 'jigsaw-lite',
      title: 'Jigsaw Lite',
      subtitle: '4-piece picture puzzle',
      icon: Icons.extension_outlined,
      color: Color(0xFF0EA5E9),
    ),
    GameEntry(
      id: 'word-search',
      title: 'Word Search',
      subtitle: 'Find calm words',
      icon: Icons.text_fields,
      color: Color(0xFF10B981),
    ),
    GameEntry(
      id: 'sudoku-easy',
      title: 'Sudoku Easy',
      subtitle: '4×4 gentle grid',
      icon: Icons.apps,
      color: Color(0xFF64748B),
    ),
    GameEntry(
      id: 'mahjong-lite',
      title: 'Mahjong Lite',
      subtitle: 'Match tile pairs',
      icon: Icons.layers_outlined,
      color: Color(0xFF059669),
    ),
    GameEntry(
      id: 'bubble-pop',
      title: 'Bubble Pop',
      subtitle: 'Pop groups of colours',
      icon: Icons.bubble_chart_outlined,
      color: Color(0xFFE11D48),
    ),
    GameEntry(
      id: 'sliding-puzzle',
      title: 'Sliding Puzzle',
      subtitle: '3×3 slide tiles',
      icon: Icons.view_module_outlined,
      color: Color(0xFF7C3AED),
    ),
    GameEntry(
      id: 'tangram',
      title: 'Shape Fit',
      subtitle: 'Drag shapes into place',
      icon: Icons.crop_square,
      color: Color(0xFF2563EB),
    ),
    GameEntry(
      id: 'calm-coloring',
      title: 'Calm Coloring',
      subtitle: 'Tap to fill regions',
      icon: Icons.palette_outlined,
      color: Color(0xFFDB2777),
    ),
    GameEntry(
      id: 'breathing-dots',
      title: 'Focus Dots',
      subtitle: 'Gentle paced taps',
      icon: Icons.spa_outlined,
      color: Color(0xFF0891B2),
    ),
  ];

  static GameEntry? byId(String id) {
    for (final e in entries) {
      if (e.id == id) return e;
    }
    return null;
  }
}
