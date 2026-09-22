import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../api/api_client.dart';
import '../auth/auth_state.dart';
import '../theme/app_theme.dart';
import '../widgets/common.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    try {
      await context.read<AuthState>().refreshMe();
    } on ApiException catch (e) {
      if (mounted) showAppToast(context, e.message);
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _editName() async {
    final me = context.read<AuthState>().me ?? {};
    final name = TextEditingController(text: me['name']?.toString() ?? '');
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      builder: (ctx) => Padding(
        padding: EdgeInsets.only(
          left: 20,
          right: 20,
          top: 20,
          bottom: MediaQuery.of(ctx).viewInsets.bottom + 20,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              'Your name (optional)',
              style: TextStyle(fontWeight: FontWeight.w800, fontSize: 18),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: name,
              decoration: const InputDecoration(labelText: 'Name'),
            ),
            const SizedBox(height: 20),
            PrimaryButton(
              label: 'Save',
              onPressed: () async {
                try {
                  final n = name.text.trim();
                  if (n.length >= 2) {
                    await context
                        .read<AuthState>()
                        .api
                        .updateProfile({'name': n});
                    await context.read<AuthState>().refreshMe();
                  }
                  if (ctx.mounted) Navigator.pop(ctx);
                  setState(() {});
                } on ApiException catch (e) {
                  if (mounted) showAppToast(context, e.message);
                }
              },
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _toggleLoud(bool value) async {
    final auth = context.read<AuthState>();
    final ns = Map<String, dynamic>.from(
      auth.me?['notificationSettings'] as Map? ?? {},
    );
    ns['loudMode'] = value;
    try {
      await auth.api.updatePreferences({'notificationSettings': ns});
      await auth.refreshMe();
    } on ApiException catch (e) {
      if (mounted) showAppToast(context, e.message);
    }
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthState>();
    final me = auth.me ?? {};
    final ns = me['notificationSettings'] as Map? ?? {};
    final loud = ns['loudMode'] == true;
    final displayName = me['name']?.toString();

    return Scaffold(
      appBar: AppBar(title: const Text('Me')),
      body: _loading
          ? const LoadingBody()
          : ListView(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 32),
              children: [
                LeafBackground(
                  child: Padding(
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      children: [
                        const BrandWordmark(size: 28),
                        const SizedBox(height: 6),
                        const Text(
                          'Senior Care',
                          style: TextStyle(
                            fontWeight: FontWeight.w700,
                            color: AppColors.slate600,
                          ),
                        ),
                        const SizedBox(height: 16),
                        CircleAvatar(
                          radius: 36,
                          backgroundColor: AppColors.brand100,
                          child: Text(
                            (displayName != null && displayName.isNotEmpty
                                    ? displayName[0]
                                    : 'S')
                                .toUpperCase(),
                            style: const TextStyle(
                              fontSize: 28,
                              fontWeight: FontWeight.w800,
                              color: AppColors.brand700,
                            ),
                          ),
                        ),
                        const SizedBox(height: 10),
                        Text(
                          (displayName != null && displayName.isNotEmpty)
                              ? displayName
                              : 'Guest',
                          style: const TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.w800,
                            color: AppColors.brand900,
                          ),
                        ),
                        if (me['phone'] != null)
                          Text(
                            me['phone'].toString(),
                            style: const TextStyle(color: AppColors.slate500),
                          ),
                        const SizedBox(height: 12),
                        OutlinedButton(
                          onPressed: _editName,
                          child: const Text('Edit name'),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                AppCard(
                  child: SwitchListTile(
                    contentPadding: EdgeInsets.zero,
                    title: const Text(
                      'Loud reminders',
                      style: TextStyle(fontWeight: FontWeight.w700),
                    ),
                    subtitle: const Text('Elderly-friendly alert style'),
                    value: loud,
                    onChanged: _toggleLoud,
                  ),
                ),
                const SizedBox(height: 12),
                AppCard(
                  onTap: () => context.push('/programs'),
                  child: const ListTile(
                    contentPadding: EdgeInsets.zero,
                    leading: Icon(Icons.workspace_premium_outlined,
                        color: AppColors.brand600),
                    title: Text(
                      'Programs',
                      style: TextStyle(fontWeight: FontWeight.w700),
                    ),
                    subtitle: Text('Enroll in senior care programs'),
                    trailing: Icon(Icons.chevron_right),
                  ),
                ),
                const SizedBox(height: 24),
                OutlinedButton(
                  onPressed: () async {
                    await auth.logout();
                  },
                  style: OutlinedButton.styleFrom(
                    foregroundColor: const Color(0xFFDC2626),
                    minimumSize: const Size.fromHeight(48),
                  ),
                  child: const Text('Log out'),
                ),
              ],
            ),
    );
  }
}
