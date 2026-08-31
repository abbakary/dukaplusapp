import 'package:flutter/material.dart';
import '../core/theme/app_colors.dart';

class AppSearchBar extends StatefulWidget {
  final String hint;
  final ValueChanged<String> onChanged;
  final VoidCallback? onClear;
  final TextEditingController? controller;

  const AppSearchBar({
    super.key,
    required this.hint,
    required this.onChanged,
    this.onClear,
    this.controller,
  });

  @override
  State<AppSearchBar> createState() => _AppSearchBarState();
}

class _AppSearchBarState extends State<AppSearchBar> {
  late final TextEditingController _ctrl;
  bool _hasText = false;

  @override
  void initState() {
    super.initState();
    _ctrl = widget.controller ?? TextEditingController();
    _ctrl.addListener(() => setState(() => _hasText = _ctrl.text.isNotEmpty));
  }

  @override
  void dispose() {
    if (widget.controller == null) _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 44,
      decoration: BoxDecoration(
        color: AppColors.surfaceVariant,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.border),
      ),
      child: TextField(
        controller: _ctrl,
        onChanged: widget.onChanged,
        style: const TextStyle(fontSize: 14, color: AppColors.textPrimary),
        decoration: InputDecoration(
          hintText: widget.hint,
          hintStyle: const TextStyle(fontSize: 13, color: AppColors.textHint),
          prefixIcon: const Icon(Icons.search_rounded, color: AppColors.textHint, size: 20),
          suffixIcon: _hasText
              ? IconButton(
                  icon: const Icon(Icons.close_rounded, size: 18, color: AppColors.textHint),
                  onPressed: () {
                    _ctrl.clear();
                    widget.onChanged('');
                    widget.onClear?.call();
                  },
                )
              : null,
          border: InputBorder.none,
          enabledBorder: InputBorder.none,
          focusedBorder: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(vertical: 12),
          isDense: true,
        ),
      ),
    );
  }
}
