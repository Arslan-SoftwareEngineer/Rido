import 'package:flutter/material.dart';
import '../constants/app_colors.dart';
import '../constants/vehicle_parts.dart';
import '../models/vehicle_type.dart';

class SearchablePartsDialog extends StatefulWidget {
  final String title;
  final List<String> initialSelected;
  final VehicleType vehicleType;
  final bool isReplacement;

  const SearchablePartsDialog({
    super.key,
    required this.title,
    required this.initialSelected,
    required this.vehicleType,
    this.isReplacement = true,
  });

  static Future<List<String>?> show({
    required BuildContext context,
    required String title,
    required List<String> initialSelected,
    required VehicleType vehicleType,
    bool isReplacement = true,
  }) {
    return showModalBottomSheet<List<String>>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => SearchablePartsDialog(
        title: title,
        initialSelected: initialSelected,
        vehicleType: vehicleType,
        isReplacement: isReplacement,
      ),
    );
  }

  @override
  State<SearchablePartsDialog> createState() => _SearchablePartsDialogState();
}

class _SearchablePartsDialogState extends State<SearchablePartsDialog> {
  late final TextEditingController _searchController;
  late final TextEditingController _customPartController;
  late final List<String> _availableParts;
  late final Set<String> _selectedParts;
  String _searchQuery = '';
  bool _isAddingCustom = false;

  @override
  void initState() {
    super.initState();
    _searchController = TextEditingController();
    _customPartController = TextEditingController();
    _availableParts = VehicleParts.getPartsForType(widget.vehicleType);
    _selectedParts = Set<String>.from(widget.initialSelected);
  }

  @override
  void dispose() {
    _searchController.dispose();
    _customPartController.dispose();
    super.dispose();
  }

  void _togglePart(String part) {
    setState(() {
      if (part == VehicleParts.none) {
        // If "None" is selected, clear everything else and keep only "None"
        _selectedParts.clear();
        _selectedParts.add(VehicleParts.none);
      } else {
        // If another item is selected, remove "None"
        _selectedParts.remove(VehicleParts.none);
        if (_selectedParts.contains(part)) {
          _selectedParts.remove(part);
        } else {
          _selectedParts.add(part);
        }
      }
    });
  }

  void _addCustomPart() {
    final customName = _customPartController.text.trim();
    if (customName.isNotEmpty) {
      setState(() {
        _selectedParts.remove(VehicleParts.none);
        _selectedParts.add(customName);
        _customPartController.clear();
        _isAddingCustom = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final filteredParts = _availableParts.where((p) {
      if (_searchQuery.isEmpty) return true;
      return p.toLowerCase().contains(_searchQuery.toLowerCase());
    }).toList();

    return Container(
      height: MediaQuery.of(context).size.height * 0.85,
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkSurface : AppColors.lightSurface,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Column(
        children: [
          // Drag Handle
          Center(
            child: Container(
              margin: const EdgeInsets.only(top: 12, bottom: 8),
              width: 44,
              height: 5,
              decoration: BoxDecoration(
                color: isDark ? AppColors.darkBorder : AppColors.lightBorder,
                borderRadius: BorderRadius.circular(3),
              ),
            ),
          ),

          // Header
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      widget.title,
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                        color: isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary,
                      ),
                    ),
                    Text(
                      '${_selectedParts.length} selected',
                      style: TextStyle(
                        fontSize: 12,
                        color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary,
                      ),
                    ),
                  ],
                ),
                // Done button
                ElevatedButton.icon(
                  onPressed: () {
                    Navigator.of(context).pop(_selectedParts.toList());
                  },
                  icon: const Icon(Icons.check_rounded, size: 18),
                  label: const Text('Done'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    elevation: 0,
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                  ),
                ),
              ],
            ),
          ),

          // Search Field
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: TextField(
              controller: _searchController,
              onChanged: (val) => setState(() => _searchQuery = val.trim()),
              decoration: InputDecoration(
                hintText: 'Search parts (e.g. Filter, Brake, Oil, Chain)...',
                prefixIcon: const Icon(Icons.search_rounded),
                suffixIcon: _searchQuery.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear_rounded),
                        onPressed: () {
                          _searchController.clear();
                          setState(() => _searchQuery = '');
                        },
                      )
                    : null,
              ),
            ),
          ),

          // Selected Items Chips
          if (_selectedParts.isNotEmpty)
            Container(
              height: 42,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: ListView(
                scrollDirection: Axis.horizontal,
                children: _selectedParts.map((part) {
                  final isNone = part == VehicleParts.none;
                  return Container(
                    margin: const EdgeInsets.only(right: 8),
                    child: Chip(
                      label: Text(
                        part,
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: isNone
                              ? Colors.grey.shade700
                              : (isDark ? Colors.white : AppColors.primaryDark),
                        ),
                      ),
                      backgroundColor: isNone
                          ? Colors.grey.shade300
                          : (isDark ? AppColors.darkCardElevated : AppColors.primary.withValues(alpha: 0.15)),
                      deleteIcon: const Icon(Icons.close_rounded, size: 14),
                      onDeleted: () => _togglePart(part),
                      side: BorderSide.none,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                    ),
                  );
                }).toList(),
              ),
            ),

          const Divider(height: 16),

          // Custom part input option
          if (_isAddingCustom)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _customPartController,
                      autofocus: true,
                      decoration: const InputDecoration(
                        hintText: 'Enter custom part name...',
                        isDense: true,
                      ),
                      onSubmitted: (_) => _addCustomPart(),
                    ),
                  ),
                  const SizedBox(width: 8),
                  IconButton.filled(
                    onPressed: _addCustomPart,
                    icon: const Icon(Icons.add_rounded),
                    style: IconButton.styleFrom(backgroundColor: AppColors.primary),
                  ),
                  IconButton(
                    onPressed: () => setState(() => _isAddingCustom = false),
                    icon: const Icon(Icons.close_rounded),
                  ),
                ],
              ),
            )
          else
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
              child: TextButton.icon(
                onPressed: () => setState(() => _isAddingCustom = true),
                icon: const Icon(Icons.add_circle_outline_rounded, size: 18),
                label: const Text('Add Custom / Other Part Not In List'),
                style: TextButton.styleFrom(
                  foregroundColor: AppColors.primary,
                  alignment: Alignment.centerLeft,
                ),
              ),
            ),

          // Parts List
          Expanded(
            child: ListView.builder(
              itemCount: filteredParts.length,
              itemBuilder: (context, index) {
                final part = filteredParts[index];
                final isSelected = _selectedParts.contains(part);
                final isNone = part == VehicleParts.none;

                return InkWell(
                  onTap: () => _togglePart(part),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                    decoration: BoxDecoration(
                      color: isSelected
                          ? (isDark
                              ? AppColors.primary.withValues(alpha: 0.1)
                              : AppColors.primary.withValues(alpha: 0.08))
                          : Colors.transparent,
                      border: Border(
                        bottom: BorderSide(
                          color: isDark ? AppColors.darkBorder.withValues(alpha: 0.5) : AppColors.lightBorder,
                          width: 0.5,
                        ),
                      ),
                    ),
                    child: Row(
                      children: [
                        // Selection indicator
                        Container(
                          width: 22,
                          height: 22,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: isSelected ? AppColors.primary : Colors.transparent,
                            border: Border.all(
                              color: isSelected
                                  ? AppColors.primary
                                  : (isDark ? AppColors.darkBorder : AppColors.lightBorder),
                              width: 2,
                            ),
                          ),
                          child: isSelected
                              ? const Icon(Icons.check_rounded, size: 14, color: Colors.white)
                              : null,
                        ),
                        const SizedBox(width: 14),
                        // Part name
                        Expanded(
                          child: Text(
                            part,
                            style: TextStyle(
                              fontSize: 15,
                              fontWeight: isSelected ? FontWeight.w700 : FontWeight.w400,
                              color: isNone
                                  ? (isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary)
                                  : (isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary),
                            ),
                          ),
                        ),
                        if (isNone)
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                            decoration: BoxDecoration(
                              color: isDark ? AppColors.darkCardElevated : AppColors.lightCardElevated,
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Text(
                              'DEFAULT',
                              style: TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.bold,
                                color: isDark ? AppColors.darkTextTertiary : AppColors.lightTextTertiary,
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
