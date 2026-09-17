import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:archive/archive.dart';
import 'package:rido/models/vehicle.dart';
import 'package:rido/models/vehicle_type.dart';
import 'package:rido/models/service_record.dart';
import 'package:rido/screens/vehicle_records_screen.dart';
import 'package:rido/screens/vehicle_profile_screen.dart';
import 'package:rido/screens/add_edit_record_screen.dart';
import 'package:rido/screens/pdf_viewer_screen.dart';
import 'package:rido/services/storage_service.dart';
import 'package:rido/services/theme_service.dart';
import 'package:rido/services/pdf_generator_service.dart';
import 'package:rido/services/excel_exporter_service.dart';
import 'package:rido/main.dart';

void main() {
  test('Vehicle model serialization test', () {
    final vehicle = Vehicle(
      id: 'test-123',
      type: VehicleType.car,
      name: 'Toyota Corolla',
      model: 'Corolla',
      variant: 'Altis Grande',
      mileage: 35000,
      fuelAverage: 14.2,
      engineCapacity: '1800 cc',
      transmissionType: 'CVT',
      createdAt: DateTime(2026, 1, 1),
    );

    final json = vehicle.toJson();
    final deserialized = Vehicle.fromJson(json);

    expect(deserialized.id, 'test-123');
    expect(deserialized.name, 'Toyota Corolla');
    expect(deserialized.type, VehicleType.car);
    expect(deserialized.mileage, 35000);
    expect(deserialized.fuelAverage, 14.2);
  });

  test('ServiceRecord model serialization test', () {
    final record = ServiceRecord(
      id: 'rec-456',
      vehicleId: 'test-123',
      serviceName: 'Oil Change',
      serviceShop: 'Express Service',
      date: DateTime(2026, 2, 1),
      mileage: 35000,
      nextServiceMileage: 40000,
      partsReplaced: const [
        PartItem(name: 'Engine Oil', company: 'Mobil 1 5W-30', price: 45.0),
        PartItem(name: 'Oil Filter', company: 'Denso', price: 15.0),
      ],
      newPartsAdded: const [
        PartItem(name: 'Cabin Air Filter', company: 'Bosch', price: 20.0),
      ],
      totalPrice: 80.0,
      notes: 'Synthetic 5W-30 used',
      imagePaths: const ['/dummy/path.jpg'],
      titleImageIndex: 0,
      createdAt: DateTime(2026, 2, 1),
    );

    final json = record.toJson();
    final deserialized = ServiceRecord.fromJson(json);

    expect(deserialized.id, 'rec-456');
    expect(deserialized.serviceName, 'Oil Change');
    expect(deserialized.totalPrice, 80.0);
    expect(deserialized.nextServiceMileage, 40000);
    expect(deserialized.partsReplaced.first.name, 'Engine Oil');
    expect(deserialized.partsReplaced.first.company, 'Mobil 1 5W-30');
    expect(deserialized.partsReplaced.first.price, 45.0);
    expect(deserialized.newPartsAdded.first.company, 'Bosch');
    expect(deserialized.titleImagePath, '/dummy/path.jpg');
  });

  test('PartItem backwards compatibility test', () {
    final legacyJson1 = {'name': 'Spark Plugs', 'price': 30.0};
    final legacyPart1 = PartItem.fromJson(legacyJson1);
    expect(legacyPart1.name, 'Spark Plugs');
    expect(legacyPart1.company, '');

    final legacyJson2 = {'name': 'Brake Pads', 'brand': 'Brembo', 'price': 120.0};
    final legacyPart2 = PartItem.fromJson(legacyJson2);
    expect(legacyPart2.company, 'Brembo');
  });

  testWidgets('RidoApp loads and displays tabs and logo', (WidgetTester tester) async {
    final storageService = StorageService();
    final themeService = ThemeService();

    await tester.pumpWidget(RidoApp(
      storageService: storageService,
      themeService: themeService,
    ));

    await tester.pumpAndSettle();

    expect(find.text('RIDO'), findsOneWidget);
    expect(find.textContaining('Cars ('), findsOneWidget);
    expect(find.textContaining('Bikes ('), findsOneWidget);
  });

  test('PdfGeneratorService generates service report bytes', () async {
    final vehicle = Vehicle(
      id: 'test-v1',
      type: VehicleType.car,
      name: 'Honda Civic',
      model: 'Civic',
      variant: 'Oriel',
      mileage: 20000,
      fuelAverage: 12.5,
      engineCapacity: '1500 cc',
      transmissionType: 'Automatic',
      createdAt: DateTime(2026, 1, 1),
    );

    final record = ServiceRecord(
      id: 'test-r1',
      vehicleId: 'test-v1',
      serviceName: 'Periodic Maintenance',
      serviceShop: 'Honda Drive-in',
      date: DateTime(2026, 2, 1),
      mileage: 20000,
      partsReplaced: const [PartItem(name: 'Engine Oil', price: 65.0)],
      newPartsAdded: const [],
      totalPrice: 65.0,
      notes: 'All checks normal',
      imagePaths: const [],
      titleImageIndex: 0,
      createdAt: DateTime(2026, 2, 1),
    );

    final pdfBytes = await PdfGeneratorService.generateServiceReport(
      vehicle: vehicle,
      record: record,
    );

    expect(pdfBytes, isNotNull);
    expect(pdfBytes.isNotEmpty, isTrue);
  });

  testWidgets('VehicleRecordsScreen searches and filters records', (WidgetTester tester) async {
    final storageService = StorageService();
    final vehicle = Vehicle(
      id: 'test-v1',
      type: VehicleType.car,
      name: 'Honda Civic',
      model: 'Civic',
      variant: 'Oriel',
      mileage: 20000,
      fuelAverage: 12.5,
      engineCapacity: '1500 cc',
      transmissionType: 'Automatic',
      createdAt: DateTime(2026, 1, 1),
    );

    final record1 = ServiceRecord(
      id: 'rec-1',
      vehicleId: 'test-v1',
      serviceName: 'Oil Change',
      serviceShop: 'Mobil 1 Center',
      date: DateTime(2026, 1, 15),
      mileage: 18000,
      nextServiceMileage: 23000,
      partsReplaced: const [PartItem(name: 'Engine Oil', company: 'Mobil 1', price: 6000.0)],
      newPartsAdded: const [],
      totalPrice: 6000.0,
      notes: 'Clean engine',
      imagePaths: const [],
      titleImageIndex: 0,
      createdAt: DateTime(2026, 1, 15),
    );

    final record2 = ServiceRecord(
      id: 'rec-2',
      vehicleId: 'test-v1',
      serviceName: 'Brake Pad Replacement',
      serviceShop: 'Brembo Authorized',
      date: DateTime(2026, 2, 20),
      mileage: 20000,
      nextServiceMileage: 40000,
      partsReplaced: const [PartItem(name: 'Front Brake Pads', company: 'Brembo', price: 15000.0)],
      newPartsAdded: const [],
      totalPrice: 15000.0,
      notes: 'Ceramic pads installed',
      imagePaths: const [],
      titleImageIndex: 0,
      createdAt: DateTime(2026, 2, 20),
    );

    storageService.addVehicleForTesting(vehicle);
    storageService.addRecordForTesting(record1);
    storageService.addRecordForTesting(record2);

    await tester.pumpWidget(MaterialApp(
      home: VehicleRecordsScreen(
        vehicle: vehicle,
        storageService: storageService,
      ),
    ));
    await tester.pumpAndSettle();

    // Verify both records exist initially
    expect(find.text('Oil Change'), findsOneWidget);
    expect(find.text('Brake Pad Replacement'), findsOneWidget);
    expect(find.textContaining('Rs. 21,000'), findsOneWidget);

    // Search for "Brembo"
    final searchField = find.byType(TextField);
    await tester.enterText(searchField, 'Brembo');
    await tester.pumpAndSettle();

    // Only Brake Pad Replacement should be visible (shows in tile and toolbar total spent)
    expect(find.text('Oil Change'), findsNothing);
    expect(find.text('Brake Pad Replacement'), findsOneWidget);
    expect(find.textContaining('Rs. 15,000'), findsNWidgets(2));

    // Clear search
    final clearButton = find.byIcon(Icons.close_rounded);
    await tester.tap(clearButton);
    await tester.pumpAndSettle();

    // Both should reappear
    expect(find.text('Oil Change'), findsOneWidget);
    expect(find.text('Brake Pad Replacement'), findsOneWidget);
  });

  testWidgets('PdfViewerScreen renders zoom controls and action buttons', (WidgetTester tester) async {
    final storageService = StorageService();
    final vehicle = Vehicle(
      id: 'test-v1',
      type: VehicleType.car,
      name: 'Honda Civic',
      model: 'Civic',
      variant: 'Oriel',
      mileage: 20000,
      fuelAverage: 12.5,
      engineCapacity: '1500 cc',
      transmissionType: 'Automatic',
      createdAt: DateTime(2026, 1, 1),
    );

    final record = ServiceRecord(
      id: 'test-r1',
      vehicleId: 'test-v1',
      serviceName: 'Periodic Maintenance',
      serviceShop: 'Honda Drive-in',
      date: DateTime(2026, 2, 1),
      mileage: 20000,
      partsReplaced: const [PartItem(name: 'Engine Oil', price: 65.0)],
      newPartsAdded: const [],
      totalPrice: 65.0,
      notes: 'All checks normal',
      imagePaths: const [],
      titleImageIndex: 0,
      createdAt: DateTime(2026, 2, 1),
    );

    await tester.pumpWidget(MaterialApp(
      home: PdfViewerScreen(
        vehicle: vehicle,
        record: record,
        storageService: storageService,
      ),
    ));

    expect(find.text('Periodic Maintenance'), findsOneWidget);
    expect(find.text('Honda Civic'), findsOneWidget);
    expect(find.byIcon(Icons.print_rounded), findsOneWidget);
    expect(find.byIcon(Icons.share_rounded), findsOneWidget);
    expect(find.byIcon(Icons.edit_rounded), findsOneWidget);
    expect(find.text('100%'), findsOneWidget);
    expect(find.byIcon(Icons.add_rounded), findsOneWidget);
    expect(find.byIcon(Icons.remove_rounded), findsOneWidget);
  });

  test('PdfGeneratorService generates full vehicle service report bytes', () async {
    final vehicle = Vehicle(
      id: 'test-v1',
      type: VehicleType.car,
      name: 'Honda Civic',
      model: 'Civic',
      variant: 'Oriel',
      mileage: 20000,
      fuelAverage: 12.5,
      engineCapacity: '1500 cc',
      transmissionType: 'Automatic',
      createdAt: DateTime(2026, 1, 1),
    );

    final record = ServiceRecord(
      id: 'test-r1',
      vehicleId: 'test-v1',
      serviceName: 'Full Service',
      serviceShop: 'Honda Drive-in',
      date: DateTime(2026, 2, 1),
      mileage: 20000,
      nextServiceMileage: 25000,
      partsReplaced: const [PartItem(name: 'Engine Oil', price: 6500.0)],
      newPartsAdded: const [PartItem(name: 'AC Filter', price: 1500.0)],
      totalPrice: 8000.0,
      notes: 'All checks passed',
      imagePaths: const [],
      titleImageIndex: 0,
      createdAt: DateTime(2026, 2, 1),
    );

    final pdfBytes = await PdfGeneratorService.generateFullVehicleServiceReport(
      vehicle: vehicle,
      records: [record],
    );

    expect(pdfBytes, isNotNull);
    expect(pdfBytes.isNotEmpty, isTrue);
  });

  testWidgets('VehicleProfileScreen renders Share Full Service History button and action', (WidgetTester tester) async {
    final storageService = StorageService();
    final vehicle = Vehicle(
      id: 'test-v1',
      type: VehicleType.car,
      name: 'Honda Civic',
      model: 'Civic',
      variant: 'Oriel',
      mileage: 20000,
      fuelAverage: 12.5,
      engineCapacity: '1500 cc',
      transmissionType: 'Automatic',
      createdAt: DateTime(2026, 1, 1),
    );

    await tester.pumpWidget(MaterialApp(
      home: VehicleProfileScreen(
        vehicle: vehicle,
        storageService: storageService,
      ),
    ));
    await tester.pumpAndSettle();

    expect(find.text('Car Profile'), findsOneWidget);
    expect(find.byIcon(Icons.share_rounded), findsNWidgets(2)); // AppBar + card button
    expect(find.text('Share Full Service History'), findsOneWidget);
  });

  testWidgets('AddEditRecordScreen shows Rs. prefix permanently', (WidgetTester tester) async {
    final storageService = StorageService();
    final vehicle = Vehicle(
      id: 'test-v1',
      type: VehicleType.car,
      name: 'Honda Civic',
      model: 'Civic',
      variant: 'Oriel',
      mileage: 20000,
      fuelAverage: 12.5,
      engineCapacity: '1500 cc',
      transmissionType: 'Automatic',
      createdAt: DateTime(2026, 1, 1),
    );

    await tester.pumpWidget(MaterialApp(
      home: AddEditRecordScreen(
        vehicle: vehicle,
        storageService: storageService,
      ),
    ));
    await tester.pumpAndSettle();

    // Verify Rs. is visible on screen even before any text input
    expect(find.text('Rs. '), findsOneWidget);
  });

  test('ExcelExporterService generates valid .xlsx spreadsheet file', () async {
    TestWidgetsFlutterBinding.ensureInitialized();
    final vehicle = Vehicle(
      id: 'test-v1',
      type: VehicleType.car,
      name: 'Honda Civic',
      model: 'Civic',
      variant: 'Oriel',
      mileage: 20000,
      fuelAverage: 12.5,
      engineCapacity: '1500 cc',
      transmissionType: 'Automatic',
      createdAt: DateTime(2026, 1, 1),
    );

    final record = ServiceRecord(
      id: 'test-r1',
      vehicleId: 'test-v1',
      serviceName: 'Periodic Maintenance',
      serviceShop: 'Honda Drive-in',
      date: DateTime(2026, 2, 1),
      mileage: 20000,
      nextServiceMileage: 25000,
      partsReplaced: const [PartItem(name: 'Engine Oil', price: 6500.0)],
      newPartsAdded: const [PartItem(name: 'AC Filter', price: 1500.0)],
      totalPrice: 8000.0,
      notes: 'All checks passed',
      imagePaths: const [],
      titleImageIndex: 0,
      createdAt: DateTime(2026, 2, 1),
    );

    final tempDir = Directory.systemTemp.createTempSync('rido_test_');
    final excelFile = await ExcelExporterService.generateFullServiceExcel(
      vehicle: vehicle,
      records: [record],
      outputDirectory: tempDir,
    );

    expect(await excelFile.exists(), isTrue);
    expect(excelFile.path.endsWith('.xlsx'), isTrue);

    final bytes = await excelFile.readAsBytes();
    expect(bytes.isNotEmpty, isTrue);

    // Verify it is a valid ZIP archive containing expected OpenXML parts
    final archive = ZipDecoder().decodeBytes(bytes);
    final fileNames = archive.files.map((f) => f.name).toSet();
    expect(fileNames.contains('[Content_Types].xml'), isTrue);
    expect(fileNames.contains('xl/workbook.xml'), isTrue);
    expect(fileNames.contains('xl/worksheets/sheet1.xml'), isTrue);
    expect(fileNames.contains('xl/worksheets/sheet2.xml'), isTrue);
    expect(fileNames.contains('xl/styles.xml'), isTrue);
  });
}
