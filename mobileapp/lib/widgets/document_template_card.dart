import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import '../../core/config/document_templates.dart';
import '../../core/theme/app_colors.dart';

class DocumentTemplateCard extends StatelessWidget {
  final DocumentTemplate template;
  final bool isSw;
  final bool isActive;
  final bool showDiscount;
  final DocumentBranding branding;
  final VoidCallback onUse;

  const DocumentTemplateCard({
    super.key,
    required this.template,
    required this.isSw,
    required this.isActive,
    required this.showDiscount,
    required this.branding,
    required this.onUse,
  });

  Widget _logoWidget() {
    if (branding.logoUrl.isEmpty) {
      return Container(
        width: 28,
        height: 28,
        decoration: BoxDecoration(
          color: Colors.white.withAlpha(40),
          borderRadius: BorderRadius.circular(6),
        ),
        alignment: Alignment.center,
        child: const Text('LOGO', style: TextStyle(fontSize: 6, fontWeight: FontWeight.w800, color: Colors.white)),
      );
    }
    if (branding.logoUrl.startsWith('data:image')) {
      try {
        final raw = branding.logoUrl.split(',').last;
        final bytes = base64Decode(raw);
        return ClipRRect(
          borderRadius: BorderRadius.circular(4),
          child: Image.memory(
            Uint8List.fromList(bytes),
            width: 28,
            height: 28,
            fit: BoxFit.contain,
          ),
        );
      } catch (_) {
        return const SizedBox.shrink();
      }
    }
    return ClipRRect(
      borderRadius: BorderRadius.circular(4),
      child: Image.network(
        branding.logoUrl,
        width: 28,
        height: 28,
        fit: BoxFit.contain,
        errorBuilder: (_, __, ___) => const SizedBox.shrink(),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = template.theme;
    final docNo = template.documentType == DocumentType.invoice
        ? 'INV-2026-0042'
        : template.documentType == DocumentType.deliveryNote
            ? 'DN-2026-0188'
            : 'ON-2026-0091';

    return Container(
      decoration: BoxDecoration(
        color: theme.cardBg,
        borderRadius: BorderRadius.circular(16),
        border: isActive
            ? Border.all(color: const Color(0xFF6264A7), width: 2)
            : null,
      ),
      padding: const EdgeInsets.all(10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Expanded(
            child: Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withAlpha(15),
                    blurRadius: 8,
                    offset: const Offset(0, 3),
                  ),
                ],
              ),
              child: Column(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                    decoration: BoxDecoration(
                      color: theme.primary,
                      borderRadius: const BorderRadius.vertical(top: Radius.circular(12)),
                    ),
                    child: Row(
                      children: [
                        _logoWidget(),
                        const SizedBox(width: 6),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                documentTypeTitle(template.documentType, isSw).toUpperCase(),
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 7,
                                  fontWeight: FontWeight.w800,
                                ),
                              ),
                              Text(
                                docNo,
                                style: TextStyle(color: Colors.white.withAlpha(200), fontSize: 6),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  Expanded(
                    child: Padding(
                      padding: const EdgeInsets.all(8),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            branding.companyName.isNotEmpty ? branding.companyName : 'Your Business',
                            style: const TextStyle(fontSize: 8, fontWeight: FontWeight.w800),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          if (branding.address.isNotEmpty)
                            Text(
                              branding.address,
                              style: const TextStyle(fontSize: 6, color: AppColors.textSecondary),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          if (branding.phone.isNotEmpty || branding.tinNumber.isNotEmpty)
                            Text(
                              [
                                if (branding.phone.isNotEmpty) branding.phone,
                                if (branding.tinNumber.isNotEmpty) 'TIN: ${branding.tinNumber}',
                              ].join(' • '),
                              style: const TextStyle(fontSize: 6, color: AppColors.textSecondary),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          const SizedBox(height: 4),
                          Container(
                            padding: const EdgeInsets.all(4),
                            decoration: BoxDecoration(
                              color: const Color(0xFFF9FAFB),
                              borderRadius: BorderRadius.circular(4),
                              border: Border.all(color: const Color(0xFFE5E7EB)),
                            ),
                            child: Text(
                              isSw ? 'Mteja: Fatuma Hassan' : 'Customer: Fatuma Hassan',
                              style: const TextStyle(fontSize: 6, fontWeight: FontWeight.w600),
                            ),
                          ),
                          const SizedBox(height: 4),
                          ...List.generate(2, (i) => Padding(
                                padding: const EdgeInsets.only(bottom: 3),
                                child: Row(
                                  children: [
                                    Expanded(
                                      child: Container(
                                        height: 5,
                                        decoration: BoxDecoration(
                                          color: theme.accent.withAlpha(60),
                                          borderRadius: BorderRadius.circular(2),
                                        ),
                                      ),
                                    ),
                                    const SizedBox(width: 4),
                                    Container(
                                      width: 16,
                                      height: 5,
                                      decoration: BoxDecoration(
                                        color: theme.primary.withAlpha(50),
                                        borderRadius: BorderRadius.circular(2),
                                      ),
                                    ),
                                  ],
                                ),
                              )),
                          if (showDiscount)
                            Text(
                              isSw ? '- Punguzo' : '- Discount',
                              style: TextStyle(fontSize: 7, color: theme.secondary),
                            ),
                          const Spacer(),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(isSw ? 'Jumla' : 'Total', style: TextStyle(fontSize: 7, fontWeight: FontWeight.w800, color: theme.primary)),
                              Container(
                                width: 36,
                                height: 6,
                                decoration: BoxDecoration(
                                  color: theme.primary.withAlpha(60),
                                  borderRadius: BorderRadius.circular(3),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 4),
                          Container(
                            height: 8,
                            width: double.infinity,
                            alignment: Alignment.center,
                            decoration: BoxDecoration(
                              color: theme.primary.withAlpha(40),
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: Text(
                              branding.footerText,
                              style: TextStyle(fontSize: 5, color: theme.primary, fontWeight: FontWeight.w600),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            isSw ? template.nameSw : template.nameEn,
            style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w700),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 6),
          SizedBox(
            height: 32,
            child: ElevatedButton(
              onPressed: onUse,
              style: ElevatedButton.styleFrom(
                backgroundColor: isActive ? AppColors.success : const Color(0xFF6264A7),
                padding: EdgeInsets.zero,
              ),
              child: Text(
                isActive ? (isSw ? 'Inatumika' : 'Active') : (isSw ? 'Tumia' : 'Use'),
                style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w700),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
