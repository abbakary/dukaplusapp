import 'dart:typed_data';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';

import '../constants/app_constants.dart';
import '../../data/models/dashboard_model.dart';
import '../../data/models/user_model.dart';
import 'formatters.dart';

// ─────────────────────────────────────────────────────────────────────────────
// Helper — PdfColor doesn't have .withOpacity(); use this instead.
// alpha is 0.0–1.0
// ─────────────────────────────────────────────────────────────────────────────
PdfColor _alpha(PdfColor c, double alpha) =>
    PdfColor(c.red, c.green, c.blue, alpha);

// ─────────────────────────────────────────────────────────────────────────────
// Colour palette — matches the template image
// ─────────────────────────────────────────────────────────────────────────────
class _C {
  static const headerL   = PdfColor.fromInt(0xFF0C3078); // deep navy
  static const headerM   = PdfColor.fromInt(0xFF0078D4); // MS blue
  static const headerR   = PdfColor.fromInt(0xFFDC5A14); // orange
  static const accent    = PdfColor.fromInt(0xFF0078D4);
  static const white     = PdfColors.white;
  static const offWhite  = PdfColor.fromInt(0xFFF5F7FC);
  static const footerBg  = PdfColor.fromInt(0xFF1C2232);
  static const footerTxt = PdfColor.fromInt(0xFFB4BED2);
  static const footerBld = PdfColors.white;
  static const border    = PdfColor.fromInt(0xFFDCE1EB);
  static const tblHead   = PdfColor.fromInt(0xFF0078D4);
  static const tblAlt    = PdfColor.fromInt(0xFFF2F6FF);
  static const text      = PdfColor.fromInt(0xFF1E283C);
  static const textMuted = PdfColor.fromInt(0xFF64738C);
  static const green     = PdfColor.fromInt(0xFF107C10);
  static const orange    = PdfColor.fromInt(0xFFC85A0A);
  static const purple    = PdfColor.fromInt(0xFF6264A7);
}

// ─────────────────────────────────────────────────────────────────────────────
// Data models
// ─────────────────────────────────────────────────────────────────────────────
class ReportKpi {
  final String label;
  final String value;
  final PdfColor color;
  const ReportKpi({required this.label, required this.value, this.color = _C.accent});
}

class ReportConfig {
  final String             title;
  final String?            subtitle;
  final AuthUser?          user;
  final String?            clientName;
  final List<ReportKpi>    kpis;
  final List<String>       tableHeaders;
  final List<List<String>> tableRows;
  final String?            notes;
  final bool               isSw;

  const ReportConfig({
    required this.title,
    this.subtitle,
    this.user,
    this.clientName,
    this.kpis         = const [],
    this.tableHeaders = const [],
    this.tableRows    = const [],
    this.notes,
    this.isSw         = false,
  });
}

// ─────────────────────────────────────────────────────────────────────────────
// Builder
// ─────────────────────────────────────────────────────────────────────────────
class ReportPdfBuilder {
  static Future<Uint8List> build(ReportConfig cfg) async {
    final doc      = pw.Document();
    final font     = await PdfGoogleFonts.openSansRegular();
    final fontBold = await PdfGoogleFonts.openSansBold();
    final dateStr  = AppFormatters.date(DateTime.now());

    doc.addPage(pw.MultiPage(
      pageFormat: PdfPageFormat.a4,
      margin:     const pw.EdgeInsets.all(0),
      build: (ctx) => [
        _buildHeader(cfg, fontBold),
        pw.SizedBox(height: 12),
        pw.Padding(
          padding: const pw.EdgeInsets.symmetric(horizontal: 16),
          child: _buildProviderBlock(cfg, font, fontBold),
        ),
        pw.SizedBox(height: 12),
        if (cfg.kpis.isNotEmpty) ...[
          pw.Padding(
            padding: const pw.EdgeInsets.symmetric(horizontal: 16),
            child: _buildKpiStrip(cfg.kpis, fontBold, font),
          ),
          pw.SizedBox(height: 12),
        ],
        if (cfg.tableRows.isNotEmpty) ...[
          pw.Padding(
            padding: const pw.EdgeInsets.symmetric(horizontal: 16),
            child: _buildTable(cfg, font, fontBold),
          ),
          pw.SizedBox(height: 12),
        ],
        pw.Padding(
          padding: const pw.EdgeInsets.symmetric(horizontal: 16),
          child: _buildChartStrip(font, cfg.isSw),
        ),
        if (cfg.notes != null) ...[
          pw.SizedBox(height: 12),
          pw.Padding(
            padding: const pw.EdgeInsets.symmetric(horizontal: 16),
            child: _buildNotes(cfg.notes!, font, fontBold, cfg.isSw),
          ),
        ],
        pw.Spacer(),
        _buildFooter(cfg, font, fontBold, dateStr),
      ],
    ));

    return doc.save();
  }

  // ── Header ──────────────────────────────────────────────────────────────
  static pw.Widget _buildHeader(ReportConfig cfg, pw.Font fontBold) {
    return pw.Container(
      width: double.infinity,
      height: 110,
      decoration: const pw.BoxDecoration(
        gradient: pw.LinearGradient(
          colors: [_C.headerL, _C.headerM, _C.headerR],
          begin:  pw.Alignment.centerLeft,
          end:    pw.Alignment.centerRight,
        ),
      ),
      child: pw.Stack(
        children: [
          // Decorative circles (opacity via _alpha helper)
          pw.Positioned(
            top: -30, left: -20,
            child: _circle(80, _alpha(_C.white, 0.05)),
          ),
          pw.Positioned(
            top: -20, right: -25,
            child: _circle(90, _alpha(_C.headerR, 0.25)),
          ),
          // Mini bar chart (left)
          pw.Positioned(
            left: 24, top: 16,
            child: pw.Row(
              crossAxisAlignment: pw.CrossAxisAlignment.end,
              children: [
                _bar(8, 18, PdfColors.yellow),
                pw.SizedBox(width: 3),
                _bar(8, 26, PdfColors.green),
                pw.SizedBox(width: 3),
                _bar(8, 34, _C.headerM),
              ],
            ),
          ),
          // Mini pie icon (right)
          pw.Positioned(
            right: 28, top: 10,
            child: pw.Container(
              width: 40, height: 40,
              decoration: pw.BoxDecoration(
                shape: pw.BoxShape.circle,
                color: _alpha(_C.white, 0.15),
              ),
              child: pw.Center(
                child: pw.Text('●',
                  style: pw.TextStyle(
                    font: fontBold, fontSize: 22,
                    color: _alpha(_C.white, 0.70))),
              ),
            ),
          ),
          // Title
          pw.Center(
            child: pw.Column(
              mainAxisAlignment: pw.MainAxisAlignment.center,
              children: [
                pw.SizedBox(height: 20),
                pw.Text(
                  cfg.title.toUpperCase(),
                  style: pw.TextStyle(
                    font: fontBold, fontSize: 22,
                    color: _C.white,
                    letterSpacing: 1.0,
                  ),
                  textAlign: pw.TextAlign.center,
                ),
                pw.SizedBox(height: 6),
                pw.Text(
                  cfg.subtitle ?? (cfg.isSw
                    ? 'Ripoti ya Biashara — Duka+'
                    : 'Business Report — Duka+'),
                  style: pw.TextStyle(
                    font: fontBold, fontSize: 10,
                    color: _alpha(_C.white, 0.85),
                  ),
                  textAlign: pw.TextAlign.center,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ── Provider profile ────────────────────────────────────────────────────
  static pw.Widget _buildProviderBlock(
      ReportConfig cfg, pw.Font font, pw.Font fontBold) {
    final u   = cfg.user;
    final isSw = cfg.isSw;

    return pw.Container(
      decoration: pw.BoxDecoration(
        color: _C.offWhite,
        border: pw.Border.all(color: _C.border, width: 0.5),
        borderRadius: pw.BorderRadius.circular(6),
      ),
      padding: const pw.EdgeInsets.all(12),
      child: pw.Row(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          // Left column
          pw.Expanded(
            flex: 3,
            child: pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                pw.Text(
                  u?.businessName ?? 'Duka+ Business',
                  style: pw.TextStyle(font: fontBold, fontSize: 13, color: _C.text),
                ),
                pw.SizedBox(height: 4),
                _infoRow(isSw ? 'Mmiliki'    : 'Owner',    u?.name      ?? '—', font),
                _infoRow(isSw ? 'Barua pepe' : 'Email',    u?.email     ?? '—', font),
                if (u?.phone      != null) _infoRow(isSw ? 'Simu'  : 'Phone', u!.phone!,      font),
                if (u?.tinNumber  != null) _infoRow('TIN',                     u!.tinNumber!,  font),
              ],
            ),
          ),
          pw.SizedBox(width: 10),
          // Right column
          pw.Expanded(
            flex: 2,
            child: pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                pw.Text(
                  isSw ? 'Taarifa Zaidi' : 'Additional Info',
                  style: pw.TextStyle(font: fontBold, fontSize: 9, color: _C.text),
                ),
                pw.SizedBox(height: 4),
                if (u?.branch      != null) _infoRow(isSw ? 'Tawi'   : 'Branch', u!.branch!,       font),
                if (u?.businessType != null) _infoRow(isSw ? 'Aina'  : 'Type',   u!.businessType!, font),
                if (u?.plan        != null) _infoRow(isSw ? 'Mpango' : 'Plan',   u!.plan!,         font),
              ],
            ),
          ),
          // Badge
          pw.Container(
            padding: const pw.EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: pw.BoxDecoration(
              color: _C.accent,
              borderRadius: pw.BorderRadius.circular(4),
            ),
            child: pw.Text(
              'Powered by Duka+',
              style: pw.TextStyle(font: fontBold, fontSize: 7, color: _C.white),
            ),
          ),
        ],
      ),
    );
  }

  // ── KPI strip ────────────────────────────────────────────────────────────
  static pw.Widget _buildKpiStrip(
      List<ReportKpi> kpis, pw.Font fontBold, pw.Font font) {
    return pw.Row(
      children: kpis.map((k) => pw.Expanded(
        child: pw.Container(
          margin: const pw.EdgeInsets.only(right: 6),
          decoration: pw.BoxDecoration(
            color: PdfColors.white,
            border: pw.Border(
              top:    pw.BorderSide(color: k.color, width: 3),
              left:   pw.BorderSide(color: _C.border, width: 0.5),
              right:  pw.BorderSide(color: _C.border, width: 0.5),
              bottom: pw.BorderSide(color: _C.border, width: 0.5),
            ),
            borderRadius: const pw.BorderRadius.only(
              bottomLeft:  pw.Radius.circular(4),
              bottomRight: pw.Radius.circular(4),
            ),
          ),
          padding: const pw.EdgeInsets.all(8),
          child: pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.center,
            children: [
              pw.Text(k.value,
                style: pw.TextStyle(font: fontBold, fontSize: 14, color: k.color)),
              pw.SizedBox(height: 3),
              pw.Text(k.label,
                style: pw.TextStyle(font: font, fontSize: 7, color: _C.textMuted),
                textAlign: pw.TextAlign.center),
            ],
          ),
        ),
      )).toList(),
    );
  }

  // ── Data table ───────────────────────────────────────────────────────────
  static pw.Widget _buildTable(
      ReportConfig cfg, pw.Font font, pw.Font fontBold) {
    return pw.Table(
      border: pw.TableBorder.all(color: _C.border, width: 0.4),
      columnWidths: {
        for (int i = 0; i < cfg.tableHeaders.length; i++)
          i: const pw.FlexColumnWidth(),
      },
      children: [
        pw.TableRow(
          decoration: const pw.BoxDecoration(color: _C.tblHead),
          children: cfg.tableHeaders.map((h) => pw.Padding(
            padding: const pw.EdgeInsets.symmetric(horizontal: 6, vertical: 5),
            child: pw.Text(h,
              style: pw.TextStyle(font: fontBold, fontSize: 8, color: _C.white)),
          )).toList(),
        ),
        ...cfg.tableRows.asMap().entries.map((entry) =>
          pw.TableRow(
            decoration: pw.BoxDecoration(
              color: entry.key.isOdd ? _C.tblAlt : PdfColors.white,
            ),
            children: entry.value.map((cell) => pw.Padding(
              padding: const pw.EdgeInsets.symmetric(horizontal: 6, vertical: 4),
              child: pw.Text(cell,
                style: pw.TextStyle(font: font, fontSize: 8, color: _C.text)),
            )).toList(),
          ),
        ),
      ],
    );
  }

  // ── Chart strip ──────────────────────────────────────────────────────────
  static pw.Widget _buildChartStrip(pw.Font font, bool isSw) {
    // Use a solid border colour instead of withOpacity to avoid the API issue
    const borderColor = PdfColor.fromInt(0xFFB0CCEE); // soft blue
    const greenBorder = PdfColor.fromInt(0xFF7BC67B); // soft green

    return pw.Container(
      height: 55,
      decoration: pw.BoxDecoration(
        color: _C.offWhite,
        border: pw.Border.all(color: _C.border, width: 0.5),
        borderRadius: pw.BorderRadius.circular(6),
      ),
      padding: const pw.EdgeInsets.all(8),
      child: pw.Row(
        mainAxisAlignment: pw.MainAxisAlignment.spaceAround,
        children: [
          _chartCell(font, isSw ? 'Mwenendo' : 'Trend',   borderColor, isSw),
          _pieCell(font,  isSw ? 'Sehemu'    : 'Share'),
          _chartCell(font, isSw ? 'Kiwango'  : 'Volume',  greenBorder, isSw),
        ],
      ),
    );
  }

  static pw.Widget _chartCell(pw.Font font, String label, PdfColor borderColor, bool isSw) =>
    pw.Column(mainAxisAlignment: pw.MainAxisAlignment.center, children: [
      pw.Container(
        width: 60, height: 28,
        decoration: pw.BoxDecoration(
          color: PdfColors.white,
          border: pw.Border.all(color: borderColor, width: 0.8),
          borderRadius: pw.BorderRadius.circular(3),
        ),
        child: pw.Center(child: pw.Text('~~~',
          style: pw.TextStyle(font: font, fontSize: 12, color: borderColor))),
      ),
      pw.SizedBox(height: 3),
      pw.Text(label,
        style: pw.TextStyle(font: font, fontSize: 7, color: _C.textMuted)),
    ]);

  static pw.Widget _pieCell(pw.Font font, String label) =>
    pw.Column(mainAxisAlignment: pw.MainAxisAlignment.center, children: [
      pw.Container(
        width: 36, height: 36,
        decoration: pw.BoxDecoration(
          shape: pw.BoxShape.circle,
          color: _C.offWhite,
          border: pw.Border.all(color: _C.border, width: 0.8),
        ),
        child: pw.Center(child: pw.Text('O',
          style: pw.TextStyle(font: font, fontSize: 18, color: _C.accent))),
      ),
      pw.SizedBox(height: 3),
      pw.Text(label,
        style: pw.TextStyle(font: font, fontSize: 7, color: _C.textMuted)),
    ]);

  // ── Notes ────────────────────────────────────────────────────────────────
  static pw.Widget _buildNotes(
      String notes, pw.Font font, pw.Font fontBold, bool isSw) {
    return pw.Container(
      decoration: pw.BoxDecoration(
        color: const PdfColor.fromInt(0xFFFFFCF0),
        border: pw.Border.all(
            color: const PdfColor.fromInt(0xFFF0C850), width: 0.5),
        borderRadius: pw.BorderRadius.circular(4),
      ),
      padding: const pw.EdgeInsets.all(8),
      child: pw.Row(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Text(isSw ? 'Maelezo: ' : 'Notes: ',
            style: pw.TextStyle(font: fontBold, fontSize: 8, color: _C.text)),
          pw.Expanded(
            child: pw.Text(notes,
              style: pw.TextStyle(font: font, fontSize: 8, color: _C.textMuted)),
          ),
        ],
      ),
    );
  }

  // ── Footer ───────────────────────────────────────────────────────────────
  static pw.Widget _buildFooter(
      ReportConfig cfg, pw.Font font, pw.Font fontBold, String dateStr) {
    final isSw    = cfg.isSw;
    final client  = cfg.clientName ?? (isSw ? 'Mteja' : 'Client');
    final company = cfg.user?.businessName ?? 'Duka+';
    // Use a slightly lighter colour for the faint watermark line
    const footerFaint = PdfColor.fromInt(0xFF7A8A9A);

    return pw.Container(
      width: double.infinity,
      color: _C.footerBg,
      padding: const pw.EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: pw.Column(
        children: [
          pw.Container(height: 1.5, color: _C.accent),
          pw.SizedBox(height: 6),
          pw.Row(
            mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
            children: [
              pw.RichText(text: pw.TextSpan(children: [
                pw.TextSpan(
                  text: isSw ? 'Imetayarishwa kwa: ' : 'Prepared for: ',
                  style: pw.TextStyle(font: font, fontSize: 8, color: _C.footerTxt)),
                pw.TextSpan(
                  text: client,
                  style: pw.TextStyle(font: fontBold, fontSize: 8, color: _C.footerBld)),
              ])),
              pw.RichText(text: pw.TextSpan(children: [
                pw.TextSpan(
                  text: isSw ? 'Tarehe: ' : 'Date: ',
                  style: pw.TextStyle(font: font, fontSize: 8, color: _C.footerTxt)),
                pw.TextSpan(
                  text: dateStr,
                  style: pw.TextStyle(font: fontBold, fontSize: 8, color: _C.footerBld)),
              ])),
              pw.RichText(text: pw.TextSpan(children: [
                pw.TextSpan(
                  text: isSw ? 'Imetayarishwa na: ' : 'Prepared by: ',
                  style: pw.TextStyle(font: font, fontSize: 8, color: _C.footerTxt)),
                pw.TextSpan(
                  text: company,
                  style: pw.TextStyle(font: fontBold, fontSize: 8, color: _C.footerBld)),
              ])),
            ],
          ),
          pw.SizedBox(height: 4),
          pw.Text(
            [
              cfg.user?.email   ?? '',
              cfg.user?.phone   ?? '',
              cfg.user?.tinNumber != null ? 'TIN: ${cfg.user!.tinNumber}' : '',
            ].where((s) => s.isNotEmpty).join('  |  '),
            style: pw.TextStyle(font: font, fontSize: 6.5, color: _C.footerTxt),
            textAlign: pw.TextAlign.center,
          ),
          pw.SizedBox(height: 3),
          pw.Text(
            'Generated by Duka+ Business Management  ·  ${AppConstants.currency}',
            style: pw.TextStyle(font: font, fontSize: 6, color: footerFaint),
            textAlign: pw.TextAlign.center,
          ),
        ],
      ),
    );
  }

  // ── Helpers ──────────────────────────────────────────────────────────────
  static pw.Widget _circle(double size, PdfColor color) =>
      pw.Container(
        width: size, height: size,
        decoration: pw.BoxDecoration(
          shape: pw.BoxShape.circle,
          color: color,
        ),
      );

  static pw.Widget _bar(double width, double height, PdfColor color) =>
      pw.Container(
        width: width, height: height,
        decoration: pw.BoxDecoration(
          color: color,
          borderRadius: pw.BorderRadius.circular(2),
        ),
      );

  static pw.Widget _infoRow(String label, String value, pw.Font font) =>
      pw.Padding(
        padding: const pw.EdgeInsets.only(bottom: 2),
        child: pw.RichText(
          text: pw.TextSpan(children: [
            pw.TextSpan(
              text: '$label: ',
              style: pw.TextStyle(font: font, fontSize: 8, color: _C.textMuted)),
            pw.TextSpan(
              text: value,
              style: pw.TextStyle(font: font, fontSize: 8, color: _C.text)),
          ]),
        ),
      );
}

// ─────────────────────────────────────────────────────────────────────────────
// Public API
// ─────────────────────────────────────────────────────────────────────────────

Future<void> exportReportPdf(ReportConfig config) async {
  final bytes = await ReportPdfBuilder.build(config);
  final slug  = config.title
      .replaceAll(RegExp(r'[^a-zA-Z0-9]'), '_')
      .substring(0, config.title.length.clamp(0, 30));
  await Printing.sharePdf(
    bytes:    bytes,
    filename: 'DukaPlus_${slug}_${_todaySlug()}.pdf',
  );
}

Future<void> exportSalesReportPdf({
  required AuthUser?      user,
  required DashboardStats stats,
  required bool           isSw,
}) async {
  await exportReportPdf(ReportConfig(
    title:    isSw
        ? 'RIPOTI YA MAUZO NA KODI YA TRA'
        : 'SALES & TRA TAX AUDIT REPORT',
    subtitle: isSw
        ? 'Muhtasari wa Mauzo, VAT 18% na Matokeo ya Kifedha'
        : 'Sales Summary, VAT 18% Remittance & Financial Overview',
    user: user,
    isSw: isSw,
    kpis: [
      ReportKpi(
        label: isSw ? 'Mauzo Leo'   : "Today's Sales",
        value: AppFormatters.tsh(stats.todayRevenue),
        color: _C.accent,
      ),
      ReportKpi(
        label: isSw ? 'Mwezi Huu'   : 'This Month',
        value: AppFormatters.compact(stats.monthRevenue),
        color: _C.green,
      ),
      ReportKpi(
        label: isSw ? 'Wiki Hii'    : 'This Week',
        value: AppFormatters.compact(stats.weekRevenue),
        color: _C.orange,
      ),
      ReportKpi(
        label: isSw ? 'Miamala Leo' : 'Transactions',
        value: '${stats.todaySalesCount}',
        color: _C.purple,
      ),
    ],
    tableHeaders: isSw
        ? ['Kipengele', 'Thamani']
        : ['Metric',    'Value'],
    tableRows: [
      [isSw ? 'Mauzo ya Leo'    : "Today's Revenue", AppFormatters.tsh(stats.todayRevenue)],
      [isSw ? 'Mauzo ya Wiki'   : 'Week Revenue',    AppFormatters.tsh(stats.weekRevenue)],
      [isSw ? 'Mauzo ya Mwezi'  : 'Month Revenue',   AppFormatters.tsh(stats.monthRevenue)],
      [isSw ? 'Thamani ya Stoo' : 'Stock Value',     AppFormatters.tsh(stats.stockValue)],
      [isSw ? 'Madeni (Wateja)' : 'Receivables',     AppFormatters.tsh(stats.totalReceivables)],
      [isSw ? 'Madeni (Wasam.)' : 'Payables',        AppFormatters.tsh(stats.totalPayables)],
    ],
    notes: isSw
        ? 'Ripoti hii imetolewa kiotomatiki na Duka+. '
          'Thamani zote zinajumuisha VAT ya TRA 18%.'
        : 'Auto-generated by Duka+. '
          'All values include TRA 18% VAT where applicable.',
  ));
}

String _todaySlug() {
  final n = DateTime.now();
  return '${n.year}'
      '${n.month.toString().padLeft(2, '0')}'
      '${n.day.toString().padLeft(2, '0')}';
}
