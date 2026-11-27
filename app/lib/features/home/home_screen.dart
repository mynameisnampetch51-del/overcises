import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:material_ui/material_ui.dart';

import '../../core/layout/breakpoints.dart';
import '../../core/theme/app_colors.dart';
import '../../core/widgets/app_header.dart';
import '../../core/widgets/level_card.dart';
import '../../core/widgets/page_body.dart';
import '../../core/widgets/progress_card.dart';
import '../../core/widgets/two_columns.dart';
import '../auth/application/auth_controller.dart';
import '../progress/progress.dart';
import '../quests/quest.dart';

class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final name = ref.watch(authControllerProvider).user?.name ?? '';
    final progress = ref.watch(myProgressProvider);
    final ready = questsReady(progress);

    return Scaffold(
      body: PageBody(
        maxWidth: PageBody.wide,
        children: [
          AppHeader(
            label: 'Hi, $name',
            title: 'Ready to move?',
            // The side rail has its own Log out button.
            trailing: Breakpoints.useRail(context)
                ? null
                : IconButton(
                    tooltip: 'Log out',
                    icon: const Icon(Icons.logout),
                    onPressed: () =>
                        ref.read(authControllerProvider.notifier).signOut(),
                  ),
          ),
          TwoColumns(
            first: [
              _PointsCard(
                balance: progress.balance,
                onTap: () => context.go('/rewards'),
              ),
              const SizedBox(height: 14),
              FilledButton(
                onPressed: () => context.go('/home/workout'),
                child: const Text('Start workout →'),
              ),
            ],
            second: [
              LevelCard(
                progress: progress,
                onTap: () => context.go('/home/level'),
              ),
              const SizedBox(height: 14),
              ProgressCard(
                title: 'Today',
                value: progress.todayPoints,
                target: PointsRules.dailyCap,
                unit: 'Points',
                note: 'Daily limit',
              ),
              const SizedBox(height: 14),
              Card(
                margin: EdgeInsets.zero,
                clipBehavior: Clip.antiAlias,
                child: ListTile(
                  onTap: () => context.go('/quests'),
                  title: const Text(
                    "Today's Quests",
                    style: TextStyle(fontWeight: FontWeight.w700),
                  ),
                  subtitle: Text(
                    ready > 0
                        ? questsReadyText(ready)
                        : '${progress.claimedQuests.length} of '
                              '${Quest.values.length} claimed',
                  ),
                  trailing: const Icon(Icons.arrow_forward),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _PointsCard extends StatelessWidget {
  const _PointsCard({required this.balance, required this.onTap});

  final int balance;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: EdgeInsets.zero,
      color: AppColors.deep,
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Points to redeem',
                      style: TextStyle(color: AppColors.pastel),
                    ),
                    FittedBox(
                      fit: BoxFit.scaleDown,
                      child: Text(
                        '$balance',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 64,
                          fontWeight: FontWeight.w800,
                          fontFeatures: [FontFeature.tabularFigures()],
                        ),
                      ),
                    ),
                    const Text(
                      'See Rewards ↗',
                      style: TextStyle(color: AppColors.skeleton),
                    ),
                  ],
                ),
              ),
              // Stands in for the Figma mascot until the art is exported.
              const Icon(
                Icons.directions_run,
                size: 96,
                color: AppColors.skeleton,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
