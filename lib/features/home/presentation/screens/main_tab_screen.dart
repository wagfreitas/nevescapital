import 'package:flutter/material.dart';
import '../../../auth/presentation/controllers/auth_controller.dart';
import '../../../../core/theme/theme_controller.dart';
import '../../../../shared/components/bottom_tab_bar.dart';
import 'dashboard_screen.dart';
import '../../../profile/presentation/screens/profile_screen.dart';

/// Tela principal com tab bar fixa que gerencia a navegação entre Vendas e Conta
class MainTabScreen extends StatefulWidget {
  final AuthController authController;
  final ThemeController themeController;
  final int initialIndex;

  const MainTabScreen({
    super.key,
    required this.authController,
    required this.themeController,
    this.initialIndex = 0,
  });

  @override
  State<MainTabScreen> createState() => _MainTabScreenState();
}

class _MainTabScreenState extends State<MainTabScreen> {
  late int _currentIndex;

  @override
  void initState() {
    super.initState();
    _currentIndex = widget.initialIndex;
  }

  void _onTabTapped(int index) {
    if (index != _currentIndex) {
      setState(() {
        _currentIndex = index;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF023E25),
      bottomNavigationBar: BottomTabBar(
        isVendasActive: _currentIndex == 0,
        onVendasTap: () => _onTabTapped(0),
        onContaTap: () => _onTabTapped(1),
      ),
      body: IndexedStack(
        index: _currentIndex,
        children: [
          // Tela de Vendas (índice 0)
          DashboardScreen(
            authController: widget.authController,
            themeController: widget.themeController,
          ),
          // Tela de Conta (índice 1)
          ProfileScreen(
            authController: widget.authController,
          ),
        ],
      ),
    );
  }
}

