import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:path_provider/path_provider.dart';
import 'package:uuid/uuid.dart';
import '../models/vehicle.dart';
import '../models/vehicle_type.dart';
import '../models/service_record.dart';
import 'pdf_generator_service.dart';

class StorageService extends ChangeNotifier {
  static const String _vehiclesFileName = 'vehicles.json';
  static const String _recordsFileName = 'service_records.json';

  final List<Vehicle> _vehicles = [];
  final List<ServiceRecord> _records = [];
  bool _isInitialized = false;

  List<Vehicle> get vehicles => List.unmodifiable(_vehicles);
  List<ServiceRecord> get records => List.unmodifiable(_records);
  bool get isInitialized => _isInitialized;

  Future<void> init() async {
    if (_isInitialized) return;
    try {
      await _loadData();
      // Remove any previously stored demo vehicles to ensure clean slate
      _vehicles.removeWhere((v) =>
          (v.name == 'Honda Civic' && v.model == 'Civic' && v.variant == '1.5 Turbo Oriel') ||
          (v.name == 'Yamaha MT-07' && v.model == 'MT-07' && v.variant == 'Hyper Naked ABS'));
      // Remove any orphaned records
      final validVehicleIds = _vehicles.map((v) => v.id).toSet();
      _records.removeWhere((r) => !validVehicleIds.contains(r.vehicleId));
      await _saveData();

      _isInitialized = true;
      notifyListeners();
    } catch (e) {
      debugPrint('StorageService init error: $e');
      _isInitialized = true;
      notifyListeners();
    }
  }

  Future<Directory> _getAppDir() async {
    return await getApplicationDocumentsDirectory();
  }

  Future<File> _getFile(String fileName) async {
    final dir = await _getAppDir();
    return File('${dir.path}/$fileName');
  }

  Future<void> _loadData() async {
    try {
      final vehiclesFile = await _getFile(_vehiclesFileName);
      if (await vehiclesFile.exists()) {
        final content = await vehiclesFile.readAsString();
        final List<dynamic> jsonList = jsonDecode(content);
        _vehicles.clear();
        for (final item in jsonList) {
          _vehicles.add(Vehicle.fromJson(item as Map<String, dynamic>));
        }
      }

      final recordsFile = await _getFile(_recordsFileName);
      if (await recordsFile.exists()) {
        final content = await recordsFile.readAsString();
        final List<dynamic> jsonList = jsonDecode(content);
        _records.clear();
        for (final item in jsonList) {
          _records.add(ServiceRecord.fromJson(item as Map<String, dynamic>));
        }
      }
    } catch (e) {
      debugPrint('Error reading files: $e');
    }
  }

  Future<void> _saveData() async {
    try {
      final vehiclesFile = await _getFile(_vehiclesFileName);
      final vehiclesJson = jsonEncode(_vehicles.map((v) => v.toJson()).toList());
      await vehiclesFile.writeAsString(vehiclesJson);

      final recordsFile = await _getFile(_recordsFileName);
      final recordsJson = jsonEncode(_records.map((r) => r.toJson()).toList());
      await recordsFile.writeAsString(recordsJson);
    } catch (e) {
      debugPrint('Error saving files: $e');
    }
  }

  List<Vehicle> getVehiclesByType(VehicleType type) {
    return _vehicles.where((v) => v.type == type).toList();
  }

  Vehicle? getVehicleById(String id) {
    try {
      return _vehicles.firstWhere((v) => v.id == id);
    } catch (_) {
      return null;
    }
  }

  List<ServiceRecord> getRecordsForVehicle(String vehicleId) {
    final list = _records.where((r) => r.vehicleId == vehicleId).toList();
    // Sort descending by date
    list.sort((a, b) => b.date.compareTo(a.date));
    return list;
  }

  Future<String> copyImageToPermanentStorage(String sourcePath) async {
    try {
      final appDir = await _getAppDir();
      final mediaDir = Directory('${appDir.path}/vehicle_images');
      if (!await mediaDir.exists()) {
        await mediaDir.create(recursive: true);
      }
      final extension = sourcePath.split('.').last;
      final newFileName = 'rido_${const Uuid().v4()}.$extension';
      final permanentPath = '${mediaDir.path}/$newFileName';
      await File(sourcePath).copy(permanentPath);
      return permanentPath;
    } catch (e) {
      debugPrint('Error copying image: $e');
      return sourcePath;
    }
  }

  Future<void> addVehicle(Vehicle vehicle) async {
    _vehicles.insert(0, vehicle);
    await _saveData();
    notifyListeners();
  }

  Future<void> updateVehicle(Vehicle vehicle) async {
    final index = _vehicles.indexWhere((v) => v.id == vehicle.id);
    if (index != -1) {
      _vehicles[index] = vehicle;
      await _saveData();
      notifyListeners();
    }
  }

  Future<void> deleteVehicle(String vehicleId) async {
    // 1. Clean up vehicle's own photo
    final vehicle = getVehicleById(vehicleId);
    if (vehicle != null && vehicle.imagePath != null) {
      try {
        final imgFile = File(vehicle.imagePath!);
        if (await imgFile.exists()) {
          await imgFile.delete();
        }
      } catch (_) {}
    }

    // 2. Clean up all records, their images, and PDFs
    final vehicleRecords = _records.where((r) => r.vehicleId == vehicleId).toList();
    for (final record in vehicleRecords) {
      if (record.pdfPath != null) {
        try {
          final pdfFile = File(record.pdfPath!);
          if (await pdfFile.exists()) {
            await pdfFile.delete();
          }
        } catch (_) {}
      }
      for (final imgPath in record.imagePaths) {
        try {
          final imgFile = File(imgPath);
          if (await imgFile.exists()) {
            await imgFile.delete();
          }
        } catch (_) {}
      }
    }

    _vehicles.removeWhere((v) => v.id == vehicleId);
    _records.removeWhere((r) => r.vehicleId == vehicleId);
    await _saveData();
    notifyListeners();
  }

  Future<ServiceRecord> saveRecordWithPdf({
    required ServiceRecord record,
    required Vehicle vehicle,
    bool isUpdate = false,
  }) async {
    // Generate PDF
    String? generatedPdfPath = record.pdfPath;
    try {
      final pdfBytes = await PdfGeneratorService.generateServiceReport(
        vehicle: vehicle,
        record: record,
      );
      final appDir = await _getAppDir();
      final reportsDir = Directory('${appDir.path}/reports');
      if (!await reportsDir.exists()) {
        await reportsDir.create(recursive: true);
      }
      final pdfFile = File('${reportsDir.path}/report_${record.id}.pdf');
      await pdfFile.writeAsBytes(pdfBytes);
      generatedPdfPath = pdfFile.path;
    } catch (e) {
      debugPrint('Error writing PDF: $e');
    }

    final finalRecord = record.copyWith(pdfPath: generatedPdfPath);

    if (isUpdate) {
      final index = _records.indexWhere((r) => r.id == finalRecord.id);
      if (index != -1) {
        _records[index] = finalRecord;
      } else {
        _records.add(finalRecord);
      }
    } else {
      _records.insert(0, finalRecord);
    }

    // Update vehicle's last service date, mileage if greater, and nextServiceMileage
    final updatedMileage = finalRecord.mileage > vehicle.mileage ? finalRecord.mileage : vehicle.mileage;
    final updatedVehicle = vehicle.copyWith(
      lastServiceDate: finalRecord.date,
      mileage: updatedMileage,
      nextServiceMileage: finalRecord.nextServiceMileage ?? vehicle.nextServiceMileage,
    );
    final vehicleIndex = _vehicles.indexWhere((v) => v.id == vehicle.id);
    if (vehicleIndex != -1) {
      _vehicles[vehicleIndex] = updatedVehicle;
    }

    await _saveData();
    notifyListeners();
    return finalRecord;
  }

  /// Returns the active next service mileage target for a vehicle.
  /// Looks at the newest service record with a specified nextServiceMileage,
  /// or falls back to the vehicle's own nextServiceMileage.
  int? getNextServiceMileageForVehicle(String vehicleId) {
    final vehicleRecords = getRecordsForVehicle(vehicleId);
    for (final r in vehicleRecords) {
      if (r.nextServiceMileage != null && r.nextServiceMileage! > 0) {
        return r.nextServiceMileage;
      }
    }
    final vehicle = getVehicleById(vehicleId);
    return vehicle?.nextServiceMileage;
  }

  /// Returns true if the vehicle has reached or exceeded its scheduled next service target.
  bool isVehicleDueForService(Vehicle vehicle) {
    final nextMileage = getNextServiceMileageForVehicle(vehicle.id);
    if (nextMileage == null || nextMileage <= 0) return false;
    return vehicle.mileage >= nextMileage;
  }

  /// Returns kilometers overdue if mileage >= nextServiceMileage, or 0 if not overdue.
  int getOverdueKm(Vehicle vehicle) {
    final nextMileage = getNextServiceMileageForVehicle(vehicle.id);
    if (nextMileage == null || nextMileage <= 0) return 0;
    final diff = vehicle.mileage - nextMileage;
    return diff > 0 ? diff : 0;
  }

  /// Returns remaining kilometers until next service, or 0 if already reached or overdue.
  int? getRemainingKm(Vehicle vehicle) {
    final nextMileage = getNextServiceMileageForVehicle(vehicle.id);
    if (nextMileage == null || nextMileage <= 0) return null;
    final remaining = nextMileage - vehicle.mileage;
    return remaining > 0 ? remaining : 0;
  }

  /// Returns all vehicles that have reached or passed their next service mileage.
  List<Vehicle> getVehiclesDueForService() {
    return _vehicles.where((v) => isVehicleDueForService(v)).toList();
  }

  Future<void> deleteServiceRecord(String recordId) async {
    final recordIndex = _records.indexWhere((r) => r.id == recordId);
    if (recordIndex != -1) {
      final record = _records[recordIndex];
      if (record.pdfPath != null) {
        try {
          final file = File(record.pdfPath!);
          if (await file.exists()) {
            await file.delete();
          }
        } catch (_) {}
      }
      for (final imgPath in record.imagePaths) {
        try {
          final imgFile = File(imgPath);
          if (await imgFile.exists()) {
            await imgFile.delete();
          }
        } catch (_) {}
      }
      _records.removeAt(recordIndex);
      await _saveData();
      notifyListeners();
    }
  }

  @visibleForTesting
  void addVehicleForTesting(Vehicle vehicle) {
    _vehicles.add(vehicle);
    notifyListeners();
  }

  @visibleForTesting
  void addRecordForTesting(ServiceRecord record) {
    _records.add(record);
    notifyListeners();
  }
}
