import 'dart:io';

import 'package:excel/excel.dart' as xl;
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:path_provider/path_provider.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:share_plus/share_plus.dart';

import '../../core/utils/formatters.dart';
import '../analytics/domain/analytics.dart';
import '../recitations/domain/recitation.dart';
import '../students/domain/student.dart';

final exportServiceProvider = Provider<ExportService>((ref) => ExportService());

/// Arabic, RTL-correct PDF and Excel exports.
class ExportService {
  pw.Font? _regular;
  pw.Font? _bold;
  pw.Font? _display;
  Uint8List? _logo;

  static const _emerald = PdfColor.fromInt(0xFF0E4D3C);
  static const _gold = PdfColor.fromInt(0xFFC9A24B);
  static const _ivory = PdfColor.fromInt(0xFFFAF6EC);

  Future<void> _loadAssets() async {
    _regular ??= pw.Font.ttf(await rootBundle.load('assets/fonts/Tajawal-Regular.ttf'));
    _bold ??= pw.Font.ttf(await rootBundle.load('assets/fonts/Tajawal-Bold.ttf'));
    _display ??= pw.Font.ttf(await rootBundle.load('assets/fonts/Amiri-Bold.ttf'));
    _logo ??= (await rootBundle.load('assets/brand/logo_mark.png')).buffer.asUint8List();
  }

  pw.ThemeData get _theme => pw.ThemeData.withFont(base: _regular!, bold: _bold!, fontFallback: [_display!]);

  pw.Widget _header(String title, String subtitle) => pw.Container(
        padding: const pw.EdgeInsets.all(14),
        decoration: pw.BoxDecoration(color: _emerald, borderRadius: pw.BorderRadius.circular(12)),
        child: pw.Row(children: [
          pw.Image(pw.MemoryImage(_logo!), width: 46, height: 46),
          pw.SizedBox(width: 12),
          pw.Expanded(
            child: pw.Column(crossAxisAlignment: pw.CrossAxisAlignment.start, children: [
              pw.Text(title, style: pw.TextStyle(font: _display, fontSize: 22, color: PdfColors.white)),
              pw.Text(subtitle, style: const pw.TextStyle(fontSize: 11, color: _gold)),
            ]),
          ),
          pw.Text('الوقار', style: pw.TextStyle(font: _display, fontSize: 26, color: PdfColors.white)),
        ]),
      );

  pw.Widget _footer(pw.Context ctx) => pw.Container(
        alignment: pw.Alignment.center,
        margin: const pw.EdgeInsets.only(top: 8),
        child: pw.Text(
          'صفحة ${Fmt.digits(ctx.pageNumber)} من ${Fmt.digits(ctx.pagesCount)} — صدر في ${Fmt.date(DateTime.now())}',
          style: const pw.TextStyle(fontSize: 9, color: PdfColors.grey700),
        ),
      );

  pw.Widget _table(List<String> headers, List<List<String>> rows) => pw.TableHelper.fromTextArray(
        headers: headers,
        data: rows,
        headerStyle: pw.TextStyle(fontWeight: pw.FontWeight.bold, color: PdfColors.white, fontSize: 10),
        headerDecoration: const pw.BoxDecoration(color: _emerald),
        cellStyle: const pw.TextStyle(fontSize: 10),
        cellAlignment: pw.Alignment.center,
        oddRowDecoration: const pw.BoxDecoration(color: _ivory),
        border: pw.TableBorder.all(color: PdfColors.grey300, width: 0.5),
      );

  Future<Uint8List> studentReportPdf(Student s, List<Recitation> history) async {
    await _loadAssets();
    final doc = pw.Document(theme: _theme, title: 'تقرير ${s.fullName}', author: 'الوقار');
    final breakdown = Analytics.evaluationBreakdown(history);
    doc.addPage(pw.MultiPage(
      pageFormat: PdfPageFormat.a4,
      textDirection: pw.TextDirection.rtl,
      margin: const pw.EdgeInsets.all(28),
      footer: _footer,
      build: (ctx) => [
        _header('تقرير الطالب', s.fullName),
        pw.SizedBox(height: 16),
        pw.Wrap(spacing: 10, runSpacing: 10, children: [
          _kv('المعلم', s.teacherName),
          _kv('القسم', s.departmentId.label),
          _kv('مجموع النقاط', Fmt.number(s.totalPoints)),
          _kv('عدد مرات التسميع', Fmt.number(s.recitationCount)),
          _kv('آخر تسميع', s.lastRecitationLabel ?? '—'),
          _kv('تاريخ آخر تسميع', Fmt.date(s.lastRecitationDate)),
        ]),
        pw.SizedBox(height: 16),
        pw.Text('توزيع التقييمات', style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 13, color: _emerald)),
        pw.SizedBox(height: 6),
        _table(
          breakdown.keys.map((e) => e.label).toList(),
          [breakdown.values.map(Fmt.number).toList()],
        ),
        pw.SizedBox(height: 16),
        pw.Text('سجل التسميع', style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 13, color: _emerald)),
        pw.SizedBox(height: 6),
        if (history.isEmpty)
          pw.Text('لا يوجد تسميع مسجل بعد')
        else
          _table(
            ['التاريخ', 'المقرر', 'التقييم', 'نقاط التقييم', 'كمية إضافية', 'المجموع', 'المعلم'],
            [
              for (final r in history)
                [
                  Fmt.date(r.recitationDate),
                  r.portionLabel,
                  r.evaluation.label,
                  Fmt.number(r.evaluationPoints),
                  Fmt.number(r.extraPoints),
                  Fmt.number(r.totalPoints),
                  r.teacherName,
                ],
            ],
          ),
      ],
    ));
    return doc.save();
  }

  pw.Widget _kv(String k, String v) => pw.Container(
        width: 160,
        padding: const pw.EdgeInsets.all(10),
        decoration: pw.BoxDecoration(
          border: pw.Border.all(color: _gold, width: 0.8),
          borderRadius: pw.BorderRadius.circular(8),
        ),
        child: pw.Column(crossAxisAlignment: pw.CrossAxisAlignment.start, children: [
          pw.Text(k, style: const pw.TextStyle(fontSize: 9, color: PdfColors.grey700)),
          pw.SizedBox(height: 2),
          pw.Text(v, style: pw.TextStyle(fontSize: 12, fontWeight: pw.FontWeight.bold, color: _emerald)),
        ]),
      );

  Future<Uint8List> leaderboardPdf({required String title, required List<Student> students}) async {
    await _loadAssets();
    final sorted = [...students]..sort(Analytics.compareByRank);
    final ranks = Analytics.ranks(sorted);
    final doc = pw.Document(theme: _theme, title: title, author: 'الوقار');
    doc.addPage(pw.MultiPage(
      pageFormat: PdfPageFormat.a4,
      textDirection: pw.TextDirection.rtl,
      margin: const pw.EdgeInsets.all(28),
      footer: _footer,
      build: (ctx) => [
        _header('لوحة الصدارة', title),
        pw.SizedBox(height: 16),
        _table(
          ['الترتيب', 'الاسم', 'المعلم', 'مجموع النقاط', 'آخر تسميع', 'التاريخ'],
          [
            for (var i = 0; i < sorted.length; i++)
              [
                Fmt.number(ranks[i]),
                sorted[i].fullName,
                sorted[i].teacherName,
                Fmt.number(sorted[i].totalPoints),
                sorted[i].lastRecitationLabel ?? '—',
                Fmt.date(sorted[i].lastRecitationDate),
              ],
          ],
        ),
      ],
    ));
    return doc.save();
  }

  Uint8List leaderboardExcel(List<Student> students) {
    final sorted = [...students]..sort(Analytics.compareByRank);
    final ranks = Analytics.ranks(sorted);
    final book = xl.Excel.createExcel();
    final sheet = book['الترتيب'];
    book.delete('Sheet1');
    sheet.isRTL = true;
    sheet.appendRow([
      for (final h in ['الترتيب', 'الاسم', 'المعلم', 'القسم', 'مجموع النقاط', 'عدد مرات التسميع', 'آخر تسميع', 'تاريخ آخر تسميع'])
        xl.TextCellValue(h),
    ]);
    for (var i = 0; i < sorted.length; i++) {
      final s = sorted[i];
      sheet.appendRow([
        xl.IntCellValue(ranks[i]),
        xl.TextCellValue(s.fullName),
        xl.TextCellValue(s.teacherName),
        xl.TextCellValue(s.departmentId.label),
        xl.IntCellValue(s.totalPoints),
        xl.IntCellValue(s.recitationCount),
        xl.TextCellValue(s.lastRecitationLabel ?? ''),
        xl.TextCellValue(s.lastRecitationDate == null ? '' : Fmt.date(s.lastRecitationDate)),
      ]);
    }
    return Uint8List.fromList(book.encode()!);
  }

  Uint8List recitationsExcel(List<Recitation> list) {
    final book = xl.Excel.createExcel();
    final sheet = book['سجل التسميع'];
    book.delete('Sheet1');
    sheet.isRTL = true;
    sheet.appendRow([
      for (final h in ['التاريخ', 'الطالب', 'المعلم', 'القسم', 'النوع', 'المقرر', 'التقييم', 'نقاط التقييم', 'كمية إضافية', 'المجموع'])
        xl.TextCellValue(h),
    ]);
    for (final r in list) {
      sheet.appendRow([
        xl.TextCellValue(Fmt.date(r.recitationDate)),
        xl.TextCellValue(r.studentName),
        xl.TextCellValue(r.teacherName),
        xl.TextCellValue(r.departmentId.label),
        xl.TextCellValue(r.recitationType.label),
        xl.TextCellValue(r.portionLabel),
        xl.TextCellValue(r.evaluation.label),
        xl.IntCellValue(r.evaluationPoints),
        xl.IntCellValue(r.extraPoints),
        xl.IntCellValue(r.totalPoints),
      ]);
    }
    return Uint8List.fromList(book.encode()!);
  }

  Future<void> printPdf(Uint8List bytes, String name) =>
      Printing.layoutPdf(onLayout: (_) async => bytes, name: name);

  Future<void> shareFile(Uint8List bytes, String fileName, {required String mime}) async {
    final dir = await getTemporaryDirectory();
    final file = File('${dir.path}/$fileName');
    await file.writeAsBytes(bytes, flush: true);
    await SharePlus.instance.share(ShareParams(files: [XFile(file.path, mimeType: mime)], title: fileName));
  }
}
