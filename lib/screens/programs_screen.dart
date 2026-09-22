import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../api/api_client.dart';
import '../auth/auth_state.dart';
import '../theme/app_theme.dart';
import '../widgets/common.dart';

class ProgramsScreen extends StatefulWidget {
  const ProgramsScreen({super.key});

  @override
  State<ProgramsScreen> createState() => _ProgramsScreenState();
}

class _ProgramsScreenState extends State<ProgramsScreen> {
  List<Map<String, dynamic>> _items = [];
  bool _loading = true;
  String? _error;
  String? _busyId;

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
      final r = await context.read<AuthState>().api.seniorPrograms();
      _items = List<Map<String, dynamic>>.from(r['items'] as List? ?? []);
    } on ApiException catch (e) {
      _error = e.message;
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _enroll(Map<String, dynamic> program) async {
    final id = program['id'].toString();
    setState(() => _busyId = id);
    try {
      final api = context.read<AuthState>().api;
      final enroll = await api.enrollSeniorProgram(id);
      if (enroll['alreadyEnrolled'] == true) {
        showAppToast(context, 'Already enrolled');
        await _load();
        return;
      }
      final orderId = enroll['orderId']?.toString();
      if (orderId == null) {
        showAppToast(context, 'Could not start enrollment');
        return;
      }
      await api.mockPay(orderId);
      if (mounted) showAppToast(context, 'Enrolled! Enjoy your program.');
      await _load();
    } on ApiException catch (e) {
      if (mounted) showAppToast(context, e.message);
    } finally {
      if (mounted) setState(() => _busyId = null);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Programs')),
      body: _loading
          ? const LoadingBody()
          : _error != null
              ? ErrorBody(message: _error!, onRetry: _load)
              : _items.isEmpty
                  ? const Center(
                      child: Padding(
                        padding: EdgeInsets.all(24),
                        child: Text(
                          'No programs yet. Seed senior content on the API.',
                          textAlign: TextAlign.center,
                        ),
                      ),
                    )
                  : ListView.separated(
                      padding: const EdgeInsets.all(16),
                      itemCount: _items.length,
                      separatorBuilder: (_, __) => const SizedBox(height: 12),
                      itemBuilder: (context, i) {
                        final p = _items[i];
                        final entitled = p['entitled'] == true;
                        final busy = _busyId == p['id']?.toString();
                        return AppCard(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                p['name']?.toString() ?? 'Program',
                                style: const TextStyle(
                                  fontWeight: FontWeight.w800,
                                  fontSize: 17,
                                  color: AppColors.brand900,
                                ),
                              ),
                              if (p['description'] != null) ...[
                                const SizedBox(height: 6),
                                Text(
                                  p['description'].toString(),
                                  style: const TextStyle(
                                      color: AppColors.slate600),
                                ),
                              ],
                              const SizedBox(height: 10),
                              Text(
                                entitled
                                    ? 'Enrolled'
                                    : '₹${p['priceInr'] ?? 0}',
                                style: TextStyle(
                                  fontWeight: FontWeight.w700,
                                  color: entitled
                                      ? const Color(0xFF16A34A)
                                      : AppColors.brand600,
                                ),
                              ),
                              if (!entitled) ...[
                                const SizedBox(height: 12),
                                PrimaryButton(
                                  label:
                                      busy ? 'Enrolling…' : 'Enroll (mock pay)',
                                  loading: busy,
                                  onPressed: busy ? null : () => _enroll(p),
                                ),
                              ],
                            ],
                          ),
                        );
                      },
                    ),
    );
  }
}
