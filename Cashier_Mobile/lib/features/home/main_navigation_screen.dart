import 'package:flutter/material.dart';
import '../../core/constants/app_colors.dart';
import '../dashboard/screens/dashboard_screen.dart';
import '../dashboard/screens/monthly_report_screen.dart';
import '../debts/screens/debts_screen.dart';
import '../expenses/screens/expenses_screen.dart';
import '../notifications/screens/low_stock_notifications_screen.dart';
import '../notifications/screens/shift_summaries_screen.dart';
import '../products/screens/add_edit_product_screen.dart';
import '../products/screens/brands_list_screen.dart';
import '../products/screens/categories_list_screen.dart';
import '../products/screens/offers_screen.dart';
import '../products/screens/price_check_screen.dart';
import '../products/screens/products_catalog_screen.dart';
import '../purchases/screens/create_purchase_screen.dart';
import '../purchases/screens/purchases_list_screen.dart';
import '../returns/screens/returns_list_screen.dart';
import '../sales/screens/installments_screen.dart';
import '../sales/screens/mobile_pos_screen.dart';
import '../sales/screens/reservations_screen.dart';
import '../sales/screens/sales_list_screen.dart';
import '../settings/screens/settings_screen.dart';
import '../settings/screens/users_list_screen.dart';
import '../suppliers/screens/suppliers_list_screen.dart';

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

  void _openQuickHubModal(BuildContext context, bool isDark) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => _buildHubSheet(ctx, isDark),
    );
  }

  Widget _buildHubSheet(BuildContext ctx, bool isDark) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.getSurface(isDark),
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        border: Border(top: BorderSide(color: AppColors.getBorder(isDark), width: 1.5)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.3),
            blurRadius: 20,
            offset: const Offset(0, -5),
          ),
        ],
      ),
      child: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(18, 12, 18, 24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Handle
              Center(
                child: Container(
                  width: 48,
                  height: 4.5,
                  decoration: BoxDecoration(
                    color: AppColors.getBorder(isDark),
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
              ),
              const SizedBox(height: 14),

              // Title
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      gradient: AppColors.primaryGradient,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(Icons.grid_view_rounded, color: Colors.white, size: 20),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          "مركز الشاشات والعمليات السريعة",
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: AppColors.getTextPrimary(isDark),
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                        Text(
                          "وصول مباشر لجميع صفحات المنظومة المتزامنة مع الديسكتوب",
                          style: TextStyle(
                            fontSize: 11,
                            color: AppColors.getTextMuted(isDark),
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const Divider(height: 24),

              // 1. المبيعات والـ POS
              _buildCategoryHeader("المبيعات والكاشير والعملاء", Icons.point_of_sale_rounded, AppColors.primaryLight, isDark),
              const SizedBox(height: 8),
              _buildHubGrid([
                _HubItem(
                  title: "كاشير الصالة (POS)",
                  icon: Icons.qr_code_scanner_rounded,
                  color: AppColors.primaryLight,
                  onTap: () => _navigate(ctx, const MobilePosScreen()),
                ),
                _HubItem(
                  title: "فواتير المبيعات",
                  icon: Icons.receipt_long_rounded,
                  color: AppColors.cyan,
                  onTap: () => _navigate(ctx, const SalesListScreen()),
                ),
                _HubItem(
                  title: "عقود التقسيط",
                  icon: Icons.payments_rounded,
                  color: AppColors.success,
                  onTap: () => _navigate(ctx, const InstallmentsScreen()),
                ),
                _HubItem(
                  title: "حجوزات الأجهزة",
                  icon: Icons.bookmark_added_rounded,
                  color: AppColors.accent,
                  onTap: () => _navigate(ctx, const ReservationsScreen()),
                ),
                _HubItem(
                  title: "مرتجع المبيعات",
                  icon: Icons.assignment_return_rounded,
                  color: AppColors.danger,
                  onTap: () => _navigate(ctx, const ReturnsListScreen()),
                ),
              ], isDark),

              const SizedBox(height: 18),

              // 2. المشتريات والموردين
              _buildCategoryHeader("المشتريات والموردين", Icons.shopping_cart_rounded, AppColors.success, isDark),
              const SizedBox(height: 8),
              _buildHubGrid([
                _HubItem(
                  title: "فواتير الشراء",
                  icon: Icons.receipt_rounded,
                  color: AppColors.primary,
                  onTap: () => _navigate(ctx, const PurchasesListScreen()),
                ),
                _HubItem(
                  title: "تسجيل فاتورة شراء",
                  icon: Icons.add_shopping_cart_rounded,
                  color: AppColors.cyan,
                  onTap: () => _navigate(ctx, const CreatePurchaseScreen()),
                ),
                _HubItem(
                  title: "دليل الموردين",
                  icon: Icons.people_alt_rounded,
                  color: AppColors.success,
                  onTap: () => _navigate(ctx, const SuppliersListScreen()),
                ),
                _HubItem(
                  title: "مرتجع مشتريات",
                  icon: Icons.reply_all_rounded,
                  color: AppColors.danger,
                  onTap: () => _navigate(ctx, const ReturnsListScreen()),
                ),
              ], isDark),

              const SizedBox(height: 18),

              // 3. الأصناف والأجهزة والمخزن
              _buildCategoryHeader("كتالوج الأجهزة والمخزون", Icons.inventory_2_rounded, AppColors.cyan, isDark),
              const SizedBox(height: 8),
              _buildHubGrid([
                _HubItem(
                  title: "كتالوج المنتجات",
                  icon: Icons.grid_view_rounded,
                  color: AppColors.cyan,
                  onTap: () => _navigate(ctx, const ProductsCatalogScreen()),
                ),
                _HubItem(
                  title: "استعلام الأسعار",
                  icon: Icons.price_check_rounded,
                  color: AppColors.success,
                  onTap: () => _navigate(ctx, const PriceCheckScreen()),
                ),
                _HubItem(
                  title: "إضافة جهاز جديد",
                  icon: Icons.add_box_rounded,
                  color: AppColors.primaryLight,
                  onTap: () => _navigate(ctx, const AddEditProductScreen()),
                ),
                _HubItem(
                  title: "الماركات التجارية",
                  icon: Icons.verified_rounded,
                  color: AppColors.accent,
                  onTap: () => _navigate(ctx, const BrandsListScreen()),
                ),
                _HubItem(
                  title: "أقسام وتصنيفات",
                  icon: Icons.category_rounded,
                  color: AppColors.purple,
                  onTap: () => _navigate(ctx, const CategoriesListScreen()),
                ),
                _HubItem(
                  title: "عروض وبكجات",
                  icon: Icons.card_giftcard_rounded,
                  color: AppColors.orange,
                  onTap: () => _navigate(ctx, const OffersScreen()),
                ),
              ], isDark),

              const SizedBox(height: 18),

              // 4. الحسابات والمالية
              _buildCategoryHeader("الحسابات والتقارير المالية", Icons.account_balance_rounded, AppColors.warning, isDark),
              const SizedBox(height: 8),
              _buildHubGrid([
                _HubItem(
                  title: "مركز الديون والآجل",
                  icon: Icons.handshake_rounded,
                  color: AppColors.warning,
                  onTap: () => _navigate(ctx, const DebtsScreen()),
                ),
                _HubItem(
                  title: "المصروفات والنثريات",
                  icon: Icons.outbox_rounded,
                  color: AppColors.danger,
                  onTap: () => _navigate(ctx, const ExpensesScreen()),
                ),
                _HubItem(
                  title: "التقرير المالي الشهري",
                  icon: Icons.calendar_month_rounded,
                  color: AppColors.cyan,
                  onTap: () => _navigate(ctx, const MonthlyReportScreen()),
                ),
              ], isDark),

              const SizedBox(height: 18),

              // 5. الرقابة والورديات
              _buildCategoryHeader("الرقابة والورديات والتنبيهات", Icons.security_rounded, AppColors.purple, isDark),
              const SizedBox(height: 8),
              _buildHubGrid([
                _HubItem(
                  title: "نواقص المخزون",
                  icon: Icons.warning_amber_rounded,
                  color: AppColors.warning,
                  onTap: () => _navigate(ctx, const LowStockNotificationsScreen()),
                ),
                _HubItem(
                  title: "تقارير الورديات والدرج",
                  icon: Icons.assignment_turned_in_rounded,
                  color: AppColors.primaryLight,
                  onTap: () => _navigate(ctx, const ShiftSummariesScreen()),
                ),

                _HubItem(
                  title: "المستخدمين وفريق العمل",
                  icon: Icons.badge_rounded,
                  color: AppColors.cyan,
                  onTap: () => _navigate(ctx, const UsersListScreen()),
                ),
                _HubItem(
                  title: "إعدادات الربط والمزامنة",
                  icon: Icons.cloud_sync_rounded,
                  color: AppColors.success,
                  onTap: () => _navigate(ctx, const SettingsScreen()),
                ),
              ], isDark),
            ],
          ),
        ),
      ),
    );
  }

  void _navigate(BuildContext ctx, Widget screen) {
    Navigator.pop(ctx);
    Navigator.push(context, MaterialPageRoute(builder: (_) => screen));
  }

  Widget _buildCategoryHeader(String title, IconData icon, Color color, bool isDark) {
    return Row(
      children: [
        Icon(icon, size: 16, color: color),
        const SizedBox(width: 8),
        Text(
          title,
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.bold,
            color: AppColors.getTextPrimary(isDark),
          ),
        ),
      ],
    );
  }

  Widget _buildHubGrid(List<_HubItem> items, bool isDark) {
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3,
        crossAxisSpacing: 8,
        mainAxisSpacing: 8,
        childAspectRatio: 1.15,
      ),
      itemCount: items.length,
      itemBuilder: (ctx, idx) {
        final item = items[idx];
        return InkWell(
          borderRadius: BorderRadius.circular(14),
          onTap: item.onTap,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 8),
            decoration: BoxDecoration(
              color: isDark ? AppColors.darkSurfaceElevated : AppColors.lightSurfaceElevated,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: item.color.withOpacity(0.25)),
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  padding: const EdgeInsets.all(7),
                  decoration: BoxDecoration(
                    color: item.color.withOpacity(0.12),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(item.icon, color: item.color, size: 20),
                ),
                const SizedBox(height: 6),
                Text(
                  item.title,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 10.5,
                    fontWeight: FontWeight.bold,
                    color: AppColors.getTextPrimary(isDark),
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        );
      },
    );
  }

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
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.06),
              blurRadius: 10,
              offset: const Offset(0, -3),
            ),
          ],
        ),
        child: BottomNavigationBar(
          currentIndex: _currentIndex >= 2 ? _currentIndex + 1 : _currentIndex,
          onTap: (idx) {
            if (idx == 2) {
              // Open quick hub modal
              _openQuickHubModal(context, isDark);
            } else if (idx > 2) {
              setState(() => _currentIndex = idx - 1);
            } else {
              setState(() => _currentIndex = idx);
            }
          },
          type: BottomNavigationBarType.fixed,
          backgroundColor: surface,
          selectedItemColor: AppColors.primaryLight,
          unselectedItemColor: isDark ? AppColors.darkTextMuted : AppColors.lightTextMuted,
          selectedFontSize: 11,
          unselectedFontSize: 10.5,
          selectedLabelStyle: const TextStyle(fontWeight: FontWeight.bold),
          elevation: 0,
          items: [
            const BottomNavigationBarItem(
              icon: Icon(Icons.dashboard_rounded),
              label: "الرئيسية",
            ),
            const BottomNavigationBarItem(
              icon: Icon(Icons.point_of_sale_rounded),
              label: "بيع POS",
            ),
            BottomNavigationBarItem(
              icon: Container(
                padding: const EdgeInsets.all(6),
                decoration: const BoxDecoration(
                  gradient: AppColors.primaryGradient,
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.grid_view_rounded, color: Colors.white, size: 20),
              ),
              label: "الشاشات",
            ),
            const BottomNavigationBarItem(
              icon: Icon(Icons.receipt_long_rounded),
              label: "المشتريات",
            ),
            const BottomNavigationBarItem(
              icon: Icon(Icons.inventory_2_rounded),
              label: "المنتجات",
            ),
          ],
        ),
      ),
    );
  }
}

class _HubItem {
  final String title;
  final IconData icon;
  final Color color;
  final VoidCallback onTap;

  const _HubItem({
    required this.title,
    required this.icon,
    required this.color,
    required this.onTap,
  });
}
