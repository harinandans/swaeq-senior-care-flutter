import 'package:flutter/material.dart';

import 'game_catalog.dart';
import 'impl/breathing_dots.dart';
import 'impl/bubble_pop.dart';
import 'impl/calm_coloring.dart';
import 'impl/color_path.dart';
import 'impl/jigsaw_lite.dart';
import 'impl/mahjong_lite.dart';
import 'impl/memory_match.dart';
import 'impl/number_order.dart';
import 'impl/pattern_repeat.dart';
import 'impl/sliding_puzzle.dart';
import 'impl/spot_difference.dart';
import 'impl/sudoku_easy.dart';
import 'impl/tangram.dart';
import 'impl/tube_sort.dart';
import 'impl/word_search.dart';

class GamePlayScreen extends StatelessWidget {
  const GamePlayScreen({super.key, required this.gameId});

  final String gameId;

  @override
  Widget build(BuildContext context) {
    switch (gameId) {
      case 'tube-sort':
        return const TubeSortGame();
      case 'memory-match':
        return const MemoryMatchGame();
      case 'color-path':
        return const ColorPathGame();
      case 'pattern-repeat':
        return const PatternRepeatGame();
      case 'number-order':
        return const NumberOrderGame();
      case 'spot-difference':
        return const SpotDifferenceGame();
      case 'jigsaw-lite':
        return const JigsawLiteGame();
      case 'word-search':
        return const WordSearchGame();
      case 'sudoku-easy':
        return const SudokuEasyGame();
      case 'mahjong-lite':
        return const MahjongLiteGame();
      case 'bubble-pop':
        return const BubblePopGame();
      case 'sliding-puzzle':
        return const SlidingPuzzleGame();
      case 'tangram':
        return const TangramGame();
      case 'calm-coloring':
        return const CalmColoringGame();
      case 'breathing-dots':
        return const BreathingDotsGame();
      default:
        final title = GameCatalog.byId(gameId)?.title ?? 'Game';
        return Scaffold(
          appBar: AppBar(title: Text(title)),
          body: Center(
            child: Text(
              'This game is not available yet.',
              style: Theme.of(context).textTheme.titleLarge,
              textAlign: TextAlign.center,
            ),
          ),
        );
    }
  }
}
