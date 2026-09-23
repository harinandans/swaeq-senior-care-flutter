import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../models/video_quiz_config.dart';
import '../services/lazy_tts_service.dart';
import '../theme/app_theme.dart';

/// State of the quiz interaction.
enum QuizState {
  /// Quiz is showing, waiting for user to select an answer or skip.
  awaiting,

  /// User selected an answer, showing feedback.
  answered,
}

/// Callback when the quiz is dismissed (answered or skipped).
typedef QuizDismissedCallback = void Function({
  required bool skipped,
  String? selectedOptionId,
  bool? wasCorrect,
});

/// Full-screen overlay that displays an in-video quiz.
///
/// Designed for seniors with:
/// - Large touch targets (minimum 56dp)
/// - High contrast text
/// - Clear visual feedback
/// - Accessible semantics
/// - Skip option always available
/// - Text-to-speech for question and options (if TTS available)
class VideoQuizOverlay extends StatefulWidget {
  const VideoQuizOverlay({
    super.key,
    required this.config,
    required this.onDismissed,
  });

  final VideoQuizConfig config;
  final QuizDismissedCallback onDismissed;

  @override
  State<VideoQuizOverlay> createState() => _VideoQuizOverlayState();
}

class _VideoQuizOverlayState extends State<VideoQuizOverlay>
    with SingleTickerProviderStateMixin {
  QuizState _state = QuizState.awaiting;
  String? _selectedOptionId;
  late AnimationController _feedbackController;
  late Animation<double> _feedbackAnimation;

  bool _ttsSpeaking = false;
  bool get _ttsAvailable => LazyTtsService.instance.isAvailable;

  @override
  void initState() {
    super.initState();
    _feedbackController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
    _feedbackAnimation = CurvedAnimation(
      parent: _feedbackController,
      curve: Curves.easeOut,
    );
    _setupTts();
  }

  void _setupTts() {
    if (!_ttsAvailable) return;
    
    LazyTtsService.instance.setCallbacks(
      onStart: () {
        if (mounted) setState(() => _ttsSpeaking = true);
      },
      onDone: () {
        if (mounted) setState(() => _ttsSpeaking = false);
      },
      onError: (msg) {
        debugPrint('TTS error: $msg');
        if (mounted) setState(() => _ttsSpeaking = false);
      },
    );
    
    _speakQuizContent();
  }

  Future<void> _speakQuizContent() async {
    if (!_ttsAvailable) return;

    final buffer = StringBuffer();
    buffer.writeln('Quiz question:');
    buffer.writeln(widget.config.question);
    buffer.writeln('Options:');

    for (final option in widget.config.options) {
      buffer.writeln('${option.id.toUpperCase()}: ${option.text}');
    }

    await LazyTtsService.instance.speak(buffer.toString());
  }

  Future<void> _stopTts() async {
    await LazyTtsService.instance.stop();
    if (mounted) setState(() => _ttsSpeaking = false);
  }

  @override
  void dispose() {
    _stopTts();
    LazyTtsService.instance.clearCallbacks();
    _feedbackController.dispose();
    super.dispose();
  }

  void _selectOption(String optionId) {
    if (_state != QuizState.awaiting) return;

    _stopTts();

    setState(() {
      _selectedOptionId = optionId;
      _state = QuizState.answered;
    });
    _feedbackController.forward();
  }

  void _skip() {
    _stopTts();
    widget.onDismissed(
      skipped: true,
      selectedOptionId: null,
      wasCorrect: null,
    );
  }

  void _continue() {
    _stopTts();
    final selected = widget.config.options
        .where((o) => o.id == _selectedOptionId)
        .firstOrNull;
    widget.onDismissed(
      skipped: false,
      selectedOptionId: _selectedOptionId,
      wasCorrect: selected?.isCorrect,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: 'Video quiz overlay',
      explicitChildNodes: true,
      child: Material(
        color: Colors.black.withOpacity(0.92),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              children: [
                _buildHeader(),
                const SizedBox(height: 16),
                Expanded(
                  child: SingleChildScrollView(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        _buildQuestion(),
                        const SizedBox(height: 24),
                        ..._buildOptions(),
                        if (_state == QuizState.answered) ...[
                          const SizedBox(height: 24),
                          _buildFeedback(),
                        ],
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                _buildActions(),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
          decoration: BoxDecoration(
            color: AppColors.brand600,
            borderRadius: BorderRadius.circular(20),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(
                Icons.quiz_outlined,
                color: Colors.white,
                size: 22,
              ),
              const SizedBox(width: 8),
              Text(
                'Quick Quiz',
                style: GoogleFonts.dmSans(
                  fontSize: 17,
                  fontWeight: FontWeight.w700,
                  color: Colors.white,
                ),
              ),
            ],
          ),
        ),
        const Spacer(),
        // Read aloud button (only if TTS is available)
        if (_ttsAvailable && _state == QuizState.awaiting)
          Semantics(
            button: true,
            label: _ttsSpeaking ? 'Stop reading' : 'Read question aloud',
            child: IconButton(
              onPressed: _ttsSpeaking ? _stopTts : _speakQuizContent,
              icon: Icon(
                _ttsSpeaking ? Icons.stop_rounded : Icons.volume_up_rounded,
                color: Colors.white70,
                size: 26,
              ),
              style: IconButton.styleFrom(
                minimumSize: const Size(56, 56),
              ),
              tooltip: _ttsSpeaking ? 'Stop' : 'Read aloud',
            ),
          ),
        Semantics(
          button: true,
          label: 'Skip quiz and continue video',
          child: TextButton.icon(
            onPressed: _skip,
            icon: const Icon(
              Icons.skip_next_rounded,
              color: Colors.white70,
              size: 24,
            ),
            label: Text(
              'Skip',
              style: GoogleFonts.dmSans(
                fontSize: 17,
                fontWeight: FontWeight.w600,
                color: Colors.white70,
              ),
            ),
            style: TextButton.styleFrom(
              minimumSize: const Size(80, 56),
              padding: const EdgeInsets.symmetric(horizontal: 16),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildQuestion() {
    return Semantics(
      header: true,
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.08),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: Colors.white.withOpacity(0.15),
          ),
        ),
        child: Text(
          widget.config.question,
          style: GoogleFonts.dmSans(
            fontSize: 22,
            fontWeight: FontWeight.w700,
            color: Colors.white,
            height: 1.35,
          ),
          textAlign: TextAlign.center,
        ),
      ),
    );
  }

  List<Widget> _buildOptions() {
    return widget.config.options.map((option) {
      final isSelected = _selectedOptionId == option.id;
      final showResult = _state == QuizState.answered;
      final isCorrect = option.isCorrect;

      Color backgroundColor;
      Color borderColor;
      Color textColor;
      IconData? trailingIcon;

      if (showResult) {
        if (isCorrect) {
          backgroundColor = const Color(0xFF166534).withOpacity(0.9);
          borderColor = const Color(0xFF22C55E);
          textColor = Colors.white;
          trailingIcon = Icons.check_circle_rounded;
        } else if (isSelected && !isCorrect) {
          backgroundColor = const Color(0xFF991B1B).withOpacity(0.9);
          borderColor = const Color(0xFFEF4444);
          textColor = Colors.white;
          trailingIcon = Icons.cancel_rounded;
        } else {
          backgroundColor = Colors.white.withOpacity(0.05);
          borderColor = Colors.white.withOpacity(0.15);
          textColor = Colors.white.withOpacity(0.5);
          trailingIcon = null;
        }
      } else {
        backgroundColor = isSelected
            ? AppColors.brand600.withOpacity(0.25)
            : Colors.white.withOpacity(0.08);
        borderColor =
            isSelected ? AppColors.brand500 : Colors.white.withOpacity(0.2);
        textColor = Colors.white;
        trailingIcon = null;
      }

      return Padding(
        padding: const EdgeInsets.only(bottom: 12),
        child: Semantics(
          button: !showResult,
          selected: isSelected,
          label:
              '${option.text}${showResult && isCorrect ? ', correct answer' : ''}${showResult && isSelected && !isCorrect ? ', incorrect' : ''}',
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: showResult ? null : () => _selectOption(option.id),
              borderRadius: BorderRadius.circular(16),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                padding: const EdgeInsets.symmetric(
                  horizontal: 20,
                  vertical: 18,
                ),
                decoration: BoxDecoration(
                  color: backgroundColor,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: borderColor, width: 2),
                ),
                child: Row(
                  children: [
                    Container(
                      width: 36,
                      height: 36,
                      decoration: BoxDecoration(
                        color: textColor.withOpacity(0.15),
                        shape: BoxShape.circle,
                      ),
                      alignment: Alignment.center,
                      child: Text(
                        option.id.toUpperCase(),
                        style: GoogleFonts.dmSans(
                          fontSize: 18,
                          fontWeight: FontWeight.w800,
                          color: textColor,
                        ),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Text(
                        option.text,
                        style: GoogleFonts.dmSans(
                          fontSize: 19,
                          fontWeight: FontWeight.w600,
                          color: textColor,
                          height: 1.3,
                        ),
                      ),
                    ),
                    if (trailingIcon != null) ...[
                      const SizedBox(width: 12),
                      Icon(
                        trailingIcon,
                        color: textColor,
                        size: 28,
                      ),
                    ],
                  ],
                ),
              ),
            ),
          ),
        ),
      );
    }).toList();
  }

  Widget _buildFeedback() {
    final selected = widget.config.options
        .where((o) => o.id == _selectedOptionId)
        .firstOrNull;
    final isCorrect = selected?.isCorrect ?? false;

    return FadeTransition(
      opacity: _feedbackAnimation,
      child: SlideTransition(
        position: Tween<Offset>(
          begin: const Offset(0, 0.1),
          end: Offset.zero,
        ).animate(_feedbackAnimation),
        child: Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: isCorrect
                ? const Color(0xFF166534).withOpacity(0.3)
                : const Color(0xFF1E3A8A).withOpacity(0.3),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: isCorrect
                  ? const Color(0xFF22C55E).withOpacity(0.5)
                  : const Color(0xFF3B82F6).withOpacity(0.5),
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(
                    isCorrect
                        ? Icons.celebration_rounded
                        : Icons.lightbulb_outline_rounded,
                    color: isCorrect
                        ? const Color(0xFF4ADE80)
                        : const Color(0xFF60A5FA),
                    size: 28,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      isCorrect ? 'Correct!' : 'Good try!',
                      style: GoogleFonts.dmSans(
                        fontSize: 20,
                        fontWeight: FontWeight.w800,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Text(
                widget.config.explanation,
                style: GoogleFonts.dmSans(
                  fontSize: 17,
                  fontWeight: FontWeight.w500,
                  color: Colors.white.withOpacity(0.9),
                  height: 1.45,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildActions() {
    if (_state == QuizState.awaiting) {
      return const SizedBox.shrink();
    }

    return Semantics(
      button: true,
      label: 'Continue watching video',
      child: SizedBox(
        width: double.infinity,
        height: 60,
        child: FilledButton.icon(
          onPressed: _continue,
          icon: const Icon(Icons.play_arrow_rounded, size: 28),
          label: Text(
            'Continue Video',
            style: GoogleFonts.dmSans(
              fontSize: 19,
              fontWeight: FontWeight.w700,
            ),
          ),
          style: FilledButton.styleFrom(
            backgroundColor: AppColors.brand600,
            foregroundColor: Colors.white,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
          ),
        ),
      ),
    );
  }
}
