import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:material_ui/material_ui.dart';

import '../../core/theme/app_colors.dart';
import '../../core/widgets/app_header.dart';
import '../../core/widgets/page_body.dart';
import '../../core/widgets/two_columns.dart';
import '../progress/progress.dart';
import '../workout/discard_guard.dart';
import '../workout/summary_view.dart' show formatTime;
import 'quest.dart';

/// Figma screen 06.
class QuestsScreen extends ConsumerWidget {
  const QuestsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final progress = ref.watch(myProgressProvider);

    Widget card(Quest quest) => _QuestCard(
      quest: quest,
      progress: progress,
      onTrain: () async {
        if (await confirmDiscard(context, ref) && context.mounted) {
          context.go('/home/workout');
        }
      },
      onClaim: () {
        ref.read(progressStoreProvider.notifier).claimQuest(quest);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('+${quest.reward} bonus Points')),
        );
      },
    );

    return Scaffold(
      body: PageBody(
        maxWidth: PageBody.wide,
        children: [
          const AppHeader(label: 'New every day', title: 'Daily Quests'),
          TwoColumns(
            first: [
              card(Quest.getMoving),
              const SizedBox(height: 16),
              card(Quest.thirtyReps),
            ],
            second: [card(Quest.tenMinutes)],
          ),
        ],
      ),
    );
  }
}

class _QuestCard extends StatelessWidget {
  const _QuestCard({
    required this.quest,
    required this.progress,
    required this.onClaim,
    required this.onTrain,
  });

  final Quest quest;
  final UserProgress progress;
  final VoidCallback onClaim;
  final VoidCallback onTrain;

  @override
  Widget build(BuildContext context) {
    final done = quest.done(progress);
    final claimed = quest.isClaimed(progress);
    // The 10 minute Quest reads better as a clock.
    final amount = quest == Quest.tenMinutes
        ? '${formatTime(done)} / ${formatTime(quest.target)}'
        : '$done / ${quest.target}';

    return Card(
      margin: EdgeInsets.zero,
      color: claimed ? AppColors.pastel : Colors.white,
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Wrap(
              alignment: WrapAlignment.spaceBetween,
              spacing: 12,
              children: [
                Text(
                  quest.difficulty,
                  style: const TextStyle(color: AppColors.muted),
                ),
                Text(
                  '+${quest.reward} Points',
                  style: const TextStyle(
                    color: AppColors.primaryDark,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ],
            ),
            Text(
              quest.title,
              style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w800),
            ),
            Text(quest.detail),
            const SizedBox(height: 12),
            LinearProgressIndicator(
              value: done / quest.target,
              minHeight: 8,
              borderRadius: BorderRadius.circular(4),
              color: AppColors.primaryDark,
              backgroundColor: claimed ? Colors.white : AppColors.pastel,
              semanticsLabel: '${quest.title} progress',
            ),
            const SizedBox(height: 8),
            Text(amount, style: const TextStyle(color: AppColors.muted)),
            const SizedBox(height: 12),
            if (claimed)
              FilledButton.icon(
                key: Key('claim-${quest.name}'),
                onPressed: null,
                icon: const Icon(Icons.check),
                label: const Text('Claimed'),
              )
            else if (quest.isComplete(progress))
              FilledButton(
                key: Key('claim-${quest.name}'),
                onPressed: onClaim,
                child: Text('Claim +${quest.reward}'),
              )
            else
              OutlinedButton(
                key: Key('train-${quest.name}'),
                onPressed: onTrain,
                child: const Text('Go train →'),
              ),
          ],
        ),
      ),
    );
  }
}
