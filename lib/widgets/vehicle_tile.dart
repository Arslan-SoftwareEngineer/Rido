import 'dart:io';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../models/vehicle.dart';
import '../models/vehicle_type.dart';
import '../constants/app_colors.dart';

class VehicleTile extends StatefulWidget {
  final Vehicle vehicle;
  final VoidCallback onTap;
  final VoidCallback? onLongPress;
  final int index;

  const VehicleTile({
    super.key,
    required this.vehicle,
    required this.onTap,
    this.onLongPress,
    this.index = 0,
  });

  @override
  State<VehicleTile> createState() => _VehicleTileState();
}

class _VehicleTileState extends State<VehicleTile> {
  bool _isPressed = false;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final numberFormat = NumberFormat('#,###');
    final dateFormat = DateFormat('dd/MM/yyyy');

    final lastServiceText = widget.vehicle.lastServiceDate != null
        ? dateFormat.format(widget.vehicle.lastServiceDate!)
        : 'No records yet';

    final isCar = widget.vehicle.type == VehicleType.car;
    final accentColor = isCar ? AppColors.carAccent : AppColors.bikeAccent;

    return AnimatedScale(
      scale: _isPressed ? 0.97 : 1.0,
      duration: const Duration(milliseconds: 120),
      curve: Curves.easeOut,
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: isDark ? AppColors.darkCard : AppColors.lightCard,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isDark ? AppColors.darkBorder : AppColors.lightBorder,
            width: 1,
          ),
          boxShadow: [
            BoxShadow(
              color: isDark ? Colors.black.withValues(alpha: 0.3) : Colors.black.withValues(alpha: 0.04),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Material(
          color: Colors.transparent,
          borderRadius: BorderRadius.circular(20),
          child: InkWell(
            borderRadius: BorderRadius.circular(20),
            onTapDown: (_) => setState(() => _isPressed = true),
            onTapUp: (_) => setState(() => _isPressed = false),
            onTapCancel: () => setState(() => _isPressed = false),
            onTap: widget.onTap,
            onLongPress: () {
              setState(() => _isPressed = false);
              widget.onLongPress?.call();
            },
            child: Padding(
              padding: const EdgeInsets.all(14),
              child: Row(
                children: [
                  // Vehicle Picture
                  Hero(
                    tag: 'vehicle_image_${widget.vehicle.id}',
                    child: Container(
                      width: 88,
                      height: 88,
                      decoration: BoxDecoration(
                        color: isDark ? AppColors.darkCardElevated : AppColors.lightCardElevated,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: accentColor.withValues(alpha: 0.3),
                          width: 1.5,
                        ),
                      ),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(14.5),
                        child: widget.vehicle.imagePath != null &&
                                File(widget.vehicle.imagePath!).existsSync()
                            ? Image.file(
                                File(widget.vehicle.imagePath!),
                                fit: BoxFit.cover,
                              )
                            : Center(
                                child: Icon(
                                  isCar ? Icons.directions_car_filled_rounded : Icons.two_wheeler_rounded,
                                  size: 42,
                                  color: accentColor.withValues(alpha: 0.7),
                                ),
                              ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),

                  // Vehicle Details
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Name & Badge
                        Row(
                          children: [
                            Expanded(
                              child: Text(
                                widget.vehicle.name,
                                style: TextStyle(
                                  fontSize: 17,
                                  fontWeight: FontWeight.w700,
                                  letterSpacing: -0.3,
                                  color: isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                              decoration: BoxDecoration(
                                color: accentColor.withValues(alpha: 0.15),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Text(
                                widget.vehicle.type.displayName.toUpperCase(),
                                style: TextStyle(
                                  fontSize: 10,
                                  fontWeight: FontWeight.w800,
                                  color: accentColor,
                                  letterSpacing: 0.5,
                                ),
                              ),
                            ),
                          ],
                        ),

                        // Model & Variant
                        if (widget.vehicle.model.isNotEmpty || widget.vehicle.variant.isNotEmpty)
                          Padding(
                            padding: const EdgeInsets.only(top: 2),
                            child: Text(
                              '${widget.vehicle.model} ${widget.vehicle.variant}'.trim(),
                              style: TextStyle(
                                fontSize: 13,
                                color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),

                        const SizedBox(height: 10),

                        // Mileage & Last Service Chips
                        Wrap(
                          spacing: 8,
                          runSpacing: 4,
                          children: [
                            // Mileage
                            _infoChip(
                              icon: Icons.speed_rounded,
                              label: '${numberFormat.format(widget.vehicle.mileage)} km',
                              color: AppColors.primary,
                              isDark: isDark,
                            ),
                            // Last Service Date
                            _infoChip(
                              icon: Icons.calendar_month_rounded,
                              label: lastServiceText,
                              color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary,
                              isDark: isDark,
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),

                  // Chevron indicator
                  Icon(
                    Icons.chevron_right_rounded,
                    color: isDark ? AppColors.darkTextTertiary : AppColors.lightTextTertiary,
                    size: 24,
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    )
        .animate()
        .fadeIn(
          duration: 350.ms,
          delay: Duration(milliseconds: 50 * widget.index),
          curve: Curves.easeOut,
        )
        .slideY(
          begin: 0.15,
          end: 0,
          duration: 400.ms,
          delay: Duration(milliseconds: 50 * widget.index),
          curve: Curves.easeOutBack,
        );
  }

  Widget _infoChip({
    required IconData icon,
    required String label,
    required Color color,
    required bool isDark,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkCardElevated : AppColors.lightCardElevated,
        borderRadius: BorderRadius.circular(6),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 12, color: color),
          const SizedBox(width: 4),
          Text(
            label,
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: color,
            ),
          ),
        ],
      ),
    );
  }
}
