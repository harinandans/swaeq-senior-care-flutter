/// Data-driven configuration for timed in-video quizzes.
///
/// Each [VideoQuizConfig] defines a quiz that triggers at a specific timestamp
/// during video playback. The quiz pauses the video, shows a multiple-choice
/// question, provides feedback, then resumes playback.
///
/// To add a new quiz, create a [VideoQuizConfig] and add it to
/// [VideoQuizRegistry.quizzes]. Match videos by their stable content ID, slot
/// ID, or stream URL substring (in order of preference).
library;

class VideoQuizOption {
  const VideoQuizOption({
    required this.id,
    required this.text,
    this.isCorrect = false,
  });

  /// Unique identifier for this option within its question.
  final String id;

  /// Display text for the option (senior-friendly, clear language).
  final String text;

  /// Whether this is the correct answer.
  final bool isCorrect;

  Map<String, dynamic> toJson() => {
        'id': id,
        'text': text,
        'isCorrect': isCorrect,
      };

  factory VideoQuizOption.fromJson(Map<String, dynamic> json) {
    return VideoQuizOption(
      id: json['id'] as String,
      text: json['text'] as String,
      isCorrect: json['isCorrect'] as bool? ?? false,
    );
  }
}

class VideoQuizConfig {
  const VideoQuizConfig({
    required this.id,
    required this.videoMatcher,
    required this.triggerTimestamp,
    required this.question,
    required this.options,
    required this.explanation,
    this.feedbackDelayMs = 2500,
    this.showContinueButton = true,
  });

  /// Unique identifier for this quiz configuration.
  final String id;

  /// Matcher to identify which video this quiz belongs to.
  /// Can match by content ID, slot ID, or URL substring.
  final VideoMatcher videoMatcher;

  /// Timestamp in seconds when the quiz should trigger.
  final int triggerTimestamp;

  /// The question text to display.
  final String question;

  /// Available answer options (3-4 recommended for seniors).
  final List<VideoQuizOption> options;

  /// Explanation shown after answering (regardless of correct/incorrect).
  final String explanation;

  /// Delay in milliseconds before auto-resuming (if no Continue button).
  final int feedbackDelayMs;

  /// Whether to show an explicit Continue button instead of auto-resuming.
  final bool showContinueButton;

  VideoQuizOption? get correctOption =>
      options.where((o) => o.isCorrect).firstOrNull;

  Map<String, dynamic> toJson() => {
        'id': id,
        'videoMatcher': videoMatcher.toJson(),
        'triggerTimestamp': triggerTimestamp,
        'question': question,
        'options': options.map((o) => o.toJson()).toList(),
        'explanation': explanation,
        'feedbackDelayMs': feedbackDelayMs,
        'showContinueButton': showContinueButton,
      };

  factory VideoQuizConfig.fromJson(Map<String, dynamic> json) {
    return VideoQuizConfig(
      id: json['id'] as String,
      videoMatcher:
          VideoMatcher.fromJson(json['videoMatcher'] as Map<String, dynamic>),
      triggerTimestamp: json['triggerTimestamp'] as int,
      question: json['question'] as String,
      options: (json['options'] as List)
          .map((o) => VideoQuizOption.fromJson(o as Map<String, dynamic>))
          .toList(),
      explanation: json['explanation'] as String,
      feedbackDelayMs: json['feedbackDelayMs'] as int? ?? 2500,
      showContinueButton: json['showContinueButton'] as bool? ?? true,
    );
  }
}

/// Identifies which video a quiz should appear on.
class VideoMatcher {
  const VideoMatcher({
    this.contentId,
    this.slotId,
    this.urlContains,
  }) : assert(
          contentId != null || slotId != null || urlContains != null,
          'At least one matcher must be provided',
        );

  /// Match by senior content ID (e.g., 'scn-pranayama').
  final String? contentId;

  /// Match by timeline slot ID (e.g., 'pranayama').
  final String? slotId;

  /// Match by URL substring (fallback for direct stream URLs).
  final String? urlContains;

  bool matches({
    String? contentId,
    String? slotId,
    String? streamUrl,
  }) {
    final matchContentId = this.contentId;
    final matchSlotId = this.slotId;
    final matchUrl = urlContains;

    if (matchContentId != null && contentId == matchContentId) return true;
    if (matchSlotId != null && slotId == matchSlotId) return true;
    if (matchUrl != null && streamUrl != null && streamUrl.contains(matchUrl)) {
      return true;
    }
    return false;
  }

  Map<String, dynamic> toJson() => {
        if (contentId != null) 'contentId': contentId,
        if (slotId != null) 'slotId': slotId,
        if (urlContains != null) 'urlContains': urlContains,
      };

  factory VideoMatcher.fromJson(Map<String, dynamic> json) {
    return VideoMatcher(
      contentId: json['contentId'] as String?,
      slotId: json['slotId'] as String?,
      urlContains: json['urlContains'] as String?,
    );
  }
}

/// Registry of all configured video quizzes.
///
/// Add new quizzes here. The player will check this registry and trigger
/// quizzes at the appropriate timestamps.
class VideoQuizRegistry {
  VideoQuizRegistry._();

  /// All configured video quizzes.
  ///
  /// To add a new quiz:
  /// 1. Create a [VideoQuizConfig] with a unique ID
  /// 2. Set [videoMatcher] to identify the target video
  /// 3. Choose an appropriate [triggerTimestamp] based on video content
  /// 4. Write a clear, senior-friendly question and options
  /// 5. Add a helpful explanation
  static const List<VideoQuizConfig> quizzes = [
    _pranayamaQuiz,
  ];

  /// Find a quiz configuration for a given video.
  static VideoQuizConfig? findQuiz({
    String? contentId,
    String? slotId,
    String? streamUrl,
  }) {
    for (final quiz in quizzes) {
      if (quiz.videoMatcher.matches(
        contentId: contentId,
        slotId: slotId,
        streamUrl: streamUrl,
      )) {
        return quiz;
      }
    }
    return null;
  }

  /// Pranayama (Breathing Exercise) Quiz
  ///
  /// Video: 6_Breathe_9_16_English_s_9x16 (approx 60-90 seconds)
  /// Triggers at 15 seconds - after the intro explains what pranayama is
  /// but before the main breathing demonstration.
  static const _pranayamaQuiz = VideoQuizConfig(
    id: 'pranayama-breathing-q1',
    videoMatcher: VideoMatcher(
      contentId: 'scn-pranayama',
      slotId: 'pranayama',
      urlContains: 'Breathe_9_16',
    ),
    triggerTimestamp: 15,
    question: 'What is the main benefit of deep breathing exercises?',
    options: [
      VideoQuizOption(
        id: 'a',
        text: 'Builds muscle strength',
        isCorrect: false,
      ),
      VideoQuizOption(
        id: 'b',
        text: 'Reduces stress and calms the mind',
        isCorrect: true,
      ),
      VideoQuizOption(
        id: 'c',
        text: 'Improves eyesight',
        isCorrect: false,
      ),
      VideoQuizOption(
        id: 'd',
        text: 'Makes you feel hungry',
        isCorrect: false,
      ),
    ],
    explanation: 'Deep breathing activates your body\'s relaxation response. '
        'It lowers heart rate and blood pressure, helping you feel calm and '
        'focused. Practice this daily for better stress management!',
    showContinueButton: true,
  );
}
