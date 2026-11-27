import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:material_ui/material_ui.dart';

import '../../core/theme/app_colors.dart';
import '../../core/widgets/app_header.dart';
import '../../core/widgets/page_body.dart';
import '../../core/widgets/two_columns.dart';
import '../progress/progress.dart';

/// Discounts on offer (Figma screen 09).
const rewardOffers = <({int percent, int cost})>[
  (percent: 10, cost: 100),
  (percent: 20, cost: 220),
];

class RewardsScreen extends ConsumerWidget {
  const RewardsScreen({super.key});

  Future<void> _redeem(
    BuildContext context,
    WidgetRef ref, {
    required int percent,
    required int cost,
  }) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Redeem $percent% discount?'),
        content: Text('This uses $cost Points. Your Ranking does not change.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Redeem'),
          ),
        ],
      ),
    );
    if (confirmed != true || !context.mounted) return;

    final done = ref
        .read(progressStoreProvider.notifier)
        .redeem(percent: percent, cost: cost);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(done ? 'Coupon added' : 'Not enough Points')),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final progress = ref.watch(myProgressProvider);

    return Scaffold(
      body: PageBody(
        maxWidth: PageBody.wide,
        children: [
          const AppHeader(label: 'Use your Points', title: 'Fitness discounts'),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: AppColors.deep,
              borderRadius: BorderRadius.circular(20),
            ),
            child: Wrap(
              alignment: WrapAlignment.spaceBetween,
              crossAxisAlignment: WrapCrossAlignment.center,
              spacing: 12,
              children: [
                const Text(
                  'Balance',
                  style: TextStyle(color: AppColors.pastel),
                ),
                Text(
                  '${progress.balance} Points',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 22,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: TwoColumns.gap),
          Builder(
            builder: (context) {
              final cards = [
                for (final offer in rewardOffers)
                  _OfferCard(
                    percent: offer.percent,
                    cost: offer.cost,
                    balance: progress.balance,
                    onRedeem: () => _redeem(
                      context,
                      ref,
                      percent: offer.percent,
                      cost: offer.cost,
                    ),
                  ),
              ];
              return TwoColumns(first: [cards[0]], second: [cards[1]]);
            },
          ),
          const SizedBox(height: 10),
          const Text(
            'Sample coupons for the demo. Not valid at any shop.',
            style: TextStyle(color: AppColors.muted, fontSize: 12),
          ),
          const SizedBox(height: 22),
          Text(
            'My coupons · ${progress.coupons.length}',
            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: 10),
          if (progress.coupons.isEmpty)
            const Text(
              'No coupons yet.',
              style: TextStyle(color: AppColors.muted),
            ),
          for (final coupon in progress.coupons.reversed)
            Card(
              margin: const EdgeInsets.only(bottom: 10),
              child: ListTile(
                leading: const Icon(
                  Icons.confirmation_number_outlined,
                  color: AppColors.primaryDark,
                ),
                title: Text('${coupon.percent}% fitness discount'),
                subtitle: Text(coupon.code),
              ),
            ),
        ],
      ),
    );
  }
}

class _OfferCard extends StatelessWidget {
  const _OfferCard({
    required this.percent,
    required this.cost,
    required this.balance,
    required this.onRedeem,
  });

  final int percent;
  final int cost;
  final int balance;
  final VoidCallback onRedeem;

  @override
  Widget build(BuildContext context) {
    final affordable = balance >= cost;

    return Card(
      margin: EdgeInsets.zero,
      color: AppColors.pastel,
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Text('Fitness discount'),
            Text(
              '$percent%',
              style: const TextStyle(fontSize: 40, fontWeight: FontWeight.w800),
            ),
            LinearProgressIndicator(
              value: (balance / cost).clamp(0, 1).toDouble(),
              minHeight: 8,
              borderRadius: BorderRadius.circular(4),
              color: AppColors.primaryDark,
              backgroundColor: Colors.white,
              semanticsLabel: 'Points towards $percent% discount',
            ),
            const SizedBox(height: 8),
            Text(
              affordable
                  ? 'Ready to redeem'
                  : '${cost - balance} more Points needed',
              style: const TextStyle(color: AppColors.muted, fontSize: 13),
            ),
            const SizedBox(height: 14),
            FilledButton(
              onPressed: affordable ? onRedeem : null,
              child: Text('Redeem $cost'),
            ),
          ],
        ),
      ),
    );
  }
}
