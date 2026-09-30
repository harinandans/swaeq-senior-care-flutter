import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// Non-blocking floating reaction chips during playback.
class VideoReactionBar extends StatelessWidget {
  const VideoReactionBar({
    super.key,
    required this.onReaction,
    this.counts = const {},
  });

  final void Function(String id) onReaction;
  final Map<String, int> counts;

  static const _reactions = <({String id, String emoji, String label})>[
    (id: 'namaskar', emoji: '🙏', label: 'Namaskar'),
    (id: 'heart', emoji: '❤️', label: 'Heart'),
    (id: 'clap', emoji: '👏', label: 'Clap'),
    (id: 'flower', emoji: '🌸', label: 'Flower'),
  ];

  @override
  Widget build(BuildContext context) {
    return Positioned(
      right: 8,
      bottom: 120,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          for (final r in _reactions)
            Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Material(
                color: Colors.black54,
                borderRadius: BorderRadius.circular(28),
                child: InkWell(
                  onTap: () {
                    HapticFeedback.lightImpact();
                    onReaction(r.id);
                  },
                  borderRadius: BorderRadius.circular(28),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 10,
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(r.emoji, style: const TextStyle(fontSize: 22)),
                        if ((counts[r.id] ?? 0) > 0) ...[
                          const SizedBox(width: 6),
                          Text(
                            '${counts[r.id]}',
                            style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
