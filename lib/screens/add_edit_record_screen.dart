import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';
import 'package:uuid/uuid.dart';
import '../models/vehicle.dart';
import '../models/service_record.dart';
import '../constants/app_colors.dart';
import '../constants/vehicle_parts.dart';
import '../services/storage_service.dart';
import '../widgets/searchable_parts_dialog.dart';

class AddEditRecordScreen extends StatefulWidget {
  final Vehicle vehicle;
  final StorageService storageService;
  final ServiceRecord? recordToEdit;

  const AddEditRecordScreen({
    super.key,
    required this.vehicle,
    required this.storageService,
    this.recordToEdit,
  });

  @override
  State<AddEditRecordScreen> createState() => _AddEditRecordScreenState();
}

class _AddEditRecordScreenState extends State<AddEditRecordScreen> {
  final _formKey = GlobalKey<FormState>();

  late final TextEditingController _serviceNameController;
  late final TextEditingController _serviceShopController;
  late final TextEditingController _mileageController;
  late final TextEditingController _nextServiceMileageController;
  late final TextEditingController _totalPriceController;
  late final TextEditingController _notesController;

  late DateTime _selectedDate;
  late List<PartItem> _partsReplaced;
  late List<PartItem> _newPartsAdded;
  late List<String> _imagePaths;
  int _titleImageIndex = 0;
  bool _isSaving = false;

  final Map<String, TextEditingController> _replacedPriceControllers = {};
  final Map<String, TextEditingController> _addedPriceControllers = {};
  final Map<String, TextEditingController> _replacedCompanyControllers = {};
  final Map<String, TextEditingController> _addedCompanyControllers = {};

  final List<String> _commonServiceSuggestions = [
    'Oil & Filter Change',
    'Periodic Maintenance',
    'Brake System Service',
    'Tire Rotation & Balance',
    'General Inspection',
    'Chain Service & Lube',
    'Battery Replacement',
    'Spark Plug Replacement',
  ];

  @override
  void initState() {
    super.initState();
    final r = widget.recordToEdit;
    _serviceNameController = TextEditingController(text: r?.serviceName ?? '');
    _serviceShopController = TextEditingController(text: r?.serviceShop ?? '');
    // Do NOT pre-fill vehicle profile mileage when adding new record
    _mileageController = TextEditingController(
      text: r != null ? r.mileage.toString() : '',
    );
    _nextServiceMileageController = TextEditingController(
      text: r?.nextServiceMileage != null && r!.nextServiceMileage! > 0 ? r.nextServiceMileage.toString() : '',
    );
    _totalPriceController = TextEditingController(
      text: r != null && r.totalPrice > 0 ? r.totalPrice.toStringAsFixed(2) : '',
    );
    _notesController = TextEditingController(text: r?.notes ?? '');
    _selectedDate = r?.date ?? DateTime.now();

    if (r != null && r.partsReplaced.isNotEmpty) {
      _partsReplaced = List<PartItem>.from(r.partsReplaced);
    } else {
      _partsReplaced = [const PartItem(name: VehicleParts.none, price: 0)];
    }

    if (r != null && r.newPartsAdded.isNotEmpty) {
      _newPartsAdded = List<PartItem>.from(r.newPartsAdded);
    } else {
      _newPartsAdded = [const PartItem(name: VehicleParts.none, price: 0)];
    }

    for (final p in _partsReplaced) {
      _replacedPriceControllers[p.name] = TextEditingController(
        text: p.price > 0 ? p.price.toStringAsFixed(2) : '',
      );
      _replacedCompanyControllers[p.name] = TextEditingController(
        text: p.company,
      );
    }
    for (final p in _newPartsAdded) {
      _addedPriceControllers[p.name] = TextEditingController(
        text: p.price > 0 ? p.price.toStringAsFixed(2) : '',
      );
      _addedCompanyControllers[p.name] = TextEditingController(
        text: p.company,
      );
    }

    _imagePaths = r != null ? List<String>.from(r.imagePaths) : [];
    _titleImageIndex = r?.titleImageIndex ?? 0;
  }

  @override
  void dispose() {
    _serviceNameController.dispose();
    _serviceShopController.dispose();
    _mileageController.dispose();
    _nextServiceMileageController.dispose();
    _totalPriceController.dispose();
    _notesController.dispose();
    for (final c in _replacedPriceControllers.values) {
      c.dispose();
    }
    for (final c in _addedPriceControllers.values) {
      c.dispose();
    }
    for (final c in _replacedCompanyControllers.values) {
      c.dispose();
    }
    for (final c in _addedCompanyControllers.values) {
      c.dispose();
    }
    super.dispose();
  }

  void _calculateTotalFromParts() {
    double sum = 0.0;
    for (final p in _partsReplaced) {
      final val = double.tryParse(_replacedPriceControllers[p.name]?.text.trim() ?? '') ?? p.price;
      sum += val;
    }
    for (final p in _newPartsAdded) {
      final val = double.tryParse(_addedPriceControllers[p.name]?.text.trim() ?? '') ?? p.price;
      sum += val;
    }
    setState(() {
      _totalPriceController.text = sum > 0 ? sum.toStringAsFixed(2) : '0.00';
    });
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(2000),
      lastDate: DateTime.now().add(const Duration(days: 365)),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: ColorScheme.light(
              primary: AppColors.primary,
              onPrimary: Colors.white,
              surface: Theme.of(context).colorScheme.surface,
              onSurface: Theme.of(context).colorScheme.onSurface,
            ),
          ),
          child: child!,
        );
      },
    );
    if (picked != null) {
      setState(() => _selectedDate = picked);
    }
  }

  Future<void> _pickImages(ImageSource source) async {
    try {
      final picker = ImagePicker();
      if (source == ImageSource.camera) {
        final photo = await picker.pickImage(source: ImageSource.camera, imageQuality: 85);
        if (photo != null) {
          final permPath = await widget.storageService.copyImageToPermanentStorage(photo.path);
          setState(() {
            _imagePaths.add(permPath);
          });
        }
      } else {
        final photos = await picker.pickMultiImage(imageQuality: 85);
        if (photos.isNotEmpty) {
          for (final p in photos) {
            final permPath = await widget.storageService.copyImageToPermanentStorage(p.path);
            _imagePaths.add(permPath);
          }
          setState(() {});
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Could not pick image: $e')),
        );
      }
    }
  }

  void _showImagePickerSource() {
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
                title: const Text('Select from Gallery'),
                onTap: () {
                  Navigator.pop(context);
                  _pickImages(ImageSource.gallery);
                },
              ),
              ListTile(
                leading: const Icon(Icons.camera_alt_rounded),
                title: const Text('Capture with Camera'),
                onTap: () {
                  Navigator.pop(context);
                  _pickImages(ImageSource.camera);
                },
              ),
            ],
          ),
        );
      },
    );
  }

  Future<void> _selectPartsReplaced() async {
    final currentNames = _partsReplaced.map((p) => p.name).toList();
    final result = await SearchablePartsDialog.show(
      context: context,
      title: 'Select Parts Replaced',
      initialSelected: currentNames,
      vehicleType: widget.vehicle.type,
      isReplacement: true,
    );
    if (result != null && mounted) {
      setState(() {
        final updated = <PartItem>[];
        if (result.isEmpty || (result.length == 1 && result.first == VehicleParts.none)) {
          updated.add(const PartItem(name: VehicleParts.none, price: 0.0));
        } else {
          for (final name in result) {
            if (name == VehicleParts.none) continue;
            final existing = _partsReplaced.firstWhere(
              (p) => p.name == name,
              orElse: () => PartItem(name: name, price: 0.0),
            );
            updated.add(existing);
            if (!_replacedPriceControllers.containsKey(name)) {
              _replacedPriceControllers[name] = TextEditingController(
                text: existing.price > 0 ? existing.price.toStringAsFixed(2) : '',
              );
            }
            if (!_replacedCompanyControllers.containsKey(name)) {
              _replacedCompanyControllers[name] = TextEditingController(
                text: existing.company,
              );
            }
          }
        }
        _partsReplaced = updated;
      });
    }
  }

  Future<void> _selectNewPartsAdded() async {
    final currentNames = _newPartsAdded.map((p) => p.name).toList();
    final result = await SearchablePartsDialog.show(
      context: context,
      title: 'Select New Parts Added',
      initialSelected: currentNames,
      vehicleType: widget.vehicle.type,
      isReplacement: false,
    );
    if (result != null && mounted) {
      setState(() {
        final updated = <PartItem>[];
        if (result.isEmpty || (result.length == 1 && result.first == VehicleParts.none)) {
          updated.add(const PartItem(name: VehicleParts.none, price: 0.0));
        } else {
          for (final name in result) {
            if (name == VehicleParts.none) continue;
            final existing = _newPartsAdded.firstWhere(
              (p) => p.name == name,
              orElse: () => PartItem(name: name, price: 0.0),
            );
            updated.add(existing);
            if (!_addedPriceControllers.containsKey(name)) {
              _addedPriceControllers[name] = TextEditingController(
                text: existing.price > 0 ? existing.price.toStringAsFixed(2) : '',
              );
            }
            if (!_addedCompanyControllers.containsKey(name)) {
              _addedCompanyControllers[name] = TextEditingController(
                text: existing.company,
              );
            }
          }
        }
        _newPartsAdded = updated;
      });
    }
  }

  Future<void> _saveRecord() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isSaving = true);

    try {
      final isEdit = widget.recordToEdit != null;
      final mileageVal = int.tryParse(_mileageController.text.replaceAll(',', '').trim()) ?? widget.vehicle.mileage;
      final nextServiceMileageVal = int.tryParse(_nextServiceMileageController.text.replaceAll(',', '').trim());
      final totalPriceVal = double.tryParse(_totalPriceController.text.replaceAll(',', '').trim()) ?? 0.0;

      // Update part prices and company/brand details from text controllers
      final finalPartsReplaced = _partsReplaced.map((p) {
        if (p.name == VehicleParts.none) return p;
        final entered = double.tryParse(_replacedPriceControllers[p.name]?.text.trim() ?? '') ?? p.price;
        final company = _replacedCompanyControllers[p.name]?.text.trim() ?? p.company;
        return p.copyWith(price: entered, company: company);
      }).toList();

      final finalNewPartsAdded = _newPartsAdded.map((p) {
        if (p.name == VehicleParts.none) return p;
        final entered = double.tryParse(_addedPriceControllers[p.name]?.text.trim() ?? '') ?? p.price;
        final company = _addedCompanyControllers[p.name]?.text.trim() ?? p.company;
        return p.copyWith(price: entered, company: company);
      }).toList();

      final record = ServiceRecord(
        id: isEdit ? widget.recordToEdit!.id : const Uuid().v4(),
        vehicleId: widget.vehicle.id,
        serviceName: _serviceNameController.text.trim(),
        serviceShop: _serviceShopController.text.trim(),
        date: _selectedDate,
        mileage: mileageVal,
        nextServiceMileage: nextServiceMileageVal,
        partsReplaced: finalPartsReplaced,
        newPartsAdded: finalNewPartsAdded,
        totalPrice: totalPriceVal,
        notes: _notesController.text.trim(),
        imagePaths: _imagePaths,
        titleImageIndex: _titleImageIndex >= _imagePaths.length ? 0 : _titleImageIndex,
        pdfPath: widget.recordToEdit?.pdfPath,
        createdAt: isEdit ? widget.recordToEdit!.createdAt : DateTime.now(),
      );

      // Save and automatically generate the PDF report!
      final savedRecord = await widget.storageService.saveRecordWithPdf(
        record: record,
        vehicle: widget.vehicle,
        isUpdate: isEdit,
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: const [
                Icon(Icons.check_circle_rounded, color: Colors.white),
                SizedBox(width: 8),
                Text('Record saved & PDF generated!'),
              ],
            ),
            backgroundColor: AppColors.primaryDark,
            behavior: SnackBarBehavior.floating,
          ),
        );
        Navigator.of(context).pop(savedRecord);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error saving record: $e')),
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
    final isEdit = widget.recordToEdit != null;
    // Strict dd/MM/yyyy date format
    final dateFormat = DateFormat('dd/MM/yyyy');

    return Scaffold(
      backgroundColor: isDark ? AppColors.darkBackground : AppColors.lightBackground,
      appBar: AppBar(
        title: Text(isEdit ? 'Edit Service Record' : 'New Service Record'),
        actions: [
          // "save button that will be shown as a green button on the top right as a tick sign"
          Padding(
            padding: const EdgeInsets.only(right: 12),
            child: _isSaving
                ? const Center(
                    child: SizedBox(
                      width: 24,
                      height: 24,
                      child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.primary),
                    ),
                  )
                : Tooltip(
                    message: 'Save Record & Generate PDF',
                    child: InkWell(
                      onTap: _saveRecord,
                      borderRadius: BorderRadius.circular(24),
                      child: Container(
                        width: 44,
                        height: 44,
                        decoration: BoxDecoration(
                          color: AppColors.greenSaveButton,
                          shape: BoxShape.circle,
                          boxShadow: [
                            BoxShadow(
                              color: AppColors.greenSaveButton.withValues(alpha: 0.4),
                              blurRadius: 8,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        child: const Icon(
                          Icons.check_rounded,
                          color: Colors.white,
                          size: 26,
                        ),
                      ),
                    ),
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
            // Vehicle Banner Info
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              decoration: BoxDecoration(
                color: isDark ? AppColors.darkCard : AppColors.lightCard,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: isDark ? AppColors.darkBorder : AppColors.lightBorder),
              ),
              child: Row(
                children: [
                  Icon(
                    widget.vehicle.type.name == 'car' ? Icons.directions_car_rounded : Icons.two_wheeler_rounded,
                    color: AppColors.primary,
                    size: 20,
                  ),
                  const SizedBox(width: 10),
                  Text(
                    'Vehicle: ',
                    style: TextStyle(
                      fontSize: 13,
                      color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary,
                    ),
                  ),
                  Text(
                    widget.vehicle.name,
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      color: isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary,
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 18),

            // 1. Service Name
            _buildFieldLabel('Service Name *'),
            TextFormField(
              controller: _serviceNameController,
              decoration: const InputDecoration(
                hintText: 'e.g. Periodic Maintenance Inspection',
                prefixIcon: Icon(Icons.build_rounded),
              ),
              validator: (v) => v == null || v.trim().isEmpty ? 'Please enter service name' : null,
            ),
            const SizedBox(height: 8),

            // Quick suggestion chips for service name
            SizedBox(
              height: 32,
              child: ListView(
                scrollDirection: Axis.horizontal,
                children: _commonServiceSuggestions.map((suggestion) {
                  return Container(
                    margin: const EdgeInsets.only(right: 8),
                    child: ActionChip(
                      label: Text(suggestion, style: const TextStyle(fontSize: 11)),
                      padding: EdgeInsets.zero,
                      backgroundColor: isDark ? AppColors.darkCardElevated : AppColors.lightCardElevated,
                      side: BorderSide.none,
                      onPressed: () {
                        setState(() {
                          _serviceNameController.text = suggestion;
                        });
                      },
                    ),
                  );
                }).toList(),
              ),
            ),

            const SizedBox(height: 18),

            // 2. Service Shop
            _buildFieldLabel('Service Shop / Garage Name'),
            TextFormField(
              controller: _serviceShopController,
              decoration: const InputDecoration(
                hintText: 'e.g. Authorized Dealership / Express Lube',
                prefixIcon: Icon(Icons.storefront_rounded),
              ),
            ),

            const SizedBox(height: 18),

            // 3. Date & 4. Mileage
            Row(
              children: [
                // Date picker field (dd/MM/yyyy)
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildFieldLabel('Service Date'),
                      InkWell(
                        onTap: _pickDate,
                        borderRadius: BorderRadius.circular(14),
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
                          decoration: BoxDecoration(
                            color: isDark ? AppColors.darkCardElevated : AppColors.lightCardElevated,
                            borderRadius: BorderRadius.circular(14),
                            border: Border.all(color: isDark ? AppColors.darkBorder : AppColors.lightBorder),
                          ),
                          child: Row(
                            children: [
                              const Icon(Icons.calendar_today_rounded, size: 18, color: AppColors.primary),
                              const SizedBox(width: 10),
                              Expanded(
                                child: Text(
                                  dateFormat.format(_selectedDate),
                                  style: TextStyle(
                                    fontSize: 13,
                                    fontWeight: FontWeight.w600,
                                    color: isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary,
                                  ),
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 14),
                // Mileage field
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildFieldLabel('Service Mileage'),
                      TextFormField(
                        controller: _mileageController,
                        keyboardType: TextInputType.number,
                        decoration: const InputDecoration(
                          hintText: 'e.g. 42500',
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
              ],
            ),

            const SizedBox(height: 16),

            // Next Service Odometer Reading Field
            _buildFieldLabel('Next Service Odometer Reading / Measure (Optional)'),
            TextFormField(
              controller: _nextServiceMileageController,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                hintText: 'e.g. 50000 (km / mi)',
                prefixIcon: Icon(Icons.update_rounded, color: AppColors.primary),
              ),
              validator: (v) {
                if (v != null && v.trim().isNotEmpty && int.tryParse(v.replaceAll(',', '').trim()) == null) {
                  return 'Enter a valid odometer number';
                }
                return null;
              },
            ),

            const SizedBox(height: 18),

            // Total Price Field with Quick Auto-Sum
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                _buildFieldLabel('Total Price / Amount Spent'),
                TextButton.icon(
                  onPressed: _calculateTotalFromParts,
                  icon: const Icon(Icons.auto_awesome_rounded, size: 14),
                  label: const Text('Sum from parts', style: TextStyle(fontSize: 12)),
                  style: TextButton.styleFrom(foregroundColor: AppColors.primary),
                ),
              ],
            ),
            TextFormField(
              controller: _totalPriceController,
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              decoration: InputDecoration(
                hintText: '4500.00',
                prefixIcon: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const SizedBox(width: 12),
                    const Icon(Icons.payments_rounded, color: AppColors.primary, size: 20),
                    const SizedBox(width: 8),
                    Text(
                      'Rs. ',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary,
                      ),
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 22),

            // 5. Parts Replaced & Price per Part
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: _buildFieldLabel('Parts Replaced & Individual Prices'),
                ),
                TextButton.icon(
                  onPressed: _selectPartsReplaced,
                  icon: const Icon(Icons.search_rounded, size: 16),
                  label: const Text('Search & Select', style: TextStyle(fontSize: 12)),
                  style: TextButton.styleFrom(foregroundColor: AppColors.primary),
                ),
              ],
            ),
            if (_partsReplaced.isEmpty || (_partsReplaced.length == 1 && _partsReplaced.first.name == VehicleParts.none))
              InkWell(
                onTap: _selectPartsReplaced,
                borderRadius: BorderRadius.circular(14),
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: isDark ? AppColors.darkCardElevated : AppColors.lightCardElevated,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: isDark ? AppColors.darkBorder : AppColors.lightBorder),
                  ),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: Colors.grey.withValues(alpha: 0.2),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: const Text('None', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
                      ),
                      const SizedBox(width: 10),
                      Text(
                        'Tap to search & add',
                        style: TextStyle(fontSize: 12, color: isDark ? AppColors.darkTextTertiary : AppColors.lightTextTertiary),
                      ),
                    ],
                  ),
                ),
              )
            else
              Column(
                children: _partsReplaced.map((part) {
                  return Container(
                    margin: const EdgeInsets.only(bottom: 10),
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: isDark ? AppColors.darkCard : AppColors.lightCard,
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: Colors.red.withValues(alpha: 0.3)),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            const Icon(Icons.build_rounded, size: 16, color: Colors.red),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                part.name,
                                style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13),
                              ),
                            ),
                            SizedBox(
                              width: 125,
                              height: 38,
                              child: TextField(
                                controller: _replacedPriceControllers[part.name],
                                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                                decoration: InputDecoration(
                                  hintText: 'Price',
                                  prefixIconConstraints: const BoxConstraints(minWidth: 0, minHeight: 0),
                                  prefixIcon: Padding(
                                    padding: const EdgeInsets.only(left: 8, right: 3),
                                    child: Text(
                                      'Rs. ',
                                      style: TextStyle(
                                        fontSize: 11.5,
                                        fontWeight: FontWeight.w600,
                                        color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary,
                                      ),
                                    ),
                                  ),
                                  isDense: true,
                                  contentPadding: const EdgeInsets.symmetric(horizontal: 6, vertical: 8),
                                  fillColor: isDark ? AppColors.darkCardElevated : AppColors.lightCardElevated,
                                ),
                              ),
                            ),
                            const SizedBox(width: 4),
                            IconButton(
                              icon: const Icon(Icons.close_rounded, size: 18, color: Colors.red),
                              tooltip: 'Remove part',
                              onPressed: () {
                                setState(() {
                                  _partsReplaced.remove(part);
                                  if (_partsReplaced.isEmpty) {
                                    _partsReplaced.add(const PartItem(name: VehicleParts.none, price: 0));
                                  }
                                });
                              },
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        TextField(
                          controller: _replacedCompanyControllers[part.name],
                          decoration: InputDecoration(
                            hintText: 'Company / Brand / Specs (e.g. Bosch, Mobil 1, 5W-30)',
                            prefixIcon: const Icon(Icons.business_rounded, size: 16, color: AppColors.primary),
                            isDense: true,
                            contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                            fillColor: isDark ? AppColors.darkCardElevated : AppColors.lightCardElevated,
                          ),
                        ),
                      ],
                    ),
                  );
                }).toList(),
              ),

            const SizedBox(height: 20),

            // 6. New Parts Added & Price per Part
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: _buildFieldLabel('New Parts / Upgrades Added & Prices'),
                ),
                TextButton.icon(
                  onPressed: _selectNewPartsAdded,
                  icon: const Icon(Icons.search_rounded, size: 16),
                  label: const Text('Search & Select', style: TextStyle(fontSize: 12)),
                  style: TextButton.styleFrom(foregroundColor: AppColors.primary),
                ),
              ],
            ),
            if (_newPartsAdded.isEmpty || (_newPartsAdded.length == 1 && _newPartsAdded.first.name == VehicleParts.none))
              InkWell(
                onTap: _selectNewPartsAdded,
                borderRadius: BorderRadius.circular(14),
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: isDark ? AppColors.darkCardElevated : AppColors.lightCardElevated,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: isDark ? AppColors.darkBorder : AppColors.lightBorder),
                  ),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: Colors.grey.withValues(alpha: 0.2),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: const Text('None', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
                      ),
                      const SizedBox(width: 10),
                      Text(
                        'No new parts added (Tap to search & add)',
                        style: TextStyle(fontSize: 12, color: isDark ? AppColors.darkTextTertiary : AppColors.lightTextTertiary),
                      ),
                    ],
                  ),
                ),
              )
            else
              Column(
                children: _newPartsAdded.map((part) {
                  return Container(
                    margin: const EdgeInsets.only(bottom: 10),
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: isDark ? AppColors.darkCard : AppColors.lightCard,
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: Colors.indigo.withValues(alpha: 0.3)),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            const Icon(Icons.add_circle_outline_rounded, size: 16, color: Colors.indigo),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                part.name,
                                style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13),
                              ),
                            ),
                            SizedBox(
                              width: 125,
                              height: 38,
                              child: TextField(
                                controller: _addedPriceControllers[part.name],
                                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                                decoration: InputDecoration(
                                  hintText: 'Price',
                                  prefixIconConstraints: const BoxConstraints(minWidth: 0, minHeight: 0),
                                  prefixIcon: Padding(
                                    padding: const EdgeInsets.only(left: 8, right: 3),
                                    child: Text(
                                      'Rs. ',
                                      style: TextStyle(
                                        fontSize: 11.5,
                                        fontWeight: FontWeight.w600,
                                        color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary,
                                      ),
                                    ),
                                  ),
                                  isDense: true,
                                  contentPadding: const EdgeInsets.symmetric(horizontal: 6, vertical: 8),
                                  fillColor: isDark ? AppColors.darkCardElevated : AppColors.lightCardElevated,
                                ),
                              ),
                            ),
                            const SizedBox(width: 4),
                            IconButton(
                              icon: const Icon(Icons.close_rounded, size: 18, color: Colors.indigo),
                              tooltip: 'Remove part',
                              onPressed: () {
                                setState(() {
                                  _newPartsAdded.remove(part);
                                  if (_newPartsAdded.isEmpty) {
                                    _newPartsAdded.add(const PartItem(name: VehicleParts.none, price: 0));
                                  }
                                });
                              },
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        TextField(
                          controller: _addedCompanyControllers[part.name],
                          decoration: InputDecoration(
                            hintText: 'Company / Brand / Specs (e.g. Denso, NGK, OEM)',
                            prefixIcon: const Icon(Icons.business_rounded, size: 16, color: AppColors.primary),
                            isDense: true,
                            contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                            fillColor: isDark ? AppColors.darkCardElevated : AppColors.lightCardElevated,
                          ),
                        ),
                      ],
                    ),
                  );
                }).toList(),
              ),

            const SizedBox(height: 20),

            // 7. Notes
            _buildFieldLabel('Maintenance Notes & Remarks'),
            TextFormField(
              controller: _notesController,
              maxLines: 3,
              decoration: const InputDecoration(
                hintText: 'Enter any technician comments, next service recommendations, fluid grades, etc.',
                alignLabelWithHint: true,
              ),
            ),

            const SizedBox(height: 22),

            // 8. Images Section
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildFieldLabel('Maintenance Photos (${_imagePaths.length})'),
                    Text(
                      'Tap an image to set it as Title Image',
                      style: TextStyle(fontSize: 11, color: isDark ? AppColors.darkTextTertiary : AppColors.lightTextTertiary),
                    ),
                  ],
                ),
                IconButton.filledTonal(
                  onPressed: _showImagePickerSource,
                  icon: const Icon(Icons.add_a_photo_rounded, size: 20),
                  tooltip: 'Add Photo',
                ),
              ],
            ),
            const SizedBox(height: 8),

            if (_imagePaths.isEmpty)
              InkWell(
                onTap: _showImagePickerSource,
                borderRadius: BorderRadius.circular(14),
                child: Container(
                  height: 100,
                  decoration: BoxDecoration(
                    color: isDark ? AppColors.darkCard : AppColors.lightCardElevated,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(
                      color: isDark ? AppColors.darkBorder : AppColors.lightBorder,
                    ),
                  ),
                  child: Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.add_photo_alternate_outlined, size: 28, color: AppColors.primary),
                        const SizedBox(height: 6),
                        Text(
                          'Upload receipts, parts, or odometer photos',
                          style: TextStyle(fontSize: 12, color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary),
                        ),
                      ],
                    ),
                  ),
                ),
              )
            else
              SizedBox(
                height: 120,
                child: ListView.builder(
                  scrollDirection: Axis.horizontal,
                  itemCount: _imagePaths.length + 1,
                  itemBuilder: (context, index) {
                    if (index == _imagePaths.length) {
                      return Center(
                        child: Container(
                          width: 80,
                          height: 110,
                          margin: const EdgeInsets.only(left: 8),
                          child: OutlinedButton(
                            onPressed: _showImagePickerSource,
                            style: OutlinedButton.styleFrom(
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                              padding: EdgeInsets.zero,
                            ),
                            child: const Icon(Icons.add_rounded, size: 28),
                          ),
                        ),
                      );
                    }

                    final path = _imagePaths[index];
                    final isTitle = _titleImageIndex == index;

                    return Container(
                      width: 110,
                      height: 110,
                      margin: const EdgeInsets.only(right: 10),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(
                          color: isTitle ? AppColors.primary : (isDark ? AppColors.darkBorder : AppColors.lightBorder),
                          width: isTitle ? 2.5 : 1,
                        ),
                      ),
                      child: Stack(
                        children: [
                          Positioned.fill(
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(12),
                              child: InkWell(
                                onTap: () {
                                  setState(() => _titleImageIndex = index);
                                },
                                child: Image.file(
                                  File(path),
                                  fit: BoxFit.cover,
                                ),
                              ),
                            ),
                          ),
                          if (isTitle)
                            Positioned(
                              top: 6,
                              left: 6,
                              child: Container(
                                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                decoration: BoxDecoration(
                                  color: AppColors.primary,
                                  borderRadius: BorderRadius.circular(6),
                                ),
                                child: const Text(
                                  'TITLE',
                                  style: TextStyle(color: Colors.white, fontSize: 9, fontWeight: FontWeight.bold),
                                ),
                              ),
                            ),
                          Positioned(
                            top: 4,
                            right: 4,
                            child: InkWell(
                              onTap: () {
                                setState(() {
                                  _imagePaths.removeAt(index);
                                  if (_titleImageIndex >= _imagePaths.length) {
                                    _titleImageIndex = 0;
                                  }
                                });
                              },
                              child: Container(
                                padding: const EdgeInsets.all(4),
                                decoration: const BoxDecoration(
                                  color: Colors.black54,
                                  shape: BoxShape.circle,
                                ),
                                child: const Icon(Icons.close_rounded, size: 14, color: Colors.white),
                              ),
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                ),
              ),

            const SizedBox(height: 36),

            // Bottom Green Save Button
            ElevatedButton(
              onPressed: _isSaving ? null : _saveRecord,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.greenSaveButton,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                elevation: 3,
              ),
              child: _isSaving
                  ? const SizedBox(width: 22, height: 22, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                  : Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: const [
                        Icon(Icons.check_circle_rounded, size: 22),
                        SizedBox(width: 8),
                        Text(
                          'Save Record & Attach PDF Report',
                          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
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
