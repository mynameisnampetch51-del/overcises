import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:material_ui/material_ui.dart';

import '../../core/theme/app_colors.dart';
import '../../core/widgets/app_header.dart';
import '../../core/widgets/page_body.dart';
import '../progress/progress.dart';
import '../quests/quest.dart';

String formatTime(int seconds) =>
    '${seconds ~/ 60}:${(seconds % 60).toString().padLeft(2, '0')}';

/// Figma screen 05: the Workout Summary.
class SummaryView extends ConsumerWidget {
  const SummaryView({super.key, required this.result});

  final WorkoutResult result;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final total = result.points + result.levelBonus;
    final ready = questsReady(ref.watch(myProgressProvider));

    return PageBody(
      children: [
        const AppHeader(label: 'Workout Summary', title: 'Result'),
        Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: AppColors.deep,
            borderRadius: BorderRadius.circular(24),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                result.exercise.title,
                style: const TextStyle(color: AppColors.pastel),
              ),
              Text(
                '+$total',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 64,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const Text(
                'Points earned',
                style: TextStyle(color: AppColors.skeleton),
              ),
            ],
          ),
        ),
        const SizedBox(height: 14),
        Card(
          margin: EdgeInsets.zero,
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              children: [
                _Row('Reps', '${result.reps}'),
                _Row('Time', formatTime(result.seconds)),
                _Row(
                  'Calories (estimate)',
                  '${result.calories.toStringAsFixed(1)} kcal',
                ),
                _Row('Experience', '+${result.xp} XP'),
                if (result.levelBonus > 0)
                  _Row('Level bonus', '+${result.levelBonus} Points'),
              ],
            ),
          ),
        ),
        if (result.capped)
          const Padding(
            padding: EdgeInsets.only(top: 10),
            child: Text(
              'You reached the daily limit of ${PointsRules.dailyCap} Points.',
              style: TextStyle(color: AppColors.muted),
            ),
          ),
        const SizedBox(height: 22),
        if (ready > 0) ...[
          Text(
            questsReadyText(ready),
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: AppColors.primaryDark,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 10),
        ],
        FilledButton(
          onPressed: () {
            // Reset the Home tab first, so it does not keep this summary.
            final router = GoRouter.of(context)..go('/home');
            WidgetsBinding.instance.addPostFrameCallback(
              (_) => router.go('/quests'),
            );
          },
          child: const Text("See today's Quests →"),
        ),
        const SizedBox(height: 10),
        OutlinedButton(
          onPressed: () => context.go('/home'),
          child: const Text('Back to Home'),
        ),
      ],
    );
  }
}

class _Row extends StatelessWidget {
  const _Row(this.label, this.value);

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          Expanded(child: Text(label)),
          Text(
            value,
            style: const TextStyle(
              fontWeight: FontWeight.w800,
              fontFeatures: [FontFeature.tabularFigures()],
            ),
          ),
        ],
      ),
    );
  }
}
