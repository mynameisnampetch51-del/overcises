import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:material_ui/material_ui.dart';

import '../../features/workout/discard_guard.dart';
import '../layout/breakpoints.dart';
import '../theme/app_colors.dart';
import 'brand_mark.dart';

/// Figma header: logo row, a small label, then the page title.
class AppHeader extends ConsumerWidget {
  const AppHeader({
    super.key,
    required this.label,
    required this.title,
    this.showBack = false,
    this.trailing,
  });

  final String label;
  final String title;
  final bool showBack;
  final Widget? trailing;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            height: 48,
            child: Row(
              children: [
                if (!Breakpoints.useRail(context)) ...const [
                  BrandMark(radius: 14),
                  SizedBox(width: 8),
                  Text(
                    'Overcise',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800),
                  ),
                ],
                const Spacer(),
                if (showBack)
                  TextButton.icon(
                    onPressed: () async {
                      if (await confirmDiscard(context, ref) &&
                          context.mounted) {
                        context.pop();
                      }
                    },
                    icon: const Icon(Icons.arrow_back, size: 18),
                    label: const Text('Back'),
                  ),
                ?trailing,
              ],
            ),
          ),
          const SizedBox(height: 10),
          Text(
            label,
            style: const TextStyle(color: AppColors.muted, fontSize: 13),
          ),
          Text(
            title,
            style: Theme.of(context).textTheme.headlineSmall
                ?.copyWith(fontWeight: FontWeight.w800),
          ),
        ],
      ),
    );
  }
}
