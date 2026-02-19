import 'package:flutter/material.dart';
import 'package:neves_capital/core/theme/app_theme.dart';

/// Tab bar inferior reutilizável para navegação entre Vendas e Conta
class BottomTabBar extends StatelessWidget {
  final bool isVendasActive;
  final VoidCallback? onVendasTap;
  final VoidCallback? onContaTap;

  const BottomTabBar({
    super.key,
    required this.isVendasActive,
    this.onVendasTap,
    this.onContaTap,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppTheme.cardColor,
        border: Border(
          top: BorderSide(color: AppTheme.borderColor),
        ),
      ),
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              // Botão Vendas
              _buildTabButton(
                context,
                icon: Icons.check_circle,
                label: 'Vendas',
                isActive: isVendasActive,
                onTap: onVendasTap,
              ),
              
              // Botão Conta
              _buildTabButton(
                context,
                icon: Icons.person,
                label: 'Conta',
                isActive: !isVendasActive,
                onTap: onContaTap,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTabButton(
    BuildContext context, {
    required IconData icon,
    required String label,
    required bool isActive,
    required VoidCallback? onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(12),
          splashColor: AppTheme.primaryColor.withValues(alpha: 0.2),
          highlightColor: AppTheme.primaryColor.withValues(alpha: 0.1),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            decoration: BoxDecoration(
              color: isActive ? AppTheme.primaryColor.withValues(alpha: 0.1) : Colors.transparent,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 24,
                  height: 24,
                  decoration: BoxDecoration(
                    color: isActive ? AppTheme.primaryColor : Colors.grey[600],
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    icon,
                    color: Colors.white,
                    size: 16,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  label,
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                    color: isActive ? AppTheme.primaryColor : Colors.grey[600],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

