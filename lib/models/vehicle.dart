import 'vehicle_type.dart';

class Vehicle {
  final String id;
  final VehicleType type;
  final String name;
  final String model;
  final String variant;
  final int mileage;
  final double fuelAverage;
  final String engineCapacity;
  final String transmissionType;
  final String? imagePath;
  final DateTime createdAt;
  final DateTime? lastServiceDate;
  final int? nextServiceMileage;

  const Vehicle({
    required this.id,
    required this.type,
    required this.name,
    required this.model,
    required this.variant,
    required this.mileage,
    required this.fuelAverage,
    required this.engineCapacity,
    required this.transmissionType,
    this.imagePath,
    required this.createdAt,
    this.lastServiceDate,
    this.nextServiceMileage,
  });

  Vehicle copyWith({
    String? id,
    VehicleType? type,
    String? name,
    String? model,
    String? variant,
    int? mileage,
    double? fuelAverage,
    String? engineCapacity,
    String? transmissionType,
    String? imagePath,
    DateTime? createdAt,
    DateTime? lastServiceDate,
    int? nextServiceMileage,
  }) {
    return Vehicle(
      id: id ?? this.id,
      type: type ?? this.type,
      name: name ?? this.name,
      model: model ?? this.model,
      variant: variant ?? this.variant,
      mileage: mileage ?? this.mileage,
      fuelAverage: fuelAverage ?? this.fuelAverage,
      engineCapacity: engineCapacity ?? this.engineCapacity,
      transmissionType: transmissionType ?? this.transmissionType,
      imagePath: imagePath ?? this.imagePath,
      createdAt: createdAt ?? this.createdAt,
      lastServiceDate: lastServiceDate ?? this.lastServiceDate,
      nextServiceMileage: nextServiceMileage ?? this.nextServiceMileage,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'type': type.name,
      'name': name,
      'model': model,
      'variant': variant,
      'mileage': mileage,
      'fuelAverage': fuelAverage,
      'engineCapacity': engineCapacity,
      'transmissionType': transmissionType,
      'imagePath': imagePath,
      'createdAt': createdAt.toIso8601String(),
      'lastServiceDate': lastServiceDate?.toIso8601String(),
      'nextServiceMileage': nextServiceMileage,
    };
  }

  factory Vehicle.fromJson(Map<String, dynamic> json) {
    return Vehicle(
      id: json['id'] as String,
      type: VehicleType.values.firstWhere(
        (t) => t.name == json['type'],
        orElse: () => VehicleType.car,
      ),
      name: json['name'] as String? ?? '',
      model: json['model'] as String? ?? '',
      variant: json['variant'] as String? ?? '',
      mileage: (json['mileage'] as num?)?.toInt() ?? 0,
      fuelAverage: (json['fuelAverage'] as num?)?.toDouble() ?? 0.0,
      engineCapacity: json['engineCapacity'] as String? ?? '',
      transmissionType: json['transmissionType'] as String? ?? 'Automatic',
      imagePath: json['imagePath'] as String?,
      createdAt: json['createdAt'] != null
          ? DateTime.tryParse(json['createdAt'] as String) ?? DateTime.now()
          : DateTime.now(),
      lastServiceDate: json['lastServiceDate'] != null
          ? DateTime.tryParse(json['lastServiceDate'] as String)
          : null,
      nextServiceMileage: (json['nextServiceMileage'] as num?)?.toInt(),
    );
  }
}
