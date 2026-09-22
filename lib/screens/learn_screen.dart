import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../api/api_client.dart';
import '../auth/auth_state.dart';
import '../theme/app_theme.dart';
import '../widgets/common.dart';

class LearnScreen extends StatefulWidget {
  const LearnScreen({super.key});

  @override
  State<LearnScreen> createState() => _LearnScreenState();
}

class _LearnScreenState extends State<LearnScreen> {
  Map<String, dynamic>? _home;
  List<Map<String, dynamic>> _games = [];
  bool _loading = true;
  String? _error;

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
      final api = context.read<AuthState>().api;
      _home = await api.seniorHome();
      try {
        final g = await api.seniorGames();
        _games = List<Map<String, dynamic>>.from(g['items'] as List? ?? []);
      } catch (_) {
        _games = [];
      }
    } on ApiException catch (e) {
      _error = e.message;
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final rails =
        List<Map<String, dynamic>>.from(_home?['rails'] as List? ?? []);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Learn'),
        actions: [
          TextButton(
            onPressed: () => context.push('/programs'),
            child: const Text('Programs'),
          ),
        ],
      ),
      body: _loading
          ? const LoadingBody()
          : _error != null
              ? ErrorBody(message: _error!, onRetry: _load)
              : RefreshIndicator(
                  onRefresh: _load,
                  child: ListView(
                    padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
                    children: [
                      if ((_home?['greeting'] ?? '').toString().isNotEmpty)
                        Padding(
                          padding: const EdgeInsets.only(bottom: 12),
                          child: Text(
                            '${_home!['greeting']}'
                            '${_home!['name'] != null ? ', ${_home!['name']}' : ''}',
                            style: const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.w800,
                              color: AppColors.brand900,
                            ),
                          ),
                        ),
                      if (rails.isEmpty && _games.isEmpty)
                        const Padding(
                          padding: EdgeInsets.all(24),
                          child: Text(
                            'Content will appear here after senior APIs are seeded.',
                            textAlign: TextAlign.center,
                            style: TextStyle(color: AppColors.slate500),
                          ),
                        ),
                      for (final rail in rails) ...[
                        Text(
                          rail['title']?.toString() ?? 'Content',
                          style: const TextStyle(
                            fontWeight: FontWeight.w800,
                            fontSize: 16,
                            color: AppColors.brand900,
                          ),
                        ),
                        const SizedBox(height: 10),
                        SizedBox(
                          height: 168,
                          child: ListView(
                            scrollDirection: Axis.horizontal,
                            children: [
                              for (final item
                                  in List<Map<String, dynamic>>.from(
                                rail['items'] as List? ?? [],
                              ))
                                _ContentCard(
                                  item: item,
                                  onTap: () =>
                                      context.push('/watch/${item['id']}'),
                                ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 20),
                      ],
                      if (_games.isNotEmpty) ...[
                        const Text(
                          'Brain & Fun Games',
                          style: TextStyle(
                            fontWeight: FontWeight.w800,
                            fontSize: 16,
                            color: AppColors.brand900,
                          ),
                        ),
                        const SizedBox(height: 10),
                        SizedBox(
                          height: 168,
                          child: ListView(
                            scrollDirection: Axis.horizontal,
                            children: [
                              for (final item in _games)
                                _ContentCard(
                                  item: item,
                                  onTap: () {
                                    final quizId = item['quizId']?.toString();
                                    if (quizId != null && quizId.isNotEmpty) {
                                      context.push('/quiz/$quizId');
                                    } else {
                                      context.push('/watch/${item['id']}');
                                    }
                                  },
                                ),
                            ],
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
    );
  }
}

class _ContentCard extends StatelessWidget {
  const _ContentCard({required this.item, required this.onTap});
  final Map<String, dynamic> item;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final thumb = item['thumbUrl']?.toString();
    final locked = item['locked'] == true;
    return Padding(
      padding: const EdgeInsets.only(right: 12),
      child: InkWell(
        onTap: locked
            ? () => showAppToast(context, 'Unlock with a senior program')
            : onTap,
        borderRadius: BorderRadius.circular(14),
        child: SizedBox(
          width: 140,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(14),
                  child: Stack(
                    fit: StackFit.expand,
                    children: [
                      if (thumb != null && thumb.isNotEmpty)
                        Image.network(thumb,
                            fit: BoxFit.cover,
                            errorBuilder: (_, __, ___) => _placeholder())
                      else
                        _placeholder(),
                      if (locked)
                        Container(
                          color: Colors.black45,
                          alignment: Alignment.center,
                          child: const Icon(Icons.lock, color: Colors.white),
                        ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 6),
              Text(
                item['title']?.toString() ?? '',
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  fontWeight: FontWeight.w700,
                  fontSize: 13,
                  color: AppColors.brand900,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _placeholder() => Container(
        color: AppColors.brand100,
        alignment: Alignment.center,
        child:
            const Icon(Icons.play_circle, color: AppColors.brand600, size: 36),
      );
}
