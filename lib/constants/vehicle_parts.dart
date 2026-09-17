import '../models/vehicle_type.dart';

class VehicleParts {
  static const String none = 'None';

  // Common Car Parts Database
  static const List<String> carParts = [
    none,
    // Engine & Fluids
    'Engine Oil',
    'Oil Filter',
    'Engine Air Filter',
    'Cabin AC Filter',
    'Spark Plugs',
    'Engine Coolant',
    'Transmission Fluid (ATF/CVTF/MTF)',
    'Brake Fluid (DOT 3/4)',
    'Power Steering Fluid',
    'Screen Washing Fluid'
    'Fuel Filter',
    'Fuel Pump',
    'Timing Belt / Chain',
    'Serpentine Drive Belt',
    'Engine Thermostat',
    'Water Pump',
    'Radiator',
    'Radiator Cap',
    'Radiator Hoses',
    'PCV Valve',
    'Oxygen Sensor (O2)',
    'Mass Airflow Sensor (MAF)',
    
    // Brakes & Wheels
    'Front Brake Pads',
    'Rear Brake Pads',
    'Front Brake Rotors / Discs',
    'Rear Brake Rotors / Discs',
    'Brake Calipers',
    'Brake Shoes (Drum)',
    'Brake Drums',
    'Front Tires',
    'Rear Tires',
    'All 4 Tires',
    'Wheel Bearings',
    'Wheel Alignment & Balancing',
    'TPMS Sensor',

    // Suspension & Steering
    'Front Shock Absorbers / Struts',
    'Rear Shock Absorbers',
    'Strut Mounts',
    'Sway Bar Links',
    'Control Arm Bushings',
    'Lower Control Arms',
    'Ball Joints',
    'Tie Rod Ends (Inner/Outer)',
    'Steering Rack & Pinion',

    // Electrical, Ignition & Battery
    '12V Starter Battery',
    'Alternator',
    'Starter Motor',
    'Ignition Coils',
    'Headlight Bulbs (Low/High Beam)',
    'Fog Light Bulbs',
    'Taillight / Brake Bulbs',
    'Wiper Blades (Front & Rear)',
    'Horn',
    'Relays & Fuses',

    // Exhaust & Transmission
    'Exhaust Catalytic Converter',
    'Exhaust Muffler',
    'Clutch Plate & Pressure Plate',
    'Clutch Release Bearing',
    'CV Axle Shafts / Boots',
    'Engine & Transmission Mounts',

    // Interior & Body
    'Windshield',
    'Side Mirror Glass / Assembly',
    'Door Locks / Actuators',
    'Window Regulator',
    'Dashcam',
    'Seat Covers',
    'Floor Mats',
    'Sunshade Film / Tint',
    'Body Polishing & Ceramic Coating',
  ];

  // Common Bike Parts Database
  static const List<String> bikeParts = [
    none,
    // Engine, Fluids & Transmission
    '4T Engine Oil',
    'Oil Filter',
    'Air Filter',
    'Spark Plug',
    'Engine Coolant',
    'Clutch Plates',
    'Clutch Cable',
    'Throttle Cable',
    'Drive Chain',
    'Front Sprocket',
    'Rear Sprocket',
    'Chain & Sprocket Kit',
    'Drive Belt',
    'Fuel Filter',
    'Carburetor / Injector Cleaning',

    // Brakes & Wheels
    'Front Brake Pads',
    'Rear Brake Pads',
    'Brake Disc Rotor',
    'Brake Fluid Flush',
    'Brake Master Cylinder',
    'Brake Lever',
    'Clutch Lever',
    'Front Tire',
    'Rear Tire',
    'Inner Tube',
    'Wheel Bearings',
    'Wheel Truing & Spoke Tuning',

    // Suspension & Steering
    'Front Fork Oil & Seals',
    'Rear Monoshock Absorber',
    'Twin Rear Shocks',
    'Steering Cone Bearings',
    'Swingarm Bushings',

    // Electrical, Lighting & Battery
    '12V Motorcycle Battery',
    'Stator Coil',
    'Rectifier Regulator',
    'LED Headlight Bulb',
    'Turn Signal Indicators',
    'Tail Light Assembly',
    'Horn',

    // Bike Accessories & Body
    'Crash Guard / Engine Slider',
    'Radiator Guard',
    'Handlebar Grips',
    'Rear View Mirrors',
    'Exhaust Slip-on / System',
    'Mobile Phone Mount & Charger',
    'Top Box / Pannier Carrier',
    'Pillion Backrest',
    'Windshield / Visor',
    'Center / Side Stand Spring',
    'Brake Caliper Guard',
  ];

  static List<String> getPartsForType(VehicleType type) {
    switch (type) {
      case VehicleType.car:
        return carParts;
      case VehicleType.bike:
        return bikeParts;
    }
  }
}
