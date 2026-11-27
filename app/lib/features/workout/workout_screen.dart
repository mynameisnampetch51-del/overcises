import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:material_ui/material_ui.dart';

import '../../core/theme/app_colors.dart';
import '../../core/widgets/app_header.dart';
import '../../core/widgets/page_body.dart';
import '../../core/widgets/two_columns.dart';
import '../progress/progress.dart';
import 'camera_view.dart';
import 'discard_guard.dart';
import 'exercise.dart';
import 'permission_view.dart';
import 'pose_camera.dart';
import 'rep_counter.dart';
import 'summary_view.dart';

/// Figma screen 04.
///
/// Jumping jacks are counted from the camera where a pose model exists (the web
/// build). Everything else is DEMO mode: a timer makes up the reps and the
/// screen says so.
class ActiveWorkoutScreen extends ConsumerStatefulWidget {
  const ActiveWorkoutScreen({super.key, required this.exercise});

  final Exercise exercise;

  static const secondsPerSimulatedRep = 2;

  /// Exercises whose rule is connected to the camera. Sit-up is on hold.
  static const liveExercises = {Exercise.jumpingJack};

  @override
  ConsumerState<ActiveWorkoutScreen> createState() =>
      _ActiveWorkoutScreenState();
}

class _ActiveWorkoutScreenState extends ConsumerState<ActiveWorkoutScreen> {
  Timer? _timer;
  int _seconds = 0;
  int _reps = 0;
  bool _visible = true;
  WorkoutResult? _result;

  final _counter = JumpingJackCounter();
  bool _demoChosen = false;
  String _hint = 'Loading the pose model…';
  String? _poseError;

  bool get _live =>
      !_demoChosen &&
      ActiveWorkoutScreen.liveExercises.contains(widget.exercise) &&
      ref.read(poseCameraProvider) != null;

  bool get _running => _timer != null;

  // Kept because ref cannot be used in dispose.
  late final _inProgress = ref.read(workoutInProgressProvider.notifier);

  @override
  void initState() {
    super.initState();
    _inProgress;
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // False while another tab is showing: stop counting and the camera.
    _visible = TickerMode.valuesOf(context).enabled;
    if (!_visible) _stopTimer();
  }

  @override
  void dispose() {
    // Removed without asking (browser back, typed address): the workout is
    // gone, so drop the flag. Later, as providers cannot change in dispose.
    if (_result == null && (_seconds > 0 || _running)) {
      Future.microtask(_inProgress.discard);
    }
    _stopTimer();
    super.dispose();
  }

  void _stopTimer() {
    _timer?.cancel();
    _timer = null;
  }

  void _tick(Timer timer) {
    // Reps and time stay put while "Leave this workout?" is open.
    if (ref.read(discardPromptOpenProvider)) return;
    setState(() {
      _seconds++;
      if (!_live &&
          _seconds % ActiveWorkoutScreen.secondsPerSimulatedRep == 0) {
        _reps++;
      }
    });
  }

  /// One camera frame.
  void _onPose(Pose? pose) {
    if (!mounted || _result != null || !_live) return;

    final counted =
        pose != null &&
        _running &&
        !ref.read(discardPromptOpenProvider) &&
        _counter.update(pose);

    final String hint;
    if (pose == null || !JumpingJackCounter.seesBody(pose)) {
      hint = 'Step back until your whole body is in view';
    } else {
      final ratio = JumpingJackCounter.feetRatio(pose);
      final feet = ratio == null ? '' : ' (feet ${ratio.toStringAsFixed(1)})';
      hint = !_running
          ? 'Ready. Press Start counting$feet'
          : _counter.isReady
          ? 'Jump: hands up, feet apart$feet'
          : 'Hands down, feet together$feet';
    }

    if (counted || hint != _hint || _poseError != null) {
      setState(() {
        if (counted) _reps++;
        _hint = hint;
        _poseError = null;
      });
    }
  }

  void _onPoseError(String message) => setState(() => _poseError = message);

  void _toggle() {
    setState(() {
      if (_running) {
        _stopTimer();
      } else {
        _timer = Timer.periodic(const Duration(seconds: 1), _tick);
        ref.read(workoutInProgressProvider.notifier).set(true);
      }
    });
  }

  Future<void> _onSystemBack(bool didPop, Object? result) async {
    if (didPop) return;
    if (await confirmDiscard(context, ref) && mounted) context.pop();
  }

  void _finish() {
    _stopTimer();
    ref.read(workoutInProgressProvider.notifier).set(false);
    final result = ref
        .read(progressStoreProvider.notifier)
        .finishWorkout(
          exercise: widget.exercise,
          reps: _reps,
          seconds: _seconds,
        );
    setState(() => _result = result);
  }

  @override
  Widget build(BuildContext context) {
    final result = _result;
    if (result != null) return Scaffold(body: SummaryView(result: result));

    if (!ref.watch(cameraConsentProvider)) {
      return Scaffold(
        body: PermissionView(
          onAllow: ref.read(cameraConsentProvider.notifier).allow,
        ),
      );
    }

    final started = _seconds > 0 || _running;
    final live = _live;
    final size = MediaQuery.sizeOf(context);

    return PopScope(
      canPop: !ref.watch(workoutInProgressProvider),
      onPopInvokedWithResult: _onSystemBack,
      child: Scaffold(
        body: PageBody(
          maxWidth: PageBody.wide,
          children: [
            AppHeader(
              label: 'Working out',
              title: widget.exercise.title,
              showBack: true,
            ),
            TwoColumns(
              first: [
                Container(
                  // Short enough that Start stays on a phone screen.
                  // Taller for live counting on a big screen, so the skeleton
                  // can be seen.
                  height: live && size.width >= 600
                      ? (size.height * 0.55).clamp(240, 520)
                      : (size.height * 0.3).clamp(200, 420),
                  clipBehavior: Clip.antiAlias,
                  decoration: BoxDecoration(
                    color: AppColors.deepest,
                    borderRadius: BorderRadius.circular(24),
                  ),
                  child: Stack(
                    fit: StackFit.expand,
                    children: [
                      if (_visible)
                        if (live)
                          ref.watch(poseCameraProvider)!(
                            onPose: _onPose,
                            onError: _onPoseError,
                          )
                        else
                          ref.watch(cameraViewProvider)(),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          // Room for the "Camera not available" line.
                          const SizedBox(height: 32),
                          Expanded(
                            child: Align(
                              alignment: Alignment.topLeft,
                              child: Padding(
                                padding: const EdgeInsets.only(left: 10),
                                child: _BigReps(reps: _reps),
                              ),
                            ),
                          ),
                          Container(
                            color: AppColors.deepest.withValues(alpha: 0.75),
                            padding: const EdgeInsets.all(8),
                            child: Text(
                              live
                                  ? _poseError ?? _hint
                                  : widget.exercise.cameraTip,
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: live ? 18 : 14,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
              second: [
                if (live)
                  _Notice(
                    icon: Icons.videocam_outlined,
                    text:
                        _poseError ??
                        'Live counting: your camera counts jumping jacks on '
                            'this device.',
                    // The backup. Not offered mid-workout unless it failed,
                    // so counted and made-up reps are not mixed.
                    onUseDemo: started && _poseError == null
                        ? null
                        : () => setState(() => _demoChosen = true),
                  )
                else
                  const _Notice(
                    icon: Icons.info_outline,
                    text:
                        'Demo mode: reps are simulated. The camera is not '
                        'counting yet.',
                  ),
                const SizedBox(height: 14),
                _Stat(value: formatTime(_seconds), label: 'time'),
                const SizedBox(height: 18),
                FilledButton(
                  onPressed: _toggle,
                  child: Text(
                    _running
                        ? 'Pause'
                        : started
                        ? 'Resume'
                        : 'Start counting',
                  ),
                ),
                const SizedBox(height: 10),
                OutlinedButton(
                  onPressed: started ? _finish : null,
                  child: const Text('Finish and see result'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _Notice extends StatelessWidget {
  const _Notice({required this.icon, required this.text, this.onUseDemo});

  final IconData icon;
  final String text;
  final VoidCallback? onUseDemo;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.pastel,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: AppColors.deep),
              const SizedBox(width: 10),
              Expanded(child: Text(text)),
            ],
          ),
          if (onUseDemo != null)
            TextButton(
              onPressed: onUseDemo,
              child: const Text('Use demo mode instead'),
            ),
        ],
      ),
    );
  }
}

/// The rep count, large enough to read from across the room.
class _BigReps extends StatelessWidget {
  const _BigReps({required this.reps});

  final int reps;

  @override
  Widget build(BuildContext context) {
    // Shrinks rather than overflows with large system text.
    return FittedBox(
      fit: BoxFit.scaleDown,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 20),
        decoration: BoxDecoration(
          color: AppColors.deepest.withValues(alpha: 0.7),
          borderRadius: BorderRadius.circular(24),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.baseline,
          textBaseline: TextBaseline.alphabetic,
          children: [
            Text(
              '$reps',
              key: const Key('big-reps'),
              style: const TextStyle(
                color: Colors.white,
                fontSize: 96,
                height: 1,
                fontWeight: FontWeight.w800,
                fontFeatures: [FontFeature.tabularFigures()],
              ),
            ),
            const SizedBox(width: 8),
            const Text(
              'reps',
              style: TextStyle(color: Colors.white, fontSize: 18),
            ),
          ],
        ),
      ),
    );
  }
}

class _Stat extends StatelessWidget {
  const _Stat({required this.value, required this.label});

  final String value;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: EdgeInsets.zero,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            FittedBox(
              fit: BoxFit.scaleDown,
              child: Text(
                value,
                style: const TextStyle(
                  fontSize: 44,
                  fontWeight: FontWeight.w800,
                  color: AppColors.deep,
                  fontFeatures: [FontFeature.tabularFigures()],
                ),
              ),
            ),
            Text(label, style: const TextStyle(color: AppColors.muted)),
          ],
        ),
      ),
    );
  }
}
