import 'package:excel/excel.dart' as xlsx;
import 'package:flutter/services.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:share_plus/share_plus.dart';

import '../models/portfolio_performance.dart';
import '../services/portfolio_valuation_service.dart';

enum ReportFileType { pdf, excel }

class ReportExportService {
  ReportExportService._();

  static final ReportExportService instance = ReportExportService._();

  Future<void> sharePortfolio({
    required PortfolioValuation valuation,
    required ReportFileType type,
    required Rect shareOrigin,
  }) async {
    final date = _dateKey(DateTime.now());
    final isPdf = type == ReportFileType.pdf;
    final bytes = isPdf
        ? await buildPortfolioPdf(valuation)
        : buildPortfolioExcel(valuation);
    await _share(
      bytes: bytes,
      fileName: 'myfin_portfoy_raporu_$date.${isPdf ? 'pdf' : 'xlsx'}',
      mimeType: isPdf
          ? 'application/pdf'
          : 'application/vnd.openxmlformats-officedocument.spreadsheetml.sheet',
      subject: 'MyFin Portföy Raporu',
      shareOrigin: shareOrigin,
    );
  }

  Future<void> sharePerformance({
    required PortfolioPerformance performance,
    required String rangeLabel,
    required ReportFileType type,
    required Rect shareOrigin,
  }) async {
    final date = _dateKey(DateTime.now());
    final isPdf = type == ReportFileType.pdf;
    final bytes = isPdf
        ? await buildPerformancePdf(performance, rangeLabel)
        : buildPerformanceExcel(performance, rangeLabel);
    await _share(
      bytes: bytes,
      fileName: 'myfin_performans_raporu_$date.${isPdf ? 'pdf' : 'xlsx'}',
      mimeType: isPdf
          ? 'application/pdf'
          : 'application/vnd.openxmlformats-officedocument.spreadsheetml.sheet',
      subject: 'MyFin Performans Raporu',
      shareOrigin: shareOrigin,
    );
  }

  Future<Uint8List> buildPortfolioPdf(PortfolioValuation valuation) async {
    final fonts = await _pdfFonts();
    final document = pw.Document(
      theme: pw.ThemeData.withFont(base: fonts.$1, bold: fonts.$2),
    );
    document.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(34),
        header: (_) => _pdfHeader('Portföy Raporu'),
        footer: _pdfFooter,
        build: (_) => [
          _pdfSummary([
            ('Toplam Değer', _money(valuation.totalValue)),
            ('Toplam Maliyet', _money(valuation.totalCost)),
            ('Kâr / Zarar', _signedMoney(valuation.totalProfit)),
            ('Getiri', _percent(valuation.profitPercent)),
          ]),
          pw.SizedBox(height: 22),
          pw.Text(
            'Varlık Detayı',
            style: pw.TextStyle(fontSize: 16, fontWeight: pw.FontWeight.normal),
          ),
          pw.SizedBox(height: 8),
          pw.TableHelper.fromTextArray(
            headers: const [
              'Varlık',
              'Tür',
              'Miktar',
              'Maliyet',
              'Güncel Değer',
              'K/Z',
              'Getiri',
            ],
            data: valuation.items.map((item) {
              return [
                item.item.name.isEmpty ? item.item.symbol : item.item.name,
                item.item.type,
                _quantity(item.item.quantity),
                _money(item.costInBaseCurrency),
                _money(item.currentValueInBaseCurrency),
                _signedMoney(item.profitLossInBaseCurrency),
                item.hasLivePrice ? _percent(item.profitPercent) : 'Fiyat yok',
              ];
            }).toList(),
            headerDecoration: const pw.BoxDecoration(
              color: PdfColor.fromInt(0xFF0F73C5),
            ),
            headerStyle: pw.TextStyle(
              color: PdfColors.white,
              fontSize: 8,
              fontWeight: pw.FontWeight.normal,
            ),
            cellStyle: const pw.TextStyle(fontSize: 7.5),
            cellPadding: const pw.EdgeInsets.symmetric(
              horizontal: 5,
              vertical: 6,
            ),
            border: const pw.TableBorder(
              horizontalInside: pw.BorderSide(
                color: PdfColor.fromInt(0xFFE2E8F0),
                width: .5,
              ),
            ),
          ),
        ],
      ),
    );
    return document.save();
  }

  Future<Uint8List> buildPerformancePdf(
    PortfolioPerformance performance,
    String rangeLabel,
  ) async {
    final fonts = await _pdfFonts();
    final document = pw.Document(
      theme: pw.ThemeData.withFont(base: fonts.$1, bold: fonts.$2),
    );
    document.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4.landscape,
        margin: const pw.EdgeInsets.all(28),
        header: (_) => _pdfHeader('Performans Raporu'),
        footer: _pdfFooter,
        build: (_) => [
          pw.Text(
            'Dönem: $rangeLabel',
            style: const pw.TextStyle(color: PdfColor.fromInt(0xFF64748B)),
          ),
          pw.SizedBox(height: 12),
          _pdfSummary([
            ('Dönem Getirisi', _percent(performance.totalReturnPercent)),
            (
              'Günlük Ortalama',
              _percent(performance.averageDailyReturnPercent),
            ),
            ('Oynaklık', _percent(performance.volatilityPercent)),
            ('Net Sermaye', _signedMoney(performance.netContribution)),
          ]),
          pw.SizedBox(height: 18),
          pw.Row(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.Expanded(
                flex: 3,
                child: pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    pw.Text(
                      'Günlük Kapanışlar',
                      style: pw.TextStyle(
                        fontSize: 15,
                        fontWeight: pw.FontWeight.normal,
                      ),
                    ),
                    pw.SizedBox(height: 8),
                    if (performance.snapshots.isEmpty)
                      pw.Text('Bu dönem için henüz kapanış verisi bulunmuyor.')
                    else
                      pw.TableHelper.fromTextArray(
                        headers: const [
                          'Tarih',
                          'Portföy Değeri',
                          'Maliyet',
                          'Kâr / Zarar',
                          'Varlık',
                        ],
                        data: performance.snapshots
                            .map(
                              (item) => [
                                item.dateKey,
                                _money(item.totalValue),
                                _money(item.totalCost),
                                _signedMoney(item.profitLoss),
                                '${item.assetCount}',
                              ],
                            )
                            .toList(),
                        headerDecoration: const pw.BoxDecoration(
                          color: PdfColor.fromInt(0xFF0F73C5),
                        ),
                        headerStyle: pw.TextStyle(
                          color: PdfColors.white,
                          fontSize: 8,
                          fontWeight: pw.FontWeight.normal,
                        ),
                        cellStyle: const pw.TextStyle(
                          fontSize: 7.5,
                          color: PdfColors.white,
                        ),
                        cellPadding: const pw.EdgeInsets.all(5),
                        oddRowDecoration: const pw.BoxDecoration(
                          color: PdfColor.fromInt(0xFF111827),
                        ),
                        rowDecoration: const pw.BoxDecoration(
                          color: PdfColor.fromInt(0xFF0F172A),
                        ),
                        border: const pw.TableBorder(
                          horizontalInside: pw.BorderSide(
                            color: PdfColor.fromInt(0xFFE2E8F0),
                            width: .5,
                          ),
                        ),
                      ),
                  ],
                ),
              ),
              pw.SizedBox(width: 16),
              pw.Expanded(
                child: pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    pw.Text(
                      'Getiri Grafiği',
                      style: pw.TextStyle(
                        fontSize: 15,
                        fontWeight: pw.FontWeight.normal,
                      ),
                    ),
                    pw.SizedBox(height: 8),
                    pw.SvgImage(svg: _performanceChartSvg(performance)),
                    pw.SizedBox(height: 8),
                    pw.Text(
                      'Başlangıca göre kümülatif getiri',
                      style: const pw.TextStyle(
                        fontSize: 7.5,
                        color: PdfColor.fromInt(0xFF64748B),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
    return document.save();
  }

  String _performanceChartSvg(PortfolioPerformance performance) {
    const width = 260.0;
    const height = 180.0;
    const left = 16.0;
    const right = 10.0;
    const top = 20.0;
    const bottom = 30.0;
    final values = performance.chartValues;
    if (values.length < 2) {
      return '<svg xmlns="http://www.w3.org/2000/svg" width="$width" height="$height"><rect width="100%" height="100%" rx="12" fill="#F8FAFC"/><text x="130" y="92" text-anchor="middle" font-size="11" fill="#64748B">Grafik için en az iki kapanış gerekir</text></svg>';
    }
    final min = values.reduce((a, b) => a < b ? a : b);
    final max = values.reduce((a, b) => a > b ? a : b);
    final range = (max - min).abs() < .01 ? 1.0 : max - min;
    final chartWidth = width - left - right;
    final chartHeight = height - top - bottom;
    final points = <String>[];
    final circles = <String>[];
    final labels = <String>[];
    for (var i = 0; i < values.length; i++) {
      final x = left + chartWidth * i / (values.length - 1);
      final y = top + chartHeight - ((values[i] - min) / range * chartHeight);
      points.add('${x.toStringAsFixed(1)},${y.toStringAsFixed(1)}');
      circles.add(
        '<circle cx="${x.toStringAsFixed(1)}" cy="${y.toStringAsFixed(1)}" r="3.5" fill="#16A34A"/>',
      );
      final day = i < performance.snapshots.length
          ? performance.snapshots[i].dateKey.substring(8)
          : '${i + 1}';
      final label =
          '${values[i] >= 0 ? '+' : ''}${values[i].toStringAsFixed(1)}%';
      labels.add(
        '<text x="${x.toStringAsFixed(1)}" y="${(y - 7).clamp(10, height - bottom - 6).toStringAsFixed(1)}" text-anchor="middle" font-size="7" font-weight="bold" fill="#16A34A">$label</text><text x="${x.toStringAsFixed(1)}" y="${height - 10}" text-anchor="middle" font-size="7" fill="#64748B">$day</text>',
      );
    }
    return '<svg xmlns="http://www.w3.org/2000/svg" width="$width" height="$height" viewBox="0 0 $width $height"><rect width="100%" height="100%" rx="12" fill="#F8FAFC"/><line x1="$left" y1="${top + chartHeight / 2}" x2="${width - right}" y2="${top + chartHeight / 2}" stroke="#E2E8F0"/><line x1="$left" y1="${top + chartHeight}" x2="${width - right}" y2="${top + chartHeight}" stroke="#CBD5E1"/><polyline points="${points.join(' ')}" fill="none" stroke="#16A34A" stroke-width="3" stroke-linecap="round" stroke-linejoin="round"/>${circles.join()}${labels.join()}</svg>';
  }

  Uint8List buildPortfolioExcel(PortfolioValuation valuation) {
    final book = xlsx.Excel.createExcel();
    final sheet = book['Portföy'];
    book.delete('Sheet1');
    _excelTitle(sheet, 'MyFin Portföy Raporu', 7);
    _excelMeta(sheet, 2, 'Rapor Tarihi', _dateKey(DateTime.now()));
    _excelMeta(sheet, 3, 'Toplam Değer', valuation.totalValue, numeric: true);
    _excelMeta(sheet, 4, 'Toplam Maliyet', valuation.totalCost, numeric: true);
    _excelMeta(sheet, 5, 'Kâr / Zarar', valuation.totalProfit, numeric: true);
    _excelMeta(sheet, 6, 'Getiri (%)', valuation.profitPercent, numeric: true);
    const headers = [
      'Varlık',
      'Sembol',
      'Tür',
      'Miktar',
      'Maliyet (TL)',
      'Güncel Değer (TL)',
      'Kâr / Zarar (TL)',
      'Getiri (%)',
    ];
    _excelHeader(sheet, 8, headers);
    for (var index = 0; index < valuation.items.length; index++) {
      final item = valuation.items[index];
      final row = index + 9;
      final values = <xlsx.CellValue>[
        xlsx.TextCellValue(item.item.name),
        xlsx.TextCellValue(item.item.symbol),
        xlsx.TextCellValue(item.item.type),
        xlsx.DoubleCellValue(item.item.quantity),
        xlsx.DoubleCellValue(item.costInBaseCurrency),
        xlsx.DoubleCellValue(item.currentValueInBaseCurrency),
        xlsx.DoubleCellValue(item.profitLossInBaseCurrency),
        xlsx.DoubleCellValue(item.hasLivePrice ? item.profitPercent : 0),
      ];
      _excelRow(sheet, row, values);
    }
    _sizePortfolioSheet(sheet);
    return Uint8List.fromList(book.save()!);
  }

  Uint8List buildPerformanceExcel(
    PortfolioPerformance performance,
    String rangeLabel,
  ) {
    final book = xlsx.Excel.createExcel();
    final sheet = book['Performans'];
    book.delete('Sheet1');
    _excelTitle(sheet, 'MyFin Performans Raporu', 5);
    _excelMeta(sheet, 2, 'Dönem', rangeLabel);
    _excelMeta(
      sheet,
      3,
      'Dönem Getirisi (%)',
      performance.totalReturnPercent,
      numeric: true,
    );
    _excelMeta(
      sheet,
      4,
      'Günlük Ortalama (%)',
      performance.averageDailyReturnPercent,
      numeric: true,
    );
    _excelMeta(
      sheet,
      5,
      'Oynaklık (%)',
      performance.volatilityPercent,
      numeric: true,
    );
    _excelMeta(
      sheet,
      6,
      'Net Sermaye Hareketi (TL)',
      performance.netContribution,
      numeric: true,
    );
    const headers = [
      'Tarih',
      'Portföy Değeri (TL)',
      'Maliyet (TL)',
      'Kâr / Zarar (TL)',
      'Varlık Sayısı',
    ];
    _excelHeader(sheet, 8, headers);
    for (var index = 0; index < performance.snapshots.length; index++) {
      final item = performance.snapshots[index];
      _excelRow(sheet, index + 9, [
        xlsx.TextCellValue(item.dateKey),
        xlsx.DoubleCellValue(item.totalValue),
        xlsx.DoubleCellValue(item.totalCost),
        xlsx.DoubleCellValue(item.profitLoss),
        xlsx.IntCellValue(item.assetCount),
      ]);
    }
    sheet.setColumnWidth(0, 15);
    for (var column = 1; column < 5; column++) {
      sheet.setColumnWidth(column, 23);
    }
    return Uint8List.fromList(book.save()!);
  }

  Future<(pw.Font, pw.Font)> _pdfFonts() async {
    final data = await rootBundle.load(
      'packages/gpt_markdown/lib/fonts/JetBrainsMono-Regular.ttf',
    );
    return (pw.Font.ttf(data), pw.Font.ttf(data));
  }

  pw.Widget _pdfHeader(String title) {
    return pw.Container(
      padding: const pw.EdgeInsets.only(bottom: 12),
      decoration: const pw.BoxDecoration(
        border: pw.Border(
          bottom: pw.BorderSide(color: PdfColor.fromInt(0xFFCBD5E1)),
        ),
      ),
      child: pw.Row(
        mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
        children: [
          pw.Text(
            'MyFin',
            style: pw.TextStyle(
              fontSize: 18,
              fontWeight: pw.FontWeight.normal,
              color: const PdfColor.fromInt(0xFF0F73C5),
            ),
          ),
          pw.Text(
            title,
            style: pw.TextStyle(fontSize: 15, fontWeight: pw.FontWeight.normal),
          ),
        ],
      ),
    );
  }

  pw.Widget _pdfFooter(pw.Context context) {
    return pw.Container(
      padding: const pw.EdgeInsets.only(top: 8),
      decoration: const pw.BoxDecoration(
        border: pw.Border(
          top: pw.BorderSide(color: PdfColor.fromInt(0xFFE2E8F0)),
        ),
      ),
      child: pw.Row(
        mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
        children: [
          pw.Text(
            'Oluşturulma: ${_dateKey(DateTime.now())}',
            style: const pw.TextStyle(
              fontSize: 8,
              color: PdfColor.fromInt(0xFF64748B),
            ),
          ),
          pw.Text(
            'Sayfa ${context.pageNumber} / ${context.pagesCount}',
            style: const pw.TextStyle(
              fontSize: 8,
              color: PdfColor.fromInt(0xFF64748B),
            ),
          ),
        ],
      ),
    );
  }

  pw.Widget _pdfSummary(List<(String, String)> values) {
    return pw.Container(
      margin: const pw.EdgeInsets.only(top: 16),
      padding: const pw.EdgeInsets.all(14),
      decoration: pw.BoxDecoration(
        color: const PdfColor.fromInt(0xFFF8FAFC),
        borderRadius: pw.BorderRadius.circular(12),
      ),
      child: pw.Row(
        children: values
            .map(
              (entry) => pw.Expanded(
                child: pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    pw.Text(
                      entry.$1,
                      style: const pw.TextStyle(
                        fontSize: 8,
                        color: PdfColor.fromInt(0xFF64748B),
                      ),
                    ),
                    pw.SizedBox(height: 4),
                    pw.Text(
                      entry.$2,
                      style: pw.TextStyle(
                        fontSize: 11,
                        fontWeight: pw.FontWeight.normal,
                      ),
                    ),
                  ],
                ),
              ),
            )
            .toList(),
      ),
    );
  }

  void _excelTitle(xlsx.Sheet sheet, String title, int lastColumn) {
    sheet.merge(
      xlsx.CellIndex.indexByColumnRow(columnIndex: 0, rowIndex: 0),
      xlsx.CellIndex.indexByColumnRow(columnIndex: lastColumn, rowIndex: 0),
      customValue: xlsx.TextCellValue(title),
    );
    sheet
        .cell(xlsx.CellIndex.indexByColumnRow(columnIndex: 0, rowIndex: 0))
        .cellStyle = xlsx.CellStyle(
      bold: true,
      fontSize: 18,
      fontColorHex: xlsx.ExcelColor.white,
      backgroundColorHex: xlsx.ExcelColor.fromHexString('#0F73C5'),
      horizontalAlign: xlsx.HorizontalAlign.Center,
      verticalAlign: xlsx.VerticalAlign.Center,
    );
    sheet.setRowHeight(0, 30);
  }

  void _excelMeta(
    xlsx.Sheet sheet,
    int row,
    String label,
    Object value, {
    bool numeric = false,
  }) {
    final rowIndex = row - 1;
    final labelCell = sheet.cell(
      xlsx.CellIndex.indexByColumnRow(columnIndex: 0, rowIndex: rowIndex),
    );
    labelCell.value = xlsx.TextCellValue(label);
    labelCell.cellStyle = xlsx.CellStyle(
      bold: true,
      fontColorHex: xlsx.ExcelColor.fromHexString('#475569'),
    );
    final valueCell = sheet.cell(
      xlsx.CellIndex.indexByColumnRow(columnIndex: 1, rowIndex: rowIndex),
    );
    valueCell.value = numeric
        ? xlsx.DoubleCellValue((value as num).toDouble())
        : xlsx.TextCellValue('$value');
    valueCell.cellStyle = numeric
        ? xlsx.CellStyle(
            bold: true,
            numberFormat: xlsx.CustomNumericNumFormat(formatCode: '#,##0.00'),
          )
        : xlsx.CellStyle(bold: true);
  }

  void _excelHeader(xlsx.Sheet sheet, int row, List<String> headers) {
    final rowIndex = row - 1;
    for (var column = 0; column < headers.length; column++) {
      final cell = sheet.cell(
        xlsx.CellIndex.indexByColumnRow(
          columnIndex: column,
          rowIndex: rowIndex,
        ),
      );
      cell.value = xlsx.TextCellValue(headers[column]);
      cell.cellStyle = xlsx.CellStyle(
        bold: true,
        fontColorHex: xlsx.ExcelColor.white,
        backgroundColorHex: xlsx.ExcelColor.fromHexString('#0F73C5'),
        horizontalAlign: xlsx.HorizontalAlign.Center,
        verticalAlign: xlsx.VerticalAlign.Center,
      );
    }
    sheet.setRowHeight(rowIndex, 24);
  }

  void _excelRow(xlsx.Sheet sheet, int row, List<xlsx.CellValue> values) {
    final rowIndex = row - 1;
    for (var column = 0; column < values.length; column++) {
      final cell = sheet.cell(
        xlsx.CellIndex.indexByColumnRow(
          columnIndex: column,
          rowIndex: rowIndex,
        ),
      );
      cell.value = values[column];
      cell.cellStyle = column >= 3
          ? xlsx.CellStyle(
              verticalAlign: xlsx.VerticalAlign.Center,
              numberFormat: xlsx.CustomNumericNumFormat(formatCode: '#,##0.00'),
            )
          : xlsx.CellStyle(verticalAlign: xlsx.VerticalAlign.Center);
    }
  }

  void _sizePortfolioSheet(xlsx.Sheet sheet) {
    sheet.setColumnWidth(0, 28);
    sheet.setColumnWidth(1, 13);
    sheet.setColumnWidth(2, 14);
    for (var column = 3; column < 8; column++) {
      sheet.setColumnWidth(column, 20);
    }
  }

  Future<void> _share({
    required Uint8List bytes,
    required String fileName,
    required String mimeType,
    required String subject,
    required Rect shareOrigin,
  }) {
    return SharePlus.instance.share(
      ShareParams(
        files: [XFile.fromData(bytes, mimeType: mimeType)],
        fileNameOverrides: [fileName],
        subject: subject,
        sharePositionOrigin: shareOrigin,
      ),
    );
  }

  String _money(double value) => '${value.toStringAsFixed(2)} TL';
  String _signedMoney(double value) =>
      '${value >= 0 ? '+' : ''}${_money(value)}';
  String _percent(double value) =>
      '${value >= 0 ? '+' : ''}${value.toStringAsFixed(2)}%';
  String _quantity(double value) =>
      value.toStringAsFixed(value == value.roundToDouble() ? 0 : 4);

  String _dateKey(DateTime date) {
    final year = date.year.toString().padLeft(4, '0');
    final month = date.month.toString().padLeft(2, '0');
    final day = date.day.toString().padLeft(2, '0');
    return '$year-$month-$day';
  }
}
