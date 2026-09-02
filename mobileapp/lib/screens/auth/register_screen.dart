import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/theme/app_colors.dart';
import '../../core/constants/app_constants.dart';
import '../../core/constants/saas_plans.dart';
import '../../providers/auth_provider.dart';
import '../../providers/locale_provider.dart';
import '../../screens/legal/terms_of_service_screen.dart';
import '../../core/legal/terms_of_service.dart';
import '../../l10n/app_localizations.dart';
import '../../widgets/plan_pricing_card.dart';

class RegisterScreen extends ConsumerStatefulWidget {
  const RegisterScreen({super.key});

  @override
  ConsumerState<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends ConsumerState<RegisterScreen> {
  final _formKey     = GlobalKey<FormState>();
  final _nameCtrl    = TextEditingController();
  final _bizCtrl     = TextEditingController();
  final _emailCtrl   = TextEditingController();
  final _phoneCtrl   = TextEditingController();
  final _passCtrl    = TextEditingController();
  final _tinCtrl     = TextEditingController();

  int _step = 0;
  String _selectedType = 'retail';
  String _selectedPlan = AppConstants.planStarter;
  bool _obscure = true;
  bool _acceptedTerms = false;

  @override
  void dispose() {
    for (final c in [_nameCtrl,_bizCtrl,_emailCtrl,_phoneCtrl,_passCtrl,_tinCtrl]) {
      c.dispose();
    }
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    final l10n = ref.read(appLocalizationsProvider);
    final isSw = ref.read(localeProvider) == AppLanguage.sw;
    if (!_acceptedTerms) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text(termsMustAcceptError(isSw)),
        backgroundColor: AppColors.danger,
        behavior: SnackBarBehavior.floating,
      ));
      return;
    }
    try {
      await ref.read(authProvider.notifier).register({
        'owner_name':    _nameCtrl.text.trim(),
        'business_name': _bizCtrl.text.trim(),
        'email':         _emailCtrl.text.trim(),
        'phone':         _phoneCtrl.text.trim(),
        'password':      _passCtrl.text,
        'business_type': _selectedType,
        'tin_number':    _tinCtrl.text.trim(),
        'region':        'Dar es Salaam',
        'plan_tier':     _selectedPlan,
      });
    } catch (_) {
      if (mounted) {
        final err = ref.read(authProvider).error ?? l10n.registrationFailed;
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
    final l10n = ref.watch(appLocalizationsProvider);
    final isLoading = ref.watch(authProvider.select((s) => s.isLoading));
    return Scaffold(
      resizeToAvoidBottomInset: true,
      body: Container(
        decoration: const BoxDecoration(gradient: AppColors.primaryGradient),
        child: SafeArea(
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
                child: Row(
                  children: [
                    IconButton(
                      icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Colors.white, size: 20),
                      onPressed: _step == 0 ? () => context.go('/login') : () => setState(() => _step--),
                    ),
                    const Spacer(),
                    Text(l10n.stepOfTotal(_step + 1, 4),
                      style: TextStyle(color: Colors.white.withValues(alpha: 0.8), fontSize: 12)),
                  ],
                ),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                child: Row(
                  children: List.generate(4, (i) => Expanded(
                    child: Container(
                      height: 4,
                      margin: EdgeInsets.only(right: i < 3 ? 6 : 0),
                      decoration: BoxDecoration(
                        color: i <= _step ? Colors.white : Colors.white.withValues(alpha: 0.3),
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  )),
                ),
              ),
              Expanded(
                child: Container(
                  margin: const EdgeInsets.fromLTRB(16, 8, 16, 16),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(24),
                    boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.12), blurRadius: 30, offset: const Offset(0, 10))],
                  ),
                  child: Form(
                    key: _formKey,
                    child: AnimatedSwitcher(
                      duration: const Duration(milliseconds: 300),
                      transitionBuilder: (child, anim) => SlideTransition(
                        position: Tween<Offset>(begin: const Offset(0.05, 0), end: Offset.zero).animate(anim),
                        child: FadeTransition(opacity: anim, child: child),
                      ),
                      child: _step == 0
                          ? _buildStep0(l10n)
                          : _step == 1
                              ? _buildStep1(l10n)
                              : _step == 2
                                  ? _buildStep2Plans(l10n)
                                  : _buildStep3Account(l10n, isLoading),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStep0(AppLocalizations l10n) => SingleChildScrollView(
    key: const ValueKey(0),
    padding: const EdgeInsets.all(20),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(l10n.whatBusinessType,
          style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w700, color: AppColors.textPrimary)),
        const SizedBox(height: 6),
        Text(l10n.tailorBusinessHint,
          style: const TextStyle(fontSize: 13, color: AppColors.textSecondary)),
        const SizedBox(height: 20),
        GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 3, mainAxisSpacing: 10, crossAxisSpacing: 10,
            childAspectRatio: 0.9,
          ),
          itemCount: AppConstants.businessTypes.length,
          itemBuilder: (_, i) {
            final t = AppConstants.businessTypes[i];
            final selected = t['id'] == _selectedType;
            final color = AppColors.forBusiness(t['id']);
            return GestureDetector(
              onTap: () => setState(() => _selectedType = t['id']!),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                decoration: BoxDecoration(
                  color: selected ? color.withValues(alpha: 0.1) : AppColors.surfaceVariant,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(
                    color: selected ? color : AppColors.border,
                    width: selected ? 2 : 1,
                  ),
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(t['icon']!, style: const TextStyle(fontSize: 24)),
                    const SizedBox(height: 6),
                    Text(l10n.businessTypeLabel(t),
                      style: TextStyle(
                        fontSize: 10, fontWeight: FontWeight.w500,
                        color: selected ? color : AppColors.textSecondary,
                      ),
                      textAlign: TextAlign.center,
                      maxLines: 2,
                    ),
                  ],
                ),
              ),
            );
          },
        ),
        const SizedBox(height: 20),
        SizedBox(
          width: double.infinity, height: 52,
          child: ElevatedButton(
            onPressed: () => setState(() => _step = 1),
            child: Text(l10n.continueLabel),
          ),
        ),
      ],
    ),
  );

  Widget _buildStep1(AppLocalizations l10n) => SingleChildScrollView(
    key: const ValueKey(1),
    padding: const EdgeInsets.all(20),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(l10n.businessDetails,
          style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w700, color: AppColors.textPrimary)),
        const SizedBox(height: 20),
        TextFormField(
          controller: _bizCtrl,
          decoration: InputDecoration(labelText: l10n.businessName,
            prefixIcon: const Icon(Icons.store_outlined, size: 20)),
          validator: (v) => (v == null || v.isEmpty) ? l10n.requiredField : null,
        ),
        const SizedBox(height: 14),
        TextFormField(
          controller: _nameCtrl,
          decoration: InputDecoration(labelText: l10n.yourFullName,
            prefixIcon: const Icon(Icons.person_outline_rounded, size: 20)),
          validator: (v) => (v == null || v.isEmpty) ? l10n.requiredField : null,
        ),
        const SizedBox(height: 14),
        TextFormField(
          controller: _tinCtrl,
          decoration: InputDecoration(labelText: l10n.tinOptional,
            prefixIcon: const Icon(Icons.receipt_long_outlined, size: 20)),
        ),
        const SizedBox(height: 20),
        SizedBox(
          width: double.infinity, height: 52,
          child: ElevatedButton(
            onPressed: () {
              if (_bizCtrl.text.isEmpty || _nameCtrl.text.isEmpty) {
                ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(l10n.fillRequiredFields)));
                return;
              }
              setState(() => _step = 2);
            },
            child: Text(l10n.continueLabel),
          ),
        ),
      ],
    ),
  );

  Widget _buildStep2Plans(AppLocalizations l10n) {
    final isSw = ref.watch(localeProvider) == AppLanguage.sw;
    return SingleChildScrollView(
      key: const ValueKey(2),
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(l10n.choosePlanTitle,
            style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w700, color: AppColors.textPrimary)),
          const SizedBox(height: 6),
          Text(l10n.choosePlanHint,
            style: const TextStyle(fontSize: 13, color: AppColors.textSecondary)),
          const SizedBox(height: 20),
          ...SaasPlans.publicPlans.map((plan) => Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: PlanPricingCard(
              plan: plan,
              isSw: isSw,
              selected: _selectedPlan == plan.tier,
              onTap: () => setState(() => _selectedPlan = plan.tier),
            ),
          )),
          const SizedBox(height: 8),
          SizedBox(
            width: double.infinity,
            height: 52,
            child: ElevatedButton(
              onPressed: () => setState(() => _step = 3),
              child: Text(l10n.continueLabel),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStep3Account(AppLocalizations l10n, bool isLoading) {
    final isSw = ref.watch(localeProvider) == AppLanguage.sw;
    return SingleChildScrollView(
    key: const ValueKey(3),
    padding: const EdgeInsets.all(20),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(l10n.createYourAccount,
          style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w700, color: AppColors.textPrimary)),
        const SizedBox(height: 20),
        TextFormField(
          controller: _emailCtrl,
          keyboardType: TextInputType.emailAddress,
          decoration: InputDecoration(labelText: l10n.email,
            prefixIcon: const Icon(Icons.email_outlined, size: 20)),
          validator: (v) => (v == null || !v.contains('@')) ? l10n.invalidEmail : null,
        ),
        const SizedBox(height: 14),
        TextFormField(
          controller: _phoneCtrl,
          keyboardType: TextInputType.phone,
          decoration: InputDecoration(labelText: l10n.phoneWithCode,
            prefixIcon: const Icon(Icons.phone_outlined, size: 20)),
          validator: (v) => (v == null || v.length < 10) ? l10n.enterValidPhone : null,
        ),
        const SizedBox(height: 14),
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
          validator: (v) => (v == null || v.length < 6) ? l10n.minSixChars : null,
        ),
        const SizedBox(height: 18),
        TermsAcceptanceTile(
          isSw: isSw,
          value: _acceptedTerms,
          onChanged: (v) => setState(() => _acceptedTerms = v ?? false),
          onOpenTerms: () => context.push('/terms'),
        ),
        const SizedBox(height: 20),
        SizedBox(
          width: double.infinity, height: 52,
          child: ElevatedButton(
            onPressed: isLoading || !_acceptedTerms ? null : _submit,
            child: isLoading
                ? const SizedBox(width: 22, height: 22,
                    child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                : Text(l10n.createAccount),
          ),
        ),
        const SizedBox(height: 16),
        Center(
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(l10n.alreadyHaveAccount,
                style: const TextStyle(fontSize: 13, color: AppColors.textSecondary)),
              GestureDetector(
                onTap: () => context.go('/login'),
                child: Text(l10n.signIn,
                  style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600,
                    color: Theme.of(context).colorScheme.primary)),
              ),
            ],
          ),
        ),
      ],
    ),
  );
  }
}
