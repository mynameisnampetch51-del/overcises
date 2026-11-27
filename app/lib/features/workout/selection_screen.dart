import 'package:go_router/go_router.dart';
import 'package:material_ui/material_ui.dart';

import '../../core/theme/app_colors.dart';
import '../../core/widgets/app_header.dart';
import '../../core/widgets/page_body.dart';
import '../../core/widgets/two_columns.dart';
import 'exercise.dart';

/// Figma screen 02.
class WorkoutSelectionScreen extends StatelessWidget {
  const WorkoutSelectionScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: PageBody(
        maxWidth: PageBody.wide,
        children: [
          const AppHeader(
            label: 'Workout',
            title: "Choose today's exercise",
            showBack: true,
          ),
          TwoColumns(
            first: [_ExerciseCard(Exercise.values[0])],
            second: [_ExerciseCard(Exercise.values[1])],
          ),
        ],
      ),
    );
  }
}

class _ExerciseCard extends StatelessWidget {
  const _ExerciseCard(this.exercise);

  final Exercise exercise;

  @override
  Widget build(BuildContext context) {
    final path = '/home/workout/${exercise.slug}';
    // The theme makes buttons full width; these sit side by side.
    const compact = Size(96, 44);

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.deep,
        borderRadius: BorderRadius.circular(24),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  exercise.title,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 22,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                Text(
                  exercise.summary,
                  style: const TextStyle(color: AppColors.pastel),
                ),
                const SizedBox(height: 18),
                Wrap(
                  spacing: 10,
                  runSpacing: 8,
                  children: [
                    OutlinedButton(
                      key: Key('howto-${exercise.slug}'),
                      style: OutlinedButton.styleFrom(
                        minimumSize: compact,
                        foregroundColor: Colors.white,
                        side: const BorderSide(color: AppColors.skeleton),
                      ),
                      onPressed: () => context.go(path),
                      child: const Text('How to'),
                    ),
                    FilledButton(
                      key: Key('start-${exercise.slug}'),
                      style: FilledButton.styleFrom(minimumSize: compact),
                      onPressed: () => context.go('$path/active'),
                      child: const Text('Start'),
                    ),
                  ],
                ),
              ],
            ),
          ),
          Icon(exercise.icon, size: 72, color: AppColors.skeleton),
        ],
      ),
    );
  }
}
