import 'package:material_ui/material_ui.dart';

import '../../features/progress/progress.dart';
import '../theme/app_colors.dart';
import 'progress_card.dart';

/// Level and XP. Used on Home and My level.
class LevelCard extends StatelessWidget {
  const LevelCard({super.key, required this.progress, this.onTap});

  final UserProgress progress;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return ProgressCard(
      title: 'Level ${progress.level}',
      value: progress.xpIntoLevel,
      target: progress.xpForNextLevel,
      unit: 'XP',
      note: onTap == null ? 'Progress' : 'See progress and bonus →',
      color: AppColors.pastel,
      onTap: onTap,
    );
  }
}
