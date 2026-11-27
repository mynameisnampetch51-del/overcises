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
import 'summary_view.dart';

/// Figma screen 04.
///
/// DEMO: no pose model is connected. Reps are made up by a timer and the
/// screen says so. Replace [_tick] when real counting is added.
class ActiveWorkoutScreen extends ConsumerStatefulWidget {
  const ActiveWorkoutScreen({super.key, required this.exercise});

  final Exercise exercise;

  static const secondsPerSimulatedRep = 2;

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
      if (_seconds % ActiveWorkoutScreen.secondsPerSimulatedRep == 0) _reps++;
    });
  }

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
                  height: (MediaQuery.sizeOf(context).height * 0.3).clamp(
                    200,
                    420,
                  ),
                  clipBehavior: Clip.antiAlias,
                  decoration: BoxDecoration(
                    color: AppColors.deepest,
                    borderRadius: BorderRadius.circular(24),
                  ),
                  child: Stack(
                    fit: StackFit.expand,
                    children: [
                      if (_visible) ref.watch(cameraViewProvider)(),
                      Column(
                        children: [
                          // Room for the "Camera not available" line.
                          const SizedBox(height: 32),
                          Expanded(
                            child: Center(child: _BigReps(reps: _reps)),
                          ),
                          Container(
                            width: double.infinity,
                            color: AppColors.deepest.withValues(alpha: 0.75),
                            padding: const EdgeInsets.all(8),
                            child: Text(
                              widget.exercise.cameraTip,
                              textAlign: TextAlign.center,
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 14,
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
                const _DemoNotice(),
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

class _DemoNotice extends StatelessWidget {
  const _DemoNotice();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.pastel,
        borderRadius: BorderRadius.circular(14),
      ),
      child: const Row(
        children: [
          Icon(Icons.info_outline, color: AppColors.deep),
          SizedBox(width: 10),
          Expanded(
            child: Text(
              'Demo mode: reps are simulated. The camera is not counting yet.',
            ),
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
