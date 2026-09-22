import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../api/api_client.dart';
import '../auth/auth_state.dart';
import '../theme/app_theme.dart';
import '../widgets/common.dart';

class QuizScreen extends StatefulWidget {
  const QuizScreen({super.key, required this.quizId});
  final String quizId;

  @override
  State<QuizScreen> createState() => _QuizScreenState();
}

class _QuizScreenState extends State<QuizScreen> {
  Map<String, dynamic>? _quiz;
  final Map<String, dynamic> _answers = {};
  bool _loading = true;
  bool _submitting = false;
  String? _error;
  Map<String, dynamic>? _result;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      _quiz = await context.read<AuthState>().api.seniorQuiz(widget.quizId);
    } on ApiException catch (e) {
      _error = e.message;
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _submit() async {
    final questions =
        List<Map<String, dynamic>>.from(_quiz?['questions'] as List? ?? []);
    if (questions.any((q) => !_answers.containsKey(q['id'].toString()))) {
      showAppToast(context, 'Please answer all questions');
      return;
    }
    setState(() => _submitting = true);
    try {
      final payload = _answers.entries
          .map((e) => {'questionId': e.key, 'value': e.value})
          .toList();
      _result = await context
          .read<AuthState>()
          .api
          .submitSeniorQuiz(widget.quizId, payload);
      setState(() {});
    } on ApiException catch (e) {
      showAppToast(context, e.message);
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final questions =
        List<Map<String, dynamic>>.from(_quiz?['questions'] as List? ?? []);

    return Scaffold(
      appBar: AppBar(title: Text(_quiz?['title']?.toString() ?? 'Quiz')),
      body: _loading
          ? const LoadingBody()
          : _error != null
              ? ErrorBody(message: _error!, onRetry: _load)
              : _result != null
                  ? _resultView()
                  : ListView(
                      padding: const EdgeInsets.fromLTRB(20, 12, 20, 32),
                      children: [
                        for (final q in questions) ...[
                          AppCard(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  q['text']?.toString() ?? '',
                                  style: const TextStyle(
                                    fontWeight: FontWeight.w700,
                                    fontSize: 16,
                                    color: AppColors.brand900,
                                  ),
                                ),
                                const SizedBox(height: 12),
                                ..._buildInputs(q),
                              ],
                            ),
                          ),
                          const SizedBox(height: 12),
                        ],
                        PrimaryButton(
                          label: 'Submit answers',
                          loading: _submitting,
                          onPressed: _submit,
                        ),
                      ],
                    ),
    );
  }

  List<Widget> _buildInputs(Map<String, dynamic> q) {
    final id = q['id'].toString();
    final type = q['type']?.toString() ?? 'single';
    if (type == 'boolean') {
      return [
        RadioListTile<bool>(
          title: const Text('Yes'),
          value: true,
          groupValue: _answers[id] as bool?,
          onChanged: (v) => setState(() => _answers[id] = v),
        ),
        RadioListTile<bool>(
          title: const Text('No'),
          value: false,
          groupValue: _answers[id] as bool?,
          onChanged: (v) => setState(() => _answers[id] = v),
        ),
      ];
    }
    final options =
        List<Map<String, dynamic>>.from(q['options'] as List? ?? []);
    return [
      for (final o in options)
        RadioListTile<String>(
          title: Text(o['label']?.toString() ?? o['value']?.toString() ?? ''),
          value: o['value'].toString(),
          groupValue: _answers[id]?.toString(),
          onChanged: (v) => setState(() => _answers[id] = v),
        ),
    ];
  }

  Widget _resultView() {
    final pct = _result?['scorePct'] ?? 0;
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: AppCard(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.emoji_events,
                  size: 48, color: AppColors.brand600),
              const SizedBox(height: 12),
              Text(
                'You scored $pct%',
                style: const TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.w800,
                  color: AppColors.brand900,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                '${_result?['correct'] ?? 0} of ${_result?['total'] ?? 0} correct',
                style: const TextStyle(color: AppColors.slate600),
              ),
              const SizedBox(height: 20),
              PrimaryButton(
                label: 'Back',
                onPressed: () => Navigator.of(context).maybePop(),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
