import 'package:flutter/material.dart';

/// Material-backed bottom sheet — avoids ListTile/DecoratedBox ink warnings.
class AppBottomSheet extends StatelessWidget {
  const AppBottomSheet({
    super.key,
    this.title,
    this.subtitle,
    required this.child,
    this.scrollController,
    this.padding = const EdgeInsets.fromLTRB(20, 0, 20, 24),
  });

  final String? title;
  final String? subtitle;
  final Widget child;
  final ScrollController? scrollController;
  final EdgeInsets padding;

  static Future<T?> show<T>(
    BuildContext context, {
    required Widget child,
    String? title,
    String? subtitle,
    bool isScrollControlled = true,
    double initialChildSize = 0.55,
    double minChildSize = 0.35,
    double maxChildSize = 0.92,
  }) {
    return showModalBottomSheet<T>(
      context: context,
      isScrollControlled: isScrollControlled,
      backgroundColor: Colors.transparent,
      useSafeArea: true,
      builder: (ctx) => DraggableScrollableSheet(
        initialChildSize: initialChildSize,
        minChildSize: minChildSize,
        maxChildSize: maxChildSize,
        expand: false,
        builder: (_, scrollController) => AppBottomSheet(
          title: title,
          subtitle: subtitle,
          scrollController: scrollController,
          child: child,
        ),
      ),
    );
  }

  static Future<T?> showCompact<T>(
    BuildContext context, {
    required Widget child,
    String? title,
    String? subtitle,
  }) {
    return showModalBottomSheet<T>(
      context: context,
      backgroundColor: Colors.transparent,
      useSafeArea: true,
      builder: (_) => Padding(
        padding: EdgeInsets.only(bottom: MediaQuery.viewInsetsOf(context).bottom),
        child: AppBottomSheet(
          title: title,
          subtitle: subtitle,
          child: child,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white,
      borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      clipBehavior: Clip.antiAlias,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const SizedBox(height: 10),
          Center(
            child: Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey.shade300,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          if (title != null)
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 14, 20, 0),
              child: Text(
                title!,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          if (subtitle != null)
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 4, 20, 0),
              child: Text(
                subtitle!,
                style: const TextStyle(fontSize: 12, color: Colors.black54),
              ),
            ),
          Flexible(
            child: SingleChildScrollView(
              controller: scrollController,
              padding: padding,
              child: child,
            ),
          ),
        ],
      ),
    );
  }
}
