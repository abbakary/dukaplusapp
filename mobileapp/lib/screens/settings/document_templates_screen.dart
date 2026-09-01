import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/config/document_templates.dart';
import '../../core/theme/app_colors.dart';
import '../../providers/business_settings_provider.dart';
import '../../providers/document_template_provider.dart';
import '../../providers/locale_provider.dart';
import '../../l10n/app_localizations.dart';
import '../../widgets/gradient_app_bar.dart';
import '../../widgets/document_template_card.dart';

class DocumentTemplatesScreen extends ConsumerStatefulWidget {
  const DocumentTemplatesScreen({super.key});

  @override
  ConsumerState<DocumentTemplatesScreen> createState() =>
      _DocumentTemplatesScreenState();
}

class _DocumentTemplatesScreenState extends ConsumerState<DocumentTemplatesScreen> {
  DocumentType _type = DocumentType.deliveryNote;

  @override
  Widget build(BuildContext context) {
    final l10n = ref.watch(appLocalizationsProvider);
    final isSw = ref.watch(localeProvider) == AppLanguage.sw;
    final config = ref.watch(documentTemplateProvider);
    final settings = ref.watch(businessSettingsProvider);
    final templates = templatesForType(_type);
    final activeId = config.activeTemplateIds[_type] ?? templates.first.id;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: GradientAppBar(
        title: l10n.documentTemplates,
        subtitle: documentTypeTitle(_type, isSw),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: DocumentType.values.map((t) {
                final selected = t == _type;
                return Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: ChoiceChip(
                    label: Text(documentTypeTitle(t, isSw)),
                    selected: selected,
                    onSelected: (_) => setState(() => _type = t),
                  ),
                );
              }).toList(),
            ),
          ),
          const SizedBox(height: 12),
          Text(
            isSw
                ? 'Chagua kati ya violezo 4 vya chaguo-msingi. Gusa "Tumia" kuweka hai.'
                : 'Choose from 4 default templates. Tap Use to activate.',
            style: const TextStyle(fontSize: 12, color: AppColors.textSecondary),
          ),
          const SizedBox(height: 16),
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              crossAxisSpacing: 12,
              mainAxisSpacing: 12,
              childAspectRatio: 0.58,
            ),
            itemCount: templates.length,
            itemBuilder: (_, i) {
              final tpl = templates[i];
              final isActive = tpl.id == activeId;
              return DocumentTemplateCard(
                template: tpl,
                isSw: isSw,
                isActive: isActive,
                showDiscount: settings.showDiscountOnDocuments && settings.discountEnabled,
                branding: config.branding,
                onUse: () => ref.read(documentTemplateProvider.notifier).setActive(_type, tpl.id),
              );
            },
          ),
          const SizedBox(height: 20),
          _BrandingSection(isSw: isSw),
          const SizedBox(height: 16),
          _DiscountSection(l10n: l10n, isSw: isSw),
        ],
      ),
    );
  }
}

class _BrandingSection extends ConsumerStatefulWidget {
  final bool isSw;
  const _BrandingSection({required this.isSw});

  @override
  ConsumerState<_BrandingSection> createState() => _BrandingSectionState();
}

class _BrandingSectionState extends ConsumerState<_BrandingSection> {
  bool _logoBusy = false;
  String? _logoError;

  Widget _logoPreview(String logoUrl) {
    if (logoUrl.isEmpty) {
      return const Icon(Icons.image_outlined, color: AppColors.textSecondary, size: 28);
    }
    if (logoUrl.startsWith('data:image')) {
      try {
        final bytes = base64Decode(logoUrl.split(',').last);
        return Image.memory(Uint8List.fromList(bytes), fit: BoxFit.contain);
      } catch (_) {
        return const Icon(Icons.broken_image_outlined, color: AppColors.textSecondary);
      }
    }
    return Image.network(logoUrl, fit: BoxFit.contain, errorBuilder: (_, __, ___) => const Icon(Icons.broken_image_outlined));
  }

  Future<void> _uploadLogo() async {
    setState(() {
      _logoBusy = true;
      _logoError = null;
    });
    try {
      await ref.read(documentTemplateProvider.notifier).pickAndUploadLogo();
    } catch (e) {
      setState(() => _logoError = e.toString());
    } finally {
      if (mounted) setState(() => _logoBusy = false);
    }
  }

  Future<void> _removeLogo() async {
    setState(() => _logoBusy = true);
    try {
      await ref.read(documentTemplateProvider.notifier).removeLogo();
    } finally {
      if (mounted) setState(() => _logoBusy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final branding = ref.watch(documentTemplateProvider).branding;
    final notifier = ref.read(documentTemplateProvider.notifier);
    final isSw = widget.isSw;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(isSw ? 'Chapa & Branding' : 'Branding',
                style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 14)),
            const SizedBox(height: 12),
            Row(
              children: [
                Container(
                  width: 72,
                  height: 72,
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: AppColors.background,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: AppColors.border),
                  ),
                  child: _logoPreview(branding.logoUrl),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      OutlinedButton.icon(
                        onPressed: _logoBusy ? null : _uploadLogo,
                        icon: _logoBusy
                            ? const SizedBox(width: 14, height: 14, child: CircularProgressIndicator(strokeWidth: 2))
                            : const Icon(Icons.upload, size: 16),
                        label: Text(isSw ? 'Pakia Logo' : 'Upload Logo'),
                      ),
                      if (branding.logoUrl.isNotEmpty)
                        TextButton.icon(
                          onPressed: _logoBusy ? null : _removeLogo,
                          icon: const Icon(Icons.delete_outline, size: 16, color: Colors.red),
                          label: Text(isSw ? 'Ondoa Logo' : 'Remove Logo', style: const TextStyle(color: Colors.red)),
                        ),
                      Text(
                        isSw ? 'PNG/JPG — hadi 500 KB' : 'PNG/JPG — max 500 KB',
                        style: const TextStyle(fontSize: 11, color: AppColors.textSecondary),
                      ),
                      if (_logoError != null)
                        Text(_logoError!, style: const TextStyle(fontSize: 11, color: Colors.red)),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            _BrandingField(
              label: isSw ? 'Jina la biashara' : 'Company name',
              value: branding.companyName,
              onChanged: (v) => notifier.patchBranding(companyName: v),
            ),
            _BrandingField(
              label: isSw ? 'Anwani' : 'Address',
              value: branding.address,
              onChanged: (v) => notifier.patchBranding(address: v),
            ),
            _BrandingField(
              label: isSw ? 'Simu' : 'Phone',
              value: branding.phone,
              onChanged: (v) => notifier.patchBranding(phone: v),
            ),
            _BrandingField(
              label: 'TIN',
              value: branding.tinNumber,
              onChanged: (v) => notifier.patchBranding(tinNumber: v),
            ),
            _BrandingField(
              label: isSw ? 'Footer' : 'Footer text',
              value: branding.footerText,
              onChanged: (v) => notifier.patchBranding(footerText: v),
            ),
          ],
        ),
      ),
    );
  }
}

class _BrandingField extends StatefulWidget {
  final String label;
  final String value;
  final ValueChanged<String> onChanged;

  const _BrandingField({
    required this.label,
    required this.value,
    required this.onChanged,
  });

  @override
  State<_BrandingField> createState() => _BrandingFieldState();
}

class _BrandingFieldState extends State<_BrandingField> {
  late final TextEditingController _controller;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: widget.value);
  }

  @override
  void didUpdateWidget(_BrandingField oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.value != widget.value && _controller.text != widget.value) {
      _controller.text = widget.value;
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: TextFormField(
        controller: _controller,
        decoration: InputDecoration(
          labelText: widget.label,
          border: const OutlineInputBorder(),
          isDense: true,
        ),
        onChanged: widget.onChanged,
      ),
    );
  }
}

class _DiscountSection extends ConsumerWidget {
  final AppLocalizations l10n;
  final bool isSw;
  const _DiscountSection({required this.l10n, required this.isSw});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final s = ref.watch(businessSettingsProvider);
    final notifier = ref.read(businessSettingsProvider.notifier);

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(isSw ? 'Mipangilio ya Punguzo' : 'Discount Settings',
                style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 14)),
            SwitchListTile(
              contentPadding: EdgeInsets.zero,
              title: Text(l10n.allowDiscounts),
              value: s.discountEnabled,
              onChanged: (v) => notifier.patch(discountEnabled: v),
            ),
            if (s.discountEnabled) ...[
              SwitchListTile(
                contentPadding: EdgeInsets.zero,
                title: Text(l10n.showDiscountOnReceipts),
                value: s.showDiscountOnReceipts,
                onChanged: (v) => notifier.patch(showDiscountOnReceipts: v),
              ),
              SwitchListTile(
                contentPadding: EdgeInsets.zero,
                title: Text(l10n.showDiscountOnDocuments),
                value: s.showDiscountOnDocuments,
                onChanged: (v) => notifier.patch(showDiscountOnDocuments: v),
              ),
              Row(
                children: [
                  Text(l10n.maxDiscount),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Slider(
                      value: s.maxDiscountPercent,
                      min: 0,
                      max: 50,
                      divisions: 10,
                      label: '${s.maxDiscountPercent.round()}%',
                      onChanged: (v) => notifier.patch(maxDiscountPercent: v),
                    ),
                  ),
                  Text('${s.maxDiscountPercent.round()}%'),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }
}
