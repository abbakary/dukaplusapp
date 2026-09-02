import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/config/business_settings.dart';
import '../../core/config/document_templates.dart';
import '../../core/theme/app_colors.dart';
import '../../core/utils/formatters.dart';
import '../../core/utils/sale_document_printer.dart';
import '../../data/models/sale_model.dart';
import '../../providers/business_settings_provider.dart';
import '../../providers/document_template_provider.dart';
import '../../l10n/app_localizations.dart';
import '../../providers/locale_provider.dart';
import '../../providers/sales_provider.dart';
import '../../widgets/gradient_app_bar.dart';
import '../../widgets/search_bar_widget.dart';
import '../../widgets/shimmer_loader.dart';

class TransactionHistoryScreen extends ConsumerStatefulWidget {
  const TransactionHistoryScreen({super.key});

  @override
  ConsumerState<TransactionHistoryScreen> createState() => _TransactionHistoryScreenState();
}

class _TransactionHistoryScreenState extends ConsumerState<TransactionHistoryScreen> {
  String _query = '';
  int _days = 30;
  String? _printingId;

  @override
  Widget build(BuildContext context) {
    final l10n = ref.watch(appLocalizationsProvider);
    final isSw = ref.watch(localeProvider) == AppLanguage.sw;
    final salesAsync = ref.watch(salesProvider);
    final docConfig = ref.watch(documentTemplateProvider);
    final settings = ref.watch(businessSettingsProvider);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: GradientAppBar(
        title: isSw ? 'Mauzo & Hati' : 'Sales & Documents',
        subtitle: isSw ? 'Chapisha ankara na noti za mauzo' : 'Print invoices and sale documents',
      ),
      body: Column(
        children: [
          Container(
            color: Colors.white,
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
            child: Column(
              children: [
                AppSearchBar(
                  hint: isSw ? 'Tafuta risiti, mteja…' : 'Search receipt, customer…',
                  onChanged: (q) => setState(() => _query = q),
                ),
                const SizedBox(height: 10),
                Row(
                  children: [
                    Text(isSw ? 'Kipindi:' : 'Period:', style: const TextStyle(fontSize: 12, color: AppColors.textSecondary)),
                    const SizedBox(width: 8),
                    Expanded(
                      child: DropdownButtonFormField<int>(
                        value: _days,
                        decoration: InputDecoration(
                          isDense: true,
                          contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                        ),
                        items: [
                          DropdownMenuItem(value: 7, child: Text(isSw ? 'Siku 7' : '7 days')),
                          DropdownMenuItem(value: 30, child: Text(isSw ? 'Siku 30' : '30 days')),
                          DropdownMenuItem(value: 90, child: Text(isSw ? 'Miezi 3' : '3 months')),
                          DropdownMenuItem(value: 365, child: Text(isSw ? 'Mwaka 1' : '1 year')),
                        ],
                        onChanged: (v) => setState(() => _days = v ?? 30),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          Expanded(
            child: salesAsync.when(
              loading: () => const ShimmerList(),
              error: (e, _) => Center(child: Text(l10n.errorMessage(e.toString()))),
              data: (sales) {
                final cutoff = DateTime.now().subtract(Duration(days: _days));
                final completed = sales.where(isCompletedSale).where((s) => !s.date.isBefore(cutoff)).toList()
                  ..sort((a, b) => b.date.compareTo(a.date));

                final q = _query.trim().toLowerCase();
                final filtered = q.isEmpty
                    ? completed
                    : completed.where((s) {
                        return s.receiptNumber.toLowerCase().contains(q) ||
                            (s.customerName ?? '').toLowerCase().contains(q);
                      }).toList();

                if (filtered.isEmpty) {
                  return Center(
                    child: Text(
                      isSw ? 'Hakuna mauzo yaliyokamilika.' : 'No completed sales found.',
                      style: const TextStyle(color: AppColors.textSecondary),
                    ),
                  );
                }

                return RefreshIndicator(
                  onRefresh: () async => ref.read(salesRefreshProvider.notifier).state++,
                  child: ListView.builder(
                    padding: const EdgeInsets.all(12),
                    itemCount: filtered.length,
                    itemBuilder: (_, i) {
                      final sale = filtered[i];
                      final busy = _printingId == sale.id;
                      return Card(
                        margin: const EdgeInsets.only(bottom: 10),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                        child: Padding(
                          padding: const EdgeInsets.all(14),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Expanded(
                                    child: Text(
                                      sale.receiptNumber,
                                      style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 14),
                                    ),
                                  ),
                                  Text(
                                    AppFormatters.tsh(sale.total),
                                    style: TextStyle(
                                      fontWeight: FontWeight.w800,
                                      color: Theme.of(context).colorScheme.primary,
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 4),
                              Text(
                                '${AppFormatters.dateTime(sale.date)} · ${sale.customerName ?? (isSw ? 'Mteja wa Kawaida' : 'Walk-in')}',
                                style: const TextStyle(fontSize: 11, color: AppColors.textSecondary),
                              ),
                              const SizedBox(height: 10),
                              Wrap(
                                spacing: 8,
                                runSpacing: 8,
                                children: DocumentType.values.map((type) {
                                  return OutlinedButton.icon(
                                    onPressed: busy
                                        ? null
                                        : () => _printDoc(sale, type, docConfig, settings, isSw),
                                    icon: busy
                                        ? const SizedBox(
                                            width: 14,
                                            height: 14,
                                            child: CircularProgressIndicator(strokeWidth: 2),
                                          )
                                        : const Icon(Icons.print_outlined, size: 16),
                                    label: Text(
                                      documentTypeTitle(type, isSw),
                                      style: const TextStyle(fontSize: 11),
                                    ),
                                  );
                                }).toList(),
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _printDoc(
    SaleTransaction sale,
    DocumentType type,
    TenantDocumentConfig config,
    BusinessSettings settings,
    bool isSw,
  ) async {
    setState(() => _printingId = sale.id);
    try {
      await printSaleDocument(
        sale: sale,
        type: type,
        config: config,
        isSw: isSw,
        settings: settings,
      );
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('${isSw ? 'Imeshindikana' : 'Failed'}: $e'), backgroundColor: AppColors.danger),
        );
      }
    } finally {
      if (mounted) setState(() => _printingId = null);
    }
  }
}
