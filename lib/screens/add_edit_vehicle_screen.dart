import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:uuid/uuid.dart';
import '../models/vehicle.dart';
import '../models/vehicle_type.dart';
import '../constants/app_colors.dart';
import '../services/storage_service.dart';

class AddEditVehicleScreen extends StatefulWidget {
  final StorageService storageService;
  final Vehicle? vehicleToEdit;
  final VehicleType initialType;

  const AddEditVehicleScreen({
    super.key,
    required this.storageService,
    this.vehicleToEdit,
    this.initialType = VehicleType.car,
  });

  @override
  State<AddEditVehicleScreen> createState() => _AddEditVehicleScreenState();
}

class _AddEditVehicleScreenState extends State<AddEditVehicleScreen> {
  final _formKey = GlobalKey<FormState>();

  late VehicleType _selectedType;
  late final TextEditingController _nameController;
  late final TextEditingController _modelController;
  late final TextEditingController _variantController;
  late final TextEditingController _mileageController;
  late final TextEditingController _fuelAverageController;
  late final TextEditingController _engineCapacityController;
  late String _transmissionType;
  String? _selectedImagePath;
  bool _isSaving = false;

  final List<String> _transmissionOptions = [
    'Automatic',
    'Manual',
    'CVT',
    'Dual Clutch (DCT)',
    'Semi-Automatic',
    'Direct Drive (EV)',
  ];

  @override
  void initState() {
    super.initState();
    final v = widget.vehicleToEdit;
    _selectedType = v?.type ?? widget.initialType;
    _nameController = TextEditingController(text: v?.name ?? '');
    _modelController = TextEditingController(text: v?.model ?? '');
    _variantController = TextEditingController(text: v?.variant ?? '');
    _mileageController = TextEditingController(text: v != null ? v.mileage.toString() : '');
    _fuelAverageController = TextEditingController(text: v != null && v.fuelAverage > 0 ? v.fuelAverage.toString() : '');
    _engineCapacityController = TextEditingController(text: v?.engineCapacity ?? '');
    _transmissionType = v != null && _transmissionOptions.contains(v.transmissionType)
        ? v.transmissionType
        : (_selectedType == VehicleType.bike ? 'Manual' : 'Automatic');
    _selectedImagePath = v?.imagePath;
  }

  @override
  void dispose() {
    _nameController.dispose();
    _modelController.dispose();
    _variantController.dispose();
    _mileageController.dispose();
    _fuelAverageController.dispose();
    _engineCapacityController.dispose();
    super.dispose();
  }

  Future<void> _pickImage(ImageSource source) async {
    try {
      final picker = ImagePicker();
      final picked = await picker.pickImage(source: source, imageQuality: 85);
      if (picked != null) {
        final permanentPath = await widget.storageService.copyImageToPermanentStorage(picked.path);
        setState(() {
          _selectedImagePath = permanentPath;
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Could not pick image: $e')),
        );
      }
    }
  }

  void _showImageSourceDialog() {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return SafeArea(
          child: Wrap(
            children: [
              ListTile(
                leading: const Icon(Icons.photo_library_rounded),
                title: const Text('Choose from Gallery'),
                onTap: () {
                  Navigator.pop(context);
                  _pickImage(ImageSource.gallery);
                },
              ),
              ListTile(
                leading: const Icon(Icons.camera_alt_rounded),
                title: const Text('Take a Photo'),
                onTap: () {
                  Navigator.pop(context);
                  _pickImage(ImageSource.camera);
                },
              ),
              if (_selectedImagePath != null)
                ListTile(
                  leading: const Icon(Icons.delete_outline_rounded, color: Colors.red),
                  title: const Text('Remove Photo', style: TextStyle(color: Colors.red)),
                  onTap: () {
                    Navigator.pop(context);
                    setState(() {
                      _selectedImagePath = null;
                    });
                  },
                ),
            ],
          ),
        );
      },
    );
  }

  Future<void> _saveVehicle() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isSaving = true);

    try {
      final isEdit = widget.vehicleToEdit != null;
      final mileageVal = int.tryParse(_mileageController.text.replaceAll(',', '').trim()) ?? 0;
      final fuelVal = double.tryParse(_fuelAverageController.text.trim()) ?? 0.0;

      final vehicle = Vehicle(
        id: isEdit ? widget.vehicleToEdit!.id : const Uuid().v4(),
        type: _selectedType,
        name: _nameController.text.trim(),
        model: _modelController.text.trim(),
        variant: _variantController.text.trim(),
        mileage: mileageVal,
        fuelAverage: fuelVal,
        engineCapacity: _engineCapacityController.text.trim(),
        transmissionType: _transmissionType,
        imagePath: _selectedImagePath,
        createdAt: isEdit ? widget.vehicleToEdit!.createdAt : DateTime.now(),
        lastServiceDate: widget.vehicleToEdit?.lastServiceDate,
      );

      if (isEdit) {
        await widget.storageService.updateVehicle(vehicle);
      } else {
        await widget.storageService.addVehicle(vehicle);
      }

      if (mounted) {
        Navigator.of(context).pop(vehicle);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error saving vehicle: $e')),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isSaving = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final isEdit = widget.vehicleToEdit != null;

    return Scaffold(
      backgroundColor: isDark ? AppColors.darkBackground : AppColors.lightBackground,
      appBar: AppBar(
        title: Text(isEdit ? 'Edit ${_selectedType.displayName}' : 'Add New ${_selectedType.displayName}'),
        actions: [
          // Green save tick button on top right
          Padding(
            padding: const EdgeInsets.only(right: 12),
            child: _isSaving
                ? const Center(child: SizedBox(width: 24, height: 24, child: CircularProgressIndicator(strokeWidth: 2)))
                : IconButton.filled(
                    onPressed: _saveVehicle,
                    icon: const Icon(Icons.check_rounded, color: Colors.white),
                    style: IconButton.styleFrom(
                      backgroundColor: AppColors.greenSaveButton,
                      padding: const EdgeInsets.all(8),
                    ),
                    tooltip: 'Save ${_selectedType.displayName}',
                  ),
          ),
        ],
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(20),
          physics: const BouncingScrollPhysics(),
          children: [
            // Vehicle Type Segmented Selector
            if (!isEdit) ...[
              Container(
                padding: const EdgeInsets.all(4),
                decoration: BoxDecoration(
                  color: isDark ? AppColors.darkCard : AppColors.lightCardElevated,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: isDark ? AppColors.darkBorder : AppColors.lightBorder),
                ),
                child: Row(
                  children: VehicleType.values.map((type) {
                    final isSelected = _selectedType == type;
                    return Expanded(
                      child: GestureDetector(
                        onTap: () {
                          setState(() {
                            _selectedType = type;
                            if (type == VehicleType.bike && _transmissionType == 'Automatic') {
                              _transmissionType = 'Manual';
                            }
                          });
                        },
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 200),
                          padding: const EdgeInsets.symmetric(vertical: 10),
                          decoration: BoxDecoration(
                            color: isSelected
                                ? (type == VehicleType.car ? AppColors.carAccent : AppColors.bikeAccent)
                                : Colors.transparent,
                            borderRadius: BorderRadius.circular(10),
                          ),
                          alignment: Alignment.center,
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                type == VehicleType.car ? Icons.directions_car_rounded : Icons.two_wheeler_rounded,
                                size: 18,
                                color: isSelected
                                    ? Colors.white
                                    : (isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary),
                              ),
                              const SizedBox(width: 8),
                              Text(
                                type.pluralName,
                                style: TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.bold,
                                  color: isSelected
                                      ? Colors.white
                                      : (isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    );
                  }).toList(),
                ),
              ),
              const SizedBox(height: 20),
            ],

            // Photo Uploader Card
            Center(
              child: GestureDetector(
                onTap: _showImageSourceDialog,
                child: Container(
                  width: double.infinity,
                  height: 180,
                  decoration: BoxDecoration(
                    color: isDark ? AppColors.darkCard : AppColors.lightCard,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: isDark ? AppColors.darkBorder : AppColors.lightBorder,
                      style: _selectedImagePath == null ? BorderStyle.solid : BorderStyle.none,
                      width: 1.5,
                    ),
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(20),
                    child: _selectedImagePath != null && File(_selectedImagePath!).existsSync()
                        ? Stack(
                            fit: StackFit.expand,
                            children: [
                              Image.file(
                                File(_selectedImagePath!),
                                fit: BoxFit.cover,
                              ),
                              Positioned(
                                bottom: 10,
                                right: 10,
                                child: Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                                  decoration: BoxDecoration(
                                    color: Colors.black.withValues(alpha: 0.7),
                                    borderRadius: BorderRadius.circular(20),
                                  ),
                                  child: const Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Icon(Icons.camera_alt_rounded, size: 14, color: Colors.white),
                                      SizedBox(width: 6),
                                      Text(
                                        'Change Photo',
                                        style: TextStyle(color: Colors.white, fontSize: 12),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ],
                          )
                        : Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Container(
                                width: 56,
                                height: 56,
                                decoration: BoxDecoration(
                                  color: AppColors.primary.withValues(alpha: 0.12),
                                  shape: BoxShape.circle,
                                ),
                                child: const Icon(
                                  Icons.add_a_photo_rounded,
                                  color: AppColors.primary,
                                  size: 28,
                                ),
                              ),
                              const SizedBox(height: 12),
                              Text(
                                'Upload ${_selectedType.displayName} Photo',
                                style: TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w600,
                                  color: isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                'Tap to take a photo or select from gallery',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: isDark ? AppColors.darkTextTertiary : AppColors.lightTextTertiary,
                                ),
                              ),
                            ],
                          ),
                  ),
                ),
              ),
            ),

            const SizedBox(height: 24),

            // Vehicle Name
            _buildFieldLabel('Vehicle Name *'),
            TextFormField(
              controller: _nameController,
              decoration: InputDecoration(
                hintText: _selectedType == VehicleType.car ? 'e.g. Honda Civic' : 'e.g. Yamaha MT-07',
                prefixIcon: const Icon(Icons.badge_rounded),
              ),
              validator: (v) => v == null || v.trim().isEmpty ? 'Please enter vehicle name' : null,
            ),

            const SizedBox(height: 16),

            // Model & Variant
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildFieldLabel('Model'),
                      TextFormField(
                        controller: _modelController,
                        decoration: const InputDecoration(
                          hintText: 'e.g. Civic / MT-07',
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildFieldLabel('Variant / Trim'),
                      TextFormField(
                        controller: _variantController,
                        decoration: const InputDecoration(
                          hintText: 'e.g. 1.5 Turbo / ABS',
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),

            const SizedBox(height: 16),

            // Current Mileage & Fuel Average
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildFieldLabel('Current Mileage (km) *'),
                      TextFormField(
                        controller: _mileageController,
                        keyboardType: TextInputType.number,
                        decoration: const InputDecoration(
                          hintText: 'e.g. 45000',
                          prefixIcon: Icon(Icons.speed_rounded),
                        ),
                        validator: (v) {
                          if (v == null || v.trim().isEmpty) return 'Enter mileage';
                          if (int.tryParse(v.trim()) == null) return 'Valid number';
                          return null;
                        },
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildFieldLabel('Fuel Avg (km/L)'),
                      TextFormField(
                        controller: _fuelAverageController,
                        keyboardType: const TextInputType.numberWithOptions(decimal: true),
                        decoration: const InputDecoration(
                          hintText: 'e.g. 14.5',
                          prefixIcon: Icon(Icons.local_gas_station_rounded),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),

            const SizedBox(height: 16),

            // Engine Capacity & Transmission Type
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildFieldLabel('Engine Capacity'),
                      TextFormField(
                        controller: _engineCapacityController,
                        decoration: InputDecoration(
                          hintText: _selectedType == VehicleType.car ? 'e.g. 1500 cc' : 'e.g. 689 cc',
                          prefixIcon: const Icon(Icons.settings_rounded),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildFieldLabel('Transmission'),
                      DropdownButtonFormField<String>(
                        initialValue: _transmissionType,
                        items: _transmissionOptions.map((opt) {
                          return DropdownMenuItem(
                            value: opt,
                            child: Text(opt, style: const TextStyle(fontSize: 13)),
                          );
                        }).toList(),
                        onChanged: (val) {
                          if (val != null) {
                            setState(() => _transmissionType = val);
                          }
                        },
                        decoration: const InputDecoration(
                          contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 14),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),

            const SizedBox(height: 32),

            // Action Save Button
            ElevatedButton(
              onPressed: _isSaving ? null : _saveVehicle,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.greenSaveButton,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                elevation: 2,
              ),
              child: _isSaving
                  ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                  : Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.check_circle_rounded, size: 20),
                        const SizedBox(width: 8),
                        Text(
                          isEdit ? 'Update ${_selectedType.displayName}' : 'Save ${_selectedType.displayName}',
                          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                        ),
                      ],
                    ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFieldLabel(String label) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 13,
          fontWeight: FontWeight.w600,
          color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary,
        ),
      ),
    );
  }
}
