class PartItem {
  final String name;
  final String company;
  final double price;

  const PartItem({
    required this.name,
    this.company = '',
    this.price = 0.0,
  });

  PartItem copyWith({
    String? name,
    String? company,
    double? price,
  }) {
    return PartItem(
      name: name ?? this.name,
      company: company ?? this.company,
      price: price ?? this.price,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'company': company,
      'price': price,
    };
  }

  factory PartItem.fromJson(dynamic json) {
    if (json == null) return const PartItem(name: 'None', company: '', price: 0.0);
    if (json is String) {
      return PartItem(name: json, company: '', price: 0.0);
    }
    if (json is Map<String, dynamic>) {
      return PartItem(
        name: json['name'] as String? ?? '',
        company: (json['company'] ?? json['brand'] ?? json['specs']) as String? ?? '',
        price: (json['price'] as num?)?.toDouble() ?? 0.0,
      );
    }
    return PartItem(name: json.toString(), company: '', price: 0.0);
  }
}

class ServiceRecord {
  final String id;
  final String vehicleId;
  final String serviceName;
  final String serviceShop;
  final DateTime date;
  final int mileage;
  final int? nextServiceMileage;
  final List<PartItem> partsReplaced;
  final List<PartItem> newPartsAdded;
  final double totalPrice;
  final String notes;
  final List<String> imagePaths;
  final int titleImageIndex;
  final String? pdfPath;
  final DateTime createdAt;

  const ServiceRecord({
    required this.id,
    required this.vehicleId,
    required this.serviceName,
    required this.serviceShop,
    required this.date,
    required this.mileage,
    this.nextServiceMileage,
    required this.partsReplaced,
    required this.newPartsAdded,
    this.totalPrice = 0.0,
    required this.notes,
    required this.imagePaths,
    this.titleImageIndex = 0,
    this.pdfPath,
    required this.createdAt,
  });

  List<String> get partsReplacedNames => partsReplaced.map((p) => p.name).toList();
  List<String> get newPartsAddedNames => newPartsAdded.map((p) => p.name).toList();

  double get partsSum =>
      partsReplaced.fold(0.0, (acc, item) => acc + item.price) +
      newPartsAdded.fold(0.0, (acc, item) => acc + item.price);

  String? get titleImagePath {
    if (imagePaths.isEmpty) return null;
    if (titleImageIndex >= 0 && titleImageIndex < imagePaths.length) {
      return imagePaths[titleImageIndex];
    }
    return imagePaths.first;
  }

  ServiceRecord copyWith({
    String? id,
    String? vehicleId,
    String? serviceName,
    String? serviceShop,
    DateTime? date,
    int? mileage,
    int? nextServiceMileage,
    List<PartItem>? partsReplaced,
    List<PartItem>? newPartsAdded,
    double? totalPrice,
    String? notes,
    List<String>? imagePaths,
    int? titleImageIndex,
    String? pdfPath,
    DateTime? createdAt,
  }) {
    return ServiceRecord(
      id: id ?? this.id,
      vehicleId: vehicleId ?? this.vehicleId,
      serviceName: serviceName ?? this.serviceName,
      serviceShop: serviceShop ?? this.serviceShop,
      date: date ?? this.date,
      mileage: mileage ?? this.mileage,
      nextServiceMileage: nextServiceMileage ?? this.nextServiceMileage,
      partsReplaced: partsReplaced ?? this.partsReplaced,
      newPartsAdded: newPartsAdded ?? this.newPartsAdded,
      totalPrice: totalPrice ?? this.totalPrice,
      notes: notes ?? this.notes,
      imagePaths: imagePaths ?? this.imagePaths,
      titleImageIndex: titleImageIndex ?? this.titleImageIndex,
      pdfPath: pdfPath ?? this.pdfPath,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'vehicleId': vehicleId,
      'serviceName': serviceName,
      'serviceShop': serviceShop,
      'date': date.toIso8601String(),
      'mileage': mileage,
      'nextServiceMileage': nextServiceMileage,
      'partsReplaced': partsReplaced.map((p) => p.toJson()).toList(),
      'newPartsAdded': newPartsAdded.map((p) => p.toJson()).toList(),
      'totalPrice': totalPrice,
      'notes': notes,
      'imagePaths': imagePaths,
      'titleImageIndex': titleImageIndex,
      'pdfPath': pdfPath,
      'createdAt': createdAt.toIso8601String(),
    };
  }

  factory ServiceRecord.fromJson(Map<String, dynamic> json) {
    return ServiceRecord(
      id: json['id'] as String,
      vehicleId: json['vehicleId'] as String,
      serviceName: json['serviceName'] as String? ?? '',
      serviceShop: json['serviceShop'] as String? ?? '',
      date: json['date'] != null
          ? DateTime.tryParse(json['date'] as String) ?? DateTime.now()
          : DateTime.now(),
      mileage: (json['mileage'] as num?)?.toInt() ?? 0,
      nextServiceMileage: (json['nextServiceMileage'] as num?)?.toInt(),
      partsReplaced: (json['partsReplaced'] as List<dynamic>?)
              ?.map((e) => PartItem.fromJson(e))
              .toList() ??
          <PartItem>[],
      newPartsAdded: (json['newPartsAdded'] as List<dynamic>?)
              ?.map((e) => PartItem.fromJson(e))
              .toList() ??
          <PartItem>[],
      totalPrice: (json['totalPrice'] as num?)?.toDouble() ?? 0.0,
      notes: json['notes'] as String? ?? '',
      imagePaths: (json['imagePaths'] as List<dynamic>?)
              ?.map((e) => e.toString())
              .toList() ??
          <String>[],
      titleImageIndex: (json['titleImageIndex'] as num?)?.toInt() ?? 0,
      pdfPath: json['pdfPath'] as String?,
      createdAt: json['createdAt'] != null
          ? DateTime.tryParse(json['createdAt'] as String) ?? DateTime.now()
          : DateTime.now(),
    );
  }
}
