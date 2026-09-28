import 'package:flutter/material.dart';
import '../../core/constants/app_colors.dart';
import '../dashboard/screens/dashboard_screen.dart';
import '../purchases/screens/purchases_list_screen.dart';
import '../suppliers/screens/suppliers_list_screen.dart';
import '../products/screens/products_catalog_screen.dart';
import '../settings/screens/settings_screen.dart';

import '../sales/screens/mobile_pos_screen.dart';

class MainNavigationScreen extends StatefulWidget {
  const MainNavigationScreen({super.key});

  @override
  State<MainNavigationScreen> createState() => _MainNavigationScreenState();
}

class _MainNavigationScreenState extends State<MainNavigationScreen> {
  int _currentIndex = 0;

  final List<Widget> _screens = const [
    DashboardScreen(),
    MobilePosScreen(),
    PurchasesListScreen(),
    ProductsCatalogScreen(),
    SettingsScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final surface = AppColors.getSurface(isDark);
    final border = AppColors.getBorder(isDark);

    return Scaffold(
      body: IndexedStack(
        index: _currentIndex,
        children: _screens,
      ),
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          color: surface,
          border: Border(top: BorderSide(color: border, width: 1)),
        ),
        child: BottomNavigationBar(
          currentIndex: _currentIndex,
          onTap: (idx) => setState(() => _currentIndex = idx),
          type: BottomNavigationBarType.fixed,
          backgroundColor: surface,
          selectedItemColor: AppColors.primary,
          unselectedItemColor: isDark ? AppColors.darkTextMuted : AppColors.lightTextMuted,
          selectedFontSize: 12,
          unselectedFontSize: 11,
          selectedLabelStyle: const TextStyle(fontWeight: FontWeight.bold),
          elevation: 8,
          items: const [
            BottomNavigationBarItem(
              icon: Icon(Icons.dashboard_rounded),
              label: "الرئيسية",
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.point_of_sale_rounded),
              label: "بيع POS",
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.receipt_long_rounded),
              label: "المشتريات",
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.inventory_2_rounded),
              label: "المنتجات",
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.settings_rounded),
              label: "الإعدادات",
            ),
          ],
        ),
      ),
    );
  }
}
