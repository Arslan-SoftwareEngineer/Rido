import 'dart:io';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/vehicle.dart';
import '../models/vehicle_type.dart';
import '../models/service_record.dart';
import '../constants/app_colors.dart';
import '../services/storage_service.dart';
import '../widgets/record_tile.dart';
import '../widgets/animated_view_switcher.dart';
import 'vehicle_profile_screen.dart';
import 'add_edit_record_screen.dart';
import 'pdf_viewer_screen.dart';

enum RecordSortOption {
  dateNewest('Date: Newest', Icons.calendar_today_rounded),
  dateOldest('Date: Oldest', Icons.history_rounded),
  amountHighToLow('Amount: High → Low', Icons.arrow_downward_rounded),
  amountLowToHigh('Amount: Low → High', Icons.arrow_upward_rounded),
  mileageHighToLow('Mileage: High → Low', Icons.speed_rounded);

  final String label;
  final IconData icon;
  const RecordSortOption(this.label, this.icon);
}

enum DateFilterPreset {
  all('All Dates'),
  last30Days('Last 30 Days'),
  last6Months('Last 6 Months'),
  thisYear('This Year'),
  custom('Custom Range');

  final String label;
  const DateFilterPreset(this.label);
}

enum AmountFilterPreset {
  all('All Amounts'),
  under5k('Under Rs. 5K'),
  k5To20k('Rs. 5K - 20K'),
  k20To50k('Rs. 20K - 50K'),
  over50k('Above Rs. 50K'),
  custom('Custom Range');

  final String label;
  const AmountFilterPreset(this.label);
}

class VehicleRecordsScreen extends StatefulWidget {
  final Vehicle vehicle;
  final StorageService storageService;

  const VehicleRecordsScreen({
    super.key,
    required this.vehicle,
    required this.storageService,
  });

  @override
  State<VehicleRecordsScreen> createState() => _VehicleRecordsScreenState();
}

class _VehicleRecordsScreenState extends State<VehicleRecordsScreen> {
  late Vehicle _vehicle;
  bool _isGridView = false;

  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';

  RecordSortOption _sortOption = RecordSortOption.dateNewest;
  DateFilterPreset _dateFilterPreset = DateFilterPreset.all;
  DateTimeRange? _customDateRange;

  AmountFilterPreset _amountFilterPreset = AmountFilterPreset.all;
  double? _customMinAmount;
  double? _customMaxAmount;

  @override
  void initState() {
    super.initState();
    _vehicle = widget.vehicle;
    widget.storageService.addListener(_onStorageChange);
    _searchController.addListener(() {
      setState(() {
        _searchQuery = _searchController.text;
      });
    });
  }

  @override
  void dispose() {
    widget.storageService.removeListener(_onStorageChange);
    _searchController.dispose();
    super.dispose();
  }

  void _onStorageChange() {
    final updated = widget.storageService.getVehicleById(_vehicle.id);
    if (updated != null && mounted) {
      setState(() {
        _vehicle = updated;
      });
    }
  }

  bool get _hasActiveFilters {
    return _searchQuery.trim().isNotEmpty ||
        _sortOption != RecordSortOption.dateNewest ||
        _dateFilterPreset != DateFilterPreset.all ||
        _amountFilterPreset != AmountFilterPreset.all;
  }

  int get _activeFilterCount {
    int count = 0;
    if (_searchQuery.trim().isNotEmpty) count++;
    if (_sortOption != RecordSortOption.dateNewest) count++;
    if (_dateFilterPreset != DateFilterPreset.all) count++;
    if (_amountFilterPreset != AmountFilterPreset.all) count++;
    return count;
  }

  void _clearAllFilters() {
    setState(() {
      _searchController.clear();
      _searchQuery = '';
      _sortOption = RecordSortOption.dateNewest;
      _dateFilterPreset = DateFilterPreset.all;
      _customDateRange = null;
      _amountFilterPreset = AmountFilterPreset.all;
      _customMinAmount = null;
      _customMaxAmount = null;
    });
  }

  List<ServiceRecord> _filterAndSortRecords(List<ServiceRecord> allRecords) {
    var list = List<ServiceRecord>.from(allRecords);

    // 1. Text Search Filter (name, shop, notes, parts replaced, added parts, company/specs, mileage)
    if (_searchQuery.trim().isNotEmpty) {
      final q = _searchQuery.toLowerCase().trim();
      list = list.where((record) {
        if (record.serviceName.toLowerCase().contains(q)) return true;
        if (record.serviceShop.toLowerCase().contains(q)) return true;
        if (record.notes.toLowerCase().contains(q)) return true;
        if (record.mileage.toString().contains(q)) return true;
        if (record.nextServiceMileage != null &&
            record.nextServiceMileage.toString().contains(q)) {
          return true;
        }
        if (record.totalPrice.toString().contains(q)) return true;

        final dateFormatted =
            DateFormat('dd MMM yyyy').format(record.date).toLowerCase();
        if (dateFormatted.contains(q)) return true;

        for (final p in record.partsReplaced) {
          if (p.name.toLowerCase().contains(q)) return true;
          if (p.company.toLowerCase().contains(q)) return true;
        }

        for (final p in record.newPartsAdded) {
          if (p.name.toLowerCase().contains(q)) return true;
          if (p.company.toLowerCase().contains(q)) return true;
        }

        return false;
      }).toList();
    }

    // 2. Date Filter
    final now = DateTime.now();
    if (_dateFilterPreset == DateFilterPreset.last30Days) {
      final cutoff = now.subtract(const Duration(days: 30));
      list = list.where((r) => r.date.isAfter(cutoff) || r.date.isAtSameMomentAs(cutoff)).toList();
    } else if (_dateFilterPreset == DateFilterPreset.last6Months) {
      final cutoff = DateTime(now.year, now.month - 6, now.day);
      list = list.where((r) => r.date.isAfter(cutoff) || r.date.isAtSameMomentAs(cutoff)).toList();
    } else if (_dateFilterPreset == DateFilterPreset.thisYear) {
      final cutoff = DateTime(now.year, 1, 1);
      list = list.where((r) => r.date.isAfter(cutoff) || r.date.isAtSameMomentAs(cutoff)).toList();
    } else if (_dateFilterPreset == DateFilterPreset.custom && _customDateRange != null) {
      final start = DateTime(_customDateRange!.start.year, _customDateRange!.start.month, _customDateRange!.start.day);
      final end = DateTime(_customDateRange!.end.year, _customDateRange!.end.month, _customDateRange!.end.day, 23, 59, 59);
      list = list.where((r) => (r.date.isAfter(start) || r.date.isAtSameMomentAs(start)) &&
                               (r.date.isBefore(end) || r.date.isAtSameMomentAs(end))).toList();
    }

    // 3. Amount Filter
    if (_amountFilterPreset == AmountFilterPreset.under5k) {
      list = list.where((r) => r.totalPrice < 5000).toList();
    } else if (_amountFilterPreset == AmountFilterPreset.k5To20k) {
      list = list.where((r) => r.totalPrice >= 5000 && r.totalPrice <= 20000).toList();
    } else if (_amountFilterPreset == AmountFilterPreset.k20To50k) {
      list = list.where((r) => r.totalPrice > 20000 && r.totalPrice <= 50000).toList();
    } else if (_amountFilterPreset == AmountFilterPreset.over50k) {
      list = list.where((r) => r.totalPrice > 50000).toList();
    } else if (_amountFilterPreset == AmountFilterPreset.custom) {
      if (_customMinAmount != null) {
        list = list.where((r) => r.totalPrice >= _customMinAmount!).toList();
      }
      if (_customMaxAmount != null) {
        list = list.where((r) => r.totalPrice <= _customMaxAmount!).toList();
      }
    }

    // 4. Sorting
    switch (_sortOption) {
      case RecordSortOption.dateNewest:
        list.sort((a, b) => b.date.compareTo(a.date));
        break;
      case RecordSortOption.dateOldest:
        list.sort((a, b) => a.date.compareTo(b.date));
        break;
      case RecordSortOption.amountHighToLow:
        list.sort((a, b) => b.totalPrice.compareTo(a.totalPrice));
        break;
      case RecordSortOption.amountLowToHigh:
        list.sort((a, b) => a.totalPrice.compareTo(b.totalPrice));
        break;
      case RecordSortOption.mileageHighToLow:
        list.sort((a, b) => b.mileage.compareTo(a.mileage));
        break;
    }

    return list;
  }

  void _openVehicleProfile() {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => VehicleProfileScreen(
          vehicle: _vehicle,
          storageService: widget.storageService,
        ),
      ),
    );
  }

  void _openAddRecord() {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => AddEditRecordScreen(
          vehicle: _vehicle,
          storageService: widget.storageService,
        ),
      ),
    );
  }

  void _openRecordPdf(ServiceRecord record) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => PdfViewerScreen(
          vehicle: _vehicle,
          record: record,
          storageService: widget.storageService,
        ),
      ),
    );
  }

  void _confirmDeleteRecord(ServiceRecord record) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Service Record?'),
        content: Text(
            'Are you sure you want to delete "${record.serviceName}"? The attached PDF will also be removed.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              widget.storageService.deleteServiceRecord(record.id);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.errorRed,
              foregroundColor: Colors.white,
            ),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }

  void _showFilterModal() {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final minController = TextEditingController(
        text: _customMinAmount != null ? _customMinAmount!.toInt().toString() : '');
    final maxController = TextEditingController(
        text: _customMaxAmount != null ? _customMaxAmount!.toInt().toString() : '');

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: isDark ? AppColors.darkCard : AppColors.lightCard,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (sheetContext) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            return Container(
              constraints: BoxConstraints(
                maxHeight: MediaQuery.of(sheetContext).size.height * 0.85,
              ),
              padding: EdgeInsets.only(
                left: 20,
                right: 20,
                top: 12,
                bottom: MediaQuery.of(sheetContext).viewInsets.bottom + 16,
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Drag handle
                  Center(
                    child: Container(
                      width: 36,
                      height: 4,
                      margin: const EdgeInsets.only(bottom: 12),
                      decoration: BoxDecoration(
                        color: isDark ? AppColors.darkBorder : AppColors.lightBorder,
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  ),

                  // Sheet Header (Pinned)
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: AppColors.primary.withValues(alpha: 0.12),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: const Icon(Icons.tune_rounded, color: AppColors.primary, size: 20),
                          ),
                          const SizedBox(width: 10),
                          Text(
                            'Filter & Sort Records',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary,
                            ),
                          ),
                        ],
                      ),
                      TextButton(
                        onPressed: () {
                          setModalState(() {
                            _sortOption = RecordSortOption.dateNewest;
                            _dateFilterPreset = DateFilterPreset.all;
                            _customDateRange = null;
                            _amountFilterPreset = AmountFilterPreset.all;
                            _customMinAmount = null;
                            _customMaxAmount = null;
                            minController.clear();
                            maxController.clear();
                          });
                          setState(() {
                            _sortOption = RecordSortOption.dateNewest;
                            _dateFilterPreset = DateFilterPreset.all;
                            _customDateRange = null;
                            _amountFilterPreset = AmountFilterPreset.all;
                            _customMinAmount = null;
                            _customMaxAmount = null;
                          });
                        },
                        child: const Text('Reset All'),
                      ),
                    ],
                  ),
                  const Divider(height: 20),

                  // Scrollable Filter Options
                  Flexible(
                    child: SingleChildScrollView(
                      physics: const BouncingScrollPhysics(),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Sort By Section
                          Text(
                            'Sort Records By',
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w700,
                              color: isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary,
                            ),
                          ),
                          const SizedBox(height: 10),
                          Wrap(
                            spacing: 8,
                            runSpacing: 8,
                            children: RecordSortOption.values.map((opt) {
                              final isSelected = _sortOption == opt;
                              return ChoiceChip(
                                showCheckmark: false,
                                avatar: Icon(
                                  opt.icon,
                                  size: 15,
                                  color: isSelected ? Colors.white : AppColors.primary,
                                ),
                                label: Text(opt.label),
                                selected: isSelected,
                                selectedColor: AppColors.primary,
                                labelStyle: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                  color: isSelected ? Colors.white : (isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary),
                                ),
                                onSelected: (selected) {
                                  if (selected) {
                                    setModalState(() => _sortOption = opt);
                                    setState(() => _sortOption = opt);
                                  }
                                },
                              );
                            }).toList(),
                          ),
                          const SizedBox(height: 20),

                          // Filter By Date Section
                          Text(
                            'Search by Date',
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w700,
                              color: isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary,
                            ),
                          ),
                          const SizedBox(height: 10),
                          Wrap(
                            spacing: 8,
                            runSpacing: 8,
                            children: DateFilterPreset.values.map((preset) {
                              final isSelected = _dateFilterPreset == preset;
                              return ChoiceChip(
                                showCheckmark: false,
                                label: Text(preset == DateFilterPreset.custom && _customDateRange != null
                                    ? '${DateFormat('dd MMM').format(_customDateRange!.start)} - ${DateFormat('dd MMM').format(_customDateRange!.end)}'
                                    : preset.label),
                                selected: isSelected,
                                selectedColor: AppColors.primary,
                                labelStyle: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                  color: isSelected ? Colors.white : (isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary),
                                ),
                                onSelected: (selected) async {
                                  if (selected) {
                                    if (preset == DateFilterPreset.custom) {
                                      final picked = await showDateRangePicker(
                                        context: context,
                                        firstDate: DateTime(2000),
                                        lastDate: DateTime.now().add(const Duration(days: 365)),
                                        initialDateRange: _customDateRange ??
                                            DateTimeRange(
                                              start: DateTime.now().subtract(const Duration(days: 30)),
                                              end: DateTime.now(),
                                            ),
                                      );
                                      if (picked != null) {
                                        setModalState(() {
                                          _dateFilterPreset = DateFilterPreset.custom;
                                          _customDateRange = picked;
                                        });
                                        setState(() {
                                          _dateFilterPreset = DateFilterPreset.custom;
                                          _customDateRange = picked;
                                        });
                                      }
                                    } else {
                                      setModalState(() {
                                        _dateFilterPreset = preset;
                                        _customDateRange = null;
                                      });
                                      setState(() {
                                        _dateFilterPreset = preset;
                                        _customDateRange = null;
                                      });
                                    }
                                  }
                                },
                              );
                            }).toList(),
                          ),
                          const SizedBox(height: 20),

                          // Filter By Amount Spent Section
                          Text(
                            'Search by Amount Spent (Rs.)',
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w700,
                              color: isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary,
                            ),
                          ),
                          const SizedBox(height: 10),
                          Wrap(
                            spacing: 8,
                            runSpacing: 8,
                            children: AmountFilterPreset.values.map((preset) {
                              final isSelected = _amountFilterPreset == preset;
                              return ChoiceChip(
                                showCheckmark: false,
                                label: Text(preset.label),
                                selected: isSelected,
                                selectedColor: AppColors.primary,
                                labelStyle: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                  color: isSelected ? Colors.white : (isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary),
                                ),
                                onSelected: (selected) {
                                  if (selected) {
                                    setModalState(() {
                                      _amountFilterPreset = preset;
                                      if (preset != AmountFilterPreset.custom) {
                                        _customMinAmount = null;
                                        _customMaxAmount = null;
                                        minController.clear();
                                        maxController.clear();
                                      }
                                    });
                                    setState(() {
                                      _amountFilterPreset = preset;
                                      if (preset != AmountFilterPreset.custom) {
                                        _customMinAmount = null;
                                        _customMaxAmount = null;
                                      }
                                    });
                                  }
                                },
                              );
                            }).toList(),
                          ),

                          if (_amountFilterPreset == AmountFilterPreset.custom) ...[
                            const SizedBox(height: 12),
                            Row(
                              children: [
                                Expanded(
                                  child: TextField(
                                    controller: minController,
                                    keyboardType: TextInputType.number,
                                    decoration: const InputDecoration(
                                      labelText: 'Min Amount',
                                      prefixText: 'Rs. ',
                                      isDense: true,
                                    ),
                                    onChanged: (val) {
                                      final d = double.tryParse(val.trim());
                                      setModalState(() => _customMinAmount = d);
                                      setState(() => _customMinAmount = d);
                                    },
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: TextField(
                                    controller: maxController,
                                    keyboardType: TextInputType.number,
                                    decoration: const InputDecoration(
                                      labelText: 'Max Amount',
                                      prefixText: 'Rs. ',
                                      isDense: true,
                                    ),
                                    onChanged: (val) {
                                      final d = double.tryParse(val.trim());
                                      setModalState(() => _customMaxAmount = d);
                                      setState(() => _customMaxAmount = d);
                                    },
                                  ),
                                ),
                              ],
                            ),
                          ],
                          const SizedBox(height: 12),
                        ],
                      ),
                    ),
                  ),

                  // Fixed Apply Button (Pinned at bottom, always visible without scrolling)
                  const SizedBox(height: 12),
                  SizedBox(
                    width: double.infinity,
                    height: 48,
                    child: ElevatedButton(
                      onPressed: () {
                        if (_amountFilterPreset == AmountFilterPreset.custom) {
                          final minVal = double.tryParse(minController.text.trim());
                          final maxVal = double.tryParse(maxController.text.trim());
                          setState(() {
                            _customMinAmount = minVal;
                            _customMaxAmount = maxVal;
                          });
                        }
                        Navigator.pop(sheetContext);
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primary,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                        elevation: 2,
                      ),
                      child: const Text('Apply Filters', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final allRecords = widget.storageService.getRecordsForVehicle(_vehicle.id);
    final filteredRecords = _filterAndSortRecords(allRecords);
    final isCar = _vehicle.type == VehicleType.car;
    final accentColor = isCar ? AppColors.carAccent : AppColors.bikeAccent;
    final numberFormat = NumberFormat('#,###');

    return Scaffold(
      backgroundColor: isDark ? AppColors.darkBackground : AppColors.lightBackground,
      appBar: AppBar(
        title: Text('${_vehicle.type.displayName} Maintenance'),
        actions: [
          IconButton(
            icon: const Icon(Icons.info_outline_rounded),
            tooltip: 'Vehicle Profile',
            onPressed: _openVehicleProfile,
          ),
        ],
      ),
      body: Column(
        children: [
          // Header Card: Vehicle picture along with name
          GestureDetector(
            onTap: _openVehicleProfile,
            child: Container(
              margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: isDark ? AppColors.darkCard : AppColors.lightCard,
                borderRadius: BorderRadius.circular(18),
                border: Border.all(
                  color: isDark ? AppColors.darkBorder : AppColors.lightBorder,
                  width: 1,
                ),
                boxShadow: [
                  BoxShadow(
                    color: isDark ? Colors.black26 : Colors.black.withValues(alpha: 0.04),
                    blurRadius: 10,
                    offset: const Offset(0, 3),
                  ),
                ],
              ),
              child: Row(
                children: [
                  // Picture of the car/bike
                  Hero(
                    tag: 'vehicle_image_${_vehicle.id}',
                    child: Container(
                      width: 64,
                      height: 64,
                      decoration: BoxDecoration(
                        color: isDark ? AppColors.darkCardElevated : AppColors.lightCardElevated,
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(color: accentColor.withValues(alpha: 0.4), width: 1.5),
                      ),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(12.5),
                        child: _vehicle.imagePath != null && File(_vehicle.imagePath!).existsSync()
                            ? Image.file(
                                File(_vehicle.imagePath!),
                                fit: BoxFit.cover,
                              )
                            : Center(
                                child: Icon(
                                  isCar ? Icons.directions_car_filled_rounded : Icons.two_wheeler_rounded,
                                  size: 32,
                                  color: accentColor,
                                ),
                              ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 14),

                  // Name & Profile Action Callout
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          _vehicle.name,
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        if (_vehicle.model.isNotEmpty || _vehicle.variant.isNotEmpty)
                          Text(
                            '${_vehicle.model} ${_vehicle.variant}'.trim(),
                            style: TextStyle(
                              fontSize: 12,
                              color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        const SizedBox(height: 5),
                        Row(
                          children: [
                            Text(
                              'Odometer: ${numberFormat.format(_vehicle.mileage)} km',
                              style: const TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w600,
                                color: AppColors.primary,
                              ),
                            ),
                            const Spacer(),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                              decoration: BoxDecoration(
                                color: accentColor.withValues(alpha: 0.12),
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Text(
                                    'Profile',
                                    style: TextStyle(
                                      fontSize: 11,
                                      fontWeight: FontWeight.bold,
                                      color: accentColor,
                                    ),
                                  ),
                                  const SizedBox(width: 2),
                                  Icon(Icons.arrow_forward_ios_rounded, size: 9, color: accentColor),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),

          // Service Due Alert Banner (if vehicle reached its next service odometer)
          if (widget.storageService.isVehicleDueForService(_vehicle))
            Container(
              margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppColors.errorRed.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: AppColors.errorRed.withValues(alpha: 0.4), width: 1.5),
              ),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: AppColors.errorRed.withValues(alpha: 0.16),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.warning_amber_rounded, color: AppColors.errorRed, size: 22),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Service Due Reminder!',
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.bold,
                            color: AppColors.errorRed,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          'Current odometer (${numberFormat.format(_vehicle.mileage)} km) has reached the target (${numberFormat.format(widget.storageService.getNextServiceMileageForVehicle(_vehicle.id) ?? _vehicle.mileage)} km).',
                          style: TextStyle(
                            fontSize: 11,
                            color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  ElevatedButton(
                    onPressed: _openAddRecord,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.errorRed,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                      elevation: 0,
                    ),
                    child: const Text('Add Record', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold)),
                  ),
                ],
              ),
            ),

          // Search Records Field & Filter Button
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
            child: Row(
              children: [
                Expanded(
                  child: SizedBox(
                    height: 48,
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(16),
                      child: TextField(
                        controller: _searchController,
                        textInputAction: TextInputAction.search,
                        textAlignVertical: TextAlignVertical.center,
                        decoration: InputDecoration(
                          isDense: true,
                          hintText: 'Search records, parts, shop, specs...',
                          hintStyle: TextStyle(
                            fontSize: 13,
                            color: isDark ? AppColors.darkTextTertiary : AppColors.lightTextTertiary,
                          ),
                          prefixIcon: const Icon(Icons.search_rounded, size: 20),
                          suffixIcon: _searchQuery.isNotEmpty
                              ? IconButton(
                                  icon: const Icon(Icons.close_rounded, size: 18),
                                  onPressed: () {
                                    _searchController.clear();
                                  },
                                )
                              : null,
                          filled: true,
                          fillColor: isDark ? AppColors.darkCard : AppColors.lightCard,
                          contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(16),
                            borderSide: BorderSide(
                              color: isDark ? AppColors.darkBorder : AppColors.lightBorder,
                            ),
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(16),
                            borderSide: BorderSide(
                              color: _searchQuery.isNotEmpty
                                  ? AppColors.primary
                                  : (isDark ? AppColors.darkBorder : AppColors.lightBorder),
                            ),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(16),
                            borderSide: const BorderSide(
                              color: AppColors.primary,
                              width: 1.5,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                InkWell(
                  onTap: _showFilterModal,
                  borderRadius: BorderRadius.circular(16),
                  child: Container(
                    height: 48,
                    width: 48,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: _hasActiveFilters
                          ? AppColors.primary.withValues(alpha: 0.15)
                          : (isDark ? AppColors.darkCard : AppColors.lightCard),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: _hasActiveFilters
                            ? AppColors.primary
                            : (isDark ? AppColors.darkBorder : AppColors.lightBorder),
                      ),
                    ),
                    child: SizedBox(
                      height: 48,
                      width: 48,
                      child: Stack(
                        alignment: Alignment.center,
                        children: [
                          Center(
                            child: Icon(
                              Icons.tune_rounded,
                              color: _hasActiveFilters
                                  ? AppColors.primary
                                  : (isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary),
                              size: 22,
                            ),
                          ),
                          if (_activeFilterCount > 0)
                            Positioned(
                              top: 6,
                              right: 6,
                              child: Container(
                                padding: const EdgeInsets.all(3),
                                decoration: const BoxDecoration(
                                  color: AppColors.primary,
                                  shape: BoxShape.circle,
                                ),
                                constraints: const BoxConstraints(
                                  minWidth: 16,
                                  minHeight: 16,
                                ),
                                child: Text(
                                  '$_activeFilterCount',
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 9,
                                    fontWeight: FontWeight.bold,
                                  ),
                                  textAlign: TextAlign.center,
                                ),
                              ),
                            ),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),

          // Filter Chips Horizontal Bar (Visible if filters active or for quick access)
          if (allRecords.isNotEmpty)
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
              child: Row(
                children: [
                  // Sort selector chip
                  ActionChip(
                    avatar: Icon(_sortOption.icon, size: 14, color: AppColors.primary),
                    label: Text(_sortOption.label),
                    labelStyle: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary,
                    ),
                    backgroundColor: isDark ? AppColors.darkCard : AppColors.lightCard,
                    side: BorderSide(
                      color: _sortOption != RecordSortOption.dateNewest
                          ? AppColors.primary
                          : (isDark ? AppColors.darkBorder : AppColors.lightBorder),
                    ),
                    onPressed: _showFilterModal,
                  ),
                  const SizedBox(width: 6),

                  // Date filter chip
                  ActionChip(
                    avatar: Icon(Icons.date_range_rounded,
                        size: 14,
                        color: _dateFilterPreset != DateFilterPreset.all ? AppColors.primary : null),
                    label: Text(_dateFilterPreset == DateFilterPreset.custom && _customDateRange != null
                        ? '${DateFormat('dd MMM').format(_customDateRange!.start)} - ${DateFormat('dd MMM').format(_customDateRange!.end)}'
                        : _dateFilterPreset.label),
                    labelStyle: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: _dateFilterPreset != DateFilterPreset.all
                          ? AppColors.primary
                          : (isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary),
                    ),
                    backgroundColor: _dateFilterPreset != DateFilterPreset.all
                        ? AppColors.primary.withValues(alpha: 0.12)
                        : (isDark ? AppColors.darkCard : AppColors.lightCard),
                    side: BorderSide(
                      color: _dateFilterPreset != DateFilterPreset.all
                          ? AppColors.primary
                          : (isDark ? AppColors.darkBorder : AppColors.lightBorder),
                    ),
                    onPressed: _showFilterModal,
                  ),
                  const SizedBox(width: 6),

                  // Amount filter chip
                  ActionChip(
                    avatar: Icon(Icons.payments_outlined,
                        size: 14,
                        color: _amountFilterPreset != AmountFilterPreset.all ? AppColors.primary : null),
                    label: Text(_amountFilterPreset.label),
                    labelStyle: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: _amountFilterPreset != AmountFilterPreset.all
                          ? AppColors.primary
                          : (isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary),
                    ),
                    backgroundColor: _amountFilterPreset != AmountFilterPreset.all
                        ? AppColors.primary.withValues(alpha: 0.12)
                        : (isDark ? AppColors.darkCard : AppColors.lightCard),
                    side: BorderSide(
                      color: _amountFilterPreset != AmountFilterPreset.all
                          ? AppColors.primary
                          : (isDark ? AppColors.darkBorder : AppColors.lightBorder),
                    ),
                    onPressed: _showFilterModal,
                  ),

                  if (_hasActiveFilters) ...[
                    const SizedBox(width: 6),
                    ActionChip(
                      avatar: const Icon(Icons.clear_all_rounded, size: 14, color: AppColors.errorRed),
                      label: const Text('Clear Filters'),
                      labelStyle: const TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        color: AppColors.errorRed,
                      ),
                      backgroundColor: AppColors.errorRed.withValues(alpha: 0.1),
                      side: BorderSide(color: AppColors.errorRed.withValues(alpha: 0.3)),
                      onPressed: _clearAllFilters,
                    ),
                  ],
                ],
              ),
            ),

          // View Switcher & Toolbar
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 6),
            child: Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        Text(
                          'Service Records',
                          style: TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w700,
                            color: isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                          decoration: BoxDecoration(
                            color: isDark ? AppColors.darkCardElevated : AppColors.lightCardElevated,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            _hasActiveFilters
                                ? '${filteredRecords.length} of ${allRecords.length}'
                                : '${allRecords.length}',
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.bold,
                              color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary,
                            ),
                          ),
                        ),
                      ],
                    ),
                    // Grid / List toggle switcher - ALWAYS PINNED ON THE RIGHT
                    AnimatedViewSwitcher(
                      isGrid: _isGridView,
                      onChanged: (val) => setState(() => _isGridView = val),
                    ),
                  ],
                ),
                if (filteredRecords.isNotEmpty) ...[
                  const SizedBox(height: 6),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      if (_hasActiveFilters)
                        Expanded(
                          child: Text(
                            'Filtered: ${filteredRecords.length} record${filteredRecords.length == 1 ? '' : 's'}',
                            style: TextStyle(
                              fontSize: 11,
                              color: isDark ? AppColors.darkTextTertiary : AppColors.lightTextTertiary,
                              fontWeight: FontWeight.w500,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        )
                      else
                        const Spacer(),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(
                          color: AppColors.primary.withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(
                            color: AppColors.primary.withValues(alpha: 0.2),
                          ),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(Icons.payments_rounded, size: 12, color: AppColors.primary),
                            const SizedBox(width: 4),
                            Text(
                              'Total: Rs. ${numberFormat.format(filteredRecords.fold(0.0, (acc, r) => acc + r.totalPrice))}',
                              style: const TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.bold,
                                color: AppColors.primary,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ],
              ],
            ),
          ),

          // Records List or Grid or Empty State
          Expanded(
            child: allRecords.isEmpty
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Container(
                          width: 80,
                          height: 80,
                          decoration: BoxDecoration(
                            color: isDark ? AppColors.darkCard : AppColors.lightCardElevated,
                            shape: BoxShape.circle,
                          ),
                          child: Icon(
                            Icons.receipt_long_rounded,
                            size: 40,
                            color: isDark ? AppColors.darkTextTertiary : AppColors.lightTextTertiary,
                          ),
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'No Service Records Yet',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary,
                          ),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          'Tap the circle (+) button below to add your first record.',
                          style: TextStyle(
                            fontSize: 12,
                            color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary,
                          ),
                        ),
                        const SizedBox(height: 20),
                        ElevatedButton.icon(
                          onPressed: _openAddRecord,
                          icon: const Icon(Icons.add_rounded),
                          label: const Text('Add Service Record'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.primary,
                            foregroundColor: Colors.white,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          ),
                        ),
                      ],
                    ),
                  )
                : filteredRecords.isEmpty
                    ? Center(
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 28),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Container(
                                width: 72,
                                height: 72,
                                decoration: BoxDecoration(
                                  color: isDark ? AppColors.darkCard : AppColors.lightCardElevated,
                                  shape: BoxShape.circle,
                                ),
                                child: Icon(
                                  Icons.search_off_rounded,
                                  size: 38,
                                  color: isDark ? AppColors.darkTextTertiary : AppColors.lightTextTertiary,
                                ),
                              ),
                              const SizedBox(height: 14),
                              Text(
                                'No Matching Records',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                  color: isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary,
                                ),
                              ),
                              const SizedBox(height: 6),
                              Text(
                                _searchQuery.isNotEmpty
                                    ? 'No records match "$_searchQuery" or the selected filters.'
                                    : 'No service records match the applied filters.',
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                  fontSize: 12,
                                  color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary,
                                ),
                              ),
                              const SizedBox(height: 16),
                              OutlinedButton.icon(
                                onPressed: _clearAllFilters,
                                icon: const Icon(Icons.refresh_rounded, size: 16),
                                label: const Text('Clear Search & Filters'),
                                style: OutlinedButton.styleFrom(
                                  foregroundColor: AppColors.primary,
                                  side: const BorderSide(color: AppColors.primary),
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                                ),
                              ),
                            ],
                          ),
                        ),
                      )
                    : AnimatedSwitcher(
                        duration: const Duration(milliseconds: 250),
                        child: _isGridView
                            ? GridView.builder(
                                key: const ValueKey('grid_view'),
                                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                                physics: const BouncingScrollPhysics(),
                                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                                  crossAxisCount: 2,
                                  crossAxisSpacing: 12,
                                  mainAxisSpacing: 12,
                                  childAspectRatio: 0.74,
                                ),
                                itemCount: filteredRecords.length,
                                itemBuilder: (context, index) {
                                  final record = filteredRecords[index];
                                  return RecordTile(
                                    record: record,
                                    isGrid: true,
                                    index: index,
                                    onTap: () => _openRecordPdf(record),
                                    onLongPress: () => _confirmDeleteRecord(record),
                                  );
                                },
                              )
                            : ListView.builder(
                                key: const ValueKey('list_view'),
                                padding: const EdgeInsets.only(top: 4, bottom: 80),
                                physics: const BouncingScrollPhysics(),
                                itemCount: filteredRecords.length,
                                itemBuilder: (context, index) {
                                  final record = filteredRecords[index];
                                  return RecordTile(
                                    record: record,
                                    isGrid: false,
                                    index: index,
                                    onTap: () => _openRecordPdf(record),
                                    onLongPress: () => _confirmDeleteRecord(record),
                                  );
                                },
                              ),
                      ),
          ),
        ],
      ),
      // Plus button in a circle on bottom right to add new record
      floatingActionButton: SizedBox(
        width: 62,
        height: 62,
        child: FloatingActionButton(
          onPressed: _openAddRecord,
          backgroundColor: AppColors.primary,
          foregroundColor: Colors.white,
          elevation: 6,
          shape: const CircleBorder(),
          tooltip: 'Add New Record',
          child: const Icon(Icons.add_rounded, size: 36),
        ),
      ),
    );
  }
}

