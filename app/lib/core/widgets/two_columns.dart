import 'package:material_ui/material_ui.dart';

import '../layout/breakpoints.dart';

/// [first] and [second] side by side when there is room, else stacked.
class TwoColumns extends StatelessWidget {
  const TwoColumns({super.key, required this.first, required this.second});

  final List<Widget> first;
  final List<Widget> second;

  static const gap = 16.0;

  @override
  Widget build(BuildContext context) {
    Widget column(List<Widget> children) => Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: children,
    );

    return LayoutBuilder(
      builder: (context, constraints) {
        if (constraints.maxWidth < Breakpoints.twoColumns) {
          return column([...first, const SizedBox(height: gap), ...second]);
        }
        return Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(child: column(first)),
            const SizedBox(width: gap),
            Expanded(child: column(second)),
          ],
        );
      },
    );
  }
}
