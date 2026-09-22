import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../api/api_client.dart';
import '../auth/auth_state.dart';
import '../notifications/notification_service.dart';
import '../theme/app_theme.dart';
import '../widgets/common.dart';

class RemindersScreen extends StatefulWidget {
  const RemindersScreen({super.key, this.openAdd = false});
  final bool openAdd;

  @override
  State<RemindersScreen> createState() => _RemindersScreenState();
}

class _RemindersScreenState extends State<RemindersScreen> {
  late String _date;
  Map<String, dynamic>? _data;
  bool _loading = true;
  String? _error;
  bool _openedAdd = false;

  @override
  void initState() {
    super.initState();
    _date = todayIstDate();
    _load();
  }

  @override
  void didUpdateWidget(covariant RemindersScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.openAdd && !_openedAdd) {
      _openedAdd = true;
      WidgetsBinding.instance.addPostFrameCallback((_) => _openEditor());
    }
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      _data = await context.read<AuthState>().api.reminders(_date);
      final defs = List<Map<String, dynamic>>.from(
        _data?['reminders'] as List? ?? [],
      );
      try {
        await NotificationService.instance.syncReminders(defs);
      } catch (e) {
        debugPrint('Reminder schedule error: $e');
      }
      if (widget.openAdd && !_openedAdd) {
        _openedAdd = true;
        WidgetsBinding.instance.addPostFrameCallback((_) => _openEditor());
      }
    } on ApiException catch (e) {
      _error = e.message;
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _markDone(String key) async {
    try {
      await context.read<AuthState>().api.markReminderDone(key);
      await _load();
    } on ApiException catch (e) {
      if (mounted) showAppToast(context, e.message);
    }
  }

  Future<void> _openEditor([Map<String, dynamic>? def]) async {
    final title = TextEditingController(text: def?['title']?.toString() ?? '');
    final subtitle =
        TextEditingController(text: def?['subtitle']?.toString() ?? '');
    var type = def?['type']?.toString() ?? 'water';
    final times = List<String>.from(
      (def?['times'] as List?)?.map((e) => e.toString()) ?? ['09:00'],
    );
    final days = Set<int>.from(
      (def?['daysOfWeek'] as List?)?.map((e) => (e as num).toInt()) ??
          [0, 1, 2, 3, 4, 5, 6],
    );
    const types = ['water', 'medicine', 'food', 'exercise', 'custom'];
    const dayLabels = ['S', 'M', 'T', 'W', 'T', 'F', 'S'];

    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (ctx, setModal) {
            return Padding(
              padding: EdgeInsets.only(
                left: 20,
                right: 20,
                top: 20,
                bottom: MediaQuery.of(ctx).viewInsets.bottom + 20,
              ),
              child: SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      def == null ? 'New reminder' : 'Edit reminder',
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Wrap(
                      spacing: 6,
                      runSpacing: 6,
                      children: types.map((t) {
                        final selected = type == t;
                        return ChoiceChip(
                          label: Text(
                            t[0].toUpperCase() + t.substring(1),
                            style: TextStyle(
                              color:
                                  selected ? Colors.white : AppColors.slate700,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          selected: selected,
                          showCheckmark: false,
                          selectedColor: AppColors.brand600,
                          backgroundColor: Colors.white,
                          onSelected: (_) => setModal(() => type = t),
                        );
                      }).toList(),
                    ),
                    const SizedBox(height: 16),
                    TextField(
                      controller: title,
                      decoration: const InputDecoration(labelText: 'Title'),
                    ),
                    const SizedBox(height: 14),
                    TextField(
                      controller: subtitle,
                      decoration: const InputDecoration(labelText: 'Note'),
                    ),
                    const SizedBox(height: 16),
                    const Text('Days',
                        style: TextStyle(fontWeight: FontWeight.w600)),
                    const SizedBox(height: 10),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: List.generate(7, (i) {
                        final on = days.contains(i);
                        return InkWell(
                          onTap: () => setModal(() {
                            on ? days.remove(i) : days.add(i);
                          }),
                          child: CircleAvatar(
                            radius: 16,
                            backgroundColor:
                                on ? AppColors.brand600 : AppColors.slate100,
                            child: Text(
                              dayLabels[i],
                              style: TextStyle(
                                fontSize: 11,
                                color: on ? Colors.white : AppColors.slate500,
                              ),
                            ),
                          ),
                        );
                      }),
                    ),
                    const SizedBox(height: 16),
                    ...List.generate(times.length, (i) {
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 14),
                        child: TextField(
                          controller: TextEditingController(text: times[i]),
                          decoration: InputDecoration(
                            labelText: 'Time ${i + 1} (HH:mm)',
                          ),
                          onChanged: (v) => times[i] = v,
                        ),
                      );
                    }),
                    TextButton(
                      onPressed: () => setModal(() => times.add('09:00')),
                      child: const Text('+ Add time'),
                    ),
                    const SizedBox(height: 12),
                    PrimaryButton(
                      label: 'Save',
                      onPressed: () async {
                        final body = {
                          'type': type,
                          'title': title.text.trim(),
                          'subtitle': subtitle.text.trim().isEmpty
                              ? null
                              : subtitle.text.trim(),
                          'times': times.where((t) => t.isNotEmpty).toList(),
                          'daysOfWeek': days.toList()..sort(),
                        };
                        try {
                          final api = context.read<AuthState>().api;
                          if (def == null) {
                            await api.createReminder(body);
                          } else {
                            await api.updateReminder(
                                def['id'].toString(), body);
                          }
                          if (ctx.mounted) Navigator.pop(ctx);
                          await _load();
                        } on ApiException catch (e) {
                          if (mounted) showAppToast(context, e.message);
                        }
                      },
                    ),
                    if (def != null)
                      TextButton(
                        onPressed: () async {
                          try {
                            await context
                                .read<AuthState>()
                                .api
                                .deleteReminder(def['id'].toString());
                            if (ctx.mounted) Navigator.pop(ctx);
                            await _load();
                          } on ApiException catch (e) {
                            if (mounted) showAppToast(context, e.message);
                          }
                        },
                        child: const Text(
                          'Delete',
                          style: TextStyle(color: Colors.red),
                        ),
                      ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  List<DateTime> _weekDays() {
    final selected = DateTime.parse(_date);
    final start = selected.subtract(const Duration(days: 3));
    return List.generate(
      7,
      (i) => DateTime(start.year, start.month, start.day + i),
    );
  }

  String _fmt(DateTime d) =>
      '${d.year.toString().padLeft(4, '0')}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';

  @override
  Widget build(BuildContext context) {
    final today =
        List<Map<String, dynamic>>.from(_data?['today'] as List? ?? []);
    final upcoming =
        List<Map<String, dynamic>>.from(_data?['upcoming'] as List? ?? []);
    final defs =
        List<Map<String, dynamic>>.from(_data?['reminders'] as List? ?? []);
    final summary = _data?['summary'] as Map<String, dynamic>?;
    final total = (summary?['total'] as num?)?.toInt() ?? 0;
    final done = (summary?['completed'] as num?)?.toInt() ?? 0;
    // DateTime.weekday: 1=Mon … 7=Sun
    const dayNames = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];

    return Scaffold(
      appBar: AppBar(
        title: const Text('Reminders'),
        actions: [
          IconButton(
            tooltip: 'Test notification in 10s',
            icon: const Icon(Icons.notification_add_outlined),
            onPressed: () async {
              try {
                await NotificationService.instance.scheduleTestIn(seconds: 10);
                if (mounted) {
                  showAppToast(context, 'Test alert in 10 seconds');
                }
              } catch (e) {
                if (mounted) showAppToast(context, 'Notification error: $e');
              }
            },
          ),
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: () => _openEditor(),
          ),
        ],
      ),
      body: _loading
          ? const LoadingBody()
          : _error != null
              ? ErrorBody(message: _error!, onRetry: _load)
              : ListView(
                  padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
                  children: [
                    SizedBox(
                      height: 72,
                      child: ListView.separated(
                        scrollDirection: Axis.horizontal,
                        itemCount: 7,
                        separatorBuilder: (_, __) => const SizedBox(width: 8),
                        itemBuilder: (_, i) {
                          final d = _weekDays()[i];
                          final key = _fmt(d);
                          final selected = key == _date;
                          return InkWell(
                            onTap: () {
                              _date = key;
                              _load();
                            },
                            borderRadius: BorderRadius.circular(999),
                            child: Container(
                              width: 52,
                              decoration: BoxDecoration(
                                color: selected
                                    ? AppColors.brand600
                                    : AppColors.slate50,
                                borderRadius: BorderRadius.circular(999),
                                border: Border.all(
                                  color: selected
                                      ? AppColors.brand600
                                      : AppColors.slate200,
                                ),
                              ),
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Text(
                                    dayNames[d.weekday - 1],
                                    style: TextStyle(
                                      fontSize: 11,
                                      fontWeight: FontWeight.w600,
                                      color: selected
                                          ? Colors.white70
                                          : AppColors.slate500,
                                    ),
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    '${d.day}',
                                    style: TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.w800,
                                      color: selected
                                          ? Colors.white
                                          : AppColors.brand900,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                    if (total > 0) ...[
                      const SizedBox(height: 14),
                      AppCard(
                        color: AppColors.brand50,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Expanded(
                                  child: Text(
                                    '$done of $total tasks completed',
                                    style: const TextStyle(
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                                ),
                                const Icon(Icons.emoji_events_outlined,
                                    color: Color(0xFFD97706)),
                              ],
                            ),
                            const SizedBox(height: 8),
                            ClipRRect(
                              borderRadius: BorderRadius.circular(99),
                              child: LinearProgressIndicator(
                                value: (done / total).clamp(0, 1),
                                minHeight: 7,
                                color: AppColors.brand600,
                                backgroundColor: Colors.white,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                    const SizedBox(height: 16),
                    const Text('Today',
                        style: TextStyle(fontWeight: FontWeight.w800)),
                    const SizedBox(height: 8),
                    if (today.isEmpty)
                      const Text('Nothing here yet',
                          style: TextStyle(color: AppColors.slate400))
                    else
                      ...today.map((r) => _row(r, r['status'] == 'done')),
                    const SizedBox(height: 16),
                    const Text('Upcoming',
                        style: TextStyle(fontWeight: FontWeight.w800)),
                    const SizedBox(height: 8),
                    if (upcoming.isEmpty)
                      const Text('No upcoming reminders',
                          style: TextStyle(color: AppColors.slate400))
                    else
                      ...upcoming.map((r) => _row(r, false)),
                    if (defs.isNotEmpty) ...[
                      const SizedBox(height: 16),
                      const Text('Manage',
                          style: TextStyle(fontWeight: FontWeight.w800)),
                      const SizedBox(height: 8),
                      ...defs.map((d) {
                        final style = categoryStyle(d['type']?.toString());
                        return Padding(
                          padding: const EdgeInsets.only(bottom: 8),
                          child: AppCard(
                            onTap: () => _openEditor(d),
                            padding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 10,
                            ),
                            child: Row(
                              children: [
                                Container(
                                  width: 36,
                                  height: 36,
                                  decoration: BoxDecoration(
                                    color: style.bg,
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                  child: Icon(style.icon,
                                      color: style.fg, size: 18),
                                ),
                                const SizedBox(width: 10),
                                Expanded(
                                  child: Text(
                                    d['title']?.toString() ?? 'Reminder',
                                    style: const TextStyle(
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                                ),
                                const Icon(Icons.edit_outlined,
                                    size: 18, color: AppColors.slate400),
                              ],
                            ),
                          ),
                        );
                      }),
                    ],
                  ],
                ),
    );
  }

  Widget _row(Map<String, dynamic> r, bool done) {
    final style = categoryStyle(r['type']?.toString());
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: AppCard(
        child: Row(
          children: [
            Container(
              width: 42,
              height: 42,
              decoration: BoxDecoration(
                color: style.bg,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(style.icon, color: style.fg, size: 22),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    r['title']?.toString() ?? '',
                    style: TextStyle(
                      fontWeight: FontWeight.w700,
                      decoration: done ? TextDecoration.lineThrough : null,
                      color: done ? AppColors.slate500 : AppColors.brand900,
                    ),
                  ),
                  Text(
                    r['subtitle']?.toString() ?? r['type']?.toString() ?? '',
                    style: const TextStyle(
                        fontSize: 12, color: AppColors.slate500),
                  ),
                ],
              ),
            ),
            Text(
              r['time']?.toString() ?? '',
              style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 12),
            ),
            const SizedBox(width: 8),
            if (done)
              const CircleAvatar(
                radius: 14,
                backgroundColor: Color(0xFF22C55E),
                child: Icon(Icons.check, size: 16, color: Colors.white),
              )
            else
              IconButton(
                icon: const Icon(Icons.circle_outlined,
                    color: AppColors.brand600),
                onPressed: () => _markDone(r['instanceKey'].toString()),
              ),
          ],
        ),
      ),
    );
  }
}
