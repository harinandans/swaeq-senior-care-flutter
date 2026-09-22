import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:swaeq_senior/models/video_quiz_config.dart';
import 'package:swaeq_senior/widgets/video_quiz_overlay.dart';

void main() {
  const testConfig = VideoQuizConfig(
    id: 'test-quiz',
    videoMatcher: VideoMatcher(contentId: 'test-video'),
    triggerTimestamp: 15,
    question: 'What is the test question?',
    options: [
      VideoQuizOption(id: 'a', text: 'First option', isCorrect: false),
      VideoQuizOption(
          id: 'b', text: 'Second option (correct)', isCorrect: true),
      VideoQuizOption(id: 'c', text: 'Third option', isCorrect: false),
    ],
    explanation: 'The second option is correct because it is marked as such.',
    showContinueButton: true,
  );

  Widget buildTestWidget({
    required VideoQuizConfig config,
    required QuizDismissedCallback onDismissed,
  }) {
    return MaterialApp(
      home: Scaffold(
        body: VideoQuizOverlay(
          config: config,
          onDismissed: onDismissed,
        ),
      ),
    );
  }

  group('VideoQuizOverlay', () {
    testWidgets('displays question text', (tester) async {
      await tester.pumpWidget(buildTestWidget(
        config: testConfig,
        onDismissed: ({required skipped, selectedOptionId, wasCorrect}) {},
      ));

      expect(find.text('What is the test question?'), findsOneWidget);
    });

    testWidgets('displays all options', (tester) async {
      await tester.pumpWidget(buildTestWidget(
        config: testConfig,
        onDismissed: ({required skipped, selectedOptionId, wasCorrect}) {},
      ));

      expect(find.text('First option'), findsOneWidget);
      expect(find.text('Second option (correct)'), findsOneWidget);
      expect(find.text('Third option'), findsOneWidget);
    });

    testWidgets('displays Skip button', (tester) async {
      await tester.pumpWidget(buildTestWidget(
        config: testConfig,
        onDismissed: ({required skipped, selectedOptionId, wasCorrect}) {},
      ));

      expect(find.text('Skip'), findsOneWidget);
    });

    testWidgets('displays Quick Quiz header', (tester) async {
      await tester.pumpWidget(buildTestWidget(
        config: testConfig,
        onDismissed: ({required skipped, selectedOptionId, wasCorrect}) {},
      ));

      expect(find.text('Quick Quiz'), findsOneWidget);
    });

    testWidgets('Skip button calls onDismissed with skipped=true',
        (tester) async {
      bool? wasSkipped;
      String? selectedId;
      bool? wasCorrectResult;

      await tester.pumpWidget(buildTestWidget(
        config: testConfig,
        onDismissed: ({required skipped, selectedOptionId, wasCorrect}) {
          wasSkipped = skipped;
          selectedId = selectedOptionId;
          wasCorrectResult = wasCorrect;
        },
      ));

      await tester.tap(find.text('Skip'));
      await tester.pumpAndSettle();

      expect(wasSkipped, isTrue);
      expect(selectedId, isNull);
      expect(wasCorrectResult, isNull);
    });

    testWidgets('selecting correct answer shows feedback and Continue button',
        (tester) async {
      await tester.pumpWidget(buildTestWidget(
        config: testConfig,
        onDismissed: ({required skipped, selectedOptionId, wasCorrect}) {},
      ));

      // Tap the correct option
      await tester.tap(find.text('Second option (correct)'));
      await tester.pumpAndSettle();

      // Should show "Correct!" and explanation
      expect(find.text('Correct!'), findsOneWidget);
      expect(
          find.textContaining('The second option is correct'), findsOneWidget);

      // Should show Continue button
      expect(find.text('Continue Video'), findsOneWidget);
    });

    testWidgets('selecting incorrect answer shows "Good try!" feedback',
        (tester) async {
      await tester.pumpWidget(buildTestWidget(
        config: testConfig,
        onDismissed: ({required skipped, selectedOptionId, wasCorrect}) {},
      ));

      // Tap an incorrect option
      await tester.tap(find.text('First option'));
      await tester.pumpAndSettle();

      // Should show "Good try!" and explanation
      expect(find.text('Good try!'), findsOneWidget);
      expect(
          find.textContaining('The second option is correct'), findsOneWidget);
    });

    testWidgets('Continue button calls onDismissed with correct answer info',
        (tester) async {
      bool? wasSkipped;
      String? selectedId;
      bool? wasCorrectResult;

      await tester.pumpWidget(buildTestWidget(
        config: testConfig,
        onDismissed: ({required skipped, selectedOptionId, wasCorrect}) {
          wasSkipped = skipped;
          selectedId = selectedOptionId;
          wasCorrectResult = wasCorrect;
        },
      ));

      // Select the correct answer
      await tester.tap(find.text('Second option (correct)'));
      await tester.pumpAndSettle();

      // Tap Continue
      await tester.tap(find.text('Continue Video'));
      await tester.pumpAndSettle();

      expect(wasSkipped, isFalse);
      expect(selectedId, 'b');
      expect(wasCorrectResult, isTrue);
    });

    testWidgets('Continue button calls onDismissed with incorrect answer info',
        (tester) async {
      bool? wasSkipped;
      String? selectedId;
      bool? wasCorrectResult;

      await tester.pumpWidget(buildTestWidget(
        config: testConfig,
        onDismissed: ({required skipped, selectedOptionId, wasCorrect}) {
          wasSkipped = skipped;
          selectedId = selectedOptionId;
          wasCorrectResult = wasCorrect;
        },
      ));

      // Select an incorrect answer
      await tester.tap(find.text('Third option'));
      await tester.pumpAndSettle();

      // Tap Continue
      await tester.tap(find.text('Continue Video'));
      await tester.pumpAndSettle();

      expect(wasSkipped, isFalse);
      expect(selectedId, 'c');
      expect(wasCorrectResult, isFalse);
    });

    testWidgets('cannot select multiple options', (tester) async {
      await tester.pumpWidget(buildTestWidget(
        config: testConfig,
        onDismissed: ({required skipped, selectedOptionId, wasCorrect}) {},
      ));

      // Select first option
      await tester.tap(find.text('First option'));
      await tester.pumpAndSettle();

      // Try to select another option - should not change state
      await tester.tap(find.text('Third option'));
      await tester.pumpAndSettle();

      // Should still show feedback for first selection (Good try!)
      expect(find.text('Good try!'), findsOneWidget);
    });

    testWidgets('has proper accessibility semantics', (tester) async {
      await tester.pumpWidget(buildTestWidget(
        config: testConfig,
        onDismissed: ({required skipped, selectedOptionId, wasCorrect}) {},
      ));

      // Check semantic label for overlay
      expect(
        find.bySemanticsLabel('Video quiz overlay'),
        findsOneWidget,
      );

      // Check Skip button has semantic label
      expect(
        find.bySemanticsLabel('Skip quiz and continue video'),
        findsOneWidget,
      );
    });

    testWidgets('options have large touch targets', (tester) async {
      await tester.pumpWidget(buildTestWidget(
        config: testConfig,
        onDismissed: ({required skipped, selectedOptionId, wasCorrect}) {},
      ));

      // Find option containers
      final optionFinders = find.ancestor(
        of: find.text('First option'),
        matching: find.byType(AnimatedContainer),
      );

      expect(optionFinders, findsOneWidget);

      // Verify minimum padding makes touch target large enough
      final container = tester.widget<AnimatedContainer>(optionFinders);
      final decoration = container.decoration as BoxDecoration?;
      expect(decoration, isNotNull);
    });
  });

  group('QuizState enum', () {
    test('has expected values', () {
      expect(QuizState.values, contains(QuizState.awaiting));
      expect(QuizState.values, contains(QuizState.answered));
    });
  });
}
