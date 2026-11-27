import 'package:material_ui/material_ui.dart';

import '../theme/app_colors.dart';

/// A title, a bar, and a large "value / target" figure under it.
/// Layout after the progress cards on 21st.dev.
class ProgressCard extends StatelessWidget {
  const ProgressCard({
    super.key,
    required this.title,
    required this.value,
    required this.target,
    required this.unit,
    required this.note,
    this.color = Colors.white,
    this.onTap,
  });

  final String title;
  final int value;
  final int target;
  final String unit;
  final String note;
  final Color color;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: EdgeInsets.zero,
      color: color,
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                title,
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 12),
              LinearProgressIndicator(
                value: (value / target).clamp(0, 1).toDouble(),
                minHeight: 8,
                borderRadius: BorderRadius.circular(4),
                color: AppColors.primaryDark,
                backgroundColor: color == Colors.white
                    ? AppColors.pastel
                    : Colors.white,
                semanticsLabel: '$title progress',
              ),
              const SizedBox(height: 12),
              // Wraps instead of overflowing with large text.
              Wrap(
                alignment: WrapAlignment.spaceBetween,
                crossAxisAlignment: WrapCrossAlignment.end,
                spacing: 12,
                children: [
                  Text(note, style: const TextStyle(color: AppColors.muted)),
                  Text.rich(
                    TextSpan(
                      text: '$value',
                      style: const TextStyle(
                        fontSize: 26,
                        fontWeight: FontWeight.w800,
                        fontFeatures: [FontFeature.tabularFigures()],
                      ),
                      children: [
                        TextSpan(
                          text: ' / $target $unit',
                          style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w400,
                            color: AppColors.muted,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
