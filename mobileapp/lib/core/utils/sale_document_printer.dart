import 'dart:convert';
import 'dart:typed_data';

import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';

import '../config/document_templates.dart';
import '../../data/models/sale_model.dart';
import 'formatters.dart';

String saleDocumentNumber(SaleTransaction sale, DocumentType type) {
  final base = sale.receiptNumber.replaceAll(RegExp(r'\s+'), '-');
  switch (type) {
    case DocumentType.invoice:
      return 'INV-$base';
    case DocumentType.deliveryNote:
      return 'DN-$base';
    case DocumentType.orderNote:
      return 'ON-$base';
  }
}

bool isCompletedSale(SaleTransaction sale) =>
    sale.status == SaleStatus.completed || sale.status == SaleStatus.pendingCredit;

Future<void> printSaleDocument({
  required SaleTransaction sale,
  required DocumentType type,
  required TenantDocumentConfig config,
  required bool isSw,
}) async {
  final bytes = await buildSaleDocumentPdf(
    sale: sale,
    type: type,
    config: config,
    isSw: isSw,
  );
  final title = '${documentTypeTitle(type, isSw)} ${sale.receiptNumber}';
  await Printing.layoutPdf(onLayout: (_) async => bytes, name: title);
}

Future<Uint8List> buildSaleDocumentPdf({
  required SaleTransaction sale,
  required DocumentType type,
  required TenantDocumentConfig config,
  required bool isSw,
}) async {
  final tpl = activeTemplateFor(config, type);
  final branding = config.branding;
  final doc = pw.Document();
  final primary = PdfColor.fromInt(tpl.theme.primary.toARGB32());

  pw.Widget? logoWidget;
  if (branding.logoUrl.startsWith('data:image')) {
    try {
      final raw = base64Decode(branding.logoUrl.split(',').last);
      logoWidget = pw.Image(pw.MemoryImage(raw), height: 36);
    } catch (_) {}
  }

  doc.addPage(
    pw.MultiPage(
      pageFormat: PdfPageFormat.a4,
      margin: const pw.EdgeInsets.all(28),
      build: (ctx) => [
        pw.Container(
          padding: const pw.EdgeInsets.all(14),
          decoration: pw.BoxDecoration(
            color: PdfColors.grey200,
            borderRadius: pw.BorderRadius.circular(8),
          ),
          child: pw.Row(
            mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
            children: [
              pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  pw.Text(
                    documentTypeTitle(type, isSw).toUpperCase(),
                    style: pw.TextStyle(
                      fontSize: 18,
                      fontWeight: pw.FontWeight.bold,
                      color: primary,
                    ),
                  ),
                  pw.SizedBox(height: 4),
                  pw.Text(saleDocumentNumber(sale, type), style: const pw.TextStyle(fontSize: 10)),
                  pw.Text(AppFormatters.date(sale.date), style: const pw.TextStyle(fontSize: 10)),
                ],
              ),
              if (logoWidget != null) logoWidget,
            ],
          ),
        ),
        pw.SizedBox(height: 12),
        pw.Text(
          branding.companyName.isNotEmpty ? branding.companyName : 'Your Business',
          style: pw.TextStyle(fontSize: 12, fontWeight: pw.FontWeight.bold),
        ),
        if (branding.address.isNotEmpty)
          pw.Text(branding.address, style: const pw.TextStyle(fontSize: 9)),
        if (branding.phone.isNotEmpty)
          pw.Text('${isSw ? 'Simu' : 'Phone'}: ${branding.phone}', style: const pw.TextStyle(fontSize: 9)),
        if (branding.tinNumber.isNotEmpty)
          pw.Text('TIN: ${branding.tinNumber}', style: const pw.TextStyle(fontSize: 9)),
        pw.SizedBox(height: 10),
        pw.Container(
          padding: const pw.EdgeInsets.all(10),
          decoration: pw.BoxDecoration(
            border: pw.Border.all(color: PdfColors.grey300),
            borderRadius: pw.BorderRadius.circular(6),
          ),
          child: pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.Text(isSw ? 'MTEJA' : 'CUSTOMER', style: const pw.TextStyle(fontSize: 8)),
              pw.Text(
                sale.customerName?.trim().isNotEmpty == true
                    ? sale.customerName!
                    : (isSw ? 'Mteja wa Kawaida' : 'Walk-in Customer'),
                style: pw.TextStyle(fontSize: 11, fontWeight: pw.FontWeight.bold),
              ),
            ],
          ),
        ),
        pw.SizedBox(height: 12),
        pw.TableHelper.fromTextArray(
          headers: [
            isSw ? 'Bidhaa' : 'Item',
            'Qty',
            isSw ? 'Bei' : 'Price',
            isSw ? 'Jumla' : 'Total',
          ],
          data: sale.items
              .map((i) => [
                    i.productName,
                    i.quantity.toStringAsFixed(i.quantity % 1 == 0 ? 0 : 1),
                    AppFormatters.tsh(i.unitPrice),
                    AppFormatters.tsh(i.total),
                  ])
              .toList(),
          headerStyle: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 9, color: primary),
          cellStyle: const pw.TextStyle(fontSize: 9),
          headerDecoration: const pw.BoxDecoration(color: PdfColors.grey200),
          cellAlignment: pw.Alignment.centerLeft,
          columnWidths: {
            0: const pw.FlexColumnWidth(3),
            1: const pw.FlexColumnWidth(1),
            2: const pw.FlexColumnWidth(1.5),
            3: const pw.FlexColumnWidth(1.5),
          },
        ),
        pw.SizedBox(height: 12),
        pw.Align(
          alignment: pw.Alignment.centerRight,
          child: pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.end,
            children: [
              pw.Text('Subtotal: ${AppFormatters.tsh(sale.subtotal)}', style: const pw.TextStyle(fontSize: 10)),
              pw.Text('VAT (18%): ${AppFormatters.tsh(sale.vatAmount)}', style: const pw.TextStyle(fontSize: 10)),
              pw.Text(
                '${isSw ? 'JUMLA' : 'TOTAL'}: ${AppFormatters.tsh(sale.total)}',
                style: pw.TextStyle(fontSize: 12, fontWeight: pw.FontWeight.bold, color: primary),
              ),
            ],
          ),
        ),
        pw.SizedBox(height: 16),
        pw.Text(
          branding.footerText,
          style: const pw.TextStyle(fontSize: 8, color: PdfColors.grey600),
          textAlign: pw.TextAlign.center,
        ),
      ],
    ),
  );

  return doc.save();
}
