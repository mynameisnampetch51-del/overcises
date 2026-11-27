import 'package:material_ui/material_ui.dart';

import '../../../../core/layout/breakpoints.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/widgets/brand_mark.dart';

/// Frame for Log in and Sign up.
///
/// Phones: a green header with the form overlapping it.
/// Wide screens: a brand panel on the left and the form on the right.
class AuthScaffold extends StatelessWidget {
  const AuthScaffold({super.key, required this.children, this.onBack});

  final List<Widget> children;

  /// Shows a back arrow and, on phones, a shorter header.
  final VoidCallback? onBack;

  @override
  Widget build(BuildContext context) {
    final split = MediaQuery.sizeOf(context).width >= Breakpoints.splitAuth;
    return Scaffold(body: split ? _split() : _stacked());
  }

  Widget _form() => Center(
    child: ConstrainedBox(
      constraints: const BoxConstraints(maxWidth: 420),
      child: Column(mainAxisSize: MainAxisSize.min, children: children),
    ),
  );

  Widget _split() {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const Expanded(child: _BrandPanel()),
        Expanded(
          child: Stack(
            children: [
              Center(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(32),
                  child: _form(),
                ),
              ),
              if (onBack != null)
                Positioned(
                  top: 16,
                  left: 16,
                  child: BackButton(onPressed: onBack),
                ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _stacked() {
    final compact = onBack != null;

    return SingleChildScrollView(
      child: Stack(
        children: [
          _Header(height: compact ? 230 : 310, compact: compact),
          Padding(
            padding: EdgeInsets.fromLTRB(20, compact ? 170 : 250, 20, 24),
            child: _form(),
          ),
          if (onBack != null)
            SafeArea(
              child: Padding(
                padding: const EdgeInsets.all(8),
                child: BackButton(color: Colors.white, onPressed: onBack),
              ),
            ),
        ],
      ),
    );
  }
}

/// Logo at the top, the pitch anchored at the bottom.
class _BrandPanel extends StatelessWidget {
  const _BrandPanel();

  static const _padding = 48.0;

  @override
  Widget build(BuildContext context) {
    return ColoredBox(
      color: AppColors.deepest,
      child: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) => SingleChildScrollView(
            padding: const EdgeInsets.all(_padding),
            child: ConstrainedBox(
              constraints: BoxConstraints(
                minHeight: constraints.maxHeight - _padding * 2,
              ),
              child: const Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  BrandMark(radius: 32),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      SizedBox(height: 32),
                      Text(
                        'Overcise',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 72,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      SizedBox(height: 12),
                      Text(
                        'Exercise. Earn Points.\nClimb the Ranking.',
                        style: TextStyle(color: AppColors.pastel, fontSize: 28),
                      ),
                      SizedBox(height: 32),
                      Text(
                        'Jumping jacks and sit-ups.\n'
                        'Daily Quests and a monthly Ranking.\n'
                        'Points you can swap for fitness discounts.',
                        style: TextStyle(
                          color: AppColors.skeleton,
                          fontSize: 16,
                          height: 1.8,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _Header extends StatelessWidget {
  const _Header({required this.height, required this.compact});

  final double height;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: height,
      width: double.infinity,
      decoration: const BoxDecoration(
        color: AppColors.deepest,
        borderRadius: BorderRadius.vertical(bottom: Radius.circular(36)),
      ),
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.only(top: 32),
          child: Column(
            children: [
              BrandMark(radius: compact ? 28 : 36),
              SizedBox(height: compact ? 8 : 14),
              Text(
                'Overcise',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: compact ? 26 : 34,
                  fontWeight: FontWeight.w800,
                ),
              ),
              if (!compact) ...const [
                SizedBox(height: 6),
                Text(
                  'Exercise. Earn Points. Climb the Ranking.',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: AppColors.pastel, fontSize: 14),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
