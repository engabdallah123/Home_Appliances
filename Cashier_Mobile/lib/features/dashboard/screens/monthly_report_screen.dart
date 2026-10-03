import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../../../core/constants/api_endpoints.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/network/api_client.dart';
import '../../../core/theme/theme_provider.dart';
import '../../../core/widgets/offline_banner.dart';

class MonthlyReportScreen extends StatefulWidget {
  const MonthlyReportScreen({super.key});

  @override
  State<MonthlyReportScreen> createState() => _MonthlyReportScreenState();
}

class _MonthlyReportScreenState extends State<MonthlyReportScreen> {
  final ApiClient _apiClient = ApiClient();
  final NumberFormat _currencyFormatter = NumberFormat("#,##0.00", "ar_EG");

  int _selectedYear = DateTime.now().year;
  int _selectedMonth = DateTime.now().month;

  bool _isLoading = false;
  String? _errorMessage;
  Map<String, dynamic>? _reportData;

  final List<String> _arabicMonths = const [
    "يناير", "فبراير", "مارس", "أبريل", "مايو", "يونيو",
    "يوليو", "أغسطس", "سبتمبر", "أكتوبر", "نوفمبر", "ديسمبر"
  ];

  @override
  void initState() {
    super.initState();
    _fetchReport();
  }

  Future<void> _fetchReport() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final res = await _apiClient.get(
        ApiEndpoints.monthlyReport,
        queryParams: {
          'year': _selectedYear,
          'month': _selectedMonth,
        },
      );

      setState(() {
        _reportData = (res is Map<String, dynamic>) ? res : null;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _errorMessage = e.toString();
        _isLoading = false;
      });
    }
  }

  void _previousMonth() {
    setState(() {
      if (_selectedMonth == 1) {
        _selectedMonth = 12;
        _selectedYear--;
      } else {
        _selectedMonth--;
      }
    });
    _fetchReport();
  }

  void _nextMonth() {
    setState(() {
      if (_selectedMonth == 12) {
        _selectedMonth = 1;
        _selectedYear++;
      } else {
        _selectedMonth++;
      }
    });
    _fetchReport();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Provider.of<ThemeProvider>(context).isDarkMode;
    final totalSales = (_reportData?['totalSales'] as num?)?.toDouble() ?? 0.0;
    final totalPurchases = (_reportData?['totalPurchases'] as num?)?.toDouble() ?? 0.0;
    final totalExpenses = (_reportData?['totalExpenses'] as num?)?.toDouble() ?? 0.0;
    final netProfit = (_reportData?['netProfit'] as num?)?.toDouble() ?? 0.0;
    final dailyStats = (_reportData?['dailyStats'] as List?) ?? [];

    return Scaffold(
      backgroundColor: AppColors.getBackground(isDark),
      appBar: AppBar(
        backgroundColor: AppColors.getSurface(isDark),
        elevation: 0,
        title: Text(
          "التقرير المالي والأرباح الشهرية",
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: AppColors.getTextPrimary(isDark)),
        ),
        actions: [
          IconButton(
            icon: Icon(Icons.refresh_rounded, color: AppColors.getTextPrimary(isDark)),
            tooltip: "تحديث التقرير",
            onPressed: _fetchReport,
          ),
        ],
      ),
      body: Column(
        children: [
          const OfflineBanner(),

          // Month / Year Selector Header Bar
          Container(
            margin: const EdgeInsets.fromLTRB(16, 12, 16, 8),
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
            decoration: BoxDecoration(
              color: AppColors.getSurface(isDark),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: AppColors.getBorder(isDark)),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                IconButton(
                  icon: const Icon(Icons.chevron_right_rounded, color: AppColors.primaryLight, size: 28),
                  tooltip: "الشهر السابق",
                  onPressed: _previousMonth,
                ),
                Column(
                  children: [
                    Text(
                      "${_arabicMonths[_selectedMonth - 1]} $_selectedYear",
                      style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: AppColors.getTextPrimary(isDark)),
                    ),
                    Text(
                      "حصيلة أداء اليوميات والدخل",
                      style: TextStyle(fontSize: 11, color: AppColors.getTextMuted(isDark)),
                    ),
                  ],
                ),
                IconButton(
                  icon: const Icon(Icons.chevron_left_rounded, color: AppColors.primaryLight, size: 28),
                  tooltip: "الشهر القادم",
                  onPressed: _nextMonth,
                ),
              ],
            ),
          ),

          // Monthly Summary KPIs (Safely wrapped with FittedBox and Expanded to eliminate overflow)
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              children: [
                Expanded(
                  child: _buildSummaryCard(
                    isDark,
                    title: "إجمالي المبيعات",
                    value: "${_currencyFormatter.format(totalSales)} ج.م",
                    color: AppColors.success,
                    icon: Icons.point_of_sale_rounded,
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: _buildSummaryCard(
                    isDark,
                    title: "صافي الأرباح",
                    value: "${_currencyFormatter.format(netProfit)} ج.م",
                    color: AppColors.cyan,
                    icon: Icons.trending_up_rounded,
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 8),

          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              children: [
                Expanded(
                  child: _buildSummaryCard(
                    isDark,
                    title: "إجمالي المشتريات",
                    value: "${_currencyFormatter.format(totalPurchases)} ج.م",
                    color: AppColors.primaryLight,
                    icon: Icons.shopping_bag_rounded,
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: _buildSummaryCard(
                    isDark,
                    title: "إجمالي المصروفات",
                    value: "${_currencyFormatter.format(totalExpenses)} ج.م",
                    color: AppColors.danger,
                    icon: Icons.outbox_rounded,
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 12),

          // Daily Breakdown Title
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              children: [
                const Icon(Icons.calendar_month_rounded, size: 16, color: AppColors.primaryLight),
                const SizedBox(width: 6),
                Text(
                  "تفاصيل كل يوم في الشهر (مبيعات ومصروفات)",
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: AppColors.getTextPrimary(isDark)),
                ),
              ],
            ),
          ),

          const SizedBox(height: 8),

          // Daily Stats List
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator(color: AppColors.primaryLight))
                : _errorMessage != null
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Icon(Icons.error_outline_rounded, color: AppColors.danger, size: 48),
                            const SizedBox(height: 8),
                            Text("خطأ: $_errorMessage", style: TextStyle(color: AppColors.getTextMuted(isDark))),
                            const SizedBox(height: 12),
                            ElevatedButton(onPressed: _fetchReport, child: const Text("إعادة المحاولة")),
                          ],
                        ),
                      )
                    : dailyStats.isEmpty
                        ? Center(
                            child: Text("لا توجد بيانات لهذا الشهر.", style: TextStyle(color: AppColors.getTextMuted(isDark))),
                          )
                        : ListView.separated(
                            padding: const EdgeInsets.fromLTRB(16, 4, 16, 80),
                            itemCount: dailyStats.length,
                            separatorBuilder: (_, __) => const SizedBox(height: 8),
                            itemBuilder: (ctx, idx) {
                              final d = dailyStats[idx];
                              return _buildDailyStatCard(d, isDark);
                            },
                          ),
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryCard(
    bool isDark, {
    required String title,
    required String value,
    required Color color,
    required IconData icon,
  }) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.getSurface(isDark),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.getBorder(isDark)),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(color: color.withOpacity(0.12), shape: BoxShape.circle),
            child: Icon(icon, color: color, size: 18),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: TextStyle(fontSize: 10.5, color: AppColors.getTextMuted(isDark)), maxLines: 1, overflow: TextOverflow.ellipsis),
                const SizedBox(height: 2),
                FittedBox(
                  fit: BoxFit.scaleDown,
                  alignment: Alignment.centerRight,
                  child: Text(value, style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: color)),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDailyStatCard(dynamic d, bool isDark) {
    final dayNum = d['day'] ?? 1;
    final dayName = d['dayName'] ?? '';
    final sales = (d['sales'] as num?)?.toDouble() ?? 0.0;
    final purchases = (d['purchases'] as num?)?.toDouble() ?? 0.0;
    final expenses = (d['expenses'] as num?)?.toDouble() ?? 0.0;
    final net = (d['net'] as num?)?.toDouble() ?? 0.0;
    final count = d['salesCount'] ?? 0;

    final hasActivity = sales > 0 || purchases > 0 || expenses > 0;

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.getSurface(isDark),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: hasActivity ? AppColors.primary.withOpacity(0.2) : AppColors.getBorder(isDark),
        ),
      ),
      child: Row(
        children: [
          // Day Badge
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: hasActivity ? AppColors.primary.withOpacity(0.12) : (isDark ? AppColors.darkSurfaceElevated : AppColors.lightSurfaceElevated),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text("$dayNum", style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: hasActivity ? AppColors.primaryLight : AppColors.getTextMuted(isDark))),
                Text(dayName.length > 3 ? dayName.substring(0, 3) : dayName, style: TextStyle(fontSize: 9, color: AppColors.getTextMuted(isDark))),
              ],
            ),
          ),
          const SizedBox(width: 12),

          // Metrics (Safely flexed)
          Expanded(
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text("مبيعات ($count فاتورة)", style: TextStyle(fontSize: 10, color: AppColors.getTextMuted(isDark)), maxLines: 1, overflow: TextOverflow.ellipsis),
                      FittedBox(
                        fit: BoxFit.scaleDown,
                        alignment: Alignment.centerRight,
                        child: Text("${_currencyFormatter.format(sales)} ج.م", style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: AppColors.success)),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 6),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text("مصروفات", style: TextStyle(fontSize: 10, color: AppColors.getTextMuted(isDark)), maxLines: 1, overflow: TextOverflow.ellipsis),
                      FittedBox(
                        fit: BoxFit.scaleDown,
                        alignment: Alignment.centerRight,
                        child: Text("${_currencyFormatter.format(expenses)} ج.م", style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: AppColors.danger)),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 6),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text("الصافي", style: TextStyle(fontSize: 10, color: AppColors.getTextMuted(isDark)), maxLines: 1, overflow: TextOverflow.ellipsis),
                      FittedBox(
                        fit: BoxFit.scaleDown,
                        alignment: Alignment.centerRight,
                        child: Text("${_currencyFormatter.format(net)} ج.م", style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: net >= 0 ? AppColors.cyan : AppColors.danger)),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
