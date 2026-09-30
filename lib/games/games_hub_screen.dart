import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';

import '../theme/app_theme.dart';
import 'game_catalog.dart';

class GamesHubScreen extends StatelessWidget {
  const GamesHubScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF3F5FA),
      appBar: AppBar(
        title: const Text('Games'),
        centerTitle: false,
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
        children: [
          Text(
            'Brain & calm play',
            style: GoogleFonts.dmSans(
              fontSize: 22,
              fontWeight: FontWeight.w800,
              color: AppColors.brand900,
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'Short, gentle games — no timer pressure. Tap a card to play.',
            style: TextStyle(color: AppColors.slate600, fontSize: 16),
          ),
          const SizedBox(height: 20),
          for (final game in GameCatalog.entries) ...[
            _GameCard(
              game: game,
              onTap: () => context.push('/games/play/${game.id}'),
            ),
            const SizedBox(height: 12),
          ],
        ],
      ),
    );
  }
}

class _GameCard extends StatelessWidget {
  const _GameCard({required this.game, required this.onTap});
  final GameEntry game;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(20),
      elevation: 0,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(20),
        child: Container(
          constraints: const BoxConstraints(minHeight: 88),
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: AppColors.brand100, width: 2),
          ),
          child: Row(
            children: [
              Container(
                width: 56,
                height: 56,
                decoration: BoxDecoration(
                  color: game.color.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Icon(game.icon, color: game.color, size: 32),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      game.title,
                      style: GoogleFonts.dmSans(
                        fontSize: 19,
                        fontWeight: FontWeight.w800,
                        color: AppColors.brand900,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      game.subtitle,
                      style: const TextStyle(
                        fontSize: 15,
                        color: AppColors.slate600,
                      ),
                    ),
                  ],
                ),
              ),
              const Icon(Icons.play_circle_fill,
                  color: AppColors.brand600, size: 40),
            ],
          ),
        ),
      ),
    );
  }
}
