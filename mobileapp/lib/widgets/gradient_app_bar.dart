import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../core/theme/app_colors.dart';
import '../providers/auth_provider.dart';
import 'drawer_menu_button.dart';

class GradientAppBar extends ConsumerWidget implements PreferredSizeWidget {
  final String title;
  final List<Widget>? actions;
  final Widget? leading;
  final bool showBack;
  final String? subtitle;
  final PreferredSizeWidget? bottom;

  const GradientAppBar({
    super.key,
    required this.title,
    this.actions,
    this.leading,
    this.showBack = false,
    this.subtitle,
    this.bottom,
  });

  @override
  Size get preferredSize => Size.fromHeight(
    kToolbarHeight + (subtitle != null ? 18 : 0) + (bottom?.preferredSize.height ?? 0),
  );

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final bizType = ref.watch(businessTypeProvider);
    final gradient = AppColors.gradientForBusiness(bizType);

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: const SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: Brightness.light,
      ),
      child: Container(
        decoration: BoxDecoration(gradient: gradient),
        child: SafeArea(
          bottom: false,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              AppBar(
                backgroundColor: Colors.transparent,
                elevation: 0,
                scrolledUnderElevation: 0,
                leading: showBack
                    ? IconButton(
                        icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 20),
                        onPressed: () => Navigator.of(context).maybePop(),
                      )
                    : (leading ?? const DrawerMenuButton()),
                title: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(title,
                      style: const TextStyle(
                        color: Colors.white, fontSize: 17,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    if (subtitle != null)
                      Text(subtitle!,
                        style: TextStyle(
                          color: Colors.white.withOpacity(0.8),
                          fontSize: 12, fontWeight: FontWeight.w400,
                        )),
                  ],
                ),
                actions: actions,
              ),
              if (bottom != null) bottom!,
            ],
          ),
        ),
      ),
    );
  }
}
