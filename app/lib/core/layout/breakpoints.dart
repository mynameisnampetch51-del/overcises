import 'package:material_ui/material_ui.dart';

/// Screen sizes the app lays itself out for.
abstract final class Breakpoints {
  /// From here the bottom bar becomes a side rail.
  static const rail = 600.0;

  /// From here the side rail shows its labels beside the icons.
  static const wideRail = 1100.0;

  /// From here Log in and Sign up use two panels.
  static const splitAuth = 900.0;

  /// Content width from which cards sit in two columns.
  static const twoColumns = 680.0;

  /// A short screen (a phone on its side) keeps the bottom bar.
  static bool useRail(BuildContext context) {
    final size = MediaQuery.sizeOf(context);
    return size.width >= rail && size.height >= 500;
  }
}
