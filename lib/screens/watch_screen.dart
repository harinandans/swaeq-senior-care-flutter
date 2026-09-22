import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:video_player/video_player.dart';
import 'package:wakelock_plus/wakelock_plus.dart';

import '../api/api_client.dart';
import '../auth/auth_state.dart';
import '../mock_videos.dart';
import '../models/video_quiz_config.dart';
import '../theme/app_theme.dart';
import '../widgets/common.dart';
import '../widgets/video_quiz_overlay.dart';

class WatchScreen extends StatefulWidget {
  const WatchScreen({
    super.key,
    required this.contentId,
    this.preferMock = false,
    this.titleHint,
  });
  final String contentId;
  final bool preferMock;
  final String? titleHint;

  @override
  State<WatchScreen> createState() => _WatchScreenState();
}

class _WatchScreenState extends State<WatchScreen> {
  VideoPlayerController? _video;
  String? _error;
  bool _loading = true;
  String? _title;
  String? _kind;
  String? _imageUrl;
  String? _audioUrl;
  String? _quizId;
  String? _gameUrl;

  /// Immersive: controls hidden until the user taps the video.
  bool _showControls = false;
  Timer? _hideControlsTimer;
  bool _dragging = false;

  /// In-video quiz configuration for this video (if any).
  VideoQuizConfig? _videoQuizConfig;

  /// Whether the in-video quiz has been triggered this session.
  /// Reset only when the video is restarted from the beginning.
  bool _quizTriggered = false;

  /// Whether the quiz overlay is currently visible.
  bool _showQuizOverlay = false;

  /// Whether the video has completed playback.
  bool _videoCompleted = false;

  /// Next content ID for "Play next" functionality.
  String? _nextContentId;
  String? _nextContentTitle;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _enterPortraitImmersive() async {
    await SystemChrome.setPreferredOrientations(const [
      DeviceOrientation.portraitUp,
    ]);
    await SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);
  }

  Future<void> _restoreSystemUi() async {
    await SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
    await SystemChrome.setPreferredOrientations(const [
      DeviceOrientation.portraitUp,
    ]);
  }

  void _scheduleHideControls() {
    _hideControlsTimer?.cancel();
    if (!_showControls || _dragging) return;
    _hideControlsTimer = Timer(const Duration(seconds: 3), () {
      if (!mounted || _dragging) return;
      setState(() => _showControls = false);
    });
  }

  void _toggleControls() {
    setState(() => _showControls = !_showControls);
    if (_showControls) {
      _scheduleHideControls();
    } else {
      _hideControlsTimer?.cancel();
    }
  }

  void _revealControls() {
    if (!_showControls) {
      setState(() => _showControls = true);
    }
    _scheduleHideControls();
  }

  Future<void> _playStream(String streamUrl, {String? title}) async {
    final format = streamUrl.contains('.m3u8') ? 'hls' : 'mp4';
    final video = VideoPlayerController.networkUrl(
      Uri.parse(streamUrl),
      formatHint: format == 'hls' ? VideoFormat.hls : VideoFormat.other,
      httpHeaders: const {'Accept': '*/*'},
    );
    await video.initialize();
    await _enterPortraitImmersive();
    // Keep screen awake for the whole watch session (no idle sleep / close).
    await WakelockPlus.enable();
    video
      ..setLooping(false)
      ..play();
    video.addListener(_onVideoUpdate);
    _video = video;
    if (title != null && title.isNotEmpty) _title = title;
    // Start clean: no chrome until tap.
    _showControls = false;
    _videoCompleted = false;

    // Look up in-video quiz configuration for this video.
    _videoQuizConfig = VideoQuizRegistry.findQuiz(
      contentId: widget.contentId,
      slotId: widget.contentId,
      streamUrl: streamUrl,
    );
    _quizTriggered = false;
  }

  void _onVideoUpdate() {
    if (!mounted) return;
    setState(() {});
    _checkQuizTrigger();
    _checkVideoCompletion();
  }

  void _checkVideoCompletion() {
    final video = _video;
    if (video == null || _videoCompleted || _showQuizOverlay) return;

    final pos = video.value.position;
    final dur = video.value.duration;

    // Check if video has completed (position at or very near duration and not playing)
    if (dur.inMilliseconds > 0 &&
        pos.inMilliseconds >= dur.inMilliseconds - 500 &&
        !video.value.isPlaying &&
        !video.value.isBuffering) {
      setState(() {
        _videoCompleted = true;
        _showControls = false;
      });
      _hideControlsTimer?.cancel();
    }
  }

  /// Check if buffering spinner should be suppressed.
  /// Suppress near end of video (within ~2s) to avoid flash on completion.
  bool _shouldShowBuffering() {
    final video = _video;
    if (video == null || !video.value.isBuffering) return false;
    if (_showQuizOverlay || _videoCompleted) return false;

    final pos = video.value.position;
    final dur = video.value.duration;

    // Suppress buffering indicator in the last 2 seconds of video
    if (dur.inMilliseconds > 0) {
      final remainingMs = dur.inMilliseconds - pos.inMilliseconds;
      if (remainingMs <= 2000) return false;
    }

    return true;
  }

  void _dismissCompletionOverlay() {
    setState(() {
      _videoCompleted = false;
    });
  }

  void _playNextVideo() {
    if (_nextContentId != null) {
      final title = Uri.encodeComponent(_nextContentTitle ?? 'Watch');
      context.pushReplacement('/watch/$_nextContentId?title=$title');
    }
  }

  void _checkQuizTrigger() {
    final video = _video;
    final config = _videoQuizConfig;

    if (video == null ||
        config == null ||
        _quizTriggered ||
        _showQuizOverlay ||
        !video.value.isPlaying) {
      return;
    }

    final positionSec = video.value.position.inSeconds;
    final triggerSec = config.triggerTimestamp;

    // Trigger when we reach or pass the timestamp (within a small window).
    // The window prevents missing the trigger if frames skip.
    if (positionSec >= triggerSec && positionSec < triggerSec + 2) {
      _triggerQuiz();
    }
  }

  void _triggerQuiz() {
    final video = _video;
    if (video == null || _quizTriggered) return;

    _quizTriggered = true;
    video.pause();
    setState(() {
      _showQuizOverlay = true;
      _showControls = false;
    });
    _hideControlsTimer?.cancel();
  }

  void _onQuizDismissed({
    required bool skipped,
    String? selectedOptionId,
    bool? wasCorrect,
  }) {
    setState(() {
      _showQuizOverlay = false;
    });
    _video?.play();
  }

  Future<void> _load() async {
    try {
      final r = await context
          .read<AuthState>()
          .api
          .playSeniorContent(widget.contentId);
      if (r['locked'] == true) {
        setState(() {
          _error = 'This content is locked. Enroll in a program to unlock.';
          _loading = false;
        });
        return;
      }
      _title = r['title']?.toString() ?? widget.titleHint;
      _kind = r['kind']?.toString();
      _imageUrl = r['imageUrl']?.toString() ?? r['thumbUrl']?.toString();
      _audioUrl = r['audioUrl']?.toString();
      _quizId = r['quizId']?.toString();
      _gameUrl = r['gameUrl']?.toString();

      // Check for next content in the response (if API provides it)
      _nextContentId = r['nextContentId']?.toString();
      _nextContentTitle = r['nextContentTitle']?.toString();

      final streamUrl = r['streamUrl']?.toString();
      if (streamUrl != null && streamUrl.isNotEmpty) {
        await _playStream(streamUrl, title: _title);
      }

      if (!mounted) return;
      setState(() => _loading = false);
    } on ApiException catch (e) {
      final mockUrl = MockVideos.urlFor(
        contentId: widget.contentId,
        slotId: widget.contentId,
      );
      if (mockUrl != null) {
        try {
          _title = widget.titleHint ?? widget.contentId;
          _kind = 'video';
          await _playStream(mockUrl, title: _title);
          if (!mounted) return;
          setState(() {
            _error = null;
            _loading = false;
          });
          return;
        } catch (_) {/* fall through */}
      }
      setState(() {
        _error = e.message;
        _loading = false;
      });
    } catch (e) {
      setState(() {
        _error = e.toString();
        _loading = false;
      });
    }
  }

  void _pop() {
    if (context.canPop()) {
      context.pop();
    } else {
      context.go('/today');
    }
  }

  @override
  void dispose() {
    _hideControlsTimer?.cancel();
    _video?.removeListener(_onVideoUpdate);
    _video?.dispose();
    // Allow screen to sleep again after leaving the player.
    WakelockPlus.disable();
    _restoreSystemUi();
    super.dispose();
  }

  String _fmt(Duration d) {
    final m = d.inMinutes.remainder(60).toString().padLeft(2, '0');
    final s = d.inSeconds.remainder(60).toString().padLeft(2, '0');
    final h = d.inHours;
    if (h > 0) return '$h:$m:$s';
    return '$m:$s';
  }

  /// Immersive fullscreen 9:16 contain — full frame visible; letterbox OK on black.
  Widget _immersivePlayer() {
    final video = _video!;
    final playing = video.value.isPlaying;
    final pos = video.value.position;
    final dur = video.value.duration;
    final buffered = video.value.buffered.isEmpty
        ? Duration.zero
        : video.value.buffered.last.end;

    return Scaffold(
      backgroundColor: Colors.black,
      body: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: _videoCompleted ? null : _toggleControls,
        onDoubleTap: _videoCompleted
            ? null
            : () {
                if (playing) {
                  video.pause();
                } else {
                  video.play();
                }
                _revealControls();
              },
        child: Stack(
          fit: StackFit.expand,
          children: [
            const ColoredBox(color: Colors.black),
            // Full-frame contain (no crop; thin letterbox/pillarbox OK on black).
            Positioned.fill(
              child: FittedBox(
                fit: BoxFit.contain,
                clipBehavior: Clip.hardEdge,
                child: SizedBox(
                  width: video.value.size.width == 0
                      ? 1080
                      : video.value.size.width,
                  height: video.value.size.height == 0
                      ? 1920
                      : video.value.size.height,
                  child: VideoPlayer(video),
                ),
              ),
            ),
            // Soft gradient only while controls are visible (not a title overlay).
            if (!_videoCompleted)
              IgnorePointer(
                ignoring: !_showControls,
                child: AnimatedOpacity(
                  opacity: _showControls ? 1 : 0,
                  duration: const Duration(milliseconds: 180),
                  child: Stack(
                    fit: StackFit.expand,
                    children: [
                      const DecoratedBox(
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.topCenter,
                            end: Alignment.bottomCenter,
                            colors: [
                              Color(0x66000000),
                              Color(0x00000000),
                              Color(0x00000000),
                              Color(0x99000000),
                            ],
                            stops: [0, 0.22, 0.55, 1],
                          ),
                        ),
                      ),
                      SafeArea(
                        child: Stack(
                          children: [
                            // Left-center large return button (senior-friendly)
                            Positioned(
                              left: 12,
                              top: 0,
                              bottom: 0,
                              child: Center(
                                child: Semantics(
                                  button: true,
                                  label: 'Return to previous screen',
                                  child: Material(
                                    color: Colors.black54,
                                    borderRadius: BorderRadius.circular(28),
                                    child: InkWell(
                                      onTap: _pop,
                                      borderRadius: BorderRadius.circular(28),
                                      child: const SizedBox(
                                        width: 56,
                                        height: 56,
                                        child: Icon(
                                          Icons.arrow_back_rounded,
                                          color: Colors.white,
                                          size: 32,
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                            ),
                            // Center play / pause
                            Center(
                              child: IconButton(
                                onPressed: () {
                                  if (playing) {
                                    video.pause();
                                  } else {
                                    video.play();
                                  }
                                  _revealControls();
                                },
                                iconSize: 72,
                                color: Colors.white,
                                icon: Icon(
                                  playing
                                      ? Icons.pause_circle_filled_rounded
                                      : Icons.play_circle_filled_rounded,
                                ),
                              ),
                            ),
                            // Bottom progress bar
                            Positioned(
                              left: 16,
                              right: 16,
                              bottom: 12,
                              child: Column(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Row(
                                    children: [
                                      Text(
                                        _fmt(pos),
                                        style: const TextStyle(
                                          color: Colors.white70,
                                          fontSize: 12,
                                          fontFeatures: [
                                            FontFeature.tabularFigures(),
                                          ],
                                        ),
                                      ),
                                      const Spacer(),
                                      Text(
                                        _fmt(dur),
                                        style: const TextStyle(
                                          color: Colors.white70,
                                          fontSize: 12,
                                          fontFeatures: [
                                            FontFeature.tabularFigures(),
                                          ],
                                        ),
                                      ),
                                    ],
                                  ),
                                  SliderTheme(
                                    data: SliderTheme.of(context).copyWith(
                                      trackHeight: 3,
                                      thumbShape: const RoundSliderThumbShape(
                                        enabledThumbRadius: 7,
                                      ),
                                      overlayShape:
                                          const RoundSliderOverlayShape(
                                        overlayRadius: 14,
                                      ),
                                      activeTrackColor: AppColors.brand600,
                                      inactiveTrackColor: Colors.white24,
                                      thumbColor: Colors.white,
                                      overlayColor:
                                          AppColors.brand600.withOpacity(0.25),
                                    ),
                                    child: Slider(
                                      min: 0,
                                      max: dur.inMilliseconds <= 0
                                          ? 1
                                          : dur.inMilliseconds.toDouble(),
                                      value: pos.inMilliseconds
                                          .clamp(
                                            0,
                                            dur.inMilliseconds <= 0
                                                ? 1
                                                : dur.inMilliseconds,
                                          )
                                          .toDouble(),
                                      secondaryTrackValue:
                                          buffered.inMilliseconds
                                              .clamp(
                                                0,
                                                dur.inMilliseconds <= 0
                                                    ? 1
                                                    : dur.inMilliseconds,
                                              )
                                              .toDouble(),
                                      onChangeStart: (_) {
                                        _dragging = true;
                                        _hideControlsTimer?.cancel();
                                      },
                                      onChanged: (v) {
                                        video.seekTo(
                                          Duration(milliseconds: v.round()),
                                        );
                                        // Reset quiz if user seeks back to start.
                                        if (v < 2000 && _quizTriggered) {
                                          _quizTriggered = false;
                                        }
                                        // Reset completion if seeking back
                                        if (_videoCompleted) {
                                          _videoCompleted = false;
                                        }
                                      },
                                      onChangeEnd: (_) {
                                        _dragging = false;
                                        _scheduleHideControls();
                                      },
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            // Buffering spinner - suppress near end of video to avoid flash.
            if (_shouldShowBuffering())
              const Center(
                child: SizedBox(
                  width: 36,
                  height: 36,
                  child: CircularProgressIndicator(
                    strokeWidth: 3,
                    color: Colors.white70,
                  ),
                ),
              ),
            // Video completion overlay.
            if (_videoCompleted) _buildCompletionOverlay(),
            // In-video quiz overlay.
            if (_showQuizOverlay && _videoQuizConfig != null)
              VideoQuizOverlay(
                config: _videoQuizConfig!,
                onDismissed: _onQuizDismissed,
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildCompletionOverlay() {
    return Container(
      color: Colors.black.withOpacity(0.85),
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(
                Icons.check_circle_outline_rounded,
                color: Colors.white,
                size: 72,
              ),
              const SizedBox(height: 20),
              Text(
                'Video Complete',
                style: GoogleFonts.dmSans(
                  fontSize: 26,
                  fontWeight: FontWeight.w800,
                  color: Colors.white,
                ),
              ),
              if (_title != null && _title!.isNotEmpty) ...[
                const SizedBox(height: 8),
                Text(
                  _title!,
                  style: GoogleFonts.dmSans(
                    fontSize: 18,
                    fontWeight: FontWeight.w500,
                    color: Colors.white70,
                  ),
                  textAlign: TextAlign.center,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
              const SizedBox(height: 40),
              // Primary action: Back to Today
              Semantics(
                button: true,
                label: 'Return to Today timeline',
                child: SizedBox(
                  width: double.infinity,
                  height: 64,
                  child: FilledButton.icon(
                    onPressed: () => context.go('/today'),
                    icon: const Icon(Icons.home_rounded, size: 28),
                    label: Text(
                      'Back to Today',
                      style: GoogleFonts.dmSans(
                        fontSize: 20,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    style: FilledButton.styleFrom(
                      backgroundColor: AppColors.brand600,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              // Play next (if available)
              if (_nextContentId != null && _nextContentId!.isNotEmpty) ...[
                Semantics(
                  button: true,
                  label: 'Play next video',
                  child: SizedBox(
                    width: double.infinity,
                    height: 64,
                    child: OutlinedButton.icon(
                      onPressed: _playNextVideo,
                      icon: const Icon(Icons.skip_next_rounded, size: 28),
                      label: Text(
                        _nextContentTitle?.isNotEmpty == true
                            ? 'Play: ${_nextContentTitle!}'
                            : 'Play Next',
                        style: GoogleFonts.dmSans(
                          fontSize: 18,
                          fontWeight: FontWeight.w700,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: Colors.white,
                        side: const BorderSide(color: Colors.white54, width: 2),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
              ],
              // Replay option
              Semantics(
                button: true,
                label: 'Replay this video',
                child: TextButton.icon(
                  onPressed: () {
                    _dismissCompletionOverlay();
                    _video?.seekTo(Duration.zero);
                    _video?.play();
                    _quizTriggered = false; // Allow quiz to trigger again
                  },
                  icon: const Icon(Icons.replay_rounded, size: 24),
                  label: Text(
                    'Replay',
                    style: GoogleFonts.dmSans(
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  style: TextButton.styleFrom(
                    foregroundColor: Colors.white70,
                    minimumSize: const Size(120, 56),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_video != null &&
        _video!.value.isInitialized &&
        !_loading &&
        _error == null) {
      return _immersivePlayer();
    }

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: Text(_title ?? 'Watch'),
        actions: [
          if (_quizId != null && _quizId!.isNotEmpty)
            TextButton(
              onPressed: () => context.push('/quiz/$_quizId'),
              child: const Text(
                'Quiz',
                style: TextStyle(
                  color: AppColors.brand600,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
        ],
      ),
      body: _loading
          ? const LoadingBody()
          : _error != null
              ? ErrorBody(message: _error!)
              : _imageAudioBody(),
    );
  }

  Widget _imageAudioBody() {
    return ListView(
      padding: const EdgeInsets.all(20),
      children: [
        if (_imageUrl != null && _imageUrl!.isNotEmpty)
          ClipRRect(
            borderRadius: BorderRadius.circular(16),
            child: Image.network(
              _imageUrl!,
              fit: BoxFit.cover,
              errorBuilder: (_, __, ___) => Container(
                height: 200,
                color: AppColors.brand100,
                alignment: Alignment.center,
                child: const Icon(Icons.image,
                    size: 48, color: AppColors.brand600),
              ),
            ),
          )
        else
          Container(
            height: 180,
            decoration: BoxDecoration(
              color: AppColors.brand50,
              borderRadius: BorderRadius.circular(16),
            ),
            alignment: Alignment.center,
            child: Icon(
              _kind == 'game' ? Icons.extension : Icons.headphones,
              size: 56,
              color: AppColors.brand600,
            ),
          ),
        const SizedBox(height: 16),
        Text(
          _title ?? 'Content',
          style: const TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.w800,
            color: AppColors.brand900,
          ),
        ),
        if (_kind != null)
          Padding(
            padding: const EdgeInsets.only(top: 4),
            child: Text(
              _kind!,
              style: const TextStyle(color: AppColors.slate500),
            ),
          ),
        if (_audioUrl != null && _audioUrl!.isNotEmpty) ...[
          const SizedBox(height: 16),
          const Text(
            'Audio is available for this item. Open the stream URL in a player, or use video content when provided.',
            style: TextStyle(color: AppColors.slate600),
          ),
        ],
        if (_gameUrl != null && _gameUrl!.isNotEmpty) ...[
          const SizedBox(height: 16),
          PrimaryButton(
            label: 'Open game',
            onPressed: () {
              showAppToast(context, 'Game URL: $_gameUrl');
            },
          ),
        ],
        if (_quizId != null && _quizId!.isNotEmpty) ...[
          const SizedBox(height: 12),
          OutlinedButton(
            onPressed: () => context.push('/quiz/$_quizId'),
            child: const Text('Take quiz'),
          ),
        ],
        const SizedBox(height: 20),
        PrimaryButton(
          label: 'Mark related activity done on Today',
          onPressed: () => context.go('/today'),
        ),
      ],
    );
  }
}
