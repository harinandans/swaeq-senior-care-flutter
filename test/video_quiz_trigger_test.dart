import 'package:flutter_test/flutter_test.dart';
import 'package:swaeq_senior/models/video_quiz_config.dart';

void main() {
  group('Quiz Trigger Logic', () {
    test('quiz triggers at correct timestamp', () {
      const config = VideoQuizConfig(
        id: 'test',
        videoMatcher: VideoMatcher(contentId: 'test'),
        triggerTimestamp: 15,
        question: 'Test?',
        options: [
          VideoQuizOption(id: 'a', text: 'A', isCorrect: true),
        ],
        explanation: 'Test',
      );

      bool shouldTrigger(
          int positionSec, bool alreadyTriggered, bool isPlaying) {
        if (alreadyTriggered || !isPlaying) return false;
        final triggerSec = config.triggerTimestamp;
        return positionSec >= triggerSec && positionSec < triggerSec + 2;
      }

      // Before trigger time - should not trigger
      expect(shouldTrigger(10, false, true), isFalse);
      expect(shouldTrigger(14, false, true), isFalse);

      // At trigger time - should trigger
      expect(shouldTrigger(15, false, true), isTrue);
      expect(shouldTrigger(16, false, true), isTrue);

      // Just past trigger window - should not trigger
      expect(shouldTrigger(17, false, true), isFalse);

      // Already triggered - should not trigger again
      expect(shouldTrigger(15, true, true), isFalse);

      // Not playing - should not trigger
      expect(shouldTrigger(15, false, false), isFalse);
    });

    test('quiz trigger resets when seeking to start', () {
      bool quizTriggered = true;

      void onSeek(double positionMs) {
        if (positionMs < 2000 && quizTriggered) {
          quizTriggered = false;
        }
      }

      // Seeking to middle - should not reset
      onSeek(10000);
      expect(quizTriggered, isTrue);

      // Seeking near start - should reset
      onSeek(1000);
      expect(quizTriggered, isFalse);
    });

    test('quiz only triggers once per session', () {
      bool quizTriggered = false;
      int triggerCount = 0;

      void checkTrigger(int positionSec) {
        if (quizTriggered) return;
        if (positionSec >= 15 && positionSec < 17) {
          quizTriggered = true;
          triggerCount++;
        }
      }

      // First pass through trigger zone
      checkTrigger(15);
      expect(triggerCount, 1);

      // Second pass through trigger zone (e.g., after seeking back)
      checkTrigger(15);
      expect(triggerCount, 1); // Should not increment
      checkTrigger(16);
      expect(triggerCount, 1); // Should not increment
    });

    test('quiz can trigger again after reset', () {
      bool quizTriggered = false;
      int triggerCount = 0;

      void checkTrigger(int positionSec) {
        if (quizTriggered) return;
        if (positionSec >= 15 && positionSec < 17) {
          quizTriggered = true;
          triggerCount++;
        }
      }

      void resetOnSeekToStart(double positionMs) {
        if (positionMs < 2000) {
          quizTriggered = false;
        }
      }

      // First trigger
      checkTrigger(15);
      expect(triggerCount, 1);

      // Reset by seeking to start
      resetOnSeekToStart(0);
      expect(quizTriggered, isFalse);

      // Second trigger after reset
      checkTrigger(15);
      expect(triggerCount, 2);
    });
  });

  group('Quiz Resume Behavior', () {
    test('video should resume after quiz dismissed', () {
      bool isPlaying = true;
      bool showQuizOverlay = false;

      void triggerQuiz() {
        isPlaying = false; // Simulates video.pause()
        showQuizOverlay = true;
      }

      void dismissQuiz() {
        showQuizOverlay = false;
        isPlaying = true; // Simulates video.play()
      }

      // Initial state
      expect(isPlaying, isTrue);
      expect(showQuizOverlay, isFalse);

      // Trigger quiz
      triggerQuiz();
      expect(isPlaying, isFalse);
      expect(showQuizOverlay, isTrue);

      // Dismiss quiz (answer or skip)
      dismissQuiz();
      expect(isPlaying, isTrue);
      expect(showQuizOverlay, isFalse);
    });

    test('quiz dismissal works for both answer and skip', () {
      var dismissedWithSkip = false;
      var dismissedWithAnswer = false;
      String? selectedOption;

      void onDismissed({required bool skipped, String? selectedOptionId}) {
        if (skipped) {
          dismissedWithSkip = true;
        } else {
          dismissedWithAnswer = true;
          selectedOption = selectedOptionId;
        }
      }

      // Test skip
      onDismissed(skipped: true, selectedOptionId: null);
      expect(dismissedWithSkip, isTrue);

      // Reset
      dismissedWithSkip = false;
      dismissedWithAnswer = false;
      selectedOption = null;

      // Test answer
      onDismissed(skipped: false, selectedOptionId: 'b');
      expect(dismissedWithAnswer, isTrue);
      expect(selectedOption, 'b');
    });
  });

  group('Quiz Prevention of Retrigger Loops', () {
    test('no retrigger when resuming at same position', () {
      bool quizTriggered = false;
      int triggerCount = 0;
      const triggerTimestamp = 15;

      void checkAndTrigger(int positionSec, bool isPlaying) {
        if (quizTriggered || !isPlaying) return;
        if (positionSec >= triggerTimestamp &&
            positionSec < triggerTimestamp + 2) {
          quizTriggered = true;
          triggerCount++;
        }
      }

      // First trigger at position 15
      checkAndTrigger(15, true);
      expect(triggerCount, 1);
      expect(quizTriggered, isTrue);

      // Simulate pause during quiz (isPlaying = false)
      checkAndTrigger(15, false);
      expect(triggerCount, 1); // No change

      // Resume at same position - should not retrigger
      checkAndTrigger(15, true);
      expect(triggerCount, 1); // No change - quizTriggered is still true

      // Continue playback
      checkAndTrigger(16, true);
      expect(triggerCount, 1); // No change

      checkAndTrigger(20, true);
      expect(triggerCount, 1); // No change
    });

    test('no retrigger when seeking past trigger point', () {
      bool quizTriggered = false;
      int triggerCount = 0;
      const triggerTimestamp = 15;

      void checkAndTrigger(int positionSec) {
        if (quizTriggered) return;
        if (positionSec >= triggerTimestamp &&
            positionSec < triggerTimestamp + 2) {
          quizTriggered = true;
          triggerCount++;
        }
      }

      // First trigger
      checkAndTrigger(15);
      expect(triggerCount, 1);

      // User seeks past trigger point
      checkAndTrigger(30);
      expect(triggerCount, 1); // Should not trigger again

      // User seeks back but not to start
      checkAndTrigger(15);
      expect(triggerCount, 1); // Should not trigger (quizTriggered is true)
    });

    test('2-second trigger window prevents frame-skip misses', () {
      bool quizTriggered = false;
      const triggerTimestamp = 15;

      bool shouldTrigger(int positionSec) {
        if (quizTriggered) return false;
        return positionSec >= triggerTimestamp &&
            positionSec < triggerTimestamp + 2;
      }

      // Position jumps from 14 to 16 (skipping exact 15)
      expect(shouldTrigger(14), isFalse);
      expect(shouldTrigger(16), isTrue); // Still triggers within window

      quizTriggered = true;

      // After triggered, even positions in window don't re-trigger
      expect(shouldTrigger(15), isFalse);
      expect(shouldTrigger(16), isFalse);
    });
  });
}
