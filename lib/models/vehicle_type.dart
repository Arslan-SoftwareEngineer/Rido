enum VehicleType {
  car,
  bike;

  String get displayName {
    switch (this) {
      case VehicleType.car:
        return 'Car';
      case VehicleType.bike:
        return 'Bike';
    }
  }

  String get pluralName {
    switch (this) {
      case VehicleType.car:
        return 'Cars';
      case VehicleType.bike:
        return 'Bikes';
    }
  }
}
