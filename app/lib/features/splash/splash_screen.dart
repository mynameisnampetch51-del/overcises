import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:material_ui/material_ui.dart';

import '../../core/theme/app_colors.dart';
import '../../core/widgets/brand_mark.dart';
import '../auth/application/auth_controller.dart';

/// Shown on launch while the app checks whether someone is logged in.
class SplashScreen extends ConsumerStatefulWidget {
  const SplashScreen({super.key});

  /// Long enough to see the logo, even when the check is instant.
  static const minimumTime = Duration(milliseconds: 1500);

  @override
  ConsumerState<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends ConsumerState<SplashScreen> {
  @override
  void initState() {
    super.initState();
    // Providers must not change while the first frame is building.
    WidgetsBinding.instance.addPostFrameCallback((_) => _start());
  }

  Future<void> _start() async {
    await Future.wait([
      Future<void>.delayed(SplashScreen.minimumTime),
      ref.read(authControllerProvider.notifier).restoreSession(),
    ]);
    if (!mounted) return;
    final signedIn = ref.read(authControllerProvider).user != null;
    context.go(signedIn ? '/home' : '/login');
  }

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      body: ColoredBox(
        color: AppColors.deepest,
        child: SizedBox.expand(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              BrandMark(radius: 56),
              SizedBox(height: 20),
              Text(
                'Overcise',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 42,
                  fontWeight: FontWeight.w800,
                ),
              ),
              SizedBox(height: 8),
              Text(
                'Exercise. Earn Points. Climb the Ranking.',
                textAlign: TextAlign.center,
                style: TextStyle(color: AppColors.pastel, fontSize: 15),
              ),
              SizedBox(height: 48),
              SizedBox.square(
                dimension: 28,
                child: CircularProgressIndicator(
                  strokeWidth: 3,
                  color: AppColors.skeleton,
                  semanticsLabel: 'Loading',
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
