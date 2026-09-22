import 'package:flutter_test/flutter_test.dart';
import 'package:swaeq_senior/models/video_quiz_config.dart';

void main() {
  group('VideoMatcher', () {
    test('matches by contentId', () {
      const matcher = VideoMatcher(contentId: 'scn-pranayama');

      expect(
        matcher.matches(
            contentId: 'scn-pranayama', slotId: null, streamUrl: null),
        isTrue,
      );
      expect(
        matcher.matches(contentId: 'scn-yoga', slotId: null, streamUrl: null),
        isFalse,
      );
    });

    test('matches by slotId', () {
      const matcher = VideoMatcher(slotId: 'pranayama');

      expect(
        matcher.matches(contentId: null, slotId: 'pranayama', streamUrl: null),
        isTrue,
      );
      expect(
        matcher.matches(contentId: null, slotId: 'yoga', streamUrl: null),
        isFalse,
      );
    });

    test('matches by URL substring', () {
      const matcher = VideoMatcher(urlContains: 'Breathe_9_16');

      expect(
        matcher.matches(
          contentId: null,
          slotId: null,
          streamUrl: 'https://example.com/Breathe_9_16_English/index.m3u8',
        ),
        isTrue,
      );
      expect(
        matcher.matches(
          contentId: null,
          slotId: null,
          streamUrl: 'https://example.com/yoga_video/index.m3u8',
        ),
        isFalse,
      );
    });

    test('contentId takes priority over slotId and URL', () {
      const matcher = VideoMatcher(
        contentId: 'scn-pranayama',
        slotId: 'pranayama',
        urlContains: 'Breathe',
      );

      expect(
        matcher.matches(
          contentId: 'scn-pranayama',
          slotId: 'yoga',
          streamUrl: 'https://example.com/yoga/index.m3u8',
        ),
        isTrue,
      );
    });

    test('returns false when no criteria match', () {
      const matcher = VideoMatcher(contentId: 'scn-test');

      expect(
        matcher.matches(contentId: null, slotId: null, streamUrl: null),
        isFalse,
      );
    });
  });

  group('VideoQuizOption', () {
    test('serializes to JSON', () {
      const option = VideoQuizOption(
        id: 'a',
        text: 'Test option',
        isCorrect: true,
      );

      final json = option.toJson();
      expect(json['id'], 'a');
      expect(json['text'], 'Test option');
      expect(json['isCorrect'], true);
    });

    test('deserializes from JSON', () {
      final option = VideoQuizOption.fromJson({
        'id': 'b',
        'text': 'Another option',
        'isCorrect': false,
      });

      expect(option.id, 'b');
      expect(option.text, 'Another option');
      expect(option.isCorrect, false);
    });
  });

  group('VideoQuizConfig', () {
    const testConfig = VideoQuizConfig(
      id: 'test-quiz',
      videoMatcher: VideoMatcher(contentId: 'test-video'),
      triggerTimestamp: 15,
      question: 'What is the answer?',
      options: [
        VideoQuizOption(id: 'a', text: 'Option A', isCorrect: false),
        VideoQuizOption(id: 'b', text: 'Option B', isCorrect: true),
        VideoQuizOption(id: 'c', text: 'Option C', isCorrect: false),
      ],
      explanation: 'The correct answer is B because...',
    );

    test('correctOption returns the correct option', () {
      expect(testConfig.correctOption, isNotNull);
      expect(testConfig.correctOption!.id, 'b');
      expect(testConfig.correctOption!.isCorrect, true);
    });

    test('correctOption returns null when no option is correct', () {
      const configNoCorrect = VideoQuizConfig(
        id: 'no-correct',
        videoMatcher: VideoMatcher(contentId: 'test'),
        triggerTimestamp: 10,
        question: 'Test?',
        options: [
          VideoQuizOption(id: 'a', text: 'A', isCorrect: false),
          VideoQuizOption(id: 'b', text: 'B', isCorrect: false),
        ],
        explanation: 'None correct',
      );

      expect(configNoCorrect.correctOption, isNull);
    });

    test('serializes to JSON and back', () {
      final json = testConfig.toJson();
      final restored = VideoQuizConfig.fromJson(json);

      expect(restored.id, testConfig.id);
      expect(restored.triggerTimestamp, testConfig.triggerTimestamp);
      expect(restored.question, testConfig.question);
      expect(restored.explanation, testConfig.explanation);
      expect(restored.options.length, testConfig.options.length);
      expect(restored.correctOption!.id, 'b');
    });

    test('default feedbackDelayMs is 2500', () {
      expect(testConfig.feedbackDelayMs, 2500);
    });

    test('default showContinueButton is true', () {
      expect(testConfig.showContinueButton, true);
    });
  });

  group('VideoQuizRegistry', () {
    test('contains at least one quiz', () {
      expect(VideoQuizRegistry.quizzes, isNotEmpty);
    });

    test('findQuiz returns quiz for pranayama video by contentId', () {
      final quiz = VideoQuizRegistry.findQuiz(contentId: 'scn-pranayama');
      expect(quiz, isNotNull);
      expect(quiz!.id, 'pranayama-breathing-q1');
    });

    test('findQuiz returns quiz for pranayama video by slotId', () {
      final quiz = VideoQuizRegistry.findQuiz(slotId: 'pranayama');
      expect(quiz, isNotNull);
      expect(quiz!.id, 'pranayama-breathing-q1');
    });

    test('findQuiz returns quiz for pranayama video by URL', () {
      final quiz = VideoQuizRegistry.findQuiz(
        streamUrl: 'https://cdn.example.com/Breathe_9_16_video/index.m3u8',
      );
      expect(quiz, isNotNull);
      expect(quiz!.id, 'pranayama-breathing-q1');
    });

    test('findQuiz returns null for unknown video', () {
      final quiz = VideoQuizRegistry.findQuiz(contentId: 'unknown-video');
      expect(quiz, isNull);
    });

    test('pranayama quiz has valid configuration', () {
      final quiz = VideoQuizRegistry.findQuiz(contentId: 'scn-pranayama');
      expect(quiz, isNotNull);

      expect(quiz!.triggerTimestamp, greaterThan(0));
      expect(quiz.question, isNotEmpty);
      expect(quiz.options.length, greaterThanOrEqualTo(3));
      expect(quiz.options.length, lessThanOrEqualTo(4));
      expect(quiz.explanation, isNotEmpty);
      expect(quiz.correctOption, isNotNull);
    });
  });
}
