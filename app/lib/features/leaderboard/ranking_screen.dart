import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:material_ui/material_ui.dart';

import '../../core/theme/app_colors.dart';
import '../../core/widgets/app_header.dart';
import '../../core/widgets/page_body.dart';
import '../../core/widgets/two_columns.dart';
import '../progress/progress.dart';
import '../workout/discard_guard.dart';
import 'ranking.dart';

const _months = [
  'January',
  'February',
  'March',
  'April',
  'May',
  'June',
  'July',
  'August',
  'September',
  'October',
  'November',
  'December',
];

typedef _Entry = ({int place, String name, int points, bool isMe});

/// Everyone in order, with the signed-in user at their place.
List<_Entry> _standings(int myPoints) {
  final players =
      [
        for (final p in otherPlayers)
          (name: p.name, points: p.points, isMe: false),
      ]..insert(rankFor(myPoints).place - 1, (
        name: 'You',
        points: myPoints,
        isMe: true,
      ));
  return [
    for (final (index, p) in players.indexed)
      (place: index + 1, name: p.name, points: p.points, isMe: p.isMe),
  ];
}

/// Figma screen 08, with a podium for the top three.
class RankingScreen extends ConsumerWidget {
  const RankingScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final points = ref.watch(myProgressProvider).monthPoints;
    final entries = _standings(points);

    return Scaffold(
      body: PageBody(
        maxWidth: PageBody.wide,
        children: [
          AppHeader(
            label: '${_months[DateTime.now().month - 1]} season',
            title: 'Monthly Ranking',
          ),
          TwoColumns(
            first: [
              _MyPlaceCard(
                rank: rankFor(points),
                points: points,
                onEarnMore: () async {
                  if (await confirmDiscard(context, ref) && context.mounted) {
                    context.go('/home/workout');
                  }
                },
              ),
              const SizedBox(height: 16),
              _Podium(entries.take(3).toList()),
              const SizedBox(height: 12),
              const Text(
                'The other players are sample data. Spending Points on '
                'Rewards does not lower your Ranking.',
                style: TextStyle(color: AppColors.muted, fontSize: 13),
              ),
            ],
            second: [
              for (final entry in entries.skip(3)) ...[
                _PlayerRow(entry),
                if (entry.place == rewardPlaces) const _RewardLine(),
              ],
            ],
          ),
        ],
      ),
    );
  }
}

class _MyPlaceCard extends StatelessWidget {
  const _MyPlaceCard({
    required this.rank,
    required this.points,
    required this.onEarnMore,
  });

  final MyRank rank;
  final int points;
  final VoidCallback onEarnMore;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: AppColors.deep,
        borderRadius: BorderRadius.circular(24),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Your place', style: TextStyle(color: AppColors.pastel)),
          Text(
            '#${rank.place}',
            style: const TextStyle(
              color: Colors.white,
              fontSize: 56,
              fontWeight: FontWeight.w800,
              fontFeatures: [FontFeature.tabularFigures()],
            ),
          ),
          Text(
            '$points Points this month',
            style: const TextStyle(color: Colors.white),
          ),
          const SizedBox(height: 8),
          Text(
            rank.inRewardZone
                ? 'You are in the top $rewardPlaces. Top $rewardPlaces '
                      'Rewards are coming soon.'
                : '${rank.pointsToRewardZone} more Points to reach the top '
                      '$rewardPlaces.',
            style: const TextStyle(color: AppColors.skeleton),
          ),
          TextButton(
            style: TextButton.styleFrom(
              foregroundColor: Colors.white,
              padding: EdgeInsets.zero,
            ),
            onPressed: onEarnMore,
            child: const Text('Earn more Points →'),
          ),
        ],
      ),
    );
  }
}

/// First place in the middle and tallest.
class _Podium extends StatelessWidget {
  const _Podium(this.top);

  final List<_Entry> top;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        Expanded(child: _PodiumStep(top[1], height: 108)),
        const SizedBox(width: 8),
        Expanded(child: _PodiumStep(top[0], height: 136)),
        const SizedBox(width: 8),
        Expanded(child: _PodiumStep(top[2], height: 92)),
      ],
    );
  }
}

class _PodiumStep extends StatelessWidget {
  const _PodiumStep(this.entry, {required this.height});

  final _Entry entry;
  final double height;

  @override
  Widget build(BuildContext context) {
    return Container(
      // Grows with large text instead of overflowing.
      constraints: BoxConstraints(minHeight: height),
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: entry.isMe ? AppColors.skeleton : AppColors.pastel,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            '#${entry.place}',
            style: const TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.w800,
              color: AppColors.deep,
            ),
          ),
          Text(
            entry.name,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(fontWeight: FontWeight.w700),
          ),
          Text(
            '${entry.points}',
            style: const TextStyle(color: AppColors.muted),
          ),
        ],
      ),
    );
  }
}

class _PlayerRow extends StatelessWidget {
  const _PlayerRow(this.entry);

  final _Entry entry;

  @override
  Widget build(BuildContext context) {
    final weight = entry.isMe ? FontWeight.w800 : FontWeight.w500;

    return Container(
      key: entry.isMe ? const Key('my-row') : null,
      margin: const EdgeInsets.only(bottom: 6),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: entry.isMe ? AppColors.pastel : Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: entry.isMe ? AppColors.primaryDark : AppColors.pastel,
          width: entry.isMe ? 2 : 1,
        ),
      ),
      child: Row(
        children: [
          SizedBox(
            width: 36,
            child: Text(
              '${entry.place}',
              style: const TextStyle(color: AppColors.muted),
            ),
          ),
          Expanded(
            child: Text(entry.name, style: TextStyle(fontWeight: weight)),
          ),
          Text(
            '${entry.points}',
            style: TextStyle(
              fontWeight: weight,
              fontFeatures: const [FontFeature.tabularFigures()],
            ),
          ),
        ],
      ),
    );
  }
}

class _RewardLine extends StatelessWidget {
  const _RewardLine();

  @override
  Widget build(BuildContext context) {
    return const Padding(
      padding: EdgeInsets.only(top: 6, bottom: 12),
      child: Text(
        'Top $rewardPlaces Rewards (coming soon) above this line',
        textAlign: TextAlign.center,
        style: TextStyle(
          color: AppColors.primaryDark,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}
