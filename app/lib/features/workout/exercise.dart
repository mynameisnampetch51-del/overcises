import 'package:material_ui/material_ui.dart';

/// The exercises in the app.
enum Exercise {
  jumpingJack(
    slug: 'jumping-jack',
    title: 'Jumping jack',
    summary: 'Full body cardio',
    icon: Icons.accessibility_new,
    met: 8.0,
    cameraTip: 'Face the camera with your whole body in view.',
    steps: [
      'Find a flat, non-slippery space. Stand tall with feet together and '
          'arms by your sides.',
      'Jump your feet out wider than your shoulders while swinging your arms '
          'up over your head.',
      'Bring your hands close together above your head. Land softly with '
          'your knees slightly bent.',
      'Jump back to the start, feet together and arms down. That is 1 rep.',
    ],
  ),
  sitUp(
    slug: 'sit-up',
    title: 'Sit-up',
    summary: 'Core strength',
    icon: Icons.self_improvement,
    met: 3.8,
    cameraTip: 'Put the camera at your side with your whole body in view.',
    steps: [
      'Lie on your back on a mat with knees bent and feet flat on the floor.',
      'Cross your arms on your chest. Do not pull on your neck.',
      'Tighten your stomach and lift your upper body towards your knees.',
      'Lower slowly until your shoulders touch the floor. That is 1 rep.',
    ],
  );

  const Exercise({
    required this.slug,
    required this.title,
    required this.summary,
    required this.icon,
    required this.met,
    required this.cameraTip,
    required this.steps,
  });

  /// Used in the page address.
  final String slug;
  final String title;
  final String summary;
  final IconData icon;

  /// Effort value for the calorie estimate: MET x kg x hours.
  final double met;

  /// Where to put the phone so the whole movement is visible.
  final String cameraTip;
  final List<String> steps;

  static Exercise? fromSlug(String? slug) {
    for (final exercise in values) {
      if (exercise.slug == slug) return exercise;
    }
    return null;
  }
}
