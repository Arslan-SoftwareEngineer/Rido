import 'dart:io';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import '../models/vehicle.dart';
import '../models/service_record.dart';

class PdfGeneratorService {
  static Future<Uint8List> generateServiceReport({
    required Vehicle vehicle,
    required ServiceRecord record,
  }) async {
    final pdf = pw.Document();
    // Date format strictly dd/MM/yyyy across whole app
    final dateFormat = DateFormat('dd/MM/yyyy');
    final numberFormat = NumberFormat('#,###');
    final currencyFormat = NumberFormat('#,##0.00');

    // Load official app logo asset
    Uint8List? logoBytes;
    try {
      final byteData = await rootBundle.load('assets/icons/app_logo.png');
      logoBytes = byteData.buffer.asUint8List();
    } catch (_) {}

    // Load any attached images that exist as local files
    final List<Uint8List> embeddedImageBytes = [];
    for (final path in record.imagePaths) {
      try {
        final file = File(path);
        if (await file.exists()) {
          final bytes = await file.readAsBytes();
          embeddedImageBytes.add(bytes);
        }
      } catch (_) {}
    }

    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(36),
        header: (pw.Context context) {
          return pw.Container(
            padding: const pw.EdgeInsets.only(bottom: 16),
            decoration: const pw.BoxDecoration(
              border: pw.Border(
                bottom: pw.BorderSide(color: PdfColors.grey300, width: 1.5),
              ),
            ),
            child: pw.Row(
              mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
              crossAxisAlignment: pw.CrossAxisAlignment.center,
              children: [
                pw.Row(
                  children: [
                    if (logoBytes != null)
                      pw.Container(
                        width: 38,
                        height: 38,
                        child: pw.ClipRRect(
                          horizontalRadius: 10,
                          verticalRadius: 10,
                          child: pw.Image(
                            pw.MemoryImage(logoBytes),
                            width: 38,
                            height: 38,
                          ),
                        ),
                      )
                    else
                      pw.Container(
                        width: 38,
                        height: 38,
                        decoration: pw.BoxDecoration(
                          color: PdfColor.fromHex('#10B981'),
                          borderRadius: pw.BorderRadius.circular(8),
                        ),
                        alignment: pw.Alignment.center,
                        child: pw.Text(
                          'R',
                          style: pw.TextStyle(
                            color: PdfColors.white,
                            fontSize: 24,
                            fontWeight: pw.FontWeight.bold,
                          ),
                        ),
                      ),
                    pw.SizedBox(width: 12),
                    pw.Column(
                      crossAxisAlignment: pw.CrossAxisAlignment.start,
                      children: [
                        pw.Text(
                          'RIDO',
                          style: pw.TextStyle(
                            fontSize: 20,
                            fontWeight: pw.FontWeight.bold,
                            letterSpacing: 2,
                            color: PdfColor.fromHex('#0F172A'),
                          ),
                        ),
                        pw.Text(
                          'Vehicle Maintenance Platform',
                          style: const pw.TextStyle(
                            fontSize: 9,
                            color: PdfColors.grey600,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
                pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.end,
                  children: [
                    pw.Container(
                      padding: const pw.EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: pw.BoxDecoration(
                        color: PdfColor.fromHex('#ECFDF5'),
                        borderRadius: pw.BorderRadius.circular(6),
                        border: pw.Border.all(color: PdfColor.fromHex('#A7F3D0')),
                      ),
                      child: pw.Text(
                        'SERVICE REPORT',
                        style: pw.TextStyle(
                          fontSize: 10,
                          fontWeight: pw.FontWeight.bold,
                          color: PdfColor.fromHex('#047857'),
                        ),
                      ),
                    ),
                    pw.SizedBox(height: 4),
                    pw.Text(
                      'Ref: #${record.id.length > 8 ? record.id.substring(0, 8).toUpperCase() : record.id}',
                      style: const pw.TextStyle(fontSize: 9, color: PdfColors.grey500),
                    ),
                  ],
                ),
              ],
            ),
          );
        },
        footer: (pw.Context context) {
          return pw.Container(
            padding: const pw.EdgeInsets.only(top: 12),
            decoration: const pw.BoxDecoration(
              border: pw.Border(
                top: pw.BorderSide(color: PdfColors.grey300, width: 0.8),
              ),
            ),
            child: pw.Row(
              mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
              children: [
                pw.Text(
                  'Generated with Rido App • ${dateFormat.format(DateTime.now())}',
                  style: const pw.TextStyle(fontSize: 8, color: PdfColors.grey500),
                ),
                pw.Text(
                  'Page ${context.pageNumber} of ${context.pagesCount}',
                  style: const pw.TextStyle(fontSize: 8, color: PdfColors.grey500),
                ),
              ],
            ),
          );
        },
        build: (pw.Context context) {
          final replacedItems = record.partsReplaced.where((p) => p.name != 'None').toList();
          final newItems = record.newPartsAdded.where((p) => p.name != 'None').toList();

          return [
            pw.SizedBox(height: 16),

            // Vehicle & Service Overview Cards
            pw.Row(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                // Vehicle Details Card
                pw.Expanded(
                  child: pw.Container(
                    padding: const pw.EdgeInsets.all(14),
                    decoration: pw.BoxDecoration(
                      color: PdfColor.fromHex('#F8FAFC'),
                      borderRadius: pw.BorderRadius.circular(10),
                      border: pw.Border.all(color: PdfColor.fromHex('#E2E8F0')),
                    ),
                    child: pw.Column(
                      crossAxisAlignment: pw.CrossAxisAlignment.start,
                      children: [
                        pw.Text(
                          'VEHICLE PROFILE',
                          style: pw.TextStyle(
                            fontSize: 10,
                            fontWeight: pw.FontWeight.bold,
                            color: PdfColor.fromHex('#475569'),
                          ),
                        ),
                        pw.SizedBox(height: 8),
                        pw.Text(
                          vehicle.name,
                          style: pw.TextStyle(
                            fontSize: 16,
                            fontWeight: pw.FontWeight.bold,
                            color: PdfColor.fromHex('#0F172A'),
                          ),
                        ),
                        pw.SizedBox(height: 4),
                        _pdfDetailRow('Type', vehicle.type.displayName),
                        _pdfDetailRow('Model / Variant', '${vehicle.model} ${vehicle.variant}'.trim()),
                        _pdfDetailRow('Engine', vehicle.engineCapacity),
                        _pdfDetailRow('Transmission', vehicle.transmissionType),
                        _pdfDetailRow('Odometer Mileage', '${numberFormat.format(vehicle.mileage)} km'),
                        if (vehicle.fuelAverage > 0)
                          _pdfDetailRow('Fuel Average', '${vehicle.fuelAverage.toStringAsFixed(1)} km/L'),
                      ],
                    ),
                  ),
                ),
                pw.SizedBox(width: 14),

                // Service Details Card
                pw.Expanded(
                  child: pw.Container(
                    padding: const pw.EdgeInsets.all(14),
                    decoration: pw.BoxDecoration(
                      color: PdfColor.fromHex('#F8FAFC'),
                      borderRadius: pw.BorderRadius.circular(10),
                      border: pw.Border.all(color: PdfColor.fromHex('#E2E8F0')),
                    ),
                    child: pw.Column(
                      crossAxisAlignment: pw.CrossAxisAlignment.start,
                      children: [
                        pw.Text(
                          'SERVICE SPECIFICATIONS',
                          style: pw.TextStyle(
                            fontSize: 10,
                            fontWeight: pw.FontWeight.bold,
                            color: PdfColor.fromHex('#475569'),
                          ),
                        ),
                        pw.SizedBox(height: 8),
                        pw.Text(
                          record.serviceName.isEmpty ? 'General Maintenance' : record.serviceName,
                          style: pw.TextStyle(
                            fontSize: 16,
                            fontWeight: pw.FontWeight.bold,
                            color: PdfColor.fromHex('#0F172A'),
                          ),
                        ),
                        pw.SizedBox(height: 4),
                        _pdfDetailRow('Service Shop', record.serviceShop.isEmpty ? 'Self / Not Specified' : record.serviceShop),
                        _pdfDetailRow('Service Date', dateFormat.format(record.date)),
                        _pdfDetailRow('Mileage at Service', '${numberFormat.format(record.mileage)} km'),
                        if (record.nextServiceMileage != null && record.nextServiceMileage! > 0)
                          _pdfDetailRow('Next Service Due', '${numberFormat.format(record.nextServiceMileage)} km'),
                        _pdfDetailRow(
                          'Total Service Cost',
                          record.totalPrice > 0 ? 'Rs. ${currencyFormat.format(record.totalPrice)}' : 'Not specified',
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),

            pw.SizedBox(height: 20),

            // Parts Replaced Section with Prices
            _pdfSectionTitle('Parts Replaced & Costs'),
            pw.SizedBox(height: 6),
            if (replacedItems.isEmpty)
              pw.Container(
                width: double.infinity,
                padding: const pw.EdgeInsets.symmetric(vertical: 8, horizontal: 12),
                decoration: pw.BoxDecoration(
                  color: PdfColors.grey100,
                  borderRadius: pw.BorderRadius.circular(6),
                ),
                child: pw.Text(
                  'No parts replaced (None).',
                  style: const pw.TextStyle(fontSize: 10, color: PdfColors.grey700),
                ),
              )
            else
              pw.Container(
                decoration: pw.BoxDecoration(
                  border: pw.Border.all(color: PdfColor.fromHex('#E2E8F0')),
                  borderRadius: pw.BorderRadius.circular(8),
                ),
                child: pw.Table(
                  border: pw.TableBorder(
                    horizontalInside: pw.BorderSide(color: PdfColor.fromHex('#E2E8F0'), width: 0.8),
                  ),
                  children: [
                    pw.TableRow(
                      decoration: pw.BoxDecoration(color: PdfColor.fromHex('#FEE2E2')),
                      children: [
                        pw.Padding(
                          padding: const pw.EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                          child: pw.Text('Part Name & Brand / Specs', style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 9.5)),
                        ),
                        pw.Padding(
                          padding: const pw.EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                          child: pw.Text('Price', style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 9.5), textAlign: pw.TextAlign.right),
                        ),
                      ],
                    ),
                    ...replacedItems.map((p) => pw.TableRow(
                          children: [
                            pw.Padding(
                              padding: const pw.EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                              child: pw.Text(
                                p.company.isNotEmpty ? '${p.name} (${p.company})' : p.name,
                                style: const pw.TextStyle(fontSize: 9.5),
                              ),
                            ),
                            pw.Padding(
                              padding: const pw.EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                              child: pw.Text(
                                p.price > 0 ? 'Rs. ${currencyFormat.format(p.price)}' : '—',
                                style: pw.TextStyle(fontSize: 9.5, fontWeight: pw.FontWeight.bold),
                                textAlign: pw.TextAlign.right,
                              ),
                            ),
                          ],
                        )),
                  ],
                ),
              ),

            pw.SizedBox(height: 18),

            // New Parts Added Section with Prices
            _pdfSectionTitle('New Parts Added / Upgrades & Costs'),
            pw.SizedBox(height: 6),
            if (newItems.isEmpty)
              pw.Container(
                width: double.infinity,
                padding: const pw.EdgeInsets.symmetric(vertical: 8, horizontal: 12),
                decoration: pw.BoxDecoration(
                  color: PdfColors.grey100,
                  borderRadius: pw.BorderRadius.circular(6),
                ),
                child: pw.Text(
                  'No new parts or accessories installed (None).',
                  style: const pw.TextStyle(fontSize: 10, color: PdfColors.grey700),
                ),
              )
            else
              pw.Container(
                decoration: pw.BoxDecoration(
                  border: pw.Border.all(color: PdfColor.fromHex('#E2E8F0')),
                  borderRadius: pw.BorderRadius.circular(8),
                ),
                child: pw.Table(
                  border: pw.TableBorder(
                    horizontalInside: pw.BorderSide(color: PdfColor.fromHex('#E2E8F0'), width: 0.8),
                  ),
                  children: [
                    pw.TableRow(
                      decoration: pw.BoxDecoration(color: PdfColor.fromHex('#E0E7FF')),
                      children: [
                        pw.Padding(
                          padding: const pw.EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                          child: pw.Text('Part / Upgrade & Brand', style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 9.5)),
                        ),
                        pw.Padding(
                          padding: const pw.EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                          child: pw.Text('Price', style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 9.5), textAlign: pw.TextAlign.right),
                        ),
                      ],
                    ),
                    ...newItems.map((p) => pw.TableRow(
                          children: [
                            pw.Padding(
                              padding: const pw.EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                              child: pw.Text(
                                p.company.isNotEmpty ? '${p.name} (${p.company})' : p.name,
                                style: const pw.TextStyle(fontSize: 9.5),
                              ),
                            ),
                            pw.Padding(
                              padding: const pw.EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                              child: pw.Text(
                                p.price > 0 ? 'Rs. ${currencyFormat.format(p.price)}' : '—',
                                style: pw.TextStyle(fontSize: 9.5, fontWeight: pw.FontWeight.bold),
                                textAlign: pw.TextAlign.right,
                              ),
                            ),
                          ],
                        )),
                  ],
                ),
              ),

            pw.SizedBox(height: 18),

            // Total Cost Banner Card
            pw.Container(
              padding: const pw.EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              decoration: pw.BoxDecoration(
                color: PdfColor.fromHex('#ECFDF5'),
                borderRadius: pw.BorderRadius.circular(8),
                border: pw.Border.all(color: PdfColor.fromHex('#A7F3D0'), width: 1),
              ),
              child: pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                children: [
                  pw.Text(
                    'TOTAL AMOUNT SPENT ON THIS SERVICE',
                    style: pw.TextStyle(
                      fontSize: 10,
                      fontWeight: pw.FontWeight.bold,
                      color: PdfColor.fromHex('#065F46'),
                    ),
                  ),
                  pw.Text(
                    record.totalPrice > 0 ? 'Rs. ${currencyFormat.format(record.totalPrice)}' : '—',
                    style: pw.TextStyle(
                      fontSize: 14,
                      fontWeight: pw.FontWeight.bold,
                      color: PdfColor.fromHex('#047857'),
                    ),
                  ),
                ],
              ),
            ),

            pw.SizedBox(height: 18),

            // Notes Section
            _pdfSectionTitle('Maintenance Notes & Mechanic Remarks'),
            pw.SizedBox(height: 6),
            pw.Container(
              width: double.infinity,
              padding: const pw.EdgeInsets.all(12),
              decoration: pw.BoxDecoration(
                color: PdfColor.fromHex('#F8FAFC'),
                borderRadius: pw.BorderRadius.circular(8),
                border: pw.Border.all(color: PdfColor.fromHex('#E2E8F0')),
              ),
              child: pw.Text(
                record.notes.trim().isEmpty ? 'No additional notes provided.' : record.notes.trim(),
                style: const pw.TextStyle(fontSize: 10, color: PdfColors.grey800, lineSpacing: 2),
              ),
            ),

            if (embeddedImageBytes.isNotEmpty) ...[
              pw.SizedBox(height: 20),
              _pdfSectionTitle('Service & Inspection Photos (${embeddedImageBytes.length})'),
              pw.SizedBox(height: 8),
              pw.Wrap(
                spacing: 12,
                runSpacing: 12,
                children: embeddedImageBytes.map((bytes) {
                  return pw.Container(
                    width: 150,
                    height: 110,
                    decoration: pw.BoxDecoration(
                      borderRadius: pw.BorderRadius.circular(6),
                      border: pw.Border.all(color: PdfColors.grey300),
                    ),
                    child: pw.ClipRRect(
                      horizontalRadius: 6,
                      verticalRadius: 6,
                      child: pw.Image(
                        pw.MemoryImage(bytes),
                        fit: pw.BoxFit.cover,
                      ),
                    ),
                  );
                }).toList(),
              ),
            ],

            pw.SizedBox(height: 28),
            // Verification Block (Technician signature removed as requested, leaving space blank)
            pw.Row(
              mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
              children: [
                pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    pw.Text(
                      'Recorded By: Owner / Authorized Workshop',
                      style: const pw.TextStyle(fontSize: 9, color: PdfColors.grey600),
                    ),
                    pw.SizedBox(height: 2),
                    pw.Text(
                      'System Verification: Verified Record',
                      style: pw.TextStyle(
                        fontSize: 9,
                        fontWeight: pw.FontWeight.bold,
                        color: PdfColor.fromHex('#059669'),
                      ),
                    ),
                  ],
                ),
                pw.SizedBox(width: 140), // Left blank
              ],
            ),
          ];
        },
      ),
    );

    return pdf.save();
  }

  static pw.Widget _pdfDetailRow(String label, String value) {
    return pw.Padding(
      padding: const pw.EdgeInsets.symmetric(vertical: 2),
      child: pw.Row(
        mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
        children: [
          pw.Text(
            label,
            style: const pw.TextStyle(fontSize: 9, color: PdfColors.grey600),
          ),
          pw.Text(
            value.isEmpty ? '—' : value,
            style: pw.TextStyle(
              fontSize: 9.5,
              fontWeight: pw.FontWeight.bold,
              color: PdfColors.grey800,
            ),
          ),
        ],
      ),
    );
  }

  static pw.Widget _pdfSectionTitle(String title) {
    return pw.Text(
      title.toUpperCase(),
      style: pw.TextStyle(
        fontSize: 10,
        fontWeight: pw.FontWeight.bold,
        color: PdfColor.fromHex('#334155'),
        letterSpacing: 0.5,
      ),
    );
  }

  /// Generates a comprehensive full service history report PDF for a vehicle
  static Future<Uint8List> generateFullVehicleServiceReport({
    required Vehicle vehicle,
    required List<ServiceRecord> records,
  }) async {
    final pdf = pw.Document();
    final dateFormat = DateFormat('dd/MM/yyyy');
    final numberFormat = NumberFormat('#,###');
    final currencyFormat = NumberFormat('#,##0.00');

    // Load official app logo asset
    Uint8List? logoBytes;
    try {
      final byteData = await rootBundle.load('assets/icons/app_logo.png');
      logoBytes = byteData.buffer.asUint8List();
    } catch (_) {}

    final sortedRecords = List<ServiceRecord>.from(records)
      ..sort((a, b) => b.date.compareTo(a.date));

    final totalSpent = sortedRecords.fold(0.0, (acc, r) => acc + r.totalPrice);

    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(36),
        header: (pw.Context context) {
          return pw.Container(
            padding: const pw.EdgeInsets.only(bottom: 14),
            decoration: const pw.BoxDecoration(
              border: pw.Border(
                bottom: pw.BorderSide(color: PdfColors.grey300, width: 1.5),
              ),
            ),
            child: pw.Row(
              mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
              crossAxisAlignment: pw.CrossAxisAlignment.center,
              children: [
                pw.Row(
                  children: [
                    if (logoBytes != null)
                      pw.Container(
                        width: 36,
                        height: 36,
                        child: pw.ClipRRect(
                          horizontalRadius: 8,
                          verticalRadius: 8,
                          child: pw.Image(
                            pw.MemoryImage(logoBytes),
                            width: 36,
                            height: 36,
                          ),
                        ),
                      )
                    else
                      pw.Container(
                        width: 36,
                        height: 36,
                        decoration: pw.BoxDecoration(
                          color: PdfColor.fromHex('#10B981'),
                          borderRadius: pw.BorderRadius.circular(8),
                        ),
                        alignment: pw.Alignment.center,
                        child: pw.Text(
                          'R',
                          style: pw.TextStyle(
                            color: PdfColors.white,
                            fontSize: 22,
                            fontWeight: pw.FontWeight.bold,
                          ),
                        ),
                      ),
                    pw.SizedBox(width: 10),
                    pw.Column(
                      crossAxisAlignment: pw.CrossAxisAlignment.start,
                      children: [
                        pw.Text(
                          'RIDO',
                          style: pw.TextStyle(
                            fontSize: 18,
                            fontWeight: pw.FontWeight.bold,
                            letterSpacing: 1.5,
                            color: PdfColor.fromHex('#0F172A'),
                          ),
                        ),
                        pw.Text(
                          'Vehicle Maintenance Platform',
                          style: const pw.TextStyle(
                            fontSize: 8.5,
                            color: PdfColors.grey600,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
                pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.end,
                  children: [
                    pw.Container(
                      padding: const pw.EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: pw.BoxDecoration(
                        color: PdfColor.fromHex('#ECFDF5'),
                        borderRadius: pw.BorderRadius.circular(6),
                        border: pw.Border.all(color: PdfColor.fromHex('#A7F3D0')),
                      ),
                      child: pw.Text(
                        'FULL SERVICE HISTORY',
                        style: pw.TextStyle(
                          fontSize: 9.5,
                          fontWeight: pw.FontWeight.bold,
                          color: PdfColor.fromHex('#047857'),
                        ),
                      ),
                    ),
                    pw.SizedBox(height: 3),
                    pw.Text(
                      vehicle.name,
                      style: pw.TextStyle(
                        fontSize: 10,
                        fontWeight: pw.FontWeight.bold,
                        color: PdfColor.fromHex('#0F172A'),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          );
        },
        footer: (pw.Context context) {
          return pw.Container(
            padding: const pw.EdgeInsets.only(top: 10),
            decoration: const pw.BoxDecoration(
              border: pw.Border(
                top: pw.BorderSide(color: PdfColors.grey300, width: 0.8),
              ),
            ),
            child: pw.Row(
              mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
              children: [
                pw.Text(
                  'Generated with Rido App • ${dateFormat.format(DateTime.now())}',
                  style: const pw.TextStyle(fontSize: 8, color: PdfColors.grey500),
                ),
                pw.Text(
                  'Page ${context.pageNumber} of ${context.pagesCount}',
                  style: const pw.TextStyle(fontSize: 8, color: PdfColors.grey500),
                ),
              ],
            ),
          );
        },
        build: (pw.Context context) {
          return [
            pw.SizedBox(height: 14),

            // Vehicle Overview & Maintenance Summary Bar
            pw.Row(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                // Vehicle Specs Box
                pw.Expanded(
                  flex: 6,
                  child: pw.Container(
                    padding: const pw.EdgeInsets.all(12),
                    decoration: pw.BoxDecoration(
                      color: PdfColor.fromHex('#F8FAFC'),
                      borderRadius: pw.BorderRadius.circular(8),
                      border: pw.Border.all(color: PdfColors.grey300),
                    ),
                    child: pw.Column(
                      crossAxisAlignment: pw.CrossAxisAlignment.start,
                      children: [
                        _pdfSectionTitle('Vehicle Specifications'),
                        pw.SizedBox(height: 8),
                        pw.Row(
                          children: [
                            pw.Expanded(child: _pdfDetailRow('Type', vehicle.type.displayName)),
                            pw.SizedBox(width: 12),
                            pw.Expanded(child: _pdfDetailRow('Model', vehicle.model.isNotEmpty ? vehicle.model : 'Standard')),
                          ],
                        ),
                        pw.Row(
                          children: [
                            pw.Expanded(child: _pdfDetailRow('Variant', vehicle.variant.isNotEmpty ? vehicle.variant : 'Standard')),
                            pw.SizedBox(width: 12),
                            pw.Expanded(child: _pdfDetailRow('Odometer', '${numberFormat.format(vehicle.mileage)} km')),
                          ],
                        ),
                        pw.Row(
                          children: [
                            pw.Expanded(child: _pdfDetailRow('Engine', vehicle.engineCapacity.isNotEmpty ? vehicle.engineCapacity : '—')),
                            pw.SizedBox(width: 12),
                            pw.Expanded(child: _pdfDetailRow('Transmission', vehicle.transmissionType.isNotEmpty ? vehicle.transmissionType : '—')),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
                pw.SizedBox(width: 12),
                // Stats Box
                pw.Expanded(
                  flex: 4,
                  child: pw.Container(
                    padding: const pw.EdgeInsets.all(12),
                    decoration: pw.BoxDecoration(
                      color: PdfColor.fromHex('#F0FDF4'),
                      borderRadius: pw.BorderRadius.circular(8),
                      border: pw.Border.all(color: PdfColor.fromHex('#BBF7D0')),
                    ),
                    child: pw.Column(
                      crossAxisAlignment: pw.CrossAxisAlignment.start,
                      children: [
                        pw.Text(
                          'MAINTENANCE STATS',
                          style: pw.TextStyle(
                            fontSize: 9.5,
                            fontWeight: pw.FontWeight.bold,
                            color: PdfColor.fromHex('#15803D'),
                          ),
                        ),
                        pw.SizedBox(height: 8),
                        _pdfDetailRow('Total Records', '${sortedRecords.length} services'),
                        _pdfDetailRow('Total Cost', 'Rs. ${numberFormat.format(totalSpent)}'),
                        _pdfDetailRow(
                          'Last Service',
                          vehicle.lastServiceDate != null ? dateFormat.format(vehicle.lastServiceDate!) : '—',
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),

            pw.SizedBox(height: 18),
            _pdfSectionTitle('Service Log Entries (${sortedRecords.length})'),
            pw.SizedBox(height: 8),

            if (sortedRecords.isEmpty)
              pw.Container(
                padding: const pw.EdgeInsets.all(20),
                alignment: pw.Alignment.center,
                decoration: pw.BoxDecoration(
                  color: PdfColor.fromHex('#F8FAFC'),
                  borderRadius: pw.BorderRadius.circular(8),
                  border: pw.Border.all(color: PdfColors.grey300),
                ),
                child: pw.Text(
                  'No service records found for this vehicle.',
                  style: const pw.TextStyle(fontSize: 10, color: PdfColors.grey600),
                ),
              )
            else
              pw.Column(
                children: sortedRecords.map((r) {
                  final replaced = r.partsReplaced
                      .where((p) => p.name.isNotEmpty && p.name != 'None')
                      .map((p) => p.price > 0 ? '${p.name} (Rs. ${numberFormat.format(p.price)})' : p.name)
                      .join(', ');
                  final added = r.newPartsAdded
                      .where((p) => p.name.isNotEmpty && p.name != 'None')
                      .map((p) => p.price > 0 ? '${p.name} (Rs. ${numberFormat.format(p.price)})' : p.name)
                      .join(', ');

                  return pw.Container(
                    margin: const pw.EdgeInsets.only(bottom: 10),
                    padding: const pw.EdgeInsets.all(10),
                    decoration: pw.BoxDecoration(
                      color: PdfColor.fromHex('#FFFFFF'),
                      borderRadius: pw.BorderRadius.circular(6),
                      border: pw.Border.all(color: PdfColors.grey300),
                    ),
                    child: pw.Column(
                      crossAxisAlignment: pw.CrossAxisAlignment.start,
                      children: [
                        // Row 1: Date, Service Name, Price
                        pw.Row(
                          mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                          children: [
                            pw.Row(
                              children: [
                                pw.Container(
                                  padding: const pw.EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                  decoration: pw.BoxDecoration(
                                    color: PdfColor.fromHex('#F1F5F9'),
                                    borderRadius: pw.BorderRadius.circular(4),
                                  ),
                                  child: pw.Text(
                                    dateFormat.format(r.date),
                                    style: pw.TextStyle(
                                      fontSize: 9,
                                      fontWeight: pw.FontWeight.bold,
                                      color: PdfColor.fromHex('#334155'),
                                    ),
                                  ),
                                ),
                                pw.SizedBox(width: 8),
                                pw.Text(
                                  r.serviceName.isEmpty ? 'General Service' : r.serviceName,
                                  style: pw.TextStyle(
                                    fontSize: 11,
                                    fontWeight: pw.FontWeight.bold,
                                    color: PdfColor.fromHex('#0F172A'),
                                  ),
                                ),
                              ],
                            ),
                            pw.Container(
                              padding: const pw.EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                              decoration: pw.BoxDecoration(
                                color: PdfColor.fromHex('#ECFDF5'),
                                borderRadius: pw.BorderRadius.circular(4),
                              ),
                              child: pw.Text(
                                r.totalPrice > 0 ? 'Rs. ${currencyFormat.format(r.totalPrice)}' : 'Free / Warranty',
                                style: pw.TextStyle(
                                  fontSize: 10,
                                  fontWeight: pw.FontWeight.bold,
                                  color: PdfColor.fromHex('#047857'),
                                ),
                              ),
                            ),
                          ],
                        ),
                        pw.SizedBox(height: 6),
                        // Row 2: Mileage, Shop, Next Due
                        pw.Row(
                          children: [
                            pw.Text('Odometer: ${numberFormat.format(r.mileage)} km',
                                style: const pw.TextStyle(fontSize: 8.5, color: PdfColors.grey700)),
                            if (r.serviceShop.isNotEmpty) ...[
                              pw.Text('  •  Workshop: ${r.serviceShop}',
                                  style: const pw.TextStyle(fontSize: 8.5, color: PdfColors.grey700)),
                            ],
                            if (r.nextServiceMileage != null && r.nextServiceMileage! > 0) ...[
                              pw.Text('  •  Next Due: ${numberFormat.format(r.nextServiceMileage)} km',
                                  style: pw.TextStyle(fontSize: 8.5, fontWeight: pw.FontWeight.bold, color: PdfColor.fromHex('#2563EB'))),
                            ],
                          ],
                        ),
                        if (replaced.isNotEmpty) ...[
                          pw.SizedBox(height: 4),
                          pw.RichText(
                            text: pw.TextSpan(
                              children: [
                                pw.TextSpan(
                                  text: 'Parts Replaced: ',
                                  style: pw.TextStyle(fontSize: 8, fontWeight: pw.FontWeight.bold, color: PdfColor.fromHex('#DC2626')),
                                ),
                                pw.TextSpan(
                                  text: replaced,
                                  style: const pw.TextStyle(fontSize: 8, color: PdfColors.grey800),
                                ),
                              ],
                            ),
                          ),
                        ],
                        if (added.isNotEmpty) ...[
                          pw.SizedBox(height: 3),
                          pw.RichText(
                            text: pw.TextSpan(
                              children: [
                                pw.TextSpan(
                                  text: 'Parts Added: ',
                                  style: pw.TextStyle(fontSize: 8, fontWeight: pw.FontWeight.bold, color: PdfColor.fromHex('#4F46E5')),
                                ),
                                pw.TextSpan(
                                  text: added,
                                  style: const pw.TextStyle(fontSize: 8, color: PdfColors.grey800),
                                ),
                              ],
                            ),
                          ),
                        ],
                        if (r.notes.isNotEmpty) ...[
                          pw.SizedBox(height: 3),
                          pw.Text(
                            'Notes: ${r.notes}',
                            style: const pw.TextStyle(fontSize: 8, color: PdfColors.grey600, fontStyle: pw.FontStyle.italic),
                          ),
                        ],
                      ],
                    ),
                  );
                }).toList(),
              ),

            pw.SizedBox(height: 14),

            // Grand Total Footer Box
            if (sortedRecords.isNotEmpty)
              pw.Container(
                padding: const pw.EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                decoration: pw.BoxDecoration(
                  color: PdfColor.fromHex('#0F172A'),
                  borderRadius: pw.BorderRadius.circular(8),
                ),
                child: pw.Row(
                  mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                  children: [
                    pw.Text(
                      'TOTAL CUMULATIVE MAINTENANCE EXPENSE',
                      style: pw.TextStyle(
                        fontSize: 9.5,
                        fontWeight: pw.FontWeight.bold,
                        color: PdfColors.white,
                        letterSpacing: 0.5,
                      ),
                    ),
                    pw.Text(
                      'Rs. ${currencyFormat.format(totalSpent)}',
                      style: pw.TextStyle(
                        fontSize: 12,
                        fontWeight: pw.FontWeight.bold,
                        color: PdfColor.fromHex('#34D399'),
                      ),
                    ),
                  ],
                ),
              ),
          ];
        },
      ),
    );

    return pdf.save();
  }
}
