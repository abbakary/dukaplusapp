import 'package:flutter/material.dart';

/// Layout helpers for screens rendered inside [MainShell] (bottom nav + safe area).
class ShellInsets {
  ShellInsets._();

  static const double navBarHeight = 60;
  static const double fabSize = 56;
  static const double fabMargin = 16;

  static double safeBottom(BuildContext context) =>
      MediaQuery.paddingOf(context).bottom;

  /// Bottom padding for scrollable content so the last row clears a screen FAB.
  static double scrollBottom(BuildContext context, {bool withFab = false}) {
    final fab = withFab ? fabSize + fabMargin : 0;
    return fab + fabMargin;
  }

  static EdgeInsets listPadding(BuildContext context, {bool withFab = false}) =>
      EdgeInsets.fromLTRB(12, 12, 12, scrollBottom(context, withFab: withFab));

  static EdgeInsets pagePadding(BuildContext context, {bool withFab = false}) =>
      EdgeInsets.fromLTRB(16, 16, 16, scrollBottom(context, withFab: withFab));
}

/// Wraps a screen-level FAB with a small bottom margin above the shell nav.
class ShellFab extends StatelessWidget {
  final Widget child;

  const ShellFab({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8, right: 4),
      child: child,
    );
  }
}
