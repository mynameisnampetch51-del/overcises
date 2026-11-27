import 'package:material_ui/material_ui.dart';

import '../theme/app_colors.dart';

/// The Overcise round logo.
class BrandMark extends StatelessWidget {
  const BrandMark({super.key, this.radius = 36});

  final double radius;

  @override
  Widget build(BuildContext context) {
    return CircleAvatar(
      radius: radius,
      backgroundColor: AppColors.primary,
      child: Icon(
        Icons.directions_run,
        size: radius * 1.15,
        color: AppColors.deepest,
      ),
    );
  }
}
