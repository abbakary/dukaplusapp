import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/config/demo_accounts.dart';
import '../../core/theme/app_colors.dart';
import '../../providers/auth_provider.dart';
import '../../l10n/app_localizations.dart';
import '../../providers/locale_provider.dart';

class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen>
    with SingleTickerProviderStateMixin {
  final _formKey   = GlobalKey<FormState>();
  final _emailCtrl = TextEditingController();
  final _passCtrl  = TextEditingController();
  bool  _obscure   = true;

  late AnimationController _animCtrl;
  late Animation<double>   _fadeAnim;
  late Animation<Offset>   _slideAnim;

  @override
  void initState() {
    super.initState();
    _animCtrl = AnimationController(
      vsync: this, duration: const Duration(milliseconds: 700));
    _fadeAnim  = CurvedAnimation(parent: _animCtrl, curve: Curves.easeOut);
    _slideAnim = Tween<Offset>(
      begin: const Offset(0, 0.05), end: Offset.zero,
    ).animate(CurvedAnimation(parent: _animCtrl, curve: Curves.easeOutCubic));
    _animCtrl.forward();
  }

  @override
  void dispose() {
    _animCtrl.dispose();
    _emailCtrl.dispose();
    _passCtrl.dispose();
    super.dispose();
  }

  Future<void> _login() async {
    FocusScope.of(context).unfocus();
    if (!_formKey.currentState!.validate()) return;
    try {
      await ref.read(authProvider.notifier).login(
        _emailCtrl.text.trim(), _passCtrl.text);
    } catch (_) {
      if (!mounted) return;
      final l10n = ref.read(appLocalizationsProvider);
      final err  = ref.read(authProvider).error ?? l10n.loginFailed;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text(err),
        backgroundColor: AppColors.danger,
        behavior: SnackBarBehavior.floating,
      ));
    }
  }

  void _showDemoSheet() {
    final l10n = ref.read(appLocalizationsProvider);
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (_) => Material(
        color: Colors.transparent,
        child: Container(
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
          ),
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(width: 40, height: 4,
                  decoration: BoxDecoration(
                    color: AppColors.border,
                    borderRadius: BorderRadius.circular(2))),
              ),
              const SizedBox(height: 14),
              Text('Demo accounts',
                style: const TextStyle(
                  fontSize: 16, fontWeight: FontWeight.w700,
                  color: AppColors.textPrimary)),
              Text('Password: ${DemoAccounts.demoPassword}',
                style: const TextStyle(
                  fontSize: 12, color: AppColors.textSecondary)),
              const SizedBox(height: 12),
              ...DemoAccounts.accounts.map((d) => ListTile(
                contentPadding: EdgeInsets.zero,
                dense: true,
                leading: CircleAvatar(
                  radius: 18,
                  backgroundColor: AppColors.primary.withValues(alpha: 0.1),
                  child: Text(d.label[0],
                    style: const TextStyle(
                      fontSize: 13, fontWeight: FontWeight.w700,
                      color: AppColors.primary)),
                ),
                title: Text(d.label,
                  style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
                subtitle: Text(d.role,
                  style: const TextStyle(fontSize: 11, color: AppColors.textHint)),
                trailing: const Icon(Icons.arrow_forward_ios_rounded,
                  size: 14, color: AppColors.textHint),
                onTap: () {
                  Navigator.pop(context);
                  setState(() {
                    _emailCtrl.text = d.email;
                    _passCtrl.text  = DemoAccounts.demoPassword;
                  });
                },
              )),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isLoading = ref.watch(authProvider.select((s) => s.isLoading));
    final l10n      = ref.watch(appLocalizationsProvider);
    final mq        = MediaQuery.of(context);
    final screenH   = mq.size.height;
    final botPad    = mq.padding.bottom;
    final isCompact = screenH < 680;

    return Scaffold(
      // Keep body fixed — keyboard pushes it up via resizeToAvoidBottomInset
      resizeToAvoidBottomInset: true,
      body: Container(
        decoration: const BoxDecoration(gradient: AppColors.primaryGradient),
        child: SafeArea(
          child: FadeTransition(
            opacity: _fadeAnim,
            child: SlideTransition(
              position: _slideAnim,
              child: LayoutBuilder(
                builder: (context, constraints) {
                  return SingleChildScrollView(
                    padding: const EdgeInsets.symmetric(horizontal: 24),
                    keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
                    child: ConstrainedBox(
                      constraints: BoxConstraints(minHeight: constraints.maxHeight),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          SizedBox(
                            height: isCompact ? 44 : 52,
                            child: Row(
                              children: [
                                _BackBtn(),
                                const Spacer(),
                                _LangToggle(),
                              ],
                            ),
                          ),
                          if (!isCompact) const SizedBox(height: 8),
                          Center(
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Container(
                                  width: isCompact ? 56 : 70,
                                  height: isCompact ? 56 : 70,
                                  decoration: BoxDecoration(
                                    color: Colors.white,
                                    borderRadius: BorderRadius.circular(isCompact ? 16 : 22),
                                    boxShadow: [BoxShadow(
                                      color: Colors.black.withValues(alpha: 0.18),
                                      blurRadius: 20, offset: const Offset(0, 6))],
                                  ),
                                  child: Center(child: Text('D+',
                                    style: TextStyle(
                                      fontSize: isCompact ? 22 : 28,
                                      fontWeight: FontWeight.w800,
                                      color: AppColors.primary,
                                      letterSpacing: -0.5,
                                    ))),
                                ),
                                SizedBox(height: isCompact ? 6 : 12),
                                Text(l10n.appName,
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontSize: isCompact ? 20 : 26,
                                    fontWeight: FontWeight.w800,
                                    letterSpacing: -0.5,
                                  )),
                                const SizedBox(height: 2),
                                Text(l10n.posTagline,
                                  style: TextStyle(
                                    color: Colors.white.withValues(alpha: 0.70),
                                    fontSize: isCompact ? 11 : 12,
                                  )),
                              ],
                            ),
                          ),
                          SizedBox(height: isCompact ? 12 : 24),
                          Container(
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(24),
                              boxShadow: [BoxShadow(
                                color: Colors.black.withValues(alpha: 0.10),
                                blurRadius: 32, offset: const Offset(0, 12))],
                            ),
                            padding: EdgeInsets.all(isCompact ? 16 : 24),
                            child: Form(
                              key: _formKey,
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Text(l10n.welcomeBack,
                                    style: TextStyle(
                                      fontSize: isCompact ? 18 : 21,
                                      fontWeight: FontWeight.w700,
                                      color: AppColors.textPrimary,
                                      letterSpacing: -0.3,
                                    )),
                                  const SizedBox(height: 2),
                                  Text(l10n.signInSubtitle,
                                    style: const TextStyle(
                                      fontSize: 12, color: AppColors.textSecondary)),
                                  SizedBox(height: isCompact ? 12 : 18),
                                  TextFormField(
                                    controller: _emailCtrl,
                                    keyboardType: TextInputType.emailAddress,
                                    textInputAction: TextInputAction.next,
                                    decoration: InputDecoration(
                                      labelText: l10n.email,
                                      prefixIcon: const Icon(
                                        Icons.email_outlined, size: 20),
                                    ),
                                    validator: (v) =>
                                      (v == null || !v.contains('@'))
                                        ? l10n.invalidEmail : null,
                                  ),
                                  SizedBox(height: isCompact ? 8 : 12),
                                  TextFormField(
                                    controller: _passCtrl,
                                    obscureText: _obscure,
                                    textInputAction: TextInputAction.done,
                                    onFieldSubmitted: (_) => _login(),
                                    decoration: InputDecoration(
                                      labelText: l10n.password,
                                      prefixIcon: const Icon(
                                        Icons.lock_outline_rounded, size: 20),
                                      suffixIcon: IconButton(
                                        icon: Icon(_obscure
                                          ? Icons.visibility_outlined
                                          : Icons.visibility_off_outlined,
                                          size: 20),
                                        onPressed: () =>
                                          setState(() => _obscure = !_obscure),
                                      ),
                                    ),
                                    validator: (v) =>
                                      (v == null || v.length < 4)
                                        ? l10n.enterPassword : null,
                                  ),
                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                    children: [
                                      TextButton(
                                        onPressed: _showDemoSheet,
                                        style: TextButton.styleFrom(
                                          padding: EdgeInsets.zero,
                                          minimumSize: Size.zero,
                                          tapTargetSize:
                                            MaterialTapTargetSize.shrinkWrap),
                                        child: const Text('Try demo',
                                          style: TextStyle(
                                            fontSize: 11,
                                            color: AppColors.textSecondary)),
                                      ),
                                      TextButton(
                                        onPressed: () =>
                                          _showForgotDialog(context, l10n),
                                        style: TextButton.styleFrom(
                                          padding: EdgeInsets.zero,
                                          minimumSize: Size.zero,
                                          tapTargetSize:
                                            MaterialTapTargetSize.shrinkWrap),
                                        child: Text(l10n.forgotPassword,
                                          style: const TextStyle(
                                            fontSize: 11,
                                            color: AppColors.primary)),
                                      ),
                                    ],
                                  ),
                                  SizedBox(height: isCompact ? 6 : 10),
                                  SizedBox(
                                    width: double.infinity,
                                    height: 48,
                                    child: ElevatedButton(
                                      onPressed: isLoading ? null : _login,
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor: AppColors.primary,
                                        disabledBackgroundColor:
                                          AppColors.primary.withValues(alpha: 0.6),
                                        shape: RoundedRectangleBorder(
                                          borderRadius: BorderRadius.circular(14)),
                                      ),
                                      child: isLoading
                                        ? const SizedBox(width: 20, height: 20,
                                            child: CircularProgressIndicator(
                                              strokeWidth: 2.5, color: Colors.white))
                                        : Text(l10n.signIn,
                                            style: const TextStyle(
                                              fontSize: 15,
                                              fontWeight: FontWeight.w700)),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                          SizedBox(height: isCompact ? 10 : 20),
                          Center(
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text(l10n.noAccount,
                                  style: TextStyle(
                                    color: Colors.white.withValues(alpha: 0.80),
                                    fontSize: 13)),
                                GestureDetector(
                                  onTap: () => context.go('/register'),
                                  child: Text(l10n.register,
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 13,
                                      fontWeight: FontWeight.w700,
                                      decoration: TextDecoration.underline,
                                      decorationColor: Colors.white)),
                                ),
                              ],
                            ),
                          ),
                          SizedBox(height: botPad > 0 ? botPad : 16),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
          ),
        ),
      ),
    );
  }

  void _showForgotDialog(BuildContext context, AppLocalizations l10n) {
    showDialog(
      context: context,
      builder: (dialogCtx) => AlertDialog(
        title:   Text(l10n.resetPassword),
        content: Text(l10n.resetPasswordHint),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogCtx).pop(),
            child: Text(l10n.ok)),
        ],
      ),
    );
  }
}

class _BackBtn extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) => GestureDetector(
    onTap: () => context.go('/welcome'),
    child: Container(
      width: 38, height: 38,
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.white.withValues(alpha: 0.25)),
      ),
      child: const Icon(
        Icons.arrow_back_rounded, color: Colors.white, size: 20),
    ),
  );
}

class _LangToggle extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isSw = ref.watch(localeProvider) == AppLanguage.sw;
    return GestureDetector(
      onTap: () => ref.read(localeProvider.notifier).setLanguage(
        isSw ? AppLanguage.en : AppLanguage.sw),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.15),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.white.withValues(alpha: 0.25)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.language_rounded,
              color: Colors.white70, size: 15),
            const SizedBox(width: 5),
            Text(isSw ? 'SW' : 'EN',
              style: const TextStyle(
                color: Colors.white, fontSize: 12,
                fontWeight: FontWeight.w600)),
          ],
        ),
      ),
    );
  }
}
