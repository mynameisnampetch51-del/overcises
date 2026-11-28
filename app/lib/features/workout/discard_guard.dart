import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_ui/material_ui.dart';

class _Flag extends Notifier<bool> {
  @override
  bool build() => false;

  void set(bool value) => state = value;

  /// Safe to call after the app has closed.
  void discard() {
    if (ref.mounted) state = false;
  }
}

/// True from "Start counting" until the workout is finished or discarded.
final workoutInProgressProvider = NotifierProvider<_Flag, bool>(_Flag.new);

/// True while the question is on screen, so nothing is counted meanwhile.
final discardPromptOpenProvider = NotifierProvider<_Flag, bool>(_Flag.new);

/// Call before anything that would throw away a workout. True means go ahead:
/// either none is in progress, or the user chose to leave it.
Future<bool> confirmDiscard(BuildContext context, WidgetRef ref) async {
  if (!ref.read(workoutInProgressProvider)) return true;

  // Read before waiting: the caller may be gone when the answer arrives.
  final inProgress = ref.read(workoutInProgressProvider.notifier);
  final promptOpen = ref.read(discardPromptOpenProvider.notifier);

  promptOpen.set(true);
  final leave = await showDialog<bool>(
    context: context,
    builder: (context) => AlertDialog(
      title: const Text('Leave this workout?'),
      content: const Text('Your reps and time will be lost.'),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(false),
          child: const Text('Keep going'),
        ),
        TextButton(
          onPressed: () => Navigator.of(context).pop(true),
          child: const Text('Leave'),
        ),
      ],
    ),
  );
  promptOpen.set(false);

  // Dismissing the question counts as "Keep going".
  if (leave != true) return false;
  inProgress.set(false);
  return true;
}
