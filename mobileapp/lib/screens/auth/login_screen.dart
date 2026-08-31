import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/theme/app_colors.dart';
import '../../core/config/demo_accounts.dart';
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
  bool _obscure    = true;
  late AnimationController _animCtrl;
  late Animation<double> _fadeAnim;
  late Animation<Offset> _slideAnim;

  @override
  void initState() {
    super.initState();
    _animCtrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 800));
    _fadeAnim  = CurvedAnimation(parent: _animCtrl, curve: Curves.easeOut);
    _slideAnim = Tween<Offset>(begin: const Offset(0, 0.08), end: Offset.zero)
        .animate(CurvedAnimation(parent: _animCtrl, curve: Curves.easeOut));
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
    if (!_formKey.currentState!.validate()) return;
    try {
      await ref.read(authProvider.notifier).login(
        _emailCtrl.text.trim(), _passCtrl.text,
      );
    } catch (_) {
      if (mounted) {
        final l10n = ref.read(appLocalizationsProvider);
        final err = ref.read(authProvider).error ?? l10n.loginFailed;
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text(err),
          backgroundColor: AppColors.danger,
          behavior: SnackBarBehavior.floating,
        ));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isLoading = ref.watch(authProvider.select((s) => s.isLoading));
    final l10n = ref.watch(appLocalizationsProvider);

    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(gradient: AppColors.primaryGradient),
        child: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: FadeTransition(
              opacity: _fadeAnim,
              child: SlideTransition(
                position: _slideAnim,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        IconButton(
                          icon: const Icon(Icons.arrow_back, color: Colors.white),
                          onPressed: () => context.go('/welcome'),
                        ),
                        const Spacer(),
                        IconButton(
                          icon: const Icon(Icons.language, color: Colors.white70),
                          onPressed: () => _toggleLanguage(ref),
                        ),
                      ],
                    ),
                    const SizedBox(height: 24),
                    Center(
                      child: Column(
                        children: [
                          Container(
                            width: 80, height: 80,
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(24),
                              boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.2), blurRadius: 20, offset: const Offset(0, 8))],
                            ),
                            child: const Center(
                              child: Text('D+', style: TextStyle(fontSize: 30, fontWeight: FontWeight.w800, color: AppColors.primary)),
                            ),
                          ),
                          const SizedBox(height: 16),
                          Text(l10n.appName, style: const TextStyle(color: Colors.white, fontSize: 28, fontWeight: FontWeight.w700)),
                          Text(l10n.posTagline,
                            style: TextStyle(color: Colors.white.withOpacity(0.7), fontSize: 13)),
                        ],
                      ),
                    ),
                    const SizedBox(height: 40),
                    Container(
                      padding: const EdgeInsets.all(24),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(24),
                        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.12), blurRadius: 30, offset: const Offset(0, 10))],
                      ),
                      child: Form(
                        key: _formKey,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(l10n.welcomeBack, style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w700, color: AppColors.textPrimary)),
                            const SizedBox(height: 4),
                            Text(l10n.signInSubtitle, style: const TextStyle(fontSize: 13, color: AppColors.textSecondary)),
                            const SizedBox(height: 24),
                            TextFormField(
                              controller: _emailCtrl,
                              keyboardType: TextInputType.emailAddress,
                              decoration: InputDecoration(
                                labelText: l10n.email,
                                prefixIcon: const Icon(Icons.email_outlined, size: 20),
                              ),
                              validator: (v) => (v == null || !v.contains('@')) ? l10n.invalidEmail : null,
                            ),
                            const SizedBox(height: 16),
                            TextFormField(
                              controller: _passCtrl,
                              obscureText: _obscure,
                              decoration: InputDecoration(
                                labelText: l10n.password,
                                prefixIcon: const Icon(Icons.lock_outline_rounded, size: 20),
                                suffixIcon: IconButton(
                                  icon: Icon(_obscure ? Icons.visibility_outlined : Icons.visibility_off_outlined, size: 20),
                                  onPressed: () => setState(() => _obscure = !_obscure),
                                ),
                              ),
                              validator: (v) => (v == null || v.length < 4) ? l10n.enterPassword : null,
                            ),
                            const SizedBox(height: 8),
                            Align(
                              alignment: Alignment.centerRight,
                              child: TextButton(
                                onPressed: () {
                                  showDialog(
                                    context: context,
                                    builder: (ctx) => AlertDialog(
                                      title: Text(l10n.resetPassword),
                                      content: Text(l10n.resetPasswordHint),
                                      actions: [
                                        TextButton(onPressed: () => Navigator.pop(ctx), child: Text(l10n.ok)),
                                      ],
                                    ),
                                  );
                                },
                                child: Text(l10n.forgotPassword, style: const TextStyle(fontSize: 12)),
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              l10n.demoAccountsHint,
                              style: const TextStyle(fontSize: 11, color: AppColors.textSecondary),
                            ),
                            const SizedBox(height: 8),
                            Wrap(
                              spacing: 6,
                              runSpacing: 6,
                              children: DemoAccounts.accounts.map((demo) {
                                return ActionChip(
                                  label: Text(demo.label, style: const TextStyle(fontSize: 11)),
                                  onPressed: isLoading
                                      ? null
                                      : () {
                                          _emailCtrl.text = demo.email;
                                          _passCtrl.text = DemoAccounts.demoPassword;
                                        },
                                );
                              }).toList(),
                            ),
                            const SizedBox(height: 12),
                            SizedBox(
                              width: double.infinity,
                              height: 52,
                              child: ElevatedButton(
                                onPressed: isLoading ? null : _login,
                                child: isLoading
                                    ? const SizedBox(width: 22, height: 22,
                                        child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                                    : Text(l10n.signIn, style: const TextStyle(fontSize: 15)),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 20),
                    Center(
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(l10n.noAccount,
                            style: TextStyle(color: Colors.white.withOpacity(0.8), fontSize: 13)),
                          GestureDetector(
                            onTap: () => context.go('/register'),
                            child: Text(l10n.register,
                              style: const TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.w700,
                                decoration: TextDecoration.underline, decorationColor: Colors.white)),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 40),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  void _toggleLanguage(WidgetRef ref) {
    final current = ref.read(localeProvider);
    ref.read(localeProvider.notifier).setLanguage(
      current == AppLanguage.sw ? AppLanguage.en : AppLanguage.sw,
    );
  }
}
