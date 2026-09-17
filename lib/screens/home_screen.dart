import 'package:flutter/material.dart';
import '../models/vehicle.dart';
import '../models/vehicle_type.dart';
import '../constants/app_colors.dart';
import '../services/storage_service.dart';
import '../services/theme_service.dart';
import '../widgets/rido_logo.dart';
import '../widgets/vehicle_tile.dart';
import 'add_edit_vehicle_screen.dart';
import 'vehicle_records_screen.dart';

class HomeScreen extends StatefulWidget {
  final StorageService storageService;
  final ThemeService themeService;

  const HomeScreen({
    super.key,
    required this.storageService,
    required this.themeService,
  });

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  VehicleType _currentTab = VehicleType.car;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _tabController.addListener(() {
      if (!_tabController.indexIsChanging) {
        setState(() {
          _currentTab = _tabController.index == 0 ? VehicleType.car : VehicleType.bike;
        });
      }
    });
    widget.storageService.addListener(_onStorageChange);
    widget.themeService.addListener(_onThemeChange);
  }

  @override
  void dispose() {
    _tabController.dispose();
    widget.storageService.removeListener(_onStorageChange);
    widget.themeService.removeListener(_onThemeChange);
    super.dispose();
  }

  void _onStorageChange() {
    if (mounted) setState(() {});
  }

  void _onThemeChange() {
    if (mounted) setState(() {});
  }

  void _openAddVehicle() {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => AddEditVehicleScreen(
          storageService: widget.storageService,
          initialType: _currentTab,
        ),
      ),
    );
  }

  void _openVehicleDetail(Vehicle vehicle) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => VehicleRecordsScreen(
          vehicle: vehicle,
          storageService: widget.storageService,
        ),
      ),
    );
  }

  void _showVehicleOptions(Vehicle vehicle) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    showModalBottomSheet(
      context: context,
      backgroundColor: isDark ? AppColors.darkSurface : AppColors.lightSurface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 8),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Drag handle
              Container(
                margin: const EdgeInsets.only(top: 6, bottom: 12),
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: isDark ? AppColors.darkBorder : AppColors.lightBorder,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              // Vehicle Header
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 6),
                child: Row(
                  children: [
                    Icon(
                      vehicle.type == VehicleType.car ? Icons.directions_car_filled_rounded : Icons.two_wheeler_rounded,
                      color: vehicle.type == VehicleType.car ? AppColors.carAccent : AppColors.bikeAccent,
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            vehicle.name,
                            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                          ),
                          Text(
                            '${vehicle.model} ${vehicle.variant}'.trim(),
                            style: TextStyle(fontSize: 12, color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const Divider(height: 16),
              // Option 1: Edit Profile
              ListTile(
                leading: const Icon(Icons.edit_rounded, color: AppColors.primary),
                title: const Text('Edit Vehicle Profile', style: TextStyle(fontWeight: FontWeight.w600)),
                subtitle: const Text('Update specifications, mileage, and photo', style: TextStyle(fontSize: 11)),
                onTap: () {
                  Navigator.pop(context);
                  Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (context) => AddEditVehicleScreen(
                        storageService: widget.storageService,
                        vehicleToEdit: vehicle,
                        initialType: vehicle.type,
                      ),
                    ),
                  );
                },
              ),
              // Option 2: Delete Vehicle
              ListTile(
                leading: const Icon(Icons.delete_forever_rounded, color: AppColors.errorRed),
                title: Text('Delete ${vehicle.name}', style: const TextStyle(fontWeight: FontWeight.w600, color: AppColors.errorRed)),
                subtitle: const Text('Deletes vehicle, all service records, photos & PDFs', style: TextStyle(fontSize: 11, color: AppColors.errorRed)),
                onTap: () {
                  Navigator.pop(context);
                  _confirmDeleteVehicle(vehicle);
                },
              ),
              const SizedBox(height: 8),
            ],
          ),
        ),
      ),
    );
  }

  void _confirmDeleteVehicle(Vehicle vehicle) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Delete ${vehicle.name}?'),
        content: Text(
          'Are you sure you want to delete ${vehicle.name}? This will permanently remove all maintenance records, uploaded photos, and generated PDF reports associated with this vehicle.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              final messenger = ScaffoldMessenger.of(context);
              Navigator.pop(context);
              await widget.storageService.deleteVehicle(vehicle.id);
              messenger.showSnackBar(
                SnackBar(
                  content: Text('${vehicle.name} and all associated data deleted'),
                  behavior: SnackBarBehavior.floating,
                ),
              );
            },
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.errorRed, foregroundColor: Colors.white),
            child: const Text('Delete Permanently'),
          ),
        ],
      ),
    );
  }

  void _showThemeDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Appearance & Theme'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _buildThemeOption(
              context: context,
              icon: Icons.brightness_auto_rounded,
              iconColor: Colors.blueGrey,
              title: 'System Aligned',
              mode: ThemeMode.system,
            ),
            const SizedBox(height: 6),
            _buildThemeOption(
              context: context,
              icon: Icons.light_mode_rounded,
              iconColor: Colors.amber,
              title: 'Light Mode',
              mode: ThemeMode.light,
            ),
            const SizedBox(height: 6),
            _buildThemeOption(
              context: context,
              icon: Icons.dark_mode_rounded,
              iconColor: Colors.indigoAccent,
              title: 'Dark Mode',
              mode: ThemeMode.dark,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildThemeOption({
    required BuildContext context,
    required IconData icon,
    required Color iconColor,
    required String title,
    required ThemeMode mode,
  }) {
    final isSelected = widget.themeService.themeMode == mode;
    return InkWell(
      borderRadius: BorderRadius.circular(12),
      onTap: () {
        widget.themeService.setThemeMode(mode);
        Navigator.pop(context);
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.primary.withValues(alpha: 0.12) : Colors.transparent,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected ? AppColors.primary : Colors.transparent,
            width: 1.5,
          ),
        ),
        child: Row(
          children: [
            Icon(icon, size: 22, color: iconColor),
            const SizedBox(width: 14),
            Expanded(
              child: Text(
                title,
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                ),
              ),
            ),
            if (isSelected)
              const Icon(Icons.check_circle_rounded, size: 20, color: AppColors.primary),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final cars = widget.storageService.getVehiclesByType(VehicleType.car);
    final bikes = widget.storageService.getVehiclesByType(VehicleType.bike);

    return Scaffold(
      backgroundColor: isDark ? AppColors.darkBackground : AppColors.lightBackground,
      appBar: AppBar(
        title: const RidoLogo(size: 34, fontSize: 21),
        actions: [
          // Theme Switcher Button (System, Light, Dark)
          IconButton(
            icon: Icon(widget.themeService.currentThemeIcon),
            tooltip: 'Theme: ${widget.themeService.currentThemeName}',
            onPressed: _showThemeDialog,
          ),
          const SizedBox(width: 6),
        ],
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(56),
          child: Container(
            margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
            decoration: BoxDecoration(
              color: isDark ? AppColors.darkCardElevated : AppColors.lightCardElevated,
              borderRadius: BorderRadius.circular(16),
            ),
            child: TabBar(
              controller: _tabController,
              indicatorSize: TabBarIndicatorSize.tab,
              dividerColor: Colors.transparent,
              indicator: BoxDecoration(
                borderRadius: BorderRadius.circular(14),
                color: _currentTab == VehicleType.car ? AppColors.carAccent : AppColors.bikeAccent,
                boxShadow: [
                  BoxShadow(
                    color: (_currentTab == VehicleType.car ? AppColors.carAccent : AppColors.bikeAccent)
                        .withValues(alpha: 0.3),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              labelColor: Colors.white,
              unselectedLabelColor: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary,
              labelStyle: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
              tabs: [
                Tab(
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.directions_car_filled_rounded, size: 18),
                      const SizedBox(width: 8),
                      Text('Cars (${cars.length})'),
                    ],
                  ),
                ),
                Tab(
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.two_wheeler_rounded, size: 18),
                      const SizedBox(width: 8),
                      Text('Bikes (${bikes.length})'),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        physics: const BouncingScrollPhysics(),
        children: [
          // Cars Tab
          _buildVehicleList(
            vehicles: cars,
            type: VehicleType.car,
            isDark: isDark,
          ),
          // Bikes Tab
          _buildVehicleList(
            vehicles: bikes,
            type: VehicleType.bike,
            isDark: isDark,
          ),
        ],
      ),
      // Circular plus button to add cars / bikes (no text, enlarged '+' icon)
      floatingActionButton: SizedBox(
        width: 62,
        height: 62,
        child: FloatingActionButton(
          onPressed: _openAddVehicle,
          backgroundColor: AppColors.primary,
          foregroundColor: Colors.white,
          elevation: 6,
          shape: const CircleBorder(),
          tooltip: 'Add ${_currentTab.displayName}',
          child: const Icon(Icons.add_rounded, size: 36),
        ),
      ),
    );
  }

  Widget _buildVehicleList({
    required List<Vehicle> vehicles,
    required VehicleType type,
    required bool isDark,
  }) {
    if (vehicles.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 88,
              height: 88,
              decoration: BoxDecoration(
                color: isDark ? AppColors.darkCard : AppColors.lightCardElevated,
                shape: BoxShape.circle,
              ),
              child: Icon(
                type == VehicleType.car ? Icons.directions_car_rounded : Icons.two_wheeler_rounded,
                size: 46,
                color: isDark ? AppColors.darkTextTertiary : AppColors.lightTextTertiary,
              ),
            ),
            const SizedBox(height: 16),
            Text(
              'No ${type.pluralName} Added Yet',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              'Add your first ${type.displayName.toLowerCase()} to track maintenance records & generate reports.',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 13,
                color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary,
              ),
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: _openAddVehicle,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
                shape: const CircleBorder(),
                padding: const EdgeInsets.all(18),
                elevation: 4,
              ),
              child: const Icon(Icons.add_rounded, size: 36),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.only(top: 8, bottom: 80),
      physics: const BouncingScrollPhysics(),
      itemCount: vehicles.length,
      itemBuilder: (context, index) {
        final vehicle = vehicles[index];
        return VehicleTile(
          vehicle: vehicle,
          index: index,
          onTap: () => _openVehicleDetail(vehicle),
          onLongPress: () => _showVehicleOptions(vehicle),
        );
      },
    );
  }
}
