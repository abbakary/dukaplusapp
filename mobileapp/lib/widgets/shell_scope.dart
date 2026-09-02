import 'package:flutter/material.dart';

/// Exposes the [MainShell] scaffold key to nested routes (each shell owns its key).
class ShellScope extends InheritedWidget {
  const ShellScope({
    super.key,
    required this.scaffoldKey,
    required super.child,
  });

  final GlobalKey<ScaffoldState> scaffoldKey;

  static ShellScope? maybeOf(BuildContext context) {
    return context.dependOnInheritedWidgetOfExactType<ShellScope>();
  }

  @override
  bool updateShouldNotify(ShellScope oldWidget) =>
      oldWidget.scaffoldKey != scaffoldKey;
}
