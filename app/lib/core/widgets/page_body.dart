import 'package:material_ui/material_ui.dart';

import '../layout/breakpoints.dart';

/// Scrolling page content with a limit on its width.
class PageBody extends StatelessWidget {
  const PageBody({super.key, required this.children, this.maxWidth = narrow});

  /// For single-column pages.
  static const narrow = 560.0;

  /// For pages that use two columns.
  static const wide = 960.0;

  final List<Widget> children;
  final double maxWidth;

  @override
  Widget build(BuildContext context) {
    final padding = Breakpoints.useRail(context) ? 32.0 : 20.0;

    return SafeArea(
      child: SingleChildScrollView(
        padding: EdgeInsets.all(padding),
        child: Center(
          child: ConstrainedBox(
            constraints: BoxConstraints(maxWidth: maxWidth),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: children,
            ),
          ),
        ),
      ),
    );
  }
}
