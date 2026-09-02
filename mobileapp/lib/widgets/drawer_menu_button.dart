import 'package:flutter/material.dart';
import 'shell_scope.dart';

class DrawerMenuButton extends StatelessWidget {
  final Color? color;
  const DrawerMenuButton({super.key, this.color});

  @override
  Widget build(BuildContext context) {
    return IconButton(
      icon: Icon(Icons.menu_rounded, color: color ?? Colors.white),
      onPressed: () {
        final shellKey = ShellScope.maybeOf(context)?.scaffoldKey;
        shellKey?.currentState?.openDrawer();
      },
    );
  }
}
