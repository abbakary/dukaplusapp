import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

enum DocumentType { deliveryNote, orderNote, invoice }

DocumentType? documentTypeFromApiKey(String key) {
  switch (key) {
    case 'delivery_note':
    case 'deliveryNote':
      return DocumentType.deliveryNote;
    case 'order_note':
    case 'orderNote':
      return DocumentType.orderNote;
    case 'invoice':
      return DocumentType.invoice;
    default:
      return null;
  }
}

String documentTypeToApiKey(DocumentType type) {
  switch (type) {
    case DocumentType.deliveryNote:
      return 'delivery_note';
    case DocumentType.orderNote:
      return 'order_note';
    case DocumentType.invoice:
      return 'invoice';
  }
}

enum TemplateLayout { classic, modern, corporate, minimal }

class TemplateTheme {
  final Color primary;
  final Color secondary;
  final Color accent;
  final Color cardBg;
  final String headerStyle;

  const TemplateTheme({
    required this.primary,
    required this.secondary,
    required this.accent,
    required this.cardBg,
    this.headerStyle = 'bar',
  });
}

class DocumentTemplate {
  final String id;
  final DocumentType documentType;
  final String nameEn;
  final String nameSw;
  final String descEn;
  final String descSw;
  final TemplateTheme theme;
  final TemplateLayout layout;

  const DocumentTemplate({
    required this.id,
    required this.documentType,
    required this.nameEn,
    required this.nameSw,
    required this.descEn,
    required this.descSw,
    required this.theme,
    required this.layout,
  });
}

class DocumentBranding {
  final String logoUrl;
  final String companyName;
  final String footerText;
  final String address;
  final String phone;
  final String tinNumber;
  final String watermark;

  const DocumentBranding({
    this.logoUrl = '',
    this.companyName = '',
    this.footerText = 'Thank you for your business — Asante kwa biashara yako',
    this.address = '',
    this.phone = '',
    this.tinNumber = '',
    this.watermark = '',
  });

  DocumentBranding copyWith({
    String? logoUrl,
    String? companyName,
    String? footerText,
    String? address,
    String? phone,
    String? tinNumber,
    String? watermark,
  }) =>
      DocumentBranding(
        logoUrl: logoUrl ?? this.logoUrl,
        companyName: companyName ?? this.companyName,
        footerText: footerText ?? this.footerText,
        address: address ?? this.address,
        phone: phone ?? this.phone,
        tinNumber: tinNumber ?? this.tinNumber,
        watermark: watermark ?? this.watermark,
      );

  Map<String, dynamic> toJson() => {
        'logoUrl': logoUrl,
        'companyName': companyName,
        'footerText': footerText,
        'address': address,
        'phone': phone,
        'tinNumber': tinNumber,
        'watermark': watermark,
      };

  factory DocumentBranding.fromJson(Map<String, dynamic> j) => DocumentBranding(
        logoUrl: j['logoUrl'] as String? ?? '',
        companyName: j['companyName'] as String? ?? '',
        footerText: j['footerText'] as String? ?? 'Thank you for your business — Asante kwa biashara yako',
        address: j['address'] as String? ?? '',
        phone: j['phone'] as String? ?? '',
        tinNumber: j['tinNumber'] as String? ?? '',
        watermark: j['watermark'] as String? ?? '',
      );
}

class TenantDocumentConfig {
  final Map<DocumentType, String> activeTemplateIds;
  final DocumentBranding branding;

  const TenantDocumentConfig({
    required this.activeTemplateIds,
    required this.branding,
  });

  TenantDocumentConfig copyWith({
    Map<DocumentType, String>? activeTemplateIds,
    DocumentBranding? branding,
  }) =>
      TenantDocumentConfig(
        activeTemplateIds: activeTemplateIds ?? this.activeTemplateIds,
        branding: branding ?? this.branding,
      );

  Map<String, dynamic> toJson() => {
        'activeTemplateIds': {
          for (final e in activeTemplateIds.entries)
            documentTypeToApiKey(e.key): e.value,
        },
        'branding': branding.toJson(),
      };

  factory TenantDocumentConfig.fromJson(Map<String, dynamic> j) {
    final raw = j['activeTemplateIds'] as Map<String, dynamic>? ?? {};
    final activeIds = <DocumentType, String>{};
    for (final entry in raw.entries) {
      final type = documentTypeFromApiKey(entry.key);
      if (type != null && entry.value is String) {
        activeIds[type] = entry.value as String;
      }
    }
    final defaults = defaultDocumentConfig(null);
    return TenantDocumentConfig(
      activeTemplateIds: {...defaults.activeTemplateIds, ...activeIds},
      branding: DocumentBranding.fromJson(j['branding'] as Map<String, dynamic>? ?? {}),
    );
  }
}

const builtInTemplates = <DocumentTemplate>[
  // Delivery notes
  DocumentTemplate(
    id: 'dn-classic-teal',
    documentType: DocumentType.deliveryNote,
    nameEn: 'Classic Teal Header',
    nameSw: 'Kichwa cha Teal',
    descEn: 'Dark teal header with itemized grid.',
    descSw: 'Kichwa cha teal na jedwali la bidhaa.',
    theme: TemplateTheme(
      primary: Color(0xFF0F766E),
      secondary: Color(0xFF134E4A),
      accent: Color(0xFFF59E0B),
      cardBg: Color(0xFFFEF3C7),
    ),
    layout: TemplateLayout.classic,
  ),
  DocumentTemplate(
    id: 'dn-minimal-blue',
    documentType: DocumentType.deliveryNote,
    nameEn: 'Minimal Blue Grid',
    nameSw: 'Grid ya Bluu Rahisi',
    descEn: 'Clean white layout with blue accents.',
    descSw: 'Muundo safi wa bluu.',
    theme: TemplateTheme(
      primary: Color(0xFF2563EB),
      secondary: Color(0xFF1E40AF),
      accent: Color(0xFF93C5FD),
      cardBg: Color(0xFFDBEAFE),
      headerStyle: 'minimal',
    ),
    layout: TemplateLayout.minimal,
  ),
  DocumentTemplate(
    id: 'dn-corporate-wave',
    documentType: DocumentType.deliveryNote,
    nameEn: 'Corporate Wave',
    nameSw: 'Wimbi la Kampuni',
    descEn: 'Navy wave header with order meta.',
    descSw: 'Kichwa cha navy na maelezo ya agizo.',
    theme: TemplateTheme(
      primary: Color(0xFF1E3A5F),
      secondary: Color(0xFF0EA5E9),
      accent: Color(0xFF14B8A6),
      cardBg: Color(0xFFCCFBF1),
      headerStyle: 'wave',
    ),
    layout: TemplateLayout.corporate,
  ),
  DocumentTemplate(
    id: 'dn-modern-beige',
    documentType: DocumentType.deliveryNote,
    nameEn: 'Modern Beige',
    nameSw: 'Beige ya Kisasa',
    descEn: 'Beige boutique with tax breakdown.',
    descSw: 'Mtindo wa beige na jumla ya kodi.',
    theme: TemplateTheme(
      primary: Color(0xFF115E59),
      secondary: Color(0xFFD97706),
      accent: Color(0xFFF5F5DC),
      cardBg: Color(0xFFFEF9C3),
      headerStyle: 'sidebar',
    ),
    layout: TemplateLayout.modern,
  ),
  // Order notes
  DocumentTemplate(
    id: 'on-warm-classic',
    documentType: DocumentType.orderNote,
    nameEn: 'Warm Classic',
    nameSw: 'Classic ya Joto',
    descEn: 'Peach/tan order summary table.',
    descSw: 'Jedwali la agizo la peach.',
    theme: TemplateTheme(
      primary: Color(0xFFEA580C),
      secondary: Color(0xFFFDBA74),
      accent: Color(0xFFFEF3C7),
      cardBg: Color(0xFFFFEDD5),
    ),
    layout: TemplateLayout.classic,
  ),
  DocumentTemplate(
    id: 'on-creative-curve',
    documentType: DocumentType.orderNote,
    nameEn: 'Creative Curve',
    nameSw: 'Curve ya Ubunifu',
    descEn: 'Teal curved sidebar layout.',
    descSw: 'Sidebar ya teal.',
    theme: TemplateTheme(
      primary: Color(0xFF0D9488),
      secondary: Color(0xFF1E3A8A),
      accent: Color(0xFF99F6E4),
      cardBg: Color(0xFFECFEFF),
      headerStyle: 'sidebar',
    ),
    layout: TemplateLayout.modern,
  ),
  DocumentTemplate(
    id: 'on-navy-corporate',
    documentType: DocumentType.orderNote,
    nameEn: 'Navy Corporate',
    nameSw: 'Navy ya Kampuni',
    descEn: 'Dark navy with teal table headers.',
    descSw: 'Navy na jedwali la teal.',
    theme: TemplateTheme(
      primary: Color(0xFF1E293B),
      secondary: Color(0xFF0EA5E9),
      accent: Color(0xFF14B8A6),
      cardBg: Color(0xFFE0F2FE),
      headerStyle: 'wave',
    ),
    layout: TemplateLayout.corporate,
  ),
  DocumentTemplate(
    id: 'on-minimal-grid',
    documentType: DocumentType.orderNote,
    nameEn: 'Minimal Grid',
    nameSw: 'Grid Rahisi',
    descEn: 'Structured delivery-to fields.',
    descSw: 'Sehemu ya mteja iliyopangwa.',
    theme: TemplateTheme(
      primary: Color(0xFF1E40AF),
      secondary: Color(0xFF64748B),
      accent: Color(0xFFCBD5E1),
      cardBg: Color(0xFFF1F5F9),
      headerStyle: 'sidebar',
    ),
    layout: TemplateLayout.minimal,
  ),
  // Invoices
  DocumentTemplate(
    id: 'inv-minimal-round',
    documentType: DocumentType.invoice,
    nameEn: 'Minimal Rounded',
    nameSw: 'Rounded Rahisi',
    descEn: 'Yellow/grey circular accents.',
    descSw: 'Midundo ya manjano.',
    theme: TemplateTheme(
      primary: Color(0xFFCA8A04),
      secondary: Color(0xFF374151),
      accent: Color(0xFFFDE047),
      cardBg: Color(0xFFFEFCE8),
      headerStyle: 'brush',
    ),
    layout: TemplateLayout.minimal,
  ),
  DocumentTemplate(
    id: 'inv-artistic-brush',
    documentType: DocumentType.invoice,
    nameEn: 'Artistic Brush',
    nameSw: 'Brush ya Sanaa',
    descEn: 'Brushstroke header design.',
    descSw: 'Kichwa cha brush.',
    theme: TemplateTheme(
      primary: Color(0xFF0F766E),
      secondary: Color(0xFF1E293B),
      accent: Color(0xFFF5F5DC),
      cardBg: Color(0xFFECFEFF),
      headerStyle: 'brush',
    ),
    layout: TemplateLayout.modern,
  ),
  DocumentTemplate(
    id: 'inv-professional-grid',
    documentType: DocumentType.invoice,
    nameEn: 'Professional Grid',
    nameSw: 'Grid ya Kitaalamu',
    descEn: 'Structured grid with highlighted totals.',
    descSw: 'Grid na jumla iliyoangaziwa.',
    theme: TemplateTheme(
      primary: Color(0xFFEA580C),
      secondary: Color(0xFF0D9488),
      accent: Color(0xFFFED7AA),
      cardBg: Color(0xFFFFF7ED),
    ),
    layout: TemplateLayout.classic,
  ),
  DocumentTemplate(
    id: 'inv-tech-corporate',
    documentType: DocumentType.invoice,
    nameEn: 'Tech Corporate',
    nameSw: 'Tech ya Kampuni',
    descEn: 'Blue waves with QR slot.',
    descSw: 'Mawimbi ya bluu na QR.',
    theme: TemplateTheme(
      primary: Color(0xFF2563EB),
      secondary: Color(0xFF1E293B),
      accent: Color(0xFF60A5FA),
      cardBg: Color(0xFFEFF6FF),
      headerStyle: 'wave',
    ),
    layout: TemplateLayout.corporate,
  ),
];

TenantDocumentConfig defaultDocumentConfig(String? businessName) => TenantDocumentConfig(
      activeTemplateIds: const {
        DocumentType.deliveryNote: 'dn-classic-teal',
        DocumentType.orderNote: 'on-warm-classic',
        DocumentType.invoice: 'inv-minimal-round',
      },
      branding: DocumentBranding(companyName: businessName ?? ''),
    );

List<DocumentTemplate> templatesForType(DocumentType type) =>
    builtInTemplates.where((t) => t.documentType == type).toList();

DocumentTemplate activeTemplateFor(TenantDocumentConfig config, DocumentType type) {
  final id = config.activeTemplateIds[type] ?? builtInTemplates.first.id;
  return builtInTemplates.firstWhere((t) => t.id == id, orElse: () => templatesForType(type).first);
}

Future<TenantDocumentConfig> loadDocumentConfig(String tenantKey, {String? businessName}) async {
  final prefs = await SharedPreferences.getInstance();
  final raw = prefs.getString('duka_document_templates_$tenantKey');
  if (raw == null) return defaultDocumentConfig(businessName);
  try {
    return TenantDocumentConfig.fromJson(jsonDecode(raw) as Map<String, dynamic>);
  } catch (_) {
    return defaultDocumentConfig(businessName);
  }
}

Future<void> saveDocumentConfig(String tenantKey, TenantDocumentConfig config) async {
  final prefs = await SharedPreferences.getInstance();
  await prefs.setString('duka_document_templates_$tenantKey', jsonEncode(config.toJson()));
}

String documentTypeTitle(DocumentType type, bool isSw) {
  switch (type) {
    case DocumentType.deliveryNote:
      return isSw ? 'Noti ya Uwasilishaji' : 'Delivery Note';
    case DocumentType.orderNote:
      return isSw ? 'Noti ya Agizo' : 'Order Note';
    case DocumentType.invoice:
      return isSw ? 'Ankara' : 'Invoice Note';
  }
}
