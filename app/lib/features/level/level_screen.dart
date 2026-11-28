import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:material_ui/material_ui.dart';

import '../../core/theme/app_colors.dart';
import '../../core/widgets/app_header.dart';
import '../../core/widgets/level_card.dart';
import '../../core/widgets/page_body.dart';
import '../progress/progress.dart';

/// Figma screen 07, "My level".
class LevelScreen extends ConsumerWidget {
  const LevelScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final progress = ref.watch(myProgressProvider);

    return Scaffold(
      body: PageBody(
        children: [
          const AppHeader(
            label: 'Your progress',
            title: 'My level',
            showBack: true,
          ),
          LevelCard(progress: progress),
          const SizedBox(height: 22),
          const Text(
            'Next level reward',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: 6),
          Text(
            '+${PointsRules.levelBonus(progress.level)} Points when you reach '
            'Level ${progress.level + 1}',
          ),
          const SizedBox(height: 10),
          const Text(
            'Each recorded rep gives ${PointsRules.xpPerRep} XP and '
            '${PointsRules.perRep} Point.\n'
            'Reps give up to ${PointsRules.dailyCap} Points a day.\n'
            'Each level needs more XP than the one before.',
            style: TextStyle(color: AppColors.muted),
          ),
          const SizedBox(height: 28),
          FilledButton(
            onPressed: () => context.go('/home/workout'),
            child: const Text('Go work out'),
          ),
        ],
      ),
    );
  }
}
