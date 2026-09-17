import 'package:flutter/material.dart';
import '../constants/app_colors.dart';

class AnimatedViewSwitcher extends StatelessWidget {
  final bool isGrid;
  final ValueChanged<bool> onChanged;

  const AnimatedViewSwitcher({
    super.key,
    required this.isGrid,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkCardElevated : AppColors.lightCardElevated,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: isDark ? AppColors.darkBorder : AppColors.lightBorder,
          width: 0.8,
        ),
      ),
      padding: const EdgeInsets.all(3),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          _buildButton(
            icon: Icons.view_list_rounded,
            isSelected: !isGrid,
            isDark: isDark,
            tooltip: 'List View',
            onTap: () => onChanged(false),
          ),
          _buildButton(
            icon: Icons.grid_view_rounded,
            isSelected: isGrid,
            isDark: isDark,
            tooltip: 'Grid View',
            onTap: () => onChanged(true),
          ),
        ],
      ),
    );
  }

  Widget _buildButton({
    required IconData icon,
    required bool isSelected,
    required bool isDark,
    required String tooltip,
    required VoidCallback onTap,
  }) {
    return Tooltip(
      message: tooltip,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(7),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
          decoration: BoxDecoration(
            color: isSelected
                ? (isDark ? AppColors.primary : Colors.white)
                : Colors.transparent,
            borderRadius: BorderRadius.circular(7),
            boxShadow: isSelected
                ? [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.08),
                      blurRadius: 4,
                      offset: const Offset(0, 1),
                    )
                  ]
                : null,
          ),
          child: Icon(
            icon,
            size: 18,
            color: isSelected
                ? (isDark ? Colors.white : AppColors.primaryDark)
                : (isDark ? AppColors.darkTextTertiary : AppColors.lightTextTertiary),
          ),
        ),
      ),
    );
  }
}
