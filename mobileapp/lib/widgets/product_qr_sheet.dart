import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:path_provider/path_provider.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:share_plus/share_plus.dart';

import '../core/theme/app_colors.dart';
import '../core/utils/formatters.dart';
import '../core/utils/product_qr.dart';
import '../data/models/product_model.dart';
import '../l10n/app_localizations.dart';
import '../providers/locale_provider.dart';

Future<void> showProductQrSheet(
  BuildContext context, {
  Product? product,
  List<Product>? allProducts,
}) {
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (_) => _ProductQrSheet(
      product: product,
      allProducts: allProducts ?? (product != null ? [product] : const []),
    ),
  );
}

class _ProductQrSheet extends ConsumerStatefulWidget {
  const _ProductQrSheet({this.product, required this.allProducts});

  final Product? product;
  final List<Product> allProducts;

  @override
  ConsumerState<_ProductQrSheet> createState() => _ProductQrSheetState();
}

class _ProductQrSheetState extends ConsumerState<_ProductQrSheet> {
  late _QrMode _mode;
  bool _downloading = false;

  @override
  void initState() {
    super.initState();
    _mode = widget.product != null ? _QrMode.single : _QrMode.batch;
  }

  Product? get _activeProduct =>
      widget.product ?? (widget.allProducts.isNotEmpty ? widget.allProducts.first : null);

  Future<Uint8List?> _renderQrPng(String data, {int size = 480}) async {
    final painter = QrPainter(
      data: data,
      version: QrVersions.auto,
      gapless: true,
      eyeStyle: const QrEyeStyle(
        eyeShape: QrEyeShape.square,
        color: Color(0xFF1E213D),
      ),
      dataModuleStyle: const QrDataModuleStyle(
        dataModuleShape: QrDataModuleShape.square,
        color: Color(0xFF1E213D),
      ),
    );
    final imageData = await painter.toImageData(size.toDouble(), format: ui.ImageByteFormat.png);
    return imageData?.buffer.asUint8List();
  }

  String _safeFileName(Product p) =>
      'QR_${p.sku}_${p.name.replaceAll(RegExp(r'\s+'), '_')}';

  Future<void> _downloadSingle(Product p) async {
    final l10n = ref.read(appLocalizationsProvider);
    setState(() => _downloading = true);
    try {
      final bytes = await _renderQrPng(getProductQrPayloadString(p));
      if (bytes == null) throw Exception('QR render failed');
      await _saveOrShare(bytes, '${_safeFileName(p)}.png', l10n);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(l10n.errorMessage(e.toString())), backgroundColor: AppColors.danger),
        );
      }
    } finally {
      if (mounted) setState(() => _downloading = false);
    }
  }

  Future<void> _downloadAll() async {
    final l10n = ref.read(appLocalizationsProvider);
    if (widget.allProducts.isEmpty) return;
    setState(() => _downloading = true);
    var saved = 0;
    try {
      if (kIsWeb) {
        for (final p in widget.allProducts) {
          final bytes = await _renderQrPng(getProductQrPayloadString(p), size: 320);
          if (bytes != null) {
            await _saveOrShare(bytes, '${_safeFileName(p)}.png', l10n, silent: true);
            saved++;
          }
        }
      } else {
        final dir = await getApplicationDocumentsDirectory();
        final folder = Directory('${dir.path}/duka_qr_labels');
        if (!await folder.exists()) await folder.create(recursive: true);
        for (final p in widget.allProducts) {
          final bytes = await _renderQrPng(getProductQrPayloadString(p), size: 320);
          if (bytes == null) continue;
          final file = File('${folder.path}/${_safeFileName(p)}.png');
          await file.writeAsBytes(bytes);
          saved++;
        }
        await Share.shareXFiles(
          widget.allProducts.map((p) {
            final path = '${folder.path}/${_safeFileName(p)}.png';
            return XFile(path);
          }).toList(),
          subject: l10n.qrShelfLabels,
        );
      }
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(l10n.qrDownloadedCount(saved)),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(l10n.errorMessage(e.toString())), backgroundColor: AppColors.danger),
        );
      }
    } finally {
      if (mounted) setState(() => _downloading = false);
    }
  }

  Future<void> _saveOrShare(
    Uint8List bytes,
    String filename,
    AppLocalizations l10n, {
    bool silent = false,
  }) async {
    if (kIsWeb) {
      await Share.shareXFiles([XFile.fromData(bytes, name: filename, mimeType: 'image/png')]);
      return;
    }
    final dir = await getTemporaryDirectory();
    final file = File('${dir.path}/$filename');
    await file.writeAsBytes(bytes);
    await Share.shareXFiles([XFile(file.path)], subject: l10n.qrShelfLabels);
    if (!silent && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(l10n.qrDownloaded), behavior: SnackBarBehavior.floating),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = ref.watch(appLocalizationsProvider);
    final p = _activeProduct;

    return DraggableScrollableSheet(
      initialChildSize: 0.88,
      minChildSize: 0.5,
      maxChildSize: 0.95,
      builder: (_, ctrl) => Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: Column(
          children: [
            const SizedBox(height: 10),
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: AppColors.border,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            _Header(l10n: l10n, product: p, count: widget.allProducts.length),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Row(
                children: [
                  Expanded(
                    child: _ModeChip(
                      label: l10n.qrSingleItem,
                      selected: _mode == _QrMode.single,
                      onTap: p == null ? null : () => setState(() => _mode = _QrMode.single),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: _ModeChip(
                      label: l10n.qrAllItems(widget.allProducts.length),
                      selected: _mode == _QrMode.batch,
                      onTap: widget.allProducts.isEmpty
                          ? null
                          : () => setState(() => _mode = _QrMode.batch),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
            Expanded(
              child: _mode == _QrMode.single && p != null
                  ? _SingleQrView(l10n: l10n, product: p)
                  : _BatchQrView(l10n: l10n, products: widget.allProducts),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
              child: Row(
                children: [
                  if (_mode == _QrMode.single && p != null)
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: _downloading ? null : () => _downloadSingle(p),
                        icon: const Icon(Icons.download_rounded, size: 18),
                        label: Text(l10n.downloadQr),
                      ),
                    ),
                  if (_mode == _QrMode.batch) ...[
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: _downloading || widget.allProducts.isEmpty
                            ? null
                            : _downloadAll,
                        icon: _downloading
                            ? const SizedBox(
                                width: 18,
                                height: 18,
                                child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                              )
                            : const Icon(Icons.download_for_offline_rounded, size: 18),
                        label: Text(l10n.downloadAllQr),
                      ),
                    ),
                  ],
                ],
              ),
            ),
            const SafeArea(top: false, child: SizedBox.shrink()),
          ],
        ),
      ),
    );
  }
}

enum _QrMode { single, batch }

class _Header extends StatelessWidget {
  const _Header({required this.l10n, this.product, required this.count});

  final AppLocalizations l10n;
  final Product? product;
  final int count;

  @override
  Widget build(BuildContext context) => Container(
        width: double.infinity,
        margin: const EdgeInsets.fromLTRB(16, 12, 16, 12),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [Color(0xFF24284A), Color(0xFF0078D4)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(16),
        ),
        child: Row(
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.15),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Icon(Icons.qr_code_2_rounded, color: Colors.white, size: 26),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    l10n.qrShelfLabels,
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w700,
                      fontSize: 15,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    product != null
                        ? '${product!.name} • SKU: ${product!.sku}'
                        : l10n.qrAllItems(count),
                    style: TextStyle(color: Colors.white.withOpacity(0.85), fontSize: 11),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
          ],
        ),
      );
}

class _ModeChip extends StatelessWidget {
  const _ModeChip({required this.label, required this.selected, this.onTap});

  final String label;
  final bool selected;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) => Material(
        color: selected ? AppColors.primary.withOpacity(0.12) : AppColors.background,
        borderRadius: BorderRadius.circular(10),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(10),
          child: Container(
            padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 8),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(10),
              border: Border.all(
                color: selected ? AppColors.primary : AppColors.border,
              ),
            ),
            child: Text(
              label,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: onTap == null
                    ? AppColors.textHint
                    : selected
                        ? AppColors.primary
                        : AppColors.textSecondary,
              ),
            ),
          ),
        ),
      );
}

class _SingleQrView extends StatelessWidget {
  const _SingleQrView({required this.l10n, required this.product});

  final AppLocalizations l10n;
  final Product product;

  @override
  Widget build(BuildContext context) {
    final payload = getProductQrPayloadString(product);
    return ListView(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      children: [
        Center(
          child: Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: AppColors.border),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.06),
                  blurRadius: 12,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Column(
              children: [
                QrImageView(
                  data: payload,
                  version: QrVersions.auto,
                  size: 220,
                  backgroundColor: Colors.white,
                  eyeStyle: const QrEyeStyle(color: Color(0xFF1E213D)),
                  dataModuleStyle: const QrDataModuleStyle(color: Color(0xFF1E213D)),
                ),
                const SizedBox(height: 12),
                Text(
                  product.name,
                  style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 14),
                  textAlign: TextAlign.center,
                ),
                Text(
                  'SKU: ${product.sku}',
                  style: const TextStyle(fontSize: 11, color: AppColors.textSecondary),
                ),
                Text(
                  AppFormatters.tsh(product.price),
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w800,
                    color: AppColors.primary,
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 16),
        Text(
          l10n.qrScanHint,
          style: const TextStyle(fontSize: 12, color: AppColors.textSecondary),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }
}

class _BatchQrView extends StatelessWidget {
  const _BatchQrView({required this.l10n, required this.products});

  final AppLocalizations l10n;
  final List<Product> products;

  @override
  Widget build(BuildContext context) {
    if (products.isEmpty) {
      return Center(child: Text(l10n.noProductsYet));
    }
    return GridView.builder(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        mainAxisSpacing: 10,
        crossAxisSpacing: 10,
        childAspectRatio: 0.72,
      ),
      itemCount: products.length,
      itemBuilder: (_, i) {
        final p = products[i];
        return Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: AppColors.border),
          ),
          child: Column(
            children: [
              Expanded(
                child: QrImageView(
                  data: getProductQrPayloadString(p),
                  version: QrVersions.auto,
                  backgroundColor: Colors.white,
                  eyeStyle: const QrEyeStyle(color: Color(0xFF1E213D)),
                  dataModuleStyle: const QrDataModuleStyle(color: Color(0xFF1E213D)),
                ),
              ),
              const SizedBox(height: 6),
              Text(
                p.name,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w600),
              ),
              Text(
                p.sku,
                style: const TextStyle(fontSize: 9, color: AppColors.textHint),
              ),
              Text(
                AppFormatters.tsh(p.price),
                style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w700, color: AppColors.primary),
              ),
            ],
          ),
        );
      },
    );
  }
}
