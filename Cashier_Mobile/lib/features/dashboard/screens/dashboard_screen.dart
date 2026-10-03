import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/theme/theme_provider.dart';
import '../../../core/widgets/offline_banner.dart';
import '../../../core/widgets/sync_status_badge.dart';
import '../../auth/providers/auth_provider.dart';
import '../../debts/screens/debts_screen.dart';
import '../../expenses/screens/expenses_screen.dart';
import '../../products/screens/add_edit_product_screen.dart';
import '../../purchases/screens/create_purchase_screen.dart';
import '../../purchases/screens/purchase_detail_screen.dart';
import '../../purchases/screens/purchases_list_screen.dart';
import '../../notifications/providers/notifications_provider.dart';
import '../../notifications/screens/expiry_notifications_screen.dart';
import '../../notifications/screens/low_stock_notifications_screen.dart';
import '../../notifications/screens/shift_summaries_screen.dart';
import '../../returns/screens/returns_list_screen.dart';
import '../../sales/screens/mobile_pos_screen.dart';
import '../../products/screens/price_check_screen.dart';
import 'monthly_report_screen.dart';
import '../../sales/screens/installments_screen.dart';
import '../../sales/screens/reservations_screen.dart';
import '../models/dashboard_model.dart';
import '../providers/dashboard_provider.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Provider.of<DashboardProvider>(context, listen: false).fetchDashboardStats();
      Provider.of<AuthProvider>(context, listen: false).fetchStoreSettings();
      Provider.of<NotificationsProvider>(context, listen: false).fetchAllNotifications();
    });
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Provider.of<ThemeProvider>(context).isDarkMode;
    final themeProv = Provider.of<ThemeProvider>(context, listen: false);
    final auth = Provider.of<AuthProvider>(context);
    final dash = Provider.of<DashboardProvider>(context);
    final stats = dash.stats;
    final currencyFormatter = NumberFormat("#,##0.00", "ar_EG");

    return Scaffold(
      backgroundColor: AppColors.getBackground(isDark),
      appBar: AppBar(
        backgroundColor: AppColors.getSurface(isDark),
        elevation: 0,
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              auth.shopName,
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppColors.getTextPrimary(isDark)),
            ),
            Text(
              "مرحباً، ${auth.userName}",
              style: const TextStyle(fontSize: 12, color: AppColors.primaryLight),
            ),
          ],
        ),
        actions: [
          Consumer<NotificationsProvider>(
            builder: (context, notif, _) {
              final count = notif.totalAlertsCount;
              return Stack(
                alignment: Alignment.center,
                children: [
                  IconButton(
                    icon: Icon(Icons.notifications_outlined, color: AppColors.getTextPrimary(isDark)),
                    tooltip: "التنبيهات والإشعارات",
                    onPressed: () => _openNotificationsSheet(context, notif, isDark),
                  ),
                  if (count > 0)
                    Positioned(
                      top: 8,
                      right: 8,
                      child: Container(
                        padding: const EdgeInsets.all(4),
                        decoration: const BoxDecoration(
                          color: AppColors.danger,
                          shape: BoxShape.circle,
                        ),
                        child: Text(
                          '$count',
                          style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold),
                        ),
                      ),
                    ),
                ],
              );
            },
          ),
          IconButton(
            icon: const Icon(Icons.price_check_rounded, color: AppColors.cyan, size: 26),
            tooltip: "استعلام الأسعار (باركود + اسم)",
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const PriceCheckScreen()),
              );
            },
          ),
          IconButton(
            icon: Icon(
              isDark ? Icons.light_mode_rounded : Icons.dark_mode_rounded,
              color: isDark ? Colors.amber : AppColors.primary,
            ),
            tooltip: isDark ? "تفعيل الوضع الفاتح" : "تفعيل الوضع الداكن",
            onPressed: () => themeProv.toggleTheme(),
          ),
          IconButton(
            icon: Icon(Icons.refresh_rounded, color: AppColors.getTextPrimary(isDark)),
            onPressed: () {
              dash.fetchDashboardStats();
              auth.fetchStoreSettings();
              Provider.of<NotificationsProvider>(context, listen: false).fetchAllNotifications();
            },
          ),
        ],
      ),
      body: Column(
        children: [
          const OfflineBanner(),
          Expanded(
            child: dash.isLoading && stats == null
                ? const Center(child: CircularProgressIndicator(color: AppColors.primaryLight))
                : RefreshIndicator(
                    color: AppColors.primaryLight,
                    backgroundColor: AppColors.getSurface(isDark),
                    onRefresh: () => dash.fetchDashboardStats(),
                    child: SingleChildScrollView(
                      physics: const AlwaysScrollableScrollPhysics(),
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Pending Sync Alert Card (if any)
                          if ((stats?.pendingSyncPurchasesCount ?? 0) > 0)
                            Container(
                              margin: const EdgeInsets.only(bottom: 16),
                              padding: const EdgeInsets.all(14),
                              decoration: BoxDecoration(
                                color: AppColors.pendingSync.withOpacity(0.12),
                                borderRadius: BorderRadius.circular(14),
                                border: Border.all(color: AppColors.pendingSync.withOpacity(0.4)),
                              ),
                              child: Row(
                                children: [
                                  Container(
                                    padding: const EdgeInsets.all(8),
                                    decoration: BoxDecoration(
                                      color: AppColors.pendingSync.withOpacity(0.2),
                                      shape: BoxShape.circle,
                                    ),
                                    child: const Icon(Icons.cloud_upload_outlined, color: AppColors.pendingSync, size: 22),
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          "يوجد ${stats!.pendingSyncPurchasesCount} فواتير بانتظار المزامنة",
                                          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: AppColors.pendingSync),
                                        ),
                                        const SizedBox(height: 2),
                                        Text(
                                          "سيتم سحبها تلقائياً لكاشير المحل خلال ثوانٍ.",
                                          style: TextStyle(fontSize: 11, color: AppColors.getTextMuted(isDark)),
                                        ),
                                      ],
                                    ),
                                  ),
                                  TextButton(
                                    onPressed: () {
                                      Navigator.push(
                                        context,
                                        MaterialPageRoute(builder: (_) => const PurchasesListScreen(initialFilter: 'PendingSync')),
                                      );
                                    },
                                    child: const Text("عرض", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: AppColors.pendingSync)),
                                  ),
                                ],
                              ),
                            ),

                          // Active Notifications Alerts Banner (Expiry / Shift Closures)
                          Consumer<NotificationsProvider>(
                            builder: (context, notif, _) {
                              final unreadShifts = notif.shiftSummaries.where((s) => !s.isReadByOwner).toList();
                              if (notif.expiryNotifications.isEmpty && unreadShifts.isEmpty && notif.lowStockProducts.isEmpty) {
                                return const SizedBox.shrink();
                              }
                              return Column(
                                children: [
                                  if (notif.expiryNotifications.isNotEmpty)
                                    Container(
                                      margin: const EdgeInsets.only(bottom: 12),
                                      padding: const EdgeInsets.all(12),
                                      decoration: BoxDecoration(
                                        color: AppColors.danger.withOpacity(0.12),
                                        borderRadius: BorderRadius.circular(14),
                                        border: Border.all(color: AppColors.danger.withOpacity(0.4)),
                                      ),
                                      child: Row(
                                        children: [
                                          const Icon(Icons.warning_amber_rounded, color: AppColors.danger, size: 24),
                                          const SizedBox(width: 10),
                                          Expanded(
                                            child: Text(
                                              "تنبيه: يوجد ${notif.expiryNotifications.length} دفعة بحاجة لمتابعة الصلاحية (هالك أو تبديل مورد).",
                                              style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: AppColors.getTextPrimary(isDark)),
                                            ),
                                          ),
                                          TextButton(
                                            onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const ExpiryNotificationsScreen())),
                                            child: const Text("متابعة", style: TextStyle(fontWeight: FontWeight.bold, color: AppColors.danger)),
                                          ),
                                        ],
                                      ),
                                    ),
                                  if (unreadShifts.isNotEmpty)
                                    Container(
                                      margin: const EdgeInsets.only(bottom: 12),
                                      padding: const EdgeInsets.all(12),
                                      decoration: BoxDecoration(
                                        color: AppColors.primary.withOpacity(0.12),
                                        borderRadius: BorderRadius.circular(14),
                                        border: Border.all(color: AppColors.primary.withOpacity(0.4)),
                                      ),
                                      child: Row(
                                        children: [
                                          const Icon(Icons.assignment_turned_in_rounded, color: AppColors.primaryLight, size: 24),
                                          const SizedBox(width: 10),
                                          Expanded(
                                            child: Text(
                                              "تم إغلاق وردية كاشير (${unreadShifts.first.cashierName}). راجع مطابقة الدرج والأداء.",
                                              style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: AppColors.getTextPrimary(isDark)),
                                            ),
                                          ),
                                          TextButton(
                                            onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const ShiftSummariesScreen())),
                                            child: const Text("استعراض", style: TextStyle(fontWeight: FontWeight.bold, color: AppColors.primaryLight)),
                                          ),
                                        ],
                                      ),
                                    ),
                                  if (notif.lowStockProducts.isNotEmpty)
                                    Container(
                                      margin: const EdgeInsets.only(bottom: 12),
                                      padding: const EdgeInsets.all(12),
                                      decoration: BoxDecoration(
                                        color: AppColors.warning.withOpacity(0.12),
                                        borderRadius: BorderRadius.circular(14),
                                        border: Border.all(color: AppColors.warning.withOpacity(0.4)),
                                      ),
                                      child: Row(
                                        children: [
                                          const Icon(Icons.inventory_2_rounded, color: AppColors.warning, size: 24),
                                          const SizedBox(width: 10),
                                          Expanded(
                                            child: Text(
                                              "تنبيه نواقص: يوجد ${notif.lowStockProducts.length} صنف قارب على النفاد أو نفدت كميته بالمخزن.",
                                              style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: AppColors.getTextPrimary(isDark)),
                                            ),
                                          ),
                                          TextButton(
                                            onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const LowStockNotificationsScreen())),
                                            child: const Text("استعراض", style: TextStyle(fontWeight: FontWeight.bold, color: AppColors.warning)),
                                          ),
                                        ],
                                      ),
                                    ),
                                ],
                              );
                            },
                          ),

                          // Mobile POS Showroom Sales Hero Card
                          Container(
                            margin: const EdgeInsets.only(bottom: 16),
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              gradient: const LinearGradient(
                                colors: [Color(0xFF1E1B4B), Color(0xFF312E81)],
                                begin: Alignment.topRight,
                                end: Alignment.bottomLeft,
                              ),
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(color: const Color(0xFF6366F1).withOpacity(0.4)),
                              boxShadow: [
                                BoxShadow(
                                  color: const Color(0xFF4F46E5).withOpacity(0.2),
                                  blurRadius: 10,
                                  offset: const Offset(0, 4),
                                ),
                              ],
                            ),
                            child: Row(
                              children: [
                                Container(
                                  padding: const EdgeInsets.all(12),
                                  decoration: BoxDecoration(
                                    color: const Color(0xFF4F46E5).withOpacity(0.25),
                                    shape: BoxShape.circle,
                                  ),
                                  child: const Icon(
                                    Icons.qr_code_scanner_rounded,
                                    color: Color(0xFF38BDF8),
                                    size: 28,
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      const Text(
                                        "بيع جهاز من الصالة (POS)",
                                        style: TextStyle(
                                          fontWeight: FontWeight.bold,
                                          fontSize: 14.5,
                                          color: Colors.white,
                                        ),
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                      const SizedBox(height: 3),
                                      const Text(
                                        "امسح باركود الأجهزة بالصالة وسجل الفاتورة في كاشير المحل مباشرة.",
                                        style: TextStyle(
                                          fontSize: 11,
                                          color: Colors.white70,
                                          height: 1.3,
                                        ),
                                        overflow: TextOverflow.ellipsis,
                                        maxLines: 2,
                                      ),
                                    ],
                                  ),
                                ),
                                const SizedBox(width: 8),
                                ElevatedButton(
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: const Color(0xFF10B981),
                                    foregroundColor: Colors.white,
                                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                                  ),
                                  onPressed: () {
                                    Navigator.push(
                                      context,
                                      MaterialPageRoute(builder: (_) => const MobilePosScreen()),
                                    );
                                  },
                                  child: const Text(
                                    "بيع الآن",
                                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12),
                                  ),
                                ),
                              ],
                            ),
                          ),

                          // Price Check Quick Action Hero Card
                          Container(
                            margin: const EdgeInsets.only(bottom: 16),
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                colors: isDark
                                    ? [const Color(0xFF0F2027), const Color(0xFF203A43)]
                                    : [const Color(0xFFF0FDF4), const Color(0xFFDCFCE7)],
                                begin: Alignment.topRight,
                                end: Alignment.bottomLeft,
                              ),
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(color: AppColors.cyan.withOpacity(0.4)),
                              boxShadow: [
                                BoxShadow(
                                  color: AppColors.cyan.withOpacity(0.12),
                                  blurRadius: 10,
                                  offset: const Offset(0, 4),
                                ),
                              ],
                            ),
                            child: Row(
                              children: [
                                Container(
                                  padding: const EdgeInsets.all(12),
                                  decoration: BoxDecoration(
                                    color: AppColors.cyan.withOpacity(0.2),
                                    shape: BoxShape.circle,
                                  ),
                                  child: const Icon(
                                    Icons.price_check_rounded,
                                    color: AppColors.cyan,
                                    size: 28,
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        "الاستعلام عن سعر المنتج",
                                        style: TextStyle(
                                          fontWeight: FontWeight.bold,
                                          fontSize: 14.5,
                                          color: isDark ? Colors.white : const Color(0xFF065F46),
                                        ),
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                      const SizedBox(height: 3),
                                      Text(
                                        "مسح الباركود بالكاميرا أو البحث باسم الجهاز لعرض السعر والمخزون.",
                                        style: TextStyle(
                                          fontSize: 11,
                                          color: isDark ? Colors.white70 : const Color(0xFF047857),
                                          height: 1.3,
                                        ),
                                        overflow: TextOverflow.ellipsis,
                                        maxLines: 2,
                                      ),
                                    ],
                                  ),
                                ),
                                const SizedBox(width: 8),
                                ElevatedButton(
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: AppColors.cyan,
                                    foregroundColor: Colors.black87,
                                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                                  ),
                                  onPressed: () {
                                    Navigator.push(
                                      context,
                                      MaterialPageRoute(builder: (_) => const PriceCheckScreen()),
                                    );
                                  },
                                  child: const Text(
                                    "استعلام",
                                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12),
                                  ),
                                ),
                              ],
                            ),
                          ),

                          // Today Performance Section
                          _buildSectionHeader(isDark, "مؤشرات اليوم", Icons.today_rounded),
                          const SizedBox(height: 10),
                          Row(
                            children: [
                              Expanded(
                                child: _buildMetricCard(
                                  isDark,
                                  title: "مبيعات اليوم",
                                  value: "${currencyFormatter.format(stats?.todaySalesAmount ?? 0)} ج.م",
                                  icon: Icons.point_of_sale_rounded,
                                  color: AppColors.success,
                                ),
                              ),
                              const SizedBox(width: 10),
                              Expanded(
                                child: _buildMetricCard(
                                  isDark,
                                  title: "صافي أرباح اليوم",
                                  value: "${currencyFormatter.format(stats?.todayProfitAmount ?? 0)} ج.م",
                                  icon: Icons.trending_up_rounded,
                                  color: AppColors.cyan,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 10),
                          Row(
                            children: [
                              Expanded(
                                child: _buildMetricCard(
                                  isDark,
                                  title: "مشتريات اليوم",
                                  value: "${currencyFormatter.format(stats?.todayPurchasesAmount ?? 0)} ج.م",
                                  icon: Icons.shopping_cart_rounded,
                                  color: AppColors.primaryLight,
                                ),
                              ),
                              const SizedBox(width: 10),
                              Expanded(
                                child: _buildMetricCard(
                                  isDark,
                                  title: "مصروفات اليوم",
                                  value: "${currencyFormatter.format(stats?.todayExpensesAmount ?? 0)} ج.م",
                                  icon: Icons.outbox_rounded,
                                  color: AppColors.danger,
                                  onTap: () {
                                    Navigator.push(context, MaterialPageRoute(builder: (_) => const ExpensesScreen()));
                                  },
                                ),
                              ),
                            ],
                          ),

                          const SizedBox(height: 20),

                          // Monthly Results & Financial Position
                          _buildSectionHeader(isDark, "حصيلة الشهر الجاري", Icons.calendar_month_rounded),
                          const SizedBox(height: 10),
                          Container(
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                colors: isDark
                                    ? [const Color(0xFF1E293B), const Color(0xFF0F172A)]
                                    : [const Color(0xFFFFFFFF), const Color(0xFFF1F5F9)],
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                              ),
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(color: AppColors.getBorder(isDark)),
                            ),
                            child: Column(
                              children: [
                                Row(
                                  children: [
                                    Expanded(
                                      child: _buildMonthStatItem(isDark, "إجمالي مبيعات الشهر", "${currencyFormatter.format(stats?.monthSalesAmount ?? 0)} ج.م", AppColors.success),
                                    ),
                                    const SizedBox(width: 12),
                                    Expanded(
                                      child: _buildMonthStatItem(isDark, "صافي ربح الشهر", "${currencyFormatter.format(stats?.monthProfitAmount ?? 0)} ج.م", AppColors.cyan),
                                    ),
                                  ],
                                ),
                                const Divider(height: 24),
                                Row(
                                  children: [
                                    Expanded(
                                      child: _buildMonthStatItem(isDark, "مشتريات الشهر", "${currencyFormatter.format(stats?.monthPurchasesAmount ?? 0)} ج.م", AppColors.primaryLight),
                                    ),
                                    const SizedBox(width: 12),
                                    Expanded(
                                      child: _buildMonthStatItem(isDark, "مصروفات الشهر", "${currencyFormatter.format(stats?.monthExpensesAmount ?? 0)} ج.م", AppColors.danger),
                                    ),
                                  ],
                                ),
                                const Divider(height: 20),
                                InkWell(
                                  onTap: () {
                                    Navigator.push(context, MaterialPageRoute(builder: (_) => const MonthlyReportScreen()));
                                  },
                                  borderRadius: BorderRadius.circular(10),
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(vertical: 9, horizontal: 12),
                                    decoration: BoxDecoration(
                                      color: AppColors.cyan.withOpacity(0.12),
                                      borderRadius: BorderRadius.circular(10),
                                      border: Border.all(color: AppColors.cyan.withOpacity(0.3)),
                                    ),
                                    child: const Row(
                                      mainAxisAlignment: MainAxisAlignment.center,
                                      children: [
                                        Icon(Icons.analytics_rounded, size: 16, color: AppColors.cyan),
                                        SizedBox(width: 8),
                                        Flexible(
                                          child: Text(
                                            "عرض التقرير المالي والشهري التفصيلي بالأيام",
                                            style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: AppColors.cyan),
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                        ),
                                        SizedBox(width: 4),
                                        Icon(Icons.arrow_forward_ios_rounded, size: 12, color: AppColors.cyan),
                                      ],
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),

                          const SizedBox(height: 20),

                          // Waste & Losses Card (Valued at Purchase Cost)
                          _buildSectionHeader(isDark, "خسائر وتوالف المخزون (بسعر الشراء)", Icons.delete_outline_rounded),
                          const SizedBox(height: 10),
                          Container(
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: AppColors.getSurface(isDark),
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(color: AppColors.danger.withOpacity(0.25)),
                            ),
                            child: Column(
                              children: [
                                Row(
                                  children: [
                                    Expanded(
                                      child: _buildMonthStatItem(isDark, "هالك اليوم", "${currencyFormatter.format(stats?.todayWasteLossAmount ?? 0)} ج.م", AppColors.warning),
                                    ),
                                    const SizedBox(width: 12),
                                    Expanded(
                                      child: _buildMonthStatItem(isDark, "هالك هذا الشهر", "${currencyFormatter.format(stats?.monthWasteLossAmount ?? 0)} ج.م", AppColors.danger),
                                    ),
                                  ],
                                ),
                                const Divider(height: 24),
                                Row(
                                  children: [
                                    Expanded(
                                      child: _buildMonthStatItem(isDark, "إجمالي خسائر الهالك", "${currencyFormatter.format(stats?.totalWasteLossAmount ?? 0)} ج.م", AppColors.danger),
                                    ),
                                    const SizedBox(width: 8),
                                    TextButton.icon(
                                      onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const ExpiryNotificationsScreen())),
                                      icon: const Icon(Icons.history_rounded, size: 16),
                                      label: const Text("إدارة الهالك والصلاحية", style: TextStyle(fontSize: 12)),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),

                          const SizedBox(height: 20),

                          // Debts Summary Card (Clickable -> DebtsScreen)
                          _buildSectionHeader(isDark, "مركز المديونية والديون", Icons.account_balance_rounded),
                          const SizedBox(height: 10),
                          InkWell(
                            borderRadius: BorderRadius.circular(16),
                            onTap: () {
                              Navigator.push(context, MaterialPageRoute(builder: (_) => const DebtsScreen()));
                            },
                            child: Container(
                              padding: const EdgeInsets.all(16),
                              decoration: BoxDecoration(
                                color: AppColors.getSurface(isDark),
                                borderRadius: BorderRadius.circular(16),
                                border: Border.all(color: AppColors.getBorder(isDark)),
                              ),
                              child: Column(
                                children: [
                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                    children: [
                                      Row(
                                        children: [
                                          Container(
                                            padding: const EdgeInsets.all(8),
                                            decoration: BoxDecoration(
                                              color: AppColors.warning.withOpacity(0.15),
                                              shape: BoxShape.circle,
                                            ),
                                            child: const Icon(Icons.handshake_rounded, color: AppColors.warning, size: 20),
                                          ),
                                          const SizedBox(width: 10),
                                          Column(
                                            crossAxisAlignment: CrossAxisAlignment.start,
                                            children: [
                                              Text("إدارة الديون والفواتير", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: AppColors.getTextPrimary(isDark))),
                                              Text("انقر للاستعراض والتحصيل والسداد", style: TextStyle(fontSize: 11, color: AppColors.getTextMuted(isDark))),
                                            ],
                                          ),
                                        ],
                                      ),
                                      const Icon(Icons.chevron_left_rounded, color: AppColors.primaryLight),
                                    ],
                                  ),
                                  const SizedBox(height: 14),
                                  Row(
                                    children: [
                                      Expanded(
                                        child: Container(
                                          padding: const EdgeInsets.all(10),
                                          decoration: BoxDecoration(
                                            color: AppColors.success.withOpacity(0.1),
                                            borderRadius: BorderRadius.circular(10),
                                          ),
                                          child: Column(
                                            crossAxisAlignment: CrossAxisAlignment.start,
                                            children: [
                                              const Text("ديون العملاء (لنا)", style: TextStyle(fontSize: 11, color: AppColors.success, fontWeight: FontWeight.w600)),
                                              const SizedBox(height: 4),
                                              Text("${currencyFormatter.format(stats?.customerDebtsTotal ?? 0)} ج.م", style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: AppColors.success)),
                                            ],
                                          ),
                                        ),
                                      ),
                                      const SizedBox(width: 10),
                                      Expanded(
                                        child: Container(
                                          padding: const EdgeInsets.all(10),
                                          decoration: BoxDecoration(
                                            color: AppColors.danger.withOpacity(0.1),
                                            borderRadius: BorderRadius.circular(10),
                                          ),
                                          child: Column(
                                            crossAxisAlignment: CrossAxisAlignment.start,
                                            children: [
                                              const Text("مستحقات الموردين (علينا)", style: TextStyle(fontSize: 11, color: AppColors.danger, fontWeight: FontWeight.w600)),
                                              const SizedBox(height: 4),
                                              Text("${currencyFormatter.format(stats?.supplierDebtsTotal ?? 0)} ج.م", style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: AppColors.danger)),
                                            ],
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                          ),

                          const SizedBox(height: 12),

                          // Returns Navigation Card
                          GestureDetector(
                            onTap: () {
                              Navigator.push(context, MaterialPageRoute(builder: (_) => const ReturnsListScreen()));
                            },
                            child: Container(
                              padding: const EdgeInsets.all(16),
                              decoration: BoxDecoration(
                                color: AppColors.getSurface(isDark),
                                borderRadius: BorderRadius.circular(16),
                                border: Border.all(color: AppColors.getBorder(isDark)),
                              ),
                              child: Row(
                                children: [
                                  Container(
                                    padding: const EdgeInsets.all(8),
                                    decoration: BoxDecoration(
                                      color: const Color(0xFFEF4444).withOpacity(0.15),
                                      shape: BoxShape.circle,
                                    ),
                                    child: const Icon(Icons.assignment_return_rounded, color: Color(0xFFEF4444), size: 20),
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          "سجل المرتجعات",
                                          style: TextStyle(
                                            fontWeight: FontWeight.bold,
                                            fontSize: 14,
                                            color: AppColors.getTextPrimary(isDark),
                                          ),
                                        ),
                                        const SizedBox(height: 2),
                                        Text(
                                          "استعراض مرتجعات المبيعات والمشتريات وتفاصيل الأصناف",
                                          style: TextStyle(
                                            fontSize: 11,
                                            color: AppColors.getTextMuted(isDark),
                                          ),
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                      ],
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  const Icon(Icons.chevron_left_rounded, color: AppColors.primaryLight),
                                ],
                              ),
                            ),
                          ),

                          const SizedBox(height: 20),

                          // Quick Actions Grid
                          _buildSectionHeader(isDark, "إجراءات سريعة", Icons.bolt_rounded),
                          const SizedBox(height: 10),
                          Row(
                            children: [
                              Expanded(
                                child: _buildActionButton(
                                  isDark,
                                  title: "فاتورة شراء",
                                  icon: Icons.add_shopping_cart_rounded,
                                  color: AppColors.primary,
                                  onTap: () {
                                    Navigator.push(context, MaterialPageRoute(builder: (_) => const CreatePurchaseScreen()));
                                  },
                                ),
                              ),
                              const SizedBox(width: 10),
                              Expanded(
                                child: _buildActionButton(
                                  isDark,
                                  title: "إضافة صنف",
                                  icon: Icons.add_box_rounded,
                                  color: AppColors.cyan,
                                  onTap: () {
                                    Navigator.push(context, MaterialPageRoute(builder: (_) => const AddEditProductScreen()));
                                  },
                                ),
                              ),
                              const SizedBox(width: 10),
                              Expanded(
                                child: _buildActionButton(
                                  isDark,
                                  title: "سداد ديون",
                                  icon: Icons.payments_rounded,
                                  color: AppColors.warning,
                                  onTap: () {
                                    Navigator.push(context, MaterialPageRoute(builder: (_) => const DebtsScreen()));
                                  },
                                ),
                              ),
                              const SizedBox(width: 10),
                              Expanded(
                                child: _buildActionButton(
                                  isDark,
                                  title: "تسجيل مصروف",
                                  icon: Icons.receipt_long_rounded,
                                  color: AppColors.danger,
                                  onTap: () {
                                    Navigator.push(context, MaterialPageRoute(builder: (_) => const ExpensesScreen()));
                                  },
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),
                          Row(
                            children: [
                              Expanded(
                                child: InkWell(
                                  onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const InstallmentsScreen())),
                                  borderRadius: BorderRadius.circular(14),
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 11),
                                    decoration: BoxDecoration(
                                      color: AppColors.getSurface(isDark),
                                      borderRadius: BorderRadius.circular(14),
                                      border: Border.all(color: AppColors.purple.withOpacity(0.3)),
                                    ),
                                    child: Row(
                                      children: [
                                        Container(
                                          padding: const EdgeInsets.all(7),
                                          decoration: BoxDecoration(
                                            color: AppColors.purple.withOpacity(0.15),
                                            shape: BoxShape.circle,
                                          ),
                                          child: const Icon(Icons.request_quote_rounded, color: AppColors.purple, size: 18),
                                        ),
                                        const SizedBox(width: 8),
                                        const Expanded(
                                          child: Column(
                                            crossAxisAlignment: CrossAxisAlignment.start,
                                            children: [
                                              Text("أقساط الأجهزة", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
                                              Text("سجل وتحصيل الأقساط", style: TextStyle(fontSize: 10, color: Colors.grey), maxLines: 1, overflow: TextOverflow.ellipsis),
                                            ],
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              ),
                              const SizedBox(width: 10),
                              Expanded(
                                child: InkWell(
                                  onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const ReservationsScreen())),
                                  borderRadius: BorderRadius.circular(14),
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 11),
                                    decoration: BoxDecoration(
                                      color: AppColors.getSurface(isDark),
                                      borderRadius: BorderRadius.circular(14),
                                      border: Border.all(color: AppColors.rose.withOpacity(0.3)),
                                    ),
                                    child: Row(
                                      children: [
                                        Container(
                                          padding: const EdgeInsets.all(7),
                                          decoration: BoxDecoration(
                                            color: AppColors.rose.withOpacity(0.15),
                                            shape: BoxShape.circle,
                                          ),
                                          child: const Icon(Icons.favorite_rounded, color: AppColors.rose, size: 18),
                                        ),
                                        const SizedBox(width: 8),
                                        const Expanded(
                                          child: Column(
                                            crossAxisAlignment: CrossAxisAlignment.start,
                                            children: [
                                              Text("حجوزات العروسة", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
                                              Text("تسليمات وعربون المحل", style: TextStyle(fontSize: 10, color: Colors.grey), maxLines: 1, overflow: TextOverflow.ellipsis),
                                            ],
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),

                          const SizedBox(height: 24),

                          // Recent Purchases Section
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              _buildSectionHeader(isDark, "آخر فواتير المشتريات", Icons.history_rounded),
                              TextButton(
                                onPressed: () {
                                  Navigator.push(context, MaterialPageRoute(builder: (_) => const PurchasesListScreen()));
                                },
                                child: const Text("عرض الكل", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: AppColors.primaryLight)),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),

                          if (stats?.recentPurchases.isEmpty ?? true)
                            Container(
                              padding: const EdgeInsets.all(24),
                              alignment: Alignment.center,
                              decoration: BoxDecoration(
                                color: AppColors.getSurface(isDark),
                                borderRadius: BorderRadius.circular(16),
                                border: Border.all(color: AppColors.getBorder(isDark)),
                              ),
                              child: Text("لا توجد فواتير مشتريات حديثة.", style: TextStyle(color: AppColors.getTextMuted(isDark), fontSize: 13)),
                            )
                          else
                            ListView.separated(
                              shrinkWrap: true,
                              physics: const NeverScrollableScrollPhysics(),
                              itemCount: stats!.recentPurchases.length,
                              separatorBuilder: (_, __) => const SizedBox(height: 8),
                              itemBuilder: (ctx, idx) {
                                final p = stats.recentPurchases[idx];
                                return _buildRecentPurchaseTile(context, isDark, p, currencyFormatter);
                              },
                            ),

                          const SizedBox(height: 30),
                        ],
                      ),
                    ),
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(bool isDark, String title, IconData icon) {
    return Row(
      children: [
        Icon(icon, size: 18, color: AppColors.primaryLight),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            title,
            style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: AppColors.getTextPrimary(isDark)),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }

  Widget _buildMetricCard(bool isDark, {required String title, required String value, required IconData icon, required Color color, VoidCallback? onTap}) {
    return InkWell(
      borderRadius: BorderRadius.circular(14),
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: AppColors.getSurface(isDark),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: AppColors.getBorder(isDark)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon, size: 16, color: color),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    title,
                    style: TextStyle(fontSize: 11, color: AppColors.getTextMuted(isDark)),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 6),
            FittedBox(
              fit: BoxFit.scaleDown,
              alignment: Alignment.centerLeft,
              child: Text(
                value,
                style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: color),
                maxLines: 1,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMonthStatItem(bool isDark, String title, String value, Color color) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: TextStyle(fontSize: 11, color: AppColors.getTextMuted(isDark)),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        const SizedBox(height: 4),
        FittedBox(
          fit: BoxFit.scaleDown,
          alignment: Alignment.centerRight,
          child: Text(
            value,
            style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: color),
            maxLines: 1,
          ),
        ),
      ],
    );
  }

  Widget _buildActionButton(bool isDark, {required String title, required IconData icon, required Color color, required VoidCallback onTap}) {
    return InkWell(
      borderRadius: BorderRadius.circular(12),
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          color: color.withOpacity(0.12),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: color.withOpacity(0.3)),
        ),
        child: Column(
          children: [
            Icon(icon, color: color, size: 22),
            const SizedBox(height: 6),
            Text(
              title,
              style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: color),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRecentPurchaseTile(BuildContext context, bool isDark, DashboardRecentPurchase p, NumberFormat currencyFormatter) {
    return InkWell(
      borderRadius: BorderRadius.circular(12),
      onTap: () {
        Navigator.push(context, MaterialPageRoute(builder: (_) => PurchaseDetailScreen(purchaseId: p.id)));
      },
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: AppColors.getSurface(isDark),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppColors.getBorder(isDark)),
        ),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text("فاتورة: ${p.invoiceNumber}", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: AppColors.getTextPrimary(isDark))),
                  Text(p.supplierName ?? "بدون مورد", style: TextStyle(fontSize: 11, color: AppColors.getTextMuted(isDark))),
                ],
              ),
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text("${currencyFormatter.format(p.totalAmount)} ج.م", style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: AppColors.success)),
                const SizedBox(height: 3),
                SyncStatusBadge(status: p.syncStatus),
              ],
            ),
          ],
        ),
      ),
    );
  }

  void _openNotificationsSheet(BuildContext context, NotificationsProvider notif, bool isDark) {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.getSurface(isDark),
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (ctx) => Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.notifications_active_rounded, color: AppColors.primaryLight),
                const SizedBox(width: 8),
                Text(
                  "مركز التنبيهات والإشعارات",
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: AppColors.getTextPrimary(isDark)),
                ),
              ],
            ),
            const SizedBox(height: 16),
            ListTile(
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              leading: const CircleAvatar(
                backgroundColor: AppColors.danger,
                child: Icon(Icons.hourglass_bottom_rounded, color: Colors.white, size: 20),
              ),
              title: const Text("تنبيهات الصلاحية العاجلة بالمخزن", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
              subtitle: Text("يوجد ${notif.expiryNotifications.length} دفعة بحاجة لمتابعة الصلاحية والهالك", style: const TextStyle(fontSize: 12)),
              trailing: const Icon(Icons.arrow_forward_ios_rounded, size: 16),
              onTap: () {
                Navigator.pop(ctx);
                Navigator.push(context, MaterialPageRoute(builder: (_) => const ExpiryNotificationsScreen()));
              },
            ),
            const SizedBox(height: 6),
            ListTile(
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              leading: const CircleAvatar(
                backgroundColor: AppColors.warning,
                child: Icon(Icons.inventory_2_rounded, color: Colors.white, size: 20),
              ),
              title: const Text("نواقص المخزون والحد الأدنى للطلب", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
              subtitle: Text("يوجد ${notif.lowStockProducts.length} صنف قارب على النفاد أو نفدت كميته", style: const TextStyle(fontSize: 12)),
              trailing: const Icon(Icons.arrow_forward_ios_rounded, size: 16),
              onTap: () {
                Navigator.pop(ctx);
                Navigator.push(context, MaterialPageRoute(builder: (_) => const LowStockNotificationsScreen()));
              },
            ),
            const SizedBox(height: 6),
            ListTile(
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              leading: const CircleAvatar(
                backgroundColor: AppColors.primary,
                child: Icon(Icons.assignment_turned_in_rounded, color: Colors.white, size: 20),
              ),
              title: const Text("تقارير إغلاق الورديات وأداء الكاشير", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
              subtitle: Text("استعراض مبيعات الورديات وفروق الدرج", style: const TextStyle(fontSize: 12)),
              trailing: const Icon(Icons.arrow_forward_ios_rounded, size: 16),
              onTap: () {
                Navigator.pop(ctx);
                Navigator.push(context, MaterialPageRoute(builder: (_) => const ShiftSummariesScreen()));
              },
            ),
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              height: 44,
              child: OutlinedButton.icon(
                style: OutlinedButton.styleFrom(
                  foregroundColor: AppColors.primaryLight,
                  side: const BorderSide(color: AppColors.primaryLight),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                ),
                icon: const Icon(Icons.vibration_rounded, size: 18),
                label: const Text(
                  "تجربة وصول إشعار وتنبيه فوري للهاتف",
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                ),
                onPressed: () async {
                  Navigator.pop(ctx);
                  await notif.triggerTestNotification();
                },
              ),
            ),
            const SizedBox(height: 6),
          ],
        ),
      ),
    );
  }
}
