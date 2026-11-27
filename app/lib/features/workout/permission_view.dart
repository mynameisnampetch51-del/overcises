import 'package:material_ui/material_ui.dart';

import '../../core/theme/app_colors.dart';
import '../../core/widgets/app_header.dart';
import '../../core/widgets/page_body.dart';

/// Figma "Your Permission": asked once, before the camera opens.
class PermissionView extends StatelessWidget {
  const PermissionView({super.key, required this.onAllow});

  final VoidCallback onAllow;

  @override
  Widget build(BuildContext context) {
    return PageBody(
      children: [
        const AppHeader(
          label: 'Before you start',
          title: 'Your permission',
          showBack: true,
        ),
        for (final (icon, text) in const [
          (
            Icons.videocam_outlined,
            'Overcise uses your camera so you can see yourself while you '
                'work out.',
          ),
          (
            Icons.lock_outline,
            'In this demo the picture stays on your device. Nothing is '
                'recorded or uploaded.',
          ),
        ])
          Card(
            margin: const EdgeInsets.only(bottom: 12),
            child: ListTile(
              leading: Icon(icon, color: AppColors.primaryDark),
              title: Text(text),
            ),
          ),
        const SizedBox(height: 12),
        FilledButton(
          onPressed: onAllow,
          child: const Text('Allow camera and continue'),
        ),
      ],
    );
  }
}
