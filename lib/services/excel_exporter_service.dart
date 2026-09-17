import 'dart:convert';
import 'dart:io';
import 'package:archive/archive.dart';
import 'package:intl/intl.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import '../models/vehicle.dart';
import '../models/service_record.dart';

class ExcelExporterService {
  /// Generates a standardized, beautifully structured .xlsx spreadsheet file
  /// containing the vehicle specifications and complete service records.
  static Future<File> generateFullServiceExcel({
    required Vehicle vehicle,
    required List<ServiceRecord> records,
    Directory? outputDirectory,
  }) async {
    final dateFormat = DateFormat('dd/MM/yyyy');
    final numberFormat = NumberFormat('#,###');
    final currencyFormat = NumberFormat('#,##0.00');

    final sortedRecords = List<ServiceRecord>.from(records)
      ..sort((a, b) => b.date.compareTo(a.date));

    final totalSpent = sortedRecords.fold(0.0, (acc, r) => acc + r.totalPrice);

    // 1. Build Service History Worksheet (Sheet 1)
    final sheet1Buffer = StringBuffer();
    sheet1Buffer.writeln('<?xml version="1.0" encoding="UTF-8" standalone="yes"?>');
    sheet1Buffer.writeln('<worksheet xmlns="http://schemas.openxmlformats.org/spreadsheetml/2006/main">');
    sheet1Buffer.writeln('  <sheetData>');

    // Title Row
    sheet1Buffer.writeln('    <row r="1">');
    sheet1Buffer.writeln('      <c r="A1" t="inlineStr" s="2"><is><t>${_escapeXml('RIDO - Full Service History: ${vehicle.name}')}</t></is></c>');
    sheet1Buffer.writeln('    </row>');

    // Subtitle Row
    sheet1Buffer.writeln('    <row r="2">');
    sheet1Buffer.writeln('      <c r="A2" t="inlineStr"><is><t>${_escapeXml('Exported on ${dateFormat.format(DateTime.now())} • Total Records: ${sortedRecords.length} • Total Spent: Rs. ${numberFormat.format(totalSpent)}')}</t></is></c>');
    sheet1Buffer.writeln('    </row>');

    // Empty spacing row
    sheet1Buffer.writeln('    <row r="3"/>');

    // Headers Row (Row 4)
    sheet1Buffer.writeln('    <row r="4">');
    final headers = [
      'S.No',
      'Date',
      'Service Title',
      'Mileage (km)',
      'Workshop / Shop',
      'Cost (Rs.)',
      'Next Due (km)',
      'Parts Replaced',
      'Parts Added',
      'Notes',
    ];
    for (int i = 0; i < headers.length; i++) {
      final colLetter = _colLetter(i + 1);
      sheet1Buffer.writeln('      <c r="${colLetter}4" t="inlineStr" s="1"><is><t>${_escapeXml(headers[i])}</t></is></c>');
    }
    sheet1Buffer.writeln('    </row>');

    // Data Rows (Row 5 onwards)
    int rowIdx = 5;
    for (int i = 0; i < sortedRecords.length; i++) {
      final record = sortedRecords[i];
      sheet1Buffer.writeln('    <row r="$rowIdx">');

      // S.No
      sheet1Buffer.writeln('      <c r="A$rowIdx" t="n"><v>${i + 1}</v></c>');

      // Date
      sheet1Buffer.writeln('      <c r="B$rowIdx" t="inlineStr"><is><t>${dateFormat.format(record.date)}</t></is></c>');

      // Service Title
      final title = record.serviceName.isEmpty ? 'General Service' : record.serviceName;
      sheet1Buffer.writeln('      <c r="C$rowIdx" t="inlineStr"><is><t>${_escapeXml(title)}</t></is></c>');

      // Mileage
      sheet1Buffer.writeln('      <c r="D$rowIdx" t="n"><v>${record.mileage}</v></c>');

      // Workshop
      sheet1Buffer.writeln('      <c r="E$rowIdx" t="inlineStr"><is><t>${_escapeXml(record.serviceShop)}</t></is></c>');

      // Cost
      sheet1Buffer.writeln('      <c r="F$rowIdx" t="n"><v>${record.totalPrice}</v></c>');

      // Next Due
      if (record.nextServiceMileage != null && record.nextServiceMileage! > 0) {
        sheet1Buffer.writeln('      <c r="G$rowIdx" t="n"><v>${record.nextServiceMileage}</v></c>');
      } else {
        sheet1Buffer.writeln('      <c r="G$rowIdx" t="inlineStr"><is><t>-</t></is></c>');
      }

      // Parts Replaced
      final replacedStr = record.partsReplaced
          .where((p) => p.name.isNotEmpty && p.name.toLowerCase() != 'none')
          .map((p) => p.price > 0 ? '${p.name} (Rs. ${numberFormat.format(p.price)})' : p.name)
          .join(', ');
      sheet1Buffer.writeln('      <c r="H$rowIdx" t="inlineStr"><is><t>${_escapeXml(replacedStr.isEmpty ? 'None' : replacedStr)}</t></is></c>');

      // Parts Added
      final addedStr = record.newPartsAdded
          .where((p) => p.name.isNotEmpty && p.name.toLowerCase() != 'none')
          .map((p) => p.price > 0 ? '${p.name} (Rs. ${numberFormat.format(p.price)})' : p.name)
          .join(', ');
      sheet1Buffer.writeln('      <c r="I$rowIdx" t="inlineStr"><is><t>${_escapeXml(addedStr.isEmpty ? 'None' : addedStr)}</t></is></c>');

      // Notes
      sheet1Buffer.writeln('      <c r="J$rowIdx" t="inlineStr"><is><t>${_escapeXml(record.notes)}</t></is></c>');

      sheet1Buffer.writeln('    </row>');
      rowIdx++;
    }

    // Summary Total Row
    sheet1Buffer.writeln('    <row r="$rowIdx">');
    sheet1Buffer.writeln('      <c r="A$rowIdx" t="inlineStr" s="1"><is><t>TOTAL</t></is></c>');
    sheet1Buffer.writeln('      <c r="B$rowIdx" t="inlineStr" s="1"><is><t>${sortedRecords.length} Records</t></is></c>');
    sheet1Buffer.writeln('      <c r="C$rowIdx" t="inlineStr" s="1"><is><t></t></is></c>');
    sheet1Buffer.writeln('      <c r="D$rowIdx" t="inlineStr" s="1"><is><t></t></is></c>');
    sheet1Buffer.writeln('      <c r="E$rowIdx" t="inlineStr" s="1"><is><t></t></is></c>');
    sheet1Buffer.writeln('      <c r="F$rowIdx" t="n" s="1"><v>$totalSpent</v></c>');
    sheet1Buffer.writeln('      <c r="G$rowIdx" t="inlineStr" s="1"><is><t></t></is></c>');
    sheet1Buffer.writeln('      <c r="H$rowIdx" t="inlineStr" s="1"><is><t></t></is></c>');
    sheet1Buffer.writeln('      <c r="I$rowIdx" t="inlineStr" s="1"><is><t></t></is></c>');
    sheet1Buffer.writeln('      <c r="J$rowIdx" t="inlineStr" s="1"><is><t></t></is></c>');
    sheet1Buffer.writeln('    </row>');

    sheet1Buffer.writeln('  </sheetData>');
    sheet1Buffer.writeln('</worksheet>');

    // 2. Build Vehicle Profile Worksheet (Sheet 2)
    final sheet2Buffer = StringBuffer();
    sheet2Buffer.writeln('<?xml version="1.0" encoding="UTF-8" standalone="yes"?>');
    sheet2Buffer.writeln('<worksheet xmlns="http://schemas.openxmlformats.org/spreadsheetml/2006/main">');
    sheet2Buffer.writeln('  <sheetData>');

    sheet2Buffer.writeln('    <row r="1">');
    sheet2Buffer.writeln('      <c r="A1" t="inlineStr" s="2"><is><t>${_escapeXml('Vehicle Profile: ${vehicle.name}')}</t></is></c>');
    sheet2Buffer.writeln('    </row>');
    sheet2Buffer.writeln('    <row r="2"/>');

    final specs = [
      ['Vehicle Name', vehicle.name],
      ['Vehicle Type', vehicle.type.displayName],
      ['Model Year / Series', vehicle.model.isNotEmpty ? vehicle.model : 'Standard'],
      ['Variant / Trim', vehicle.variant.isNotEmpty ? vehicle.variant : 'Standard'],
      ['Current Odometer Mileage', '${numberFormat.format(vehicle.mileage)} km'],
      ['Fuel Average', vehicle.fuelAverage > 0 ? '${vehicle.fuelAverage.toStringAsFixed(1)} km/L' : 'Not Set'],
      ['Engine Capacity', vehicle.engineCapacity.isNotEmpty ? vehicle.engineCapacity : 'Not Set'],
      ['Transmission Type', vehicle.transmissionType.isNotEmpty ? vehicle.transmissionType : 'Not Set'],
      ['Last Service Date', vehicle.lastServiceDate != null ? dateFormat.format(vehicle.lastServiceDate!) : 'No records'],
      ['Total Services Logged', '${sortedRecords.length}'],
      ['Total Maintenance Cost', 'Rs. ${currencyFormat.format(totalSpent)}'],
    ];

    sheet2Buffer.writeln('    <row r="3">');
    sheet2Buffer.writeln('      <c r="A3" t="inlineStr" s="1"><is><t>Specification / Metric</t></is></c>');
    sheet2Buffer.writeln('      <c r="B3" t="inlineStr" s="1"><is><t>Details</t></is></c>');
    sheet2Buffer.writeln('    </row>');

    for (int i = 0; i < specs.length; i++) {
      final r = i + 4;
      sheet2Buffer.writeln('    <row r="$r">');
      sheet2Buffer.writeln('      <c r="A$r" t="inlineStr"><is><t>${_escapeXml(specs[i][0])}</t></is></c>');
      sheet2Buffer.writeln('      <c r="B$r" t="inlineStr"><is><t>${_escapeXml(specs[i][1])}</t></is></c>');
      sheet2Buffer.writeln('    </row>');
    }

    sheet2Buffer.writeln('  </sheetData>');
    sheet2Buffer.writeln('</worksheet>');

    // 3. Packaging & Relationships
    const contentTypes = '''<?xml version="1.0" encoding="UTF-8" standalone="yes"?>
<Types xmlns="http://schemas.openxmlformats.org/package/2006/content-types">
  <Default Extension="rels" ContentType="application/vnd.openxmlformats-package.relationships+xml"/>
  <Default Extension="xml" ContentType="application/xml"/>
  <Override PartName="/xl/workbook.xml" ContentType="application/vnd.openxmlformats-officedocument.spreadsheetml.sheet.main+xml"/>
  <Override PartName="/xl/worksheets/sheet1.xml" ContentType="application/vnd.openxmlformats-officedocument.spreadsheetml.worksheet+xml"/>
  <Override PartName="/xl/worksheets/sheet2.xml" ContentType="application/vnd.openxmlformats-officedocument.spreadsheetml.worksheet+xml"/>
  <Override PartName="/xl/styles.xml" ContentType="application/vnd.openxmlformats-officedocument.spreadsheetml.styles+xml"/>
</Types>''';

    const globalRels = '''<?xml version="1.0" encoding="UTF-8" standalone="yes"?>
<Relationships xmlns="http://schemas.openxmlformats.org/package/2006/relationships">
  <Relationship Id="rId1" Type="http://schemas.openxmlformats.org/officeDocument/2006/relationships/officeDocument" Target="xl/workbook.xml"/>
</Relationships>''';

    const workbook = '''<?xml version="1.0" encoding="UTF-8" standalone="yes"?>
<workbook xmlns="http://schemas.openxmlformats.org/spreadsheetml/2006/main" xmlns:r="http://schemas.openxmlformats.org/officeDocument/2006/relationships">
  <sheets>
    <sheet name="Service History" sheetId="1" r:id="rId1"/>
    <sheet name="Vehicle Profile" sheetId="2" r:id="rId2"/>
  </sheets>
</workbook>''';

    const workbookRels = '''<?xml version="1.0" encoding="UTF-8" standalone="yes"?>
<Relationships xmlns="http://schemas.openxmlformats.org/package/2006/relationships">
  <Relationship Id="rId1" Type="http://schemas.openxmlformats.org/officeDocument/2006/relationships/worksheet" Target="worksheets/sheet1.xml"/>
  <Relationship Id="rId2" Type="http://schemas.openxmlformats.org/officeDocument/2006/relationships/worksheet" Target="worksheets/sheet2.xml"/>
  <Relationship Id="rId3" Type="http://schemas.openxmlformats.org/officeDocument/2006/relationships/styles" Target="styles.xml"/>
</Relationships>''';

    const styles = '''<?xml version="1.0" encoding="UTF-8" standalone="yes"?>
<styleSheet xmlns="http://schemas.openxmlformats.org/spreadsheetml/2006/main">
  <fonts count="3">
    <font><name val="Calibri"/><sz val="11"/></font>
    <font><b/><color rgb="FFFFFFFF"/><name val="Calibri"/><sz val="11"/></font>
    <font><b/><sz val="14"/><color rgb="FF0F172A"/><name val="Calibri"/></font>
  </fonts>
  <fills count="3">
    <fill><patternFill patternType="none"/></fill>
    <fill><patternFill patternType="gray125"/></fill>
    <fill><patternFill patternType="solid"><fgColor rgb="FF10B981"/></patternFill></fill>
  </fills>
  <borders count="1">
    <border><left/><right/><top/><bottom/></border>
  </borders>
  <cellStyleXfs count="1">
    <xf numFmtId="0" fontId="0" fillId="0" borderId="0"/>
  </cellStyleXfs>
  <cellXfs count="3">
    <xf numFmtId="0" fontId="0" fillId="0" borderId="0" xfId="0"/>
    <xf numFmtId="0" fontId="1" fillId="2" borderId="0" xfId="0" applyFont="1" applyFill="1"/>
    <xf numFmtId="0" fontId="2" fillId="0" borderId="0" xfId="0" applyFont="1"/>
  </cellXfs>
</styleSheet>''';

    // 4. Assemble ZIP Archive
    final archive = Archive();
    _addStringToArchive(archive, '[Content_Types].xml', contentTypes);
    _addStringToArchive(archive, '_rels/.rels', globalRels);
    _addStringToArchive(archive, 'xl/workbook.xml', workbook);
    _addStringToArchive(archive, 'xl/_rels/workbook.xml.rels', workbookRels);
    _addStringToArchive(archive, 'xl/styles.xml', styles);
    _addStringToArchive(archive, 'xl/worksheets/sheet1.xml', sheet1Buffer.toString());
    _addStringToArchive(archive, 'xl/worksheets/sheet2.xml', sheet2Buffer.toString());

    final zipData = ZipEncoder().encode(archive);

    // 5. Write to temporary or specified directory
    final targetDir = outputDirectory ?? await getTemporaryDirectory();
    final sanitizedName = vehicle.name.replaceAll(RegExp(r'[^\w\s\-]'), '').replaceAll(' ', '_');
    final fileName = '${sanitizedName}_Full_Service_History_${DateFormat('yyyyMMdd').format(DateTime.now())}.xlsx';
    final file = File('${targetDir.path}/$fileName');
    await file.writeAsBytes(zipData);

    return file;
  }

  /// Exports and shares the full service history spreadsheet via share_plus
  static Future<void> shareFullServiceExcel({
    required Vehicle vehicle,
    required List<ServiceRecord> records,
  }) async {
    final file = await generateFullServiceExcel(vehicle: vehicle, records: records);
    await SharePlus.instance.share(
      ShareParams(
        files: [
          XFile(
            file.path,
            name: file.path.split('/').last,
            mimeType: 'application/vnd.openxmlformats-officedocument.spreadsheetml.sheet',
          ),
        ],
        text: 'Full Service History for ${vehicle.name} - Rido',
      ),
    );
  }

  static void _addStringToArchive(Archive archive, String path, String content) {
    final bytes = utf8.encode(content);
    archive.addFile(ArchiveFile(path, bytes.length, bytes));
  }

  static String _escapeXml(String text) {
    return text
        .replaceAll('&', '&amp;')
        .replaceAll('<', '&lt;')
        .replaceAll('>', '&gt;')
        .replaceAll('"', '&quot;')
        .replaceAll("'", '&apos;');
  }

  static String _colLetter(int colNumber) {
    var dividend = colNumber;
    var columnName = '';
    while (dividend > 0) {
      final modulo = (dividend - 1) % 26;
      columnName = String.fromCharCode(65 + modulo) + columnName;
      dividend = (dividend - modulo) ~/ 26;
    }
    return columnName;
  }
}
