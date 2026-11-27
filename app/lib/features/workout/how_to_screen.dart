import 'package:go_router/go_router.dart';
import 'package:material_ui/material_ui.dart';

import '../../core/theme/app_colors.dart';
import '../../core/widgets/app_header.dart';
import '../../core/widgets/page_body.dart';
import '../../core/widgets/two_columns.dart';
import 'exercise.dart';

/// Figma screen 03: the Guide for one exercise.
class HowToScreen extends StatelessWidget {
  const HowToScreen({super.key, required this.exercise});

  final Exercise exercise;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: PageBody(
        maxWidth: PageBody.wide,
        children: [
          AppHeader(label: 'How to', title: exercise.title, showBack: true),
          TwoColumns(
            first: [
              Container(
                height: 180,
                decoration: BoxDecoration(
                  color: AppColors.deep,
                  borderRadius: BorderRadius.circular(24),
                ),
                // Stands in for the Figma illustration.
                child: Icon(exercise.icon, size: 96, color: AppColors.skeleton),
              ),
              const SizedBox(height: 14),
              Card(
                margin: EdgeInsets.zero,
                color: AppColors.pastel,
                child: ListTile(
                  leading: const Icon(
                    Icons.videocam_outlined,
                    color: AppColors.primaryDark,
                  ),
                  title: Text(exercise.cameraTip),
                ),
              ),
            ],
            second: [
              for (final (index, step) in exercise.steps.indexed)
                Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      CircleAvatar(
                        radius: 13,
                        backgroundColor: AppColors.pastel,
                        child: Text(
                          '${index + 1}',
                          style: const TextStyle(
                            color: AppColors.deepest,
                            fontWeight: FontWeight.w800,
                            fontSize: 13,
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(child: Text(step)),
                    ],
                  ),
                ),
              const SizedBox(height: 6),
              FilledButton(
                onPressed: () =>
                    context.go('/home/workout/${exercise.slug}/active'),
                child: const Text('Try it! →'),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
