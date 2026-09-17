import 'dart:io';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:printing/printing.dart';
import '../models/vehicle.dart';
import '../models/vehicle_type.dart';
import '../models/service_record.dart';
import '../constants/app_colors.dart';
import '../services/storage_service.dart';
import '../services/pdf_generator_service.dart';
import '../services/excel_exporter_service.dart';
import 'add_edit_vehicle_screen.dart';

class VehicleProfileScreen extends StatefulWidget {
  final Vehicle vehicle;
  final StorageService storageService;

  const VehicleProfileScreen({
    super.key,
    required this.vehicle,
    required this.storageService,
  });

  @override
  State<VehicleProfileScreen> createState() => _VehicleProfileScreenState();
}

class _VehicleProfileScreenState extends State<VehicleProfileScreen> {
  late Vehicle _vehicle;

  @override
  void initState() {
    super.initState();
    _vehicle = widget.vehicle;
    widget.storageService.addListener(_onStorageUpdated);
  }

  @override
  void dispose() {
    widget.storageService.removeListener(_onStorageUpdated);
    super.dispose();
  }

  void _onStorageUpdated() {
    final updated = widget.storageService.getVehicleById(_vehicle.id);
    if (updated != null && mounted) {
      setState(() {
        _vehicle = updated;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final numberFormat = NumberFormat('#,###');
    final dateFormat = DateFormat('dd/MM/yyyy');
    final isCar = _vehicle.type == VehicleType.car;
    final accentColor = isCar ? AppColors.carAccent : AppColors.bikeAccent;

    final records = widget.storageService.getRecordsForVehicle(_vehicle.id);

    return Scaffold(
      backgroundColor: isDark ? AppColors.darkBackground : AppColors.lightBackground,
      appBar: AppBar(
        title: Text('${_vehicle.type.displayName} Profile'),
        elevation: 0,
        actions: [
          // Share full service history button
          IconButton(
            icon: const Icon(Icons.share_rounded),
            tooltip: 'Share Full Service History',
            onPressed: () => _showShareOptionsModal(context, records),
          ),
          // Pencil button on the top to edit the profile
          Padding(
            padding: const EdgeInsets.only(right: 8),
            child: IconButton(
              icon: const Icon(Icons.edit_rounded),
              tooltip: 'Edit Profile',
              onPressed: () async {
                final result = await Navigator.of(context).push<Vehicle>(
                  MaterialPageRoute(
                    builder: (context) => AddEditVehicleScreen(
                      storageService: widget.storageService,
                      vehicleToEdit: _vehicle,
                      initialType: _vehicle.type,
                    ),
                  ),
                );
                if (result != null && mounted) {
                  setState(() {
                    _vehicle = result;
                  });
                }
              },
            ),
          ),
        ],
      ),
      body: SingleChildScrollView(
        physics: const BouncingScrollPhysics(),
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Hero Vehicle Image & Banner
            Center(
              child: Hero(
                tag: 'vehicle_image_${_vehicle.id}',
                child: Container(
                  width: double.infinity,
                  height: 220,
                  decoration: BoxDecoration(
                    color: isDark ? AppColors.darkCard : AppColors.lightCardElevated,
                    borderRadius: BorderRadius.circular(24),
                    border: Border.all(
                      color: accentColor.withValues(alpha: 0.3),
                      width: 2,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: isDark ? Colors.black.withValues(alpha: 0.4) : Colors.black.withValues(alpha: 0.08),
                        blurRadius: 16,
                        offset: const Offset(0, 6),
                      ),
                    ],
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(22),
                    child: _vehicle.imagePath != null && File(_vehicle.imagePath!).existsSync()
                        ? Image.file(
                            File(_vehicle.imagePath!),
                            fit: BoxFit.cover,
                          )
                        : Center(
                            child: Icon(
                              isCar ? Icons.directions_car_filled_rounded : Icons.two_wheeler_rounded,
                              size: 84,
                              color: accentColor.withValues(alpha: 0.6),
                            ),
                          ),
                  ),
                ),
              ),
            ).animate().fadeIn(duration: 350.ms).scale(begin: const Offset(0.95, 0.95)),

            const SizedBox(height: 20),

            // Vehicle Title & Badges
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        _vehicle.name,
                        style: TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.w800,
                          letterSpacing: -0.5,
                          color: isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary,
                        ),
                      ),
                      if (_vehicle.model.isNotEmpty || _vehicle.variant.isNotEmpty)
                        Text(
                          '${_vehicle.model} • ${_vehicle.variant}'.trim(),
                          style: TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w500,
                            color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary,
                          ),
                        ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: accentColor.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: accentColor.withValues(alpha: 0.4)),
                  ),
                  child: Text(
                    _vehicle.type.displayName.toUpperCase(),
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w800,
                      color: accentColor,
                      letterSpacing: 1,
                    ),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 24),

            // Specifications Title
            Text(
              'VEHICLE SPECIFICATIONS',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.bold,
                letterSpacing: 1,
                color: isDark ? AppColors.darkTextTertiary : AppColors.lightTextTertiary,
              ),
            ),
            const SizedBox(height: 12),

            // Grid of 6 key specs requested by the user:
            // Name, Model, Variant, Mileage, Fuel Average, Engine Capacity, Transmission Type
            GridView.count(
              crossAxisCount: 2,
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              mainAxisSpacing: 12,
              crossAxisSpacing: 12,
              childAspectRatio: 1.6,
              children: [
                _buildSpecCard(
                  icon: Icons.speed_rounded,
                  label: 'Current Mileage',
                  value: '${numberFormat.format(_vehicle.mileage)} km',
                  accent: AppColors.primary,
                  isDark: isDark,
                ),
                _buildSpecCard(
                  icon: Icons.local_gas_station_rounded,
                  label: 'Fuel Average',
                  value: _vehicle.fuelAverage > 0 ? '${_vehicle.fuelAverage.toStringAsFixed(1)} km/L' : 'Not Set',
                  accent: Colors.orange,
                  isDark: isDark,
                ),
                _buildSpecCard(
                  icon: Icons.settings_suggest_rounded,
                  label: 'Engine Capacity',
                  value: _vehicle.engineCapacity.isNotEmpty ? _vehicle.engineCapacity : 'Not Set',
                  accent: AppColors.carAccent,
                  isDark: isDark,
                ),
                _buildSpecCard(
                  icon: Icons.settings_input_component_rounded,
                  label: 'Transmission',
                  value: _vehicle.transmissionType.isNotEmpty ? _vehicle.transmissionType : 'Not Set',
                  accent: AppColors.accentPurple,
                  isDark: isDark,
                ),
                _buildSpecCard(
                  icon: Icons.category_rounded,
                  label: 'Model Year / Series',
                  value: _vehicle.model.isNotEmpty ? _vehicle.model : 'Standard',
                  accent: AppColors.accentTeal,
                  isDark: isDark,
                ),
                _buildSpecCard(
                  icon: Icons.style_rounded,
                  label: 'Variant / Trim',
                  value: _vehicle.variant.isNotEmpty ? _vehicle.variant : 'Base',
                  accent: Colors.pinkAccent,
                  isDark: isDark,
                ),
              ],
            ).animate().fadeIn(duration: 400.ms).slideY(begin: 0.1, end: 0, curve: Curves.easeOutBack),

            const SizedBox(height: 24),

            // Maintenance Summary Card
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: isDark ? AppColors.darkCard : AppColors.lightCard,
                borderRadius: BorderRadius.circular(18),
                border: Border.all(color: isDark ? AppColors.darkBorder : AppColors.lightBorder),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Maintenance Overview',
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w700,
                          color: isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary,
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(
                          color: AppColors.primary.withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          '${records.length} Records',
                          style: const TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                            color: AppColors.primary,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Icon(Icons.history_rounded, size: 16, color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary),
                      const SizedBox(width: 8),
                      Text(
                        'Last Serviced: ',
                        style: TextStyle(fontSize: 13, color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary),
                      ),
                      Text(
                        _vehicle.lastServiceDate != null ? dateFormat.format(_vehicle.lastServiceDate!) : 'No records yet',
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.bold,
                          color: isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary,
                        ),
                      ),
                    ],
                  ),
                  if (records.isNotEmpty) ...[
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        const Icon(Icons.payments_rounded, size: 16, color: AppColors.primary),
                        const SizedBox(width: 8),
                        Text(
                          'Total Spent on Services: ',
                          style: TextStyle(fontSize: 13, color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary),
                        ),
                        Text(
                          'Rs. ${numberFormat.format(records.fold(0.0, (acc, r) => acc + r.totalPrice))}',
                          style: const TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.bold,
                            color: AppColors.primary,
                          ),
                        ),
                      ],
                    ),
                  ],
                ],
              ),
            ),

            const SizedBox(height: 16),

            // Share Full Service History Card Button
            Container(
              width: double.infinity,
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [AppColors.primary, AppColors.primaryDark],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(18),
                boxShadow: [
                  BoxShadow(
                    color: AppColors.primary.withValues(alpha: 0.35),
                    blurRadius: 14,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Material(
                color: Colors.transparent,
                borderRadius: BorderRadius.circular(18),
                child: InkWell(
                  borderRadius: BorderRadius.circular(18),
                  onTap: () => _showShareOptionsModal(context, records),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 15),
                    child: Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.2),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: const Icon(Icons.share_rounded, color: Colors.white, size: 22),
                        ),
                        const SizedBox(width: 14),
                        const Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Share Full Service History',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 15,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              SizedBox(height: 2),
                              Text(
                                'Export records as PDF or Excel file',
                                style: TextStyle(
                                  color: Colors.white70,
                                  fontSize: 12,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const Icon(
                          Icons.arrow_forward_ios_rounded,
                          color: Colors.white70,
                          size: 15,
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showShareOptionsModal(BuildContext context, List<ServiceRecord> records) {
    if (records.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('No service records found for this vehicle to share.'),
          backgroundColor: AppColors.errorRed,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        ),
      );
      return;
    }

    final isDark = Theme.of(context).brightness == Brightness.dark;

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        return Container(
          decoration: BoxDecoration(
            color: isDark ? AppColors.darkCard : AppColors.lightCard,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.25),
                blurRadius: 20,
                offset: const Offset(0, -4),
              ),
            ],
          ),
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 28),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Drag handle
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: isDark ? Colors.grey[700] : Colors.grey[300],
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 18),
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: AppColors.primary.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Icon(Icons.share_rounded, color: AppColors.primary, size: 20),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Share Service History',
                          style: TextStyle(
                            fontSize: 17,
                            fontWeight: FontWeight.bold,
                            color: isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary,
                          ),
                        ),
                        Text(
                          '${records.length} records available for ${_vehicle.name}',
                          style: TextStyle(
                            fontSize: 12,
                            color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              // Option 1: PDF Document
              _buildShareFormatTile(
                ctx: ctx,
                title: 'Share as PDF Document',
                subtitle: 'Formatted report with specs, maintenance log & stats',
                icon: Icons.picture_as_pdf_rounded,
                iconColor: const Color(0xFFEF4444),
                badgeText: 'PDF',
                isDark: isDark,
                onTap: () {
                  Navigator.pop(ctx);
                  _sharePdfHistory(records);
                },
              ),
              const SizedBox(height: 12),
              // Option 2: Excel Spreadsheet
              _buildShareFormatTile(
                ctx: ctx,
                title: 'Share as Excel File',
                subtitle: 'Complete data spreadsheet (.xlsx) for Excel & Sheets',
                icon: Icons.table_chart_rounded,
                iconColor: const Color(0xFF10B981),
                badgeText: 'XLSX',
                isDark: isDark,
                onTap: () {
                  Navigator.pop(ctx);
                  _shareExcelHistory(records);
                },
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildShareFormatTile({
    required BuildContext ctx,
    required String title,
    required String subtitle,
    required IconData icon,
    required Color iconColor,
    required String badgeText,
    required bool isDark,
    required VoidCallback onTap,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkCardElevated : AppColors.lightCardElevated,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isDark ? AppColors.darkBorder : AppColors.lightBorder,
        ),
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(16),
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: iconColor.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(icon, color: iconColor, size: 24),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Text(
                            title,
                            style: TextStyle(
                              fontSize: 14.5,
                              fontWeight: FontWeight.w700,
                              color: isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(
                              color: iconColor.withValues(alpha: 0.15),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Text(
                              badgeText,
                              style: TextStyle(
                                fontSize: 9.5,
                                fontWeight: FontWeight.bold,
                                color: iconColor,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 3),
                      Text(
                        subtitle,
                        style: TextStyle(
                          fontSize: 11.5,
                          color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
                Icon(
                  Icons.arrow_forward_ios_rounded,
                  size: 14,
                  color: isDark ? AppColors.darkTextTertiary : AppColors.lightTextTertiary,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _sharePdfHistory(List<ServiceRecord> records) async {
    try {
      final bytes = await PdfGeneratorService.generateFullVehicleServiceReport(
        vehicle: _vehicle,
        records: records,
      );
      final sanitized = _vehicle.name.replaceAll(RegExp(r'[^\w\s\-]'), '').replaceAll(' ', '_');
      await Printing.sharePdf(
        bytes: bytes,
        filename: '${sanitized}_Full_Service_History.pdf',
      );
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error generating PDF report: $e'),
            backgroundColor: AppColors.errorRed,
          ),
        );
      }
    }
  }

  Future<void> _shareExcelHistory(List<ServiceRecord> records) async {
    try {
      await ExcelExporterService.shareFullServiceExcel(
        vehicle: _vehicle,
        records: records,
      );
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error generating Excel spreadsheet: $e'),
            backgroundColor: AppColors.errorRed,
          ),
        );
      }
    }
  }

  Widget _buildSpecCard({
    required IconData icon,
    required String label,
    required String value,
    required Color accent,
    required bool isDark,
  }) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkCard : AppColors.lightCard,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: isDark ? AppColors.darkBorder : AppColors.lightBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Row(
            children: [
              Icon(icon, size: 16, color: accent),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  label,
                  style: TextStyle(
                    fontSize: 11,
                    color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            value,
            style: TextStyle(
              fontSize: 14.5,
              fontWeight: FontWeight.w700,
              color: isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }
}
