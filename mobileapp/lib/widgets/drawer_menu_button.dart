import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final shellScaffoldKeyProvider =
    Provider<GlobalKey<ScaffoldState>>((ref) => GlobalKey<ScaffoldState>());

class DrawerMenuButton extends ConsumerWidget {
  final Color? color;
  const DrawerMenuButton({super.key, this.color});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return IconButton(
      icon: Icon(Icons.menu_rounded, color: color ?? Colors.white),
      onPressed: () =>
          ref.read(shellScaffoldKeyProvider).currentState?.openDrawer(),
    );
  }
}
