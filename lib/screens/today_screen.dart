import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';

import '../api/api_client.dart';
import '../config.dart';
import '../auth/auth_state.dart';
import '../mock_timeline.dart';
import '../services/local_store.dart';
import '../services/lazy_tts_service.dart';
import '../theme/app_theme.dart';
import '../widgets/common.dart';

/// Where a slot sits relative to the current time.
///
/// [now] is the single slot whose time window contains the current moment,
/// [missed] is an earlier slot from today that was never marked done, and
/// [available] covers past days, which stay fully unlocked.
enum SlotPhase { done, now, missed, available, upcoming }

const _gutterWidth = 76.0;
const _railWidth = 30.0;
const _nowRed = Color(0xFFE11D48);
const _doneGreen = Color(0xFF16A34A);

/// Greyscales the artwork behind locked slots.
const _greyscale = ColorFilter.matrix(<double>[
  0.2126, 0.7152, 0.0722, 0, 0, //
  0.2126, 0.7152, 0.0722, 0, 0, //
  0.2126, 0.7152, 0.0722, 0, 0, //
  0, 0, 0, 1, 0, //
]);

/// Picks the background artwork that best matches a slot's wording.
String _bgAssetFor(Map<String, dynamic> slot) {
  final text = [slot['id'], slot['title'], slot['subtitle'], slot['mediaKind']]
      .where((e) => e != null)
      .join(' ')
      .toLowerCase();
  bool has(List<String> keys) => keys.any(text.contains);

  // Order matters: the most specific cues are checked first so that, say,
  // "Night Medicines" lands on medicine rather than the bedtime artwork.
  if (has(['water', 'methi', 'hydrat'])) return 'assets/bg/bg_water.jpg';
  if (has(['medicine', 'meds', 'tablet', 'pill', 'sugar', 'blood pressure'])) {
    return 'assets/bg/bg_medicine.jpg';
  }
  if (has(['yoga', 'pranayama', 'breath', 'meditat', 'relax', 'stretch'])) {
    return 'assets/bg/bg_yoga.jpg';
  }
  if (has(['walk', 'steps', 'exercise', 'weights'])) {
    return 'assets/bg/bg_walk.jpg';
  }
  if (has(['nap', 'sleep', 'good night', 'bedtime', 'audiobook'])) {
    return 'assets/bg/bg_night.jpg';
  }
  if (has([
    'puja',
    'pooja',
    'prayer',
    'darshan',
    'abhishek',
    'kumkum',
    'archane',
    'bhajan',
    'satsang',
    'japa',
    'mala',
    'deity',
    'deepa',
    'temple',
    'cow',
  ])) {
    return 'assets/bg/bg_devotional.jpg';
  }
  if (has([
    'breakfast',
    'lunch',
    'dinner',
    'meal',
    'food',
    'snack',
    'ragi',
    'malt',
    'drink',
    'tea',
    'milk',
    'cook',
  ])) {
    return 'assets/bg/bg_meal.jpg';
  }
  if (has([
    'game',
    'quiz',
    'story',
    'puzzle',
    'sudoku',
    'brain',
    'memory',
    'colour',
    'ludo',
    'news',
  ])) {
    return 'assets/bg/bg_games.jpg';
  }
  if (has(['family', 'photo', 'call'])) return 'assets/bg/bg_family.jpg';
  return 'assets/bg/bg_sunrise.jpg';
}

class TodayScreen extends StatefulWidget {
  const TodayScreen({
    super.key,
    this.scrollToNextIncomplete = false,
    this.afterSlotId,
  });

  final bool scrollToNextIncomplete;
  final String? afterSlotId;

  @override
  State<TodayScreen> createState() => _TodayScreenState();
}

class _TodayScreenState extends State<TodayScreen> {
  Map<String, dynamic>? _data;
  bool _loading = true;
  String? _error;
  final _nowKey = GlobalKey();
  final _slotKeys = <String, GlobalKey>{};
  final _scroll = ScrollController();
  bool _revealed = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void didUpdateWidget(covariant TodayScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.scrollToNextIncomplete &&
        (oldWidget.scrollToNextIncomplete != widget.scrollToNextIncomplete ||
            oldWidget.afterSlotId != widget.afterSlotId)) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _scrollToNextIncomplete(afterSlotId: widget.afterSlotId);
      });
    }
  }

  @override
  void dispose() {
    _scroll.dispose();
    super.dispose();
  }

  // ---------------------------------------------------------------- time utils

  DateTime _nowIst() =>
      DateTime.now().toUtc().add(const Duration(hours: 5, minutes: 30));

  int _nowMinutes() {
    final n = _nowIst();
    return n.hour * 60 + n.minute;
  }

  int _minutesOf(String? hhmm) {
    if (hhmm == null || !hhmm.contains(':')) return 0;
    final parts = hhmm.split(':');
    return (int.tryParse(parts[0]) ?? 0) * 60 + (int.tryParse(parts[1]) ?? 0);
  }

  String _clock(int minutes) {
    final h24 = (minutes ~/ 60) % 24;
    final m = minutes % 60;
    final h12 = h24 % 12 == 0 ? 12 : h24 % 12;
    return '$h12:${m.toString().padLeft(2, '0')} ${h24 < 12 ? 'AM' : 'PM'}';
  }

  String _clockOf(String? hhmm) => _clock(_minutesOf(hhmm));

  String _prettyDate(String? ymd) {
    final now = _nowIst();
    final d = (ymd != null && ymd.length >= 10)
        ? (DateTime.tryParse(ymd) ?? now)
        : now;
    const days = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
    const months = [
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'May',
      'Jun',
      'Jul',
      'Aug',
      'Sep',
      'Oct',
      'Nov',
      'Dec'
    ];
    return '${days[d.weekday - 1]}, ${months[d.month - 1]} ${d.day}, ${d.year}';
  }

  /// The plan is only "live" for today — past days stay fully unlocked.
  bool get _isToday {
    final ymd = _data?['date']?.toString();
    if (ymd == null) return true;
    final n = _nowIst();
    final today = '${n.year.toString().padLeft(4, '0')}-'
        '${n.month.toString().padLeft(2, '0')}-'
        '${n.day.toString().padLeft(2, '0')}';
    return ymd == today;
  }

  bool _isDone(Map<String, dynamic> slot) {
    final s = slot['status']?.toString() ?? 'pending';
    return s == 'done' || s == 'skipped';
  }

  bool _isUpcoming(Map<String, dynamic> slot) {
    if (!AppConfig.lockFutureSlotsByTime) return false;
    return _isToday &&
        !_isDone(slot) &&
        _minutesOf(slot['time']?.toString()) > _nowMinutes();
  }

  /// Index of the slot that owns the current moment: the last one whose start
  /// time has already passed. Anything earlier is history, done or not.
  int _currentIndex(List<Map<String, dynamic>> slots) {
    if (!_isToday) return -1;
    final now = _nowMinutes();
    var index = -1;
    for (var i = 0; i < slots.length; i++) {
      if (_minutesOf(slots[i]['time']?.toString()) <= now) index = i;
    }
    return index;
  }

  SlotPhase _phaseOf(
    Map<String, dynamic> slot,
    int index,
    int currentIndex,
  ) {
    if (_isDone(slot)) return SlotPhase.done;
    if (_isUpcoming(slot)) return SlotPhase.upcoming;
    if (index == currentIndex) return SlotPhase.now;
    return _isToday ? SlotPhase.missed : SlotPhase.available;
  }

  // ------------------------------------------------------------------- actions

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final apiData = await context.read<AuthState>().api.seniorToday();
      _data = MockTimeline.withFallback(apiData);
    } on ApiException catch (e) {
      _data = MockTimeline.generateDaySchedule();
      debugPrint('API error, using mock timeline: ${e.message}');
    }
    await _mergeLocalCompletion();
    if (!mounted) return;
    setState(() => _loading = false);
    if (!_revealed) {
      _revealed = true;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (widget.scrollToNextIncomplete) {
          _scrollToNextIncomplete(afterSlotId: widget.afterSlotId);
        } else {
          _revealNow();
        }
      });
      _initTtsLazily();
    } else if (widget.scrollToNextIncomplete) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _scrollToNextIncomplete(afterSlotId: widget.afterSlotId);
      });
    }
  }

  Future<void> _mergeLocalCompletion() async {
    final date = _data?['date']?.toString();
    if (date == null || _data == null) return;
    final slots =
        List<Map<String, dynamic>>.from(_data!['slots'] as List? ?? []);
    for (final slot in slots) {
      final id = slot['id']?.toString();
      if (id != null && await LocalStore.instance.isSlotDone(date, id)) {
        slot['status'] = 'done';
      }
    }
    _data!['slots'] = slots;
  }

  Future<void> _scrollToNextIncomplete({String? afterSlotId}) async {
    final slots =
        List<Map<String, dynamic>>.from(_data?['slots'] as List? ?? []);
    var passedAnchor = afterSlotId == null || afterSlotId.isEmpty;
    GlobalKey? targetKey;
    for (final slot in slots) {
      final id = slot['id']?.toString() ?? '';
      if (!passedAnchor) {
        if (id == afterSlotId) passedAnchor = true;
        continue;
      }
      if (!_isDone(slot) && (slot['contentId']?.toString().isNotEmpty == true ||
          slot['mediaKind']?.toString() == 'video')) {
        targetKey = _slotKeys[id];
        break;
      }
    }
    if (targetKey == null) {
      await _revealNow();
      return;
    }
    for (var step = 0; step < 40; step++) {
      final ctx = targetKey.currentContext;
      if (ctx != null) {
        await Scrollable.ensureVisible(
          ctx,
          duration: const Duration(milliseconds: 350),
          alignment: 0.15,
        );
        return;
      }
      if (!mounted || !_scroll.hasClients) return;
      final pos = _scroll.position;
      _scroll.jumpTo(math.min(
        pos.pixels + pos.viewportDimension * 0.85,
        pos.maxScrollExtent,
      ));
      await WidgetsBinding.instance.endOfFrame;
    }
  }

  /// Initialize TTS lazily after home screen is visible.
  /// Shows toast if TTS is unavailable; hides speaker button session-wide.
  void _initTtsLazily() {
    final tts = LazyTtsService.instance;
    if (tts.status != TtsStatus.notInitialized) return;
    
    Future(() async {
      await Future.delayed(const Duration(milliseconds: 500));
      if (!mounted) return;
      
      final success = await tts.initialize(timeoutMs: 5000);
      if (!mounted) return;
      
      if (!success) {
        final reason = tts.failureReason ?? 'unknown error';
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Voice read-aloud unavailable: $reason'),
            duration: const Duration(seconds: 4),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    });
  }

  /// The list only materialises the rows it can see, so the current activity
  /// usually has no context on the first frame. Step down the timeline until
  /// that row exists, then bring it near the top.
  Future<void> _revealNow() async {
    for (var step = 0; step < 40; step++) {
      final ctx = _nowKey.currentContext;
      if (ctx != null) {
        await Scrollable.ensureVisible(
          ctx,
          duration: const Duration(milliseconds: 300),
          alignment: 0.12,
        );
        return;
      }
      if (!mounted || !_scroll.hasClients) return;
      final pos = _scroll.position;
      if (pos.pixels >= pos.maxScrollExtent) return;
      _scroll.jumpTo(math.min(
        pos.pixels + pos.viewportDimension * 0.9,
        pos.maxScrollExtent,
      ));
      await WidgetsBinding.instance.endOfFrame;
      if (!mounted) return;
    }
  }

  void _lockedToast(Map<String, dynamic> slot) {
    showAppToast(context, 'Opens at ${_clockOf(slot['time']?.toString())}');
  }

  Future<void> _complete(Map<String, dynamic> slot,
      {bool skipped = false}) async {
    if (_isUpcoming(slot)) {
      _lockedToast(slot);
      return;
    }
    final date = _data?['date']?.toString() ?? '';
    final slotId = slot['id'].toString();
    await LocalStore.instance.markSlotDone(date, slotId);
    try {
      await context.read<AuthState>().api.completeSeniorSlot(
            slotId,
            date: date.isEmpty ? null : date,
            skipped: skipped,
          );
    } on ApiException catch (e) {
      if (mounted) showAppToast(context, e.message);
    }
    await _load();
  }

  void _openSlot(Map<String, dynamic> slot) {
    if (_isUpcoming(slot)) {
      _lockedToast(slot);
      return;
    }
    final contentId = slot['contentId']?.toString();
    final quizId = slot['quizId']?.toString();
    final kind = slot['mediaKind']?.toString() ?? '';
    final slotId = slot['id']?.toString();
    final hasLocalStream = (slot['streamUrl']?.toString() ?? '').isNotEmpty;

    if (kind == 'quiz' && quizId != null && quizId.isNotEmpty) {
      context.push('/quiz/$quizId');
      return;
    }

    // Play whatever the CMS scheduled for this slot (content library → /play).
    // If slot has a mock streamUrl, use mock=1 to skip API and use mock videos.
    final date = Uri.encodeComponent(_data?['date']?.toString() ?? '');
    final slotQ = slotId != null ? '&slotId=${Uri.encodeComponent(slotId)}' : '';
    const fromToday = '&fromToday=1';
    final dateQ = date.isNotEmpty ? '&date=$date' : '';

    if (contentId != null && contentId.isNotEmpty) {
      final title = Uri.encodeComponent(slot['title']?.toString() ?? 'Watch');
      final mockParam = hasLocalStream ? '&mock=1' : '';
      context.push(
        '/watch/$contentId?title=$title$mockParam$slotQ$dateQ$fromToday',
      );
      return;
    }
    // Fallback: try slotId as contentId for mock videos
    if (slotId != null && slotId.isNotEmpty && hasLocalStream) {
      final title = Uri.encodeComponent(slot['title']?.toString() ?? 'Watch');
      context.push(
        '/watch/$slotId?title=$title&mock=1$slotQ$dateQ$fromToday',
      );
      return;
    }
    if (!_isDone(slot)) _complete(slot);
  }

  // --------------------------------------------------------------------- build

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthState>();
    final name = auth.me?['name']?.toString();
    final summary = _data?['summary'] as Map?;
    final slots =
        List<Map<String, dynamic>>.from(_data?['slots'] as List? ?? []);
    final currentIndex = _currentIndex(slots);
    final completed =
        (summary?['completed'] as num?)?.toInt() ?? slots.where(_isDone).length;
    final total = (summary?['total'] as num?)?.toInt() ?? slots.length;

    return Scaffold(
      backgroundColor: const Color(0xFFF3F5FA),
      body: SafeArea(
        bottom: false,
        child: Column(
          children: [
            _header(name, completed, total),
            Expanded(
              child: _loading
                  ? const LoadingBody()
                  : _error != null
                      ? ErrorBody(message: _error!, onRetry: _load)
                      : RefreshIndicator(
                          onRefresh: _load,
                          child: ListView(
                            controller: _scroll,
                            physics: const AlwaysScrollableScrollPhysics(),
                            padding: const EdgeInsets.only(top: 8, bottom: 32),
                            children: _timeline(slots, currentIndex),
                          ),
                        ),
            ),
          ],
        ),
      ),
    );
  }

  List<Widget> _timeline(
    List<Map<String, dynamic>> slots,
    int currentIndex,
  ) {
    if (slots.isEmpty) {
      return [
        Padding(
          padding: const EdgeInsets.all(32),
          child: Text(
            'Your daily plan will appear here.',
            textAlign: TextAlign.center,
            style: GoogleFonts.dmSans(fontSize: 18, color: AppColors.slate500),
          ),
        ),
      ];
    }

    final rows = <Widget>[];
    final nowMins = _nowMinutes();
    var nowLinePlaced = !_isToday;

    for (var i = 0; i < slots.length; i++) {
      final slot = slots[i];
      final startMins = _minutesOf(slot['time']?.toString());
      final endMins = i + 1 < slots.length
          ? _minutesOf(slots[i + 1]['time']?.toString())
          : null;

      if (!nowLinePlaced && startMins > nowMins) {
        rows.add(_nowMarker(nowMins, key: currentIndex < 0 ? _nowKey : null));
        nowLinePlaced = true;
      }

      final slotId = slot['id']?.toString() ?? 'slot_$i';
      final rowKey = _slotKeys.putIfAbsent(slotId, GlobalKey.new);

      rows.add(
        _TimelineRow(
          key: i == currentIndex ? _nowKey : rowKey,
          slot: slot,
          phase: _phaseOf(slot, i, currentIndex),
          timeLabel: _clock(startMins),
          rangeLabel: endMins == null
              ? _clock(startMins)
              : '${_clock(startMins)} – ${_clock(endMins)}',
          isLast: i == slots.length - 1,
          onOpen: () => _openSlot(slot),
          onDone: () => _complete(slot),
          onSkip: slot['optional'] == true
              ? () => _complete(slot, skipped: true)
              : null,
        ),
      );
    }

    if (!nowLinePlaced) {
      rows.add(_nowMarker(nowMins, key: currentIndex < 0 ? _nowKey : null));
    }
    return rows;
  }

  Widget _header(String? name, int completed, int total) {
    return Container(
      color: Colors.white,
      padding: const EdgeInsets.fromLTRB(12, 8, 12, 14),
      child: Column(
        children: [
          Row(
            children: [
              IconButton(
                iconSize: 30,
                onPressed: () => context.go('/reminders'),
                icon: const Icon(Icons.notifications_none,
                    color: AppColors.brand700),
                tooltip: 'Reminders',
              ),
              Expanded(
                child: Column(
                  children: [
                    Text(
                      'My Daily Timeline',
                      style: GoogleFonts.dmSans(
                        fontSize: 22,
                        fontWeight: FontWeight.w800,
                        color: AppColors.brand900,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      _prettyDate(_data?['date']?.toString()),
                      style: GoogleFonts.dmSans(
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                        color: AppColors.slate500,
                      ),
                    ),
                  ],
                ),
              ),
              GestureDetector(
                onTap: () => context.go('/me'),
                child: CircleAvatar(
                  radius: 22,
                  backgroundColor: AppColors.brand100,
                  child: Text(
                    (name != null && name.isNotEmpty ? name[0] : 'S')
                        .toUpperCase(),
                    style: GoogleFonts.dmSans(
                      fontSize: 20,
                      fontWeight: FontWeight.w800,
                      color: AppColors.brand700,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 4),
            ],
          ),
          if (total > 0) ...[
            const SizedBox(height: 10),
            Row(
              children: [
                Expanded(
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(99),
                    child: LinearProgressIndicator(
                      value: completed / total,
                      minHeight: 12,
                      backgroundColor: AppColors.brand100,
                      color: AppColors.brand600,
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Text(
                  '$completed / $total done',
                  style: GoogleFonts.dmSans(
                    fontSize: 16,
                    fontWeight: FontWeight.w800,
                    color: AppColors.brand900,
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  Widget _nowMarker(int nowMins, {Key? key}) {
    return Padding(
      key: key,
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          SizedBox(
            width: _gutterWidth,
            child: Text(
              _clock(nowMins),
              textAlign: TextAlign.right,
              style: GoogleFonts.dmSans(
                fontSize: 16,
                fontWeight: FontWeight.w800,
                color: _nowRed,
              ),
            ),
          ),
          SizedBox(
            width: _railWidth,
            child: Center(
              child: Container(
                width: 16,
                height: 16,
                decoration: const BoxDecoration(
                  color: _nowRed,
                  shape: BoxShape.circle,
                ),
              ),
            ),
          ),
          Expanded(
            child: Container(
              height: 3,
              margin: const EdgeInsets.only(right: 16),
              color: _nowRed,
            ),
          ),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------- row

class _TimelineRow extends StatelessWidget {
  const _TimelineRow({
    super.key,
    required this.slot,
    required this.phase,
    required this.timeLabel,
    required this.rangeLabel,
    required this.isLast,
    required this.onOpen,
    required this.onDone,
    this.onSkip,
  });

  final Map<String, dynamic> slot;
  final SlotPhase phase;
  final String timeLabel;
  final String rangeLabel;
  final bool isLast;
  final VoidCallback onOpen;
  final VoidCallback onDone;
  final VoidCallback? onSkip;

  bool get _locked => phase == SlotPhase.upcoming;
  bool get _done => phase == SlotPhase.done;
  bool get _now => phase == SlotPhase.now;
  bool get _missed => phase == SlotPhase.missed;

  IconData get _icon {
    if (_locked) return Icons.lock_outline;
    if (_done) return Icons.check_circle;
    switch (slot['mediaKind']?.toString()) {
      case 'video':
        return Icons.play_circle_fill;
      case 'audio':
      case 'image_audio':
        return Icons.headphones;
      case 'game':
        return Icons.extension;
      case 'quiz':
        return Icons.quiz;
      case 'reminder':
        return Icons.notifications_active;
      case 'live':
        return Icons.live_tv;
      default:
        return Icons.spa;
    }
  }

  @override
  Widget build(BuildContext context) {
    final railColor = _locked
        ? AppColors.slate300
        : _done
            ? _doneGreen
            : _missed
                ? const Color(0xFFF59E0B)
                : AppColors.brand300;

    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          SizedBox(
            width: _gutterWidth,
            child: Padding(
              padding: const EdgeInsets.only(top: 22, right: 4),
              child: Text(
                timeLabel,
                textAlign: TextAlign.right,
                style: GoogleFonts.dmSans(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  color: _locked ? AppColors.slate400 : AppColors.slate600,
                ),
              ),
            ),
          ),
          SizedBox(
            width: _railWidth,
            child: Column(
              children: [
                const SizedBox(height: 22),
                _dot(railColor),
                if (!isLast)
                  Expanded(
                    child: CustomPaint(
                      painter: _DashPainter(railColor.withOpacity(0.5)),
                      child: const SizedBox(width: _railWidth),
                    ),
                  ),
              ],
            ),
          ),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.only(bottom: 14, right: 14),
              child: _card(),
            ),
          ),
        ],
      ),
    );
  }

  Widget _dot(Color color) {
    if (_now) {
      return Container(
        width: 20,
        height: 20,
        decoration: BoxDecoration(
          color: AppColors.brand600,
          shape: BoxShape.circle,
          border: Border.all(color: AppColors.brand200, width: 4),
        ),
      );
    }
    return Container(
      width: 14,
      height: 14,
      decoration: BoxDecoration(color: color, shape: BoxShape.circle),
      child:
          _done ? const Icon(Icons.check, size: 10, color: Colors.white) : null,
    );
  }

  /// Photo background, dark scrim, then white text on top.
  Widget _card() {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        boxShadow: _locked
            ? null
            : [
                BoxShadow(
                  color: AppColors.brand900.withOpacity(0.22),
                  blurRadius: 12,
                  offset: const Offset(0, 4),
                ),
              ],
      ),
      foregroundDecoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color:
              _now ? AppColors.brand600 : Colors.white.withOpacity(0.28),
          width: _now ? 3 : 1,
        ),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(20),
        child: Stack(
          children: [
            Positioned.fill(child: _artwork()),
            Positioned.fill(
              child: DecoratedBox(decoration: BoxDecoration(gradient: _scrim)),
            ),
            Material(
              type: MaterialType.transparency,
              child: InkWell(
                onTap: onOpen,
                child: ConstrainedBox(
                  constraints: const BoxConstraints(minHeight: 130),
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: _overlay(),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _artwork() {
    final image = Image.asset(
      _bgAssetFor(slot),
      fit: BoxFit.cover,
      // Slightly favours the upper part of the photo, where the subject sits.
      alignment: const Alignment(0, -0.2),
    );
    if (_locked) {
      return ColorFiltered(colorFilter: _greyscale, child: image);
    }
    return Opacity(opacity: _done ? 0.75 : 1, child: image);
  }

  LinearGradient get _scrim {
    final strength = _locked ? 0.24 : 0.34;
    return LinearGradient(
      begin: Alignment.topRight,
      end: Alignment.bottomLeft,
      colors: [
        Colors.black.withOpacity(strength),
        Colors.black.withOpacity(strength + 0.38),
      ],
    );
  }

  Widget _overlay() {
    final title = slot['title']?.toString() ?? '';
    final subtitle = slot['subtitle']?.toString();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _iconChip(),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: GoogleFonts.dmSans(
                      fontSize: 21,
                      fontWeight: FontWeight.w800,
                      height: 1.2,
                      color: Colors.white,
                      shadows: const [
                        Shadow(blurRadius: 8, color: Colors.black54),
                      ],
                    ),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    rangeLabel,
                    style: GoogleFonts.dmSans(
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                      color: Colors.white.withOpacity(0.85),
                      shadows: const [
                        Shadow(blurRadius: 6, color: Colors.black54),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            _badge(),
          ],
        ),
        if (subtitle != null && subtitle.isNotEmpty) ...[
          const SizedBox(height: 8),
          Text(
            subtitle,
            style: GoogleFonts.dmSans(
              fontSize: 16,
              height: 1.3,
              fontWeight: FontWeight.w500,
              color: Colors.white.withOpacity(0.9),
              shadows: const [Shadow(blurRadius: 6, color: Colors.black54)],
            ),
          ),
        ],
        const SizedBox(height: 12),
        _actions(),
      ],
    );
  }

  Widget _iconChip() {
    return Container(
      width: 52,
      height: 52,
      decoration: BoxDecoration(
        color: _done
            ? _doneGreen.withOpacity(0.92)
            : Colors.white.withOpacity(0.22),
        shape: BoxShape.circle,
        border:
            Border.all(color: Colors.white.withOpacity(0.65), width: 2),
      ),
      child: Icon(_icon, size: 28, color: Colors.white),
    );
  }

  Widget _actions() {
    if (_locked) {
      return Row(
        children: [
          Icon(Icons.lock_clock,
              size: 20, color: Colors.white.withOpacity(0.85)),
          const SizedBox(width: 6),
          Expanded(
            child: Text(
              'Opens at $timeLabel',
              style: GoogleFonts.dmSans(
                fontSize: 16,
                fontWeight: FontWeight.w700,
                color: Colors.white.withOpacity(0.9),
                shadows: const [Shadow(blurRadius: 6, color: Colors.black54)],
              ),
            ),
          ),
        ],
      );
    }

    if (_done) return const SizedBox.shrink();

    final outlined = OutlinedButton.styleFrom(
      foregroundColor: Colors.white,
      side: BorderSide(color: Colors.white.withOpacity(0.8), width: 2),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
    );

    if (_now) {
      return Row(
        children: [
          Expanded(
            child: SizedBox(
              height: 54,
              child: FilledButton(
                onPressed: onOpen,
                style: FilledButton.styleFrom(
                  backgroundColor: Colors.white,
                  foregroundColor: AppColors.brand700,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                  textStyle: GoogleFonts.dmSans(
                    fontSize: 19,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                child: const Text('Start now'),
              ),
            ),
          ),
          const SizedBox(width: 8),
          SizedBox(
            height: 54,
            child: OutlinedButton(
              onPressed: onDone,
              style: outlined,
              child: Text(
                'Done',
                style: GoogleFonts.dmSans(
                  fontSize: 17,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ),
        ],
      );
    }

    return Row(
      children: [
        SizedBox(
          height: 46,
          child: OutlinedButton(
            onPressed: onDone,
            style: outlined,
            child: Text(
              'Mark done',
              style: GoogleFonts.dmSans(
                fontSize: 16,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ),
        if (onSkip != null) ...[
          const SizedBox(width: 8),
          TextButton(
            onPressed: onSkip,
            style: TextButton.styleFrom(foregroundColor: Colors.white),
            child: Text(
              'Skip',
              style: GoogleFonts.dmSans(
                fontSize: 16,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ],
    );
  }

  Widget _badge() {
    final (label, bg, fg) = switch (phase) {
      SlotPhase.now => ('Now', Colors.white, AppColors.brand700),
      SlotPhase.done => ('Done', _doneGreen, Colors.white),
      SlotPhase.missed => (
          'Catch up',
          const Color(0xFFFBBF24),
          const Color(0xFF78350F)
        ),
      SlotPhase.available => (
          'Ready',
          Colors.white.withOpacity(0.92),
          AppColors.brand700
        ),
      SlotPhase.upcoming => (
          'Later',
          Colors.black.withOpacity(0.35),
          Colors.white
        ),
    };
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(99),
        border: phase == SlotPhase.upcoming
            ? Border.all(color: Colors.white.withOpacity(0.6))
            : null,
      ),
      child: Text(
        label,
        style: GoogleFonts.dmSans(
          fontSize: 15,
          fontWeight: FontWeight.w800,
          color: fg,
        ),
      ),
    );
  }
}

class _DashPainter extends CustomPainter {
  _DashPainter(this.color);
  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = 3
      ..strokeCap = StrokeCap.round;
    const dash = 4.0;
    const gap = 7.0;
    final x = size.width / 2;
    var y = 2.0;
    while (y < size.height) {
      canvas.drawLine(
        Offset(x, y),
        Offset(x, math.min(y + dash, size.height)),
        paint,
      );
      y += dash + gap;
    }
  }

  @override
  bool shouldRepaint(_DashPainter old) => old.color != color;
}
