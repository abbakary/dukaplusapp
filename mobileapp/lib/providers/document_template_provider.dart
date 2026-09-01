import 'dart:convert';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';

import '../core/config/document_templates.dart';
import '../data/services/api_client.dart';
import '../providers/api_provider.dart';
import '../providers/auth_provider.dart';

TenantDocumentConfig configFromApiDoc(
  Map<String, dynamic> raw, {
  String? businessName,
}) {
  final brandingRaw = raw['branding'] as Map<String, dynamic>? ?? {};
  final idsRaw = raw['activeTemplateIds'] as Map<String, dynamic>? ?? {};
  final activeIds = <DocumentType, String>{};
  for (final entry in idsRaw.entries) {
    final type = documentTypeFromApiKey(entry.key);
    if (type != null && entry.value is String) {
      activeIds[type] = entry.value as String;
    }
  }
  final defaults = defaultDocumentConfig(businessName);
  return TenantDocumentConfig(
    activeTemplateIds: {...defaults.activeTemplateIds, ...activeIds},
    branding: DocumentBranding.fromJson(brandingRaw),
  );
}

Map<String, dynamic> configToApiDoc(TenantDocumentConfig config) {
  final branding = config.branding.toJson()..remove('logoUrl');
  return {
    'activeTemplateIds': {
      for (final e in config.activeTemplateIds.entries)
        documentTypeToApiKey(e.key): e.value,
    },
    'branding': branding,
    'updatedAt': DateTime.now().toIso8601String(),
  };
}

class DocumentTemplateNotifier extends StateNotifier<TenantDocumentConfig> {
  DocumentTemplateNotifier(this._ref, this._tenantKey, String? businessName, this._api)
      : super(defaultDocumentConfig(businessName)) {
    _load(businessName);
  }

  final Ref _ref;
  final String _tenantKey;
  final ApiClient _api;
  final _picker = ImagePicker();

  Future<void> _load(String? businessName) async {
    state = await loadDocumentConfig(_tenantKey, businessName: businessName);
    try {
      final res = await _api.getTenantSettings();
      final doc = res['document_config'] as Map<String, dynamic>? ?? {};
      if (doc.isNotEmpty) {
        final mapped = configFromApiDoc(doc, businessName: businessName);
        state = mapped;
        await saveDocumentConfig(_tenantKey, mapped);
      }
    } catch (_) {
      // offline — keep local cache
    }
  }

  Future<void> _persist() async {
    await saveDocumentConfig(_tenantKey, state);
    try {
      await _api.updateTenantSettings({'document_config': configToApiDoc(state)});
    } catch (_) {
      // queued for next sync
    }
  }

  Future<void> setActive(DocumentType type, String templateId) async {
    state = state.copyWith(
      activeTemplateIds: {...state.activeTemplateIds, type: templateId},
    );
    await _persist();
  }

  Future<void> updateBranding(DocumentBranding branding) async {
    state = state.copyWith(branding: branding);
    await _persist();
  }

  Future<void> patchBranding({
    String? logoUrl,
    String? companyName,
    String? footerText,
    String? address,
    String? phone,
    String? tinNumber,
    String? watermark,
  }) async {
    state = state.copyWith(
      branding: state.branding.copyWith(
        logoUrl: logoUrl,
        companyName: companyName,
        footerText: footerText,
        address: address,
        phone: phone,
        tinNumber: tinNumber,
        watermark: watermark,
      ),
    );
    await _persist();
  }

  Future<String?> pickAndUploadLogo() async {
    final picked = await _picker.pickImage(
      source: ImageSource.gallery,
      maxWidth: 420,
      maxHeight: 420,
      imageQuality: 80,
    );
    if (picked == null) return null;

    final bytes = await picked.readAsBytes();
    if (bytes.length > 512000) {
      throw Exception('Logo must be 500 KB or smaller. Try a smaller image.');
    }

    const mime = 'image/jpeg';
    final dataUrl = 'data:$mime;base64,${base64Encode(bytes)}';

    try {
      final res = await _api.uploadDocumentLogo(dataUrl);
      final doc = res['document_config'] as Map<String, dynamic>? ?? {};
      final user = _ref.read(currentUserProvider);
      final mapped = configFromApiDoc(doc, businessName: user?.businessName);
      state = mapped;
      await saveDocumentConfig(_tenantKey, mapped);
      return dataUrl;
    } catch (e) {
      rethrow;
    }
  }

  Future<void> removeLogo() async {
    try {
      final res = await _api.removeDocumentLogo();
      final doc = res['document_config'] as Map<String, dynamic>? ?? {};
      final user = _ref.read(currentUserProvider);
      final mapped = configFromApiDoc(doc, businessName: user?.businessName);
      state = mapped;
      await saveDocumentConfig(_tenantKey, mapped);
    } catch (_) {
      await patchBranding(logoUrl: '');
    }
  }

  Future<void> reload() async {
    final user = _ref.read(currentUserProvider);
    await _load(user?.businessName);
  }
}

final documentTemplateProvider =
    StateNotifierProvider<DocumentTemplateNotifier, TenantDocumentConfig>((ref) {
  final user = ref.watch(currentUserProvider);
  final key = user?.email ?? user?.id ?? 'default';
  final api = ref.watch(apiClientProvider);
  return DocumentTemplateNotifier(ref, key, user?.businessName, api);
});
