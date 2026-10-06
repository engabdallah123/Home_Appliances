import 'package:flutter/material.dart';
import 'package:intl/intl.dart' hide TextDirection;
import 'package:provider/provider.dart';
import '../../../core/constants/api_endpoints.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/network/api_client.dart';
import '../../../core/theme/theme_provider.dart';
import '../../../core/widgets/offline_banner.dart';
import '../../sales/screens/sales_list_screen.dart';

// ==========================================
// Models for Monthly Report & Daily Breakdown
// ==========================================
class MonthlyReportData {
  final int year;
  final int month;
  final String monthNameAr;
  final int daysInMonth;
  final int firstDayDayOfWeek;
  final double totalMonthlySales;
  final double netMonthlySales;
  final double totalMonthlyCashSales;
  final double totalMonthlyCreditSales;
  final double totalMonthlyDebtCollections;
  final double totalMonthlyCollected;
  final double totalMonthlyReturns;
  final double totalMonthlyPurchases;
  final double totalMonthlyExpenses;
  final double netProfit;
  final int totalMonthlyInvoices;
  final double dailyAverageSales;
  final int activeDaysCount;
  final int highestSalesDay;
  final double highestSalesAmount;
  final int lowestSalesDay;
  final double lowestSalesAmount;
  final List<MonthlyDayData> days;

  MonthlyReportData({
    required this.year,
    required this.month,
    required this.monthNameAr,
    required this.daysInMonth,
    required this.firstDayDayOfWeek,
    required this.totalMonthlySales,
    required this.netMonthlySales,
    required this.totalMonthlyCashSales,
    required this.totalMonthlyCreditSales,
    required this.totalMonthlyDebtCollections,
    required this.totalMonthlyCollected,
    required this.totalMonthlyReturns,
    required this.totalMonthlyPurchases,
    required this.totalMonthlyExpenses,
    required this.netProfit,
    required this.totalMonthlyInvoices,
    required this.dailyAverageSales,
    required this.activeDaysCount,
    required this.highestSalesDay,
    required this.highestSalesAmount,
    required this.lowestSalesDay,
    required this.lowestSalesAmount,
    required this.days,
  });

  factory MonthlyReportData.fromJson(Map<String, dynamic> json) {
    num getNum(dynamic v) => (v is num) ? v : (num.tryParse(v?.toString() ?? '') ?? 0);
    double getD(dynamic v) => getNum(v).toDouble();
    int getI(dynamic v) => getNum(v).toInt();

    final rawDays = (json['days'] ?? json['Days'] ?? json['dailyStats'] ?? json['DailyStats']) as List? ?? [];
    final parsedDays = rawDays.map((d) => MonthlyDayData.fromJson(d as Map<String, dynamic>)).toList();

    return MonthlyReportData(
      year: getI(json['year'] ?? json['Year'] ?? DateTime.now().year),
      month: getI(json['month'] ?? json['Month'] ?? DateTime.now().month),
      monthNameAr: (json['monthNameAr'] ?? json['MonthNameAr'] ?? '').toString(),
      daysInMonth: getI(json['daysInMonth'] ?? json['DaysInMonth'] ?? parsedDays.length),
      firstDayDayOfWeek: getI(json['firstDayDayOfWeek'] ?? json['FirstDayDayOfWeek'] ?? 0),
      totalMonthlySales: getD(json['totalMonthlySales'] ?? json['TotalMonthlySales'] ?? json['totalSales'] ?? json['TotalSales']),
      netMonthlySales: getD(json['netMonthlySales'] ?? json['NetMonthlySales'] ?? json['netSales'] ?? json['NetSales']),
      totalMonthlyCashSales: getD(json['totalMonthlyCashSales'] ?? json['TotalMonthlyCashSales'] ?? json['totalCashSales'] ?? json['TotalCashSales']),
      totalMonthlyCreditSales: getD(json['totalMonthlyCreditSales'] ?? json['TotalMonthlyCreditSales'] ?? json['totalCreditSales'] ?? json['TotalCreditSales']),
      totalMonthlyDebtCollections: getD(json['totalMonthlyDebtCollections'] ?? json['TotalMonthlyDebtCollections'] ?? json['totalDebtCollections'] ?? json['TotalDebtCollections']),
      totalMonthlyCollected: getD(json['totalMonthlyCollected'] ?? json['TotalMonthlyCollected'] ?? json['totalCollected'] ?? json['TotalCollected']),
      totalMonthlyReturns: getD(json['totalMonthlyReturns'] ?? json['TotalMonthlyReturns'] ?? json['totalReturns'] ?? json['TotalReturns']),
      totalMonthlyPurchases: getD(json['totalMonthlyPurchases'] ?? json['TotalMonthlyPurchases'] ?? json['totalPurchases'] ?? json['TotalPurchases']),
      totalMonthlyExpenses: getD(json['totalMonthlyExpenses'] ?? json['TotalMonthlyExpenses'] ?? json['totalExpenses'] ?? json['TotalExpenses']),
      netProfit: getD(json['netProfit'] ?? json['NetProfit']),
      totalMonthlyInvoices: getI(json['totalMonthlyInvoices'] ?? json['TotalMonthlyInvoices'] ?? json['totalInvoices'] ?? json['TotalInvoices']),
      dailyAverageSales: getD(json['dailyAverageSales'] ?? json['DailyAverageSales']),
      activeDaysCount: getI(json['activeDaysCount'] ?? json['ActiveDaysCount']),
      highestSalesDay: getI(json['highestSalesDay'] ?? json['HighestSalesDay']),
      highestSalesAmount: getD(json['highestSalesAmount'] ?? json['HighestSalesAmount']),
      lowestSalesDay: getI(json['lowestSalesDay'] ?? json['LowestSalesDay']),
      lowestSalesAmount: getD(json['lowestSalesAmount'] ?? json['LowestSalesAmount']),
      days: parsedDays,
    );
  }
}

class MonthlyDayData {
  final int dayNumber;
  final String dateStr;
  final String dayNameAr;
  final int dayOfWeekIndex;
  final double totalSales;
  final double netSales;
  final double cashSales;
  final double creditSales;
  final double debtCollections;
  final double totalPaid;
  final double totalReturns;
  final double totalPurchases;
  final double totalExpenses;
  final double net;
  final int invoiceCount;
  final bool hasSales;
  final bool isToday;
  final bool isWeekend;

  MonthlyDayData({
    required this.dayNumber,
    required this.dateStr,
    required this.dayNameAr,
    required this.dayOfWeekIndex,
    required this.totalSales,
    required this.netSales,
    required this.cashSales,
    required this.creditSales,
    required this.debtCollections,
    required this.totalPaid,
    required this.totalReturns,
    required this.totalPurchases,
    required this.totalExpenses,
    required this.net,
    required this.invoiceCount,
    required this.hasSales,
    required this.isToday,
    required this.isWeekend,
  });

  factory MonthlyDayData.fromJson(Map<String, dynamic> json) {
    num getNum(dynamic v) => (v is num) ? v : (num.tryParse(v?.toString() ?? '') ?? 0);
    double getD(dynamic v) => getNum(v).toDouble();
    int getI(dynamic v) => getNum(v).toInt();
    bool getB(dynamic v) => v == true || v?.toString().toLowerCase() == 'true';

    final dNum = getI(json['dayNumber'] ?? json['DayNumber'] ?? json['day'] ?? json['Day'] ?? 1);
    final sCount = getI(json['invoiceCount'] ?? json['InvoiceCount'] ?? json['salesCount'] ?? json['SalesCount'] ?? 0);
    final tSales = getD(json['totalSales'] ?? json['TotalSales'] ?? json['sales'] ?? json['Sales'] ?? 0);
    final nSales = getD(json['netSales'] ?? json['NetSales'] ?? tSales);

    return MonthlyDayData(
      dayNumber: dNum,
      dateStr: (json['date'] ?? json['Date'] ?? '').toString(),
      dayNameAr: (json['dayNameAr'] ?? json['DayNameAr'] ?? json['dayName'] ?? json['DayName'] ?? '').toString(),
      dayOfWeekIndex: getI(json['dayOfWeekIndex'] ?? json['DayOfWeekIndex'] ?? 0),
      totalSales: tSales,
      netSales: nSales,
      cashSales: getD(json['cashSales'] ?? json['CashSales'] ?? 0),
      creditSales: getD(json['creditSales'] ?? json['CreditSales'] ?? 0),
      debtCollections: getD(json['debtCollections'] ?? json['DebtCollections'] ?? 0),
      totalPaid: getD(json['totalPaid'] ?? json['TotalPaid'] ?? 0),
      totalReturns: getD(json['totalReturns'] ?? json['TotalReturns'] ?? 0),
      totalPurchases: getD(json['totalPurchases'] ?? json['TotalPurchases'] ?? json['purchases'] ?? json['Purchases'] ?? 0),
      totalExpenses: getD(json['totalExpenses'] ?? json['TotalExpenses'] ?? json['expenses'] ?? json['Expenses'] ?? 0),
      net: getD(json['net'] ?? json['Net'] ?? 0),
      invoiceCount: sCount,
      hasSales: getB(json['hasSales'] ?? json['HasSales'] ?? (tSales > 0 || sCount > 0)),
      isToday: getB(json['isToday'] ?? json['IsToday']),
      isWeekend: getB(json['isWeekend'] ?? json['IsWeekend']),
    );
  }
}

// ==========================================
// Main Monthly Report Screen Widget
// ==========================================
class MonthlyReportScreen extends StatefulWidget {
  const MonthlyReportScreen({super.key});

  @override
  State<MonthlyReportScreen> createState() => _MonthlyReportScreenState();
}

class _MonthlyReportScreenState extends State<MonthlyReportScreen> {
  final ApiClient _apiClient = ApiClient();
  final NumberFormat _currencyFormatter = NumberFormat("#,##0.00");
  final NumberFormat _integerFormatter = NumberFormat("#,##0");

  int _selectedYear = DateTime.now().year;
  int _selectedMonth = DateTime.now().month;
  String _selectedDisplayMetric = "Sales"; // Matches Desktop options
  String _viewMode = "calendar"; // 'calendar' or 'list'

  bool _isLoading = false;
  String? _errorMessage;
  MonthlyReportData? _report;

  final List<String> _arabicMonths = const [
    "يناير", "فبراير", "مارس", "أبريل", "مايو", "يونيو",
    "يوليو", "أغسطس", "سبتمبر", "أكتوبر", "نوفمبر", "ديسمبر"
  ];

  final List<String> _arabicWeekdays = const [
    "السبت", "الأحد", "الإثنين", "الثلاثاء", "الأربعاء", "الخميس", "الجمعة"
  ];

  final Map<String, String> _metricTitles = const {
    "Sales": "إجمالي المبيعات (نقدي + آجل)",
    "NetSales": "صافي المبيعات (بعد المرتجع)",
    "Collected": "المبالغ المحصلة فعلياً (كاش)",
    "Credit": "المبيعات الآجلة (ديون معلقة)",
    "Invoices": "عدد الفواتير",
    "Expenses": "المصروفات اليومية",
    "Purchases": "المشتريات اليومية",
  };

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

      if (res is Map<String, dynamic>) {
        setState(() {
          _report = MonthlyReportData.fromJson(res);
          _isLoading = false;
        });
      } else {
        setState(() {
          _errorMessage = "تعذر استلام بيانات التقرير بتنسيق صحيح";
          _isLoading = false;
        });
      }
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

  void _goToCurrentMonth() {
    final now = DateTime.now();
    if (_selectedYear == now.year && _selectedMonth == now.month) return;
    setState(() {
      _selectedYear = now.year;
      _selectedMonth = now.month;
    });
    _fetchReport();
  }

  double _getMetricValue(MonthlyDayData day) {
    switch (_selectedDisplayMetric) {
      case "Sales":
        return day.totalSales;
      case "NetSales":
        return day.netSales;
      case "Collected":
        return day.totalPaid;
      case "Credit":
        return day.creditSales;
      case "Invoices":
        return day.invoiceCount.toDouble();
      case "Expenses":
        return day.totalExpenses;
      case "Purchases":
        return day.totalPurchases;
      default:
        return day.netSales;
    }
  }

  String _formatMetricDisplay(double val) {
    if (val <= 0) return "—";
    if (_selectedDisplayMetric == "Invoices") return "${val.toInt()} ف";
    if (val >= 1000) return _integerFormatter.format(val);
    return _currencyFormatter.format(val);
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Provider.of<ThemeProvider>(context).isDarkMode;
    final monthName = (_report?.monthNameAr.isNotEmpty ?? false)
        ? _report!.monthNameAr
        : _arabicMonths[_selectedMonth - 1];

    return Scaffold(
      backgroundColor: AppColors.getBackground(isDark),
      appBar: AppBar(
        backgroundColor: AppColors.getSurface(isDark),
        elevation: 0,
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              "تقرير المبيعات والنشاط الشهري",
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: AppColors.getTextPrimary(isDark)),
            ),
            Text(
              "شهر $monthName $_selectedYear — مطابقة يومية كاملة",
              style: TextStyle(fontSize: 11, color: AppColors.getTextMuted(isDark)),
            ),
          ],
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

          // Filters & View Mode Controller
          _buildFilterBar(isDark, monthName),

          Expanded(
            child: _isLoading && _report == null
                ? const Center(child: CircularProgressIndicator(color: AppColors.primaryLight))
                : _errorMessage != null && _report == null
                    ? Center(
                        child: Padding(
                          padding: const EdgeInsets.all(24),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              const Icon(Icons.error_outline_rounded, color: AppColors.danger, size: 52),
                              const SizedBox(height: 12),
                              Text("تعذر تحميل التقرير الشهري", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: AppColors.getTextPrimary(isDark))),
                              const SizedBox(height: 6),
                              Text(_errorMessage!, textAlign: TextAlign.center, style: TextStyle(fontSize: 12, color: AppColors.getTextMuted(isDark))),
                              const SizedBox(height: 16),
                              ElevatedButton.icon(
                                onPressed: _fetchReport,
                                icon: const Icon(Icons.refresh),
                                label: const Text("إعادة المحاولة"),
                              ),
                            ],
                          ),
                        ),
                      )
                    : RefreshIndicator(
                        onRefresh: _fetchReport,
                        color: AppColors.primaryLight,
                        child: SingleChildScrollView(
                          physics: const AlwaysScrollableScrollPhysics(),
                          padding: const EdgeInsets.fromLTRB(14, 4, 14, 32),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              // KPI Cards Carousel/Grid (1-to-1 match with Desktop)
                              if (_report != null) ...[
                                _buildKpiCardsSection(isDark),
                                const SizedBox(height: 14),
                              ],

                              // Display Metric Selector & View Toggle Bar
                              _buildMetricAndToggleBar(isDark),
                              const SizedBox(height: 12),

                              // View: Calendar or Detailed List
                              if (_viewMode == "calendar")
                                _buildCalendarGrid(isDark)
                              else
                                _buildDetailedDaysList(isDark),

                              const SizedBox(height: 16),

                              // Bottom Monthly Summary Card (Matching Desktop footer)
                              if (_report != null) _buildBottomSummaryCard(isDark),
                            ],
                          ),
                        ),
                      ),
          ),
        ],
      ),
    );
  }

  // ==========================================
  // Filter Bar (Month Navigation & Current Month)
  // ==========================================
  Widget _buildFilterBar(bool isDark, String monthName) {
    final now = DateTime.now();
    final isCurrentMonth = _selectedYear == now.year && _selectedMonth == now.month;

    return Container(
      margin: const EdgeInsets.fromLTRB(14, 8, 14, 6),
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: AppColors.getSurface(isDark),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.getBorder(isDark)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(isDark ? 0.2 : 0.04),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          // Previous Month button (points right in RTL)
          IconButton(
            icon: const Icon(Icons.chevron_right_rounded, color: AppColors.primaryLight, size: 28),
            tooltip: "الشهر السابق",
            visualDensity: VisualDensity.compact,
            onPressed: _previousMonth,
          ),

          // Month Title
          Expanded(
            child: InkWell(
              onTap: () => _showMonthPickerSheet(isDark),
              borderRadius: BorderRadius.circular(8),
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 4),
                child: Column(
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          "$monthName $_selectedYear",
                          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: AppColors.getTextPrimary(isDark)),
                        ),
                        const SizedBox(width: 4),
                        Icon(Icons.keyboard_arrow_down_rounded, size: 20, color: AppColors.getTextMuted(isDark)),
                      ],
                    ),
                    Text(
                      "اضغط لتغيير الشهر أو السنة",
                      style: TextStyle(fontSize: 10, color: AppColors.getTextMuted(isDark)),
                    ),
                  ],
                ),
              ),
            ),
          ),

          // Next Month button (points left in RTL)
          IconButton(
            icon: const Icon(Icons.chevron_left_rounded, color: AppColors.primaryLight, size: 28),
            tooltip: "الشهر التالي",
            visualDensity: VisualDensity.compact,
            onPressed: _nextMonth,
          ),

          // Current Month Jump Button
          if (!isCurrentMonth)
            TextButton.icon(
              style: TextButton.styleFrom(
                backgroundColor: AppColors.primaryLight.withOpacity(0.12),
                foregroundColor: AppColors.primaryLight,
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
              ),
              onPressed: _goToCurrentMonth,
              icon: const Icon(Icons.history_rounded, size: 16),
              label: const Text("الحالي", style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold)),
            ),
        ],
      ),
    );
  }

  // ==========================================
  // KPI Cards Section (Exact 1-to-1 Desktop Cards)
  // ==========================================
  Widget _buildKpiCardsSection(bool isDark) {
    final rep = _report!;

    return Column(
      children: [
        // Primary Row: Net Sales & Collected Cash
        Row(
          children: [
            Expanded(
              child: _buildDesktopKpiCard(
                isDark,
                accentColor: AppColors.success,
                title: "صافي المبيعات",
                subtitle: "شامل النقدي والآجل",
                valueText: "${_currencyFormatter.format(rep.netMonthlySales)} ج.م",
                icon: Icons.point_of_sale_rounded,
                tags: [
                  _buildMiniTag("نقدي", rep.totalMonthlyCashSales, AppColors.success, isDark),
                  _buildMiniTag("آجل", rep.totalMonthlyCreditSales, AppColors.warning, isDark),
                ],
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: _buildDesktopKpiCard(
                isDark,
                accentColor: AppColors.primaryLight,
                title: "المقبوض والمحصل الفعلي",
                subtitle: "كاش الخزينة",
                valueText: "${_currencyFormatter.format(rep.totalMonthlyCollected)} ج.م",
                icon: Icons.account_balance_wallet_rounded,
                tags: [
                  _buildMiniTag("مبيعات", rep.totalMonthlyCashSales, AppColors.primaryLight, isDark),
                  _buildMiniTag("تحصيلات", rep.totalMonthlyDebtCollections, AppColors.cyan, isDark),
                ],
              ),
            ),
          ],
        ),

        const SizedBox(height: 10),

        // Secondary Row: New Credit Debts & Returns
        Row(
          children: [
            Expanded(
              child: _buildDesktopKpiCard(
                isDark,
                accentColor: AppColors.warning,
                title: "الديون الآجلة الجديدة",
                subtitle: "ذمم معلقة على فواتير الشهر",
                valueText: "${_currencyFormatter.format(rep.totalMonthlyCreditSales)} ج.م",
                icon: Icons.receipt_long_rounded,
                footerText: "مستحقات بيع آجل (بدون الأقساط)",
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: _buildDesktopKpiCard(
                isDark,
                accentColor: AppColors.danger,
                title: "إجمالي المرتجعات",
                subtitle: "مستردات للعملاء",
                valueText: "${_currencyFormatter.format(rep.totalMonthlyReturns)} ج.م",
                icon: Icons.replay_rounded,
                footerText: rep.totalMonthlyReturns > 0 ? "خصم من أصل المبيعات" : "لا توجد مرتجعات لهذا الشهر",
              ),
            ),
          ],
        ),

        const SizedBox(height: 10),

        // Third Row: Net Profit & Invoices/Activity
        Row(
          children: [
            Expanded(
              child: _buildDesktopKpiCard(
                isDark,
                accentColor: AppColors.cyan,
                title: "صافي الأرباح المحققة",
                subtitle: "من المقبوض الفعلي",
                valueText: "${_currencyFormatter.format(rep.netProfit)} ج.م",
                icon: Icons.trending_up_rounded,
                footerText: "المقبوض - المشتريات - المصروفات",
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: _buildDesktopKpiCard(
                isDark,
                accentColor: AppColors.purple,
                title: "عدد الفواتير وأيام العمل",
                subtitle: "${rep.totalMonthlyInvoices} فاتورة",
                valueText: "${rep.activeDaysCount} / ${rep.daysInMonth} يوم",
                icon: Icons.calendar_month_rounded,
                footerText: "متوسط: ${_currencyFormatter.format(rep.dailyAverageSales)} ج.م/يوم",
              ),
            ),
          ],
        ),

        const SizedBox(height: 10),

        // Fourth Row: Purchases & Expenses Summary Strip
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
          decoration: BoxDecoration(
            color: AppColors.getSurface(isDark),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: AppColors.getBorder(isDark)),
          ),
          child: Row(
            children: [
              Expanded(
                child: Row(
                  children: [
                    const Icon(Icons.shopping_bag_rounded, size: 16, color: AppColors.primaryLight),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text("مشتريات بضاعة", style: TextStyle(fontSize: 10, color: AppColors.getTextMuted(isDark))),
                          Text("${_currencyFormatter.format(rep.totalMonthlyPurchases)} ج.م",
                              style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: AppColors.getTextPrimary(isDark))),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              Container(width: 1, height: 28, color: AppColors.getBorder(isDark)),
              const SizedBox(width: 12),
              Expanded(
                child: Row(
                  children: [
                    const Icon(Icons.outbox_rounded, size: 16, color: AppColors.danger),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text("مصروفات تشغيل", style: TextStyle(fontSize: 10, color: AppColors.getTextMuted(isDark))),
                          Text("${_currencyFormatter.format(rep.totalMonthlyExpenses)} ج.م",
                              style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: AppColors.danger)),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildDesktopKpiCard(
    bool isDark, {
    required Color accentColor,
    required String title,
    required String subtitle,
    required String valueText,
    required IconData icon,
    List<Widget>? tags,
    String? footerText,
  }) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.getSurface(isDark),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.getBorder(isDark)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(isDark ? 0.2 : 0.03),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header with icon and title
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: accentColor.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(icon, color: accentColor, size: 16),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: AppColors.getTextPrimary(isDark)),
                ),
              ),
            ],
          ),

          const SizedBox(height: 8),

          // Main value
          FittedBox(
            fit: BoxFit.scaleDown,
            alignment: Alignment.centerRight,
            child: Text(
              valueText,
              style: TextStyle(fontSize: 15, fontWeight: FontWeight.w900, color: accentColor),
            ),
          ),

          const SizedBox(height: 6),

          // Subtitle / tags
          if (tags != null && tags.isNotEmpty)
            Row(children: tags.map((t) => Expanded(child: t)).toList())
          else if (footerText != null)
            Text(
              footerText,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(fontSize: 9.5, color: AppColors.getTextMuted(isDark)),
            ),
        ],
      ),
    );
  }

  Widget _buildMiniTag(String label, double val, Color color, bool isDark) {
    return Container(
      margin: const EdgeInsets.only(left: 4),
      padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        "$label: ${_integerFormatter.format(val)}",
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: TextStyle(fontSize: 9, fontWeight: FontWeight.bold, color: color),
      ),
    );
  }

  // ==========================================
  // Metric Selector Dropdown & View Mode Switcher
  // ==========================================
  Widget _buildMetricAndToggleBar(bool isDark) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: AppColors.getSurface(isDark),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.getBorder(isDark)),
      ),
      child: Row(
        children: [
          // Metric Dropdown Selector
          Expanded(
            child: Row(
              children: [
                const Icon(Icons.tune_rounded, size: 18, color: AppColors.primaryLight),
                const SizedBox(width: 8),
                Expanded(
                  child: DropdownButtonHideUnderline(
                    child: DropdownButton<String>(
                      isExpanded: true,
                      value: _selectedDisplayMetric,
                      icon: const Icon(Icons.arrow_drop_down, color: AppColors.primaryLight),
                      style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: AppColors.getTextPrimary(isDark)),
                      dropdownColor: AppColors.getSurface(isDark),
                      items: _metricTitles.entries.map((entry) {
                        return DropdownMenuItem<String>(
                          value: entry.key,
                          child: Text(entry.value, maxLines: 1, overflow: TextOverflow.ellipsis),
                        );
                      }).toList(),
                      onChanged: (newVal) {
                        if (newVal != null) {
                          setState(() => _selectedDisplayMetric = newVal);
                        }
                      },
                    ),
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(width: 8),

          // View Switcher (Calendar vs List)
          Container(
            padding: const EdgeInsets.all(2),
            decoration: BoxDecoration(
              color: AppColors.getBackground(isDark),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              children: [
                _buildViewToggleButton(
                  icon: Icons.calendar_month_rounded,
                  tooltip: "عرض التقويم",
                  isSelected: _viewMode == "calendar",
                  onTap: () => setState(() => _viewMode = "calendar"),
                  isDark: isDark,
                ),
                _buildViewToggleButton(
                  icon: Icons.view_list_rounded,
                  tooltip: "عرض القائمة",
                  isSelected: _viewMode == "list",
                  onTap: () => setState(() => _viewMode = "list"),
                  isDark: isDark,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildViewToggleButton({
    required IconData icon,
    required String tooltip,
    required bool isSelected,
    required VoidCallback onTap,
    required bool isDark,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(6),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.primaryLight : Colors.transparent,
          borderRadius: BorderRadius.circular(6),
        ),
        child: Icon(
          icon,
          size: 18,
          color: isSelected ? Colors.white : AppColors.getTextMuted(isDark),
        ),
      ),
    );
  }

  // ==========================================
  // Calendar Grid (7 Columns RTL: السبت -> الجمعة)
  // ==========================================
  Widget _buildCalendarGrid(bool isDark) {
    if (_report == null || _report!.days.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Text("لا توجد مبيعات أو بيانات مسجلة لهذا الشهر", style: TextStyle(color: AppColors.getTextMuted(isDark))),
        ),
      );
    }

    final rep = _report!;
    final firstDayOffset = rep.firstDayDayOfWeek % 7;
    final totalDays = rep.days.length;
    final trailingCount = (7 - ((firstDayOffset + totalDays) % 7)) % 7;

    return Directionality(
      textDirection: TextDirection.rtl,
      child: Container(
        decoration: BoxDecoration(
          color: AppColors.getSurface(isDark),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppColors.getBorder(isDark)),
        ),
        padding: const EdgeInsets.all(10),
        child: Column(
          children: [
            // Weekday Header (السبت -> الجمعة)
            Row(
              children: _arabicWeekdays.map((w) {
                return Expanded(
                  child: Container(
                    padding: const EdgeInsets.symmetric(vertical: 6),
                    margin: const EdgeInsets.symmetric(horizontal: 1.5),
                    decoration: BoxDecoration(
                      color: isDark ? const Color(0xFF1E293B) : const Color(0xFFF1F5F9),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    alignment: Alignment.center,
                    child: Text(
                      w,
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                        color: w == "الجمعة" ? AppColors.danger : AppColors.getTextPrimary(isDark),
                      ),
                    ),
                  ),
                );
              }).toList(),
            ),

            const SizedBox(height: 6),

            // Days Grid
            GridView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 7,
                mainAxisSpacing: 4,
                crossAxisSpacing: 3,
                childAspectRatio: 0.72,
              ),
              itemCount: firstDayOffset + totalDays + trailingCount,
              itemBuilder: (context, index) {
                // Leading Empty Cells
                if (index < firstDayOffset) {
                  return Container(
                    decoration: BoxDecoration(
                      color: Colors.transparent,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: AppColors.getBorder(isDark).withOpacity(0.3), style: BorderStyle.solid),
                    ),
                  );
                }

                // Trailing Empty Cells
                final dayIdx = index - firstDayOffset;
                if (dayIdx >= totalDays) {
                  return Container(
                    decoration: BoxDecoration(
                      color: Colors.transparent,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: AppColors.getBorder(isDark).withOpacity(0.3), style: BorderStyle.solid),
                    ),
                  );
                }

                final day = rep.days[dayIdx];
                return _buildCalendarDayCell(day, isDark);
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCalendarDayCell(MonthlyDayData day, bool isDark) {
    final rep = _report!;
    final isPeak = rep.highestSalesDay == day.dayNumber && day.totalSales > 0;
    final metricVal = _getMetricValue(day);
    final metricText = _formatMetricDisplay(metricVal);

    Color cellBorderColor = AppColors.getBorder(isDark);
    Color cellBgColor = isDark ? const Color(0xFF0F172A) : const Color(0xFFFAFAFA);

    if (day.isToday) {
      cellBorderColor = AppColors.primaryLight;
      cellBgColor = AppColors.primaryLight.withOpacity(0.08);
    } else if (isPeak) {
      cellBorderColor = Colors.amber;
      cellBgColor = Colors.amber.withOpacity(0.12);
    } else if (day.hasSales) {
      cellBorderColor = AppColors.success.withOpacity(0.35);
      cellBgColor = AppColors.success.withOpacity(0.04);
    }

    return InkWell(
      onTap: () => _showDayDetailsModal(day, isDark),
      borderRadius: BorderRadius.circular(8),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 2, vertical: 3),
        decoration: BoxDecoration(
          color: cellBgColor,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: cellBorderColor, width: day.isToday || isPeak ? 1.5 : 0.8),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            // Top: Day number badge & peak indicator
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                if (isPeak)
                  const Icon(Icons.star_rounded, size: 12, color: Colors.amber)
                else if (day.isToday)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 3, vertical: 1),
                    decoration: BoxDecoration(color: AppColors.primaryLight, borderRadius: BorderRadius.circular(4)),
                    child: const Text("اليوم", style: TextStyle(color: Colors.white, fontSize: 7, fontWeight: FontWeight.bold)),
                  )
                else
                  const SizedBox(width: 8),

                // Day number
                Container(
                  width: 18,
                  height: 18,
                  decoration: BoxDecoration(
                    color: day.isToday
                        ? AppColors.primaryLight
                        : (isDark ? Colors.white10 : Colors.black.withOpacity(0.05)),
                    shape: BoxShape.circle,
                  ),
                  alignment: Alignment.center,
                  child: Text(
                    "${day.dayNumber}",
                    style: TextStyle(
                      fontSize: 9.5,
                      fontWeight: FontWeight.bold,
                      color: day.isToday ? Colors.white : AppColors.getTextPrimary(isDark),
                    ),
                  ),
                ),
              ],
            ),

            // Middle: Metric Value
            FittedBox(
              fit: BoxFit.scaleDown,
              child: Text(
                metricText,
                style: TextStyle(
                  fontSize: 10.5,
                  fontWeight: FontWeight.w900,
                  color: metricVal > 0
                      ? (_selectedDisplayMetric == "Expenses"
                          ? AppColors.danger
                          : (_selectedDisplayMetric == "Credit" ? AppColors.warning : AppColors.success))
                      : AppColors.getTextMuted(isDark),
                ),
              ),
            ),

            // Bottom Sub-stat (Invoices / Net / Returns)
            if (day.invoiceCount > 0 || day.totalReturns > 0)
              FittedBox(
                fit: BoxFit.scaleDown,
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (day.invoiceCount > 0)
                      Text(
                        "${day.invoiceCount}ف",
                        style: TextStyle(fontSize: 8, color: AppColors.getTextMuted(isDark)),
                      ),
                    if (day.totalReturns > 0)
                      Text(
                        " -${day.totalReturns.toInt()}",
                        style: const TextStyle(fontSize: 7.5, fontWeight: FontWeight.bold, color: AppColors.danger),
                      ),
                  ],
                ),
              )
            else
              const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }

  // ==========================================
  // Detailed Days List View (Alternative to Calendar)
  // ==========================================
  Widget _buildDetailedDaysList(bool isDark) {
    if (_report == null || _report!.days.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Text("لا توجد مبيعات أو بيانات مسجلة لهذا الشهر", style: TextStyle(color: AppColors.getTextMuted(isDark))),
        ),
      );
    }

    final rep = _report!;

    return ListView.separated(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: rep.days.length,
      separatorBuilder: (_, __) => const SizedBox(height: 8),
      itemBuilder: (context, index) {
        final day = rep.days[index];
        final isPeak = rep.highestSalesDay == day.dayNumber && day.totalSales > 0;

        return InkWell(
          onTap: () => _showDayDetailsModal(day, isDark),
          borderRadius: BorderRadius.circular(12),
          child: Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppColors.getSurface(isDark),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: day.isToday
                    ? AppColors.primaryLight
                    : (isPeak ? Colors.amber : (day.hasSales ? AppColors.success.withOpacity(0.3) : AppColors.getBorder(isDark))),
                width: day.isToday || isPeak ? 1.5 : 1,
              ),
            ),
            child: Row(
              children: [
                // Day Badge
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    color: day.isToday
                        ? AppColors.primaryLight.withOpacity(0.15)
                        : (isPeak ? Colors.amber.withOpacity(0.15) : AppColors.getBackground(isDark)),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(
                      color: day.isToday
                          ? AppColors.primaryLight
                          : (isPeak ? Colors.amber : AppColors.getBorder(isDark)),
                    ),
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        "${day.dayNumber}",
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: day.isToday
                              ? AppColors.primaryLight
                              : (isPeak ? Colors.amber.shade700 : AppColors.getTextPrimary(isDark)),
                        ),
                      ),
                      Text(
                        day.dayNameAr,
                        style: TextStyle(fontSize: 9, color: AppColors.getTextMuted(isDark)),
                      ),
                    ],
                  ),
                ),

                const SizedBox(width: 12),

                // Metrics summary
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Row(
                            children: [
                              Text(
                                "صافي المبيعات:",
                                style: TextStyle(fontSize: 11, color: AppColors.getTextMuted(isDark)),
                              ),
                              const SizedBox(width: 4),
                              Text(
                                "${_currencyFormatter.format(day.netSales)} ج.م",
                                style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: AppColors.success),
                              ),
                            ],
                          ),
                          if (isPeak)
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                              decoration: BoxDecoration(color: Colors.amber.withOpacity(0.2), borderRadius: BorderRadius.circular(4)),
                              child: const Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(Icons.star, size: 10, color: Colors.amber),
                                  SizedBox(width: 2),
                                  Text("أعلى يوم", style: TextStyle(fontSize: 9, fontWeight: FontWeight.bold, color: Colors.amber)),
                                ],
                              ),
                            ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              "نقدي: ${_integerFormatter.format(day.cashSales)} | آجل: ${_integerFormatter.format(day.creditSales)}",
                              style: TextStyle(fontSize: 10.5, color: AppColors.getTextMuted(isDark)),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          Text(
                            "${day.invoiceCount} فاتورة",
                            style: const TextStyle(fontSize: 10.5, fontWeight: FontWeight.bold, color: AppColors.primaryLight),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),

                const SizedBox(width: 8),
                const Icon(Icons.arrow_forward_ios_rounded, size: 14, color: AppColors.primaryLight),
              ],
            ),
          ),
        );
      },
    );
  }

  // ==========================================
  // Bottom Monthly Summary (Matching Desktop Footer)
  // ==========================================
  Widget _buildBottomSummaryCard(bool isDark) {
    final rep = _report!;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.getSurface(isDark),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.getBorder(isDark)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(isDark ? 0.25 : 0.04),
            blurRadius: 6,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: AppColors.success.withOpacity(0.12),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.check_circle_rounded, color: AppColors.success, size: 20),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      "إجمالي حصيلة شهر ${rep.monthNameAr} ${rep.year}",
                      style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: AppColors.getTextPrimary(isDark)),
                    ),
                    Text(
                      "متوسط البيع اليومي: ${_currencyFormatter.format(rep.dailyAverageSales)} ج.م",
                      style: TextStyle(fontSize: 11, color: AppColors.getTextMuted(isDark)),
                    ),
                  ],
                ),
              ),
            ],
          ),

          const Divider(height: 20),

          // Peak and Lowest Day badges
          Row(
            children: [
              Expanded(
                child: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.amber.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Row(
                        children: [
                          Icon(Icons.star_rounded, size: 14, color: Colors.amber),
                          SizedBox(width: 4),
                          Text("أعلى يوم مبيعات", style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.amber)),
                        ],
                      ),
                      const SizedBox(height: 2),
                      Text(
                        rep.highestSalesDay > 0 ? "يوم ${rep.highestSalesDay} (${_integerFormatter.format(rep.highestSalesAmount)} ج.م)" : "—",
                        style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: AppColors.getTextPrimary(isDark)),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: AppColors.cyan.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Row(
                        children: [
                          Icon(Icons.trending_down_rounded, size: 14, color: AppColors.cyan),
                          SizedBox(width: 4),
                          Text("أقل يوم مبيعات", style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: AppColors.cyan)),
                        ],
                      ),
                      const SizedBox(height: 2),
                      Text(
                        rep.lowestSalesDay > 0 ? "يوم ${rep.lowestSalesDay} (${_integerFormatter.format(rep.lowestSalesAmount)} ج.م)" : "—",
                        style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: AppColors.getTextPrimary(isDark)),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // ==========================================
  // Day Details Bottom Sheet (Interactive Modal)
  // ==========================================
  void _showDayDetailsModal(MonthlyDayData day, bool isDark) {
    final rep = _report!;
    final isPeak = rep.highestSalesDay == day.dayNumber && day.totalSales > 0;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        return Container(
          decoration: BoxDecoration(
            color: AppColors.getSurface(isDark),
            borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
          ),
          padding: EdgeInsets.only(
            top: 16,
            left: 16,
            right: 16,
            bottom: MediaQuery.of(ctx).padding.bottom + 16,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Drag Handle
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: AppColors.getBorder(isDark),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),

              const SizedBox(height: 14),

              // Title Header
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: AppColors.primaryLight.withOpacity(0.14),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      "${day.dayNumber}",
                      style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: AppColors.primaryLight),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          "تفاصيل يوم ${day.dayNameAr} (${day.dayNumber} ${rep.monthNameAr} ${rep.year})",
                          style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: AppColors.getTextPrimary(isDark)),
                        ),
                        Row(
                          children: [
                            if (day.isToday)
                              Container(
                                margin: const EdgeInsets.only(left: 6),
                                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
                                decoration: BoxDecoration(color: AppColors.primaryLight, borderRadius: BorderRadius.circular(4)),
                                child: const Text("اليوم", style: TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold)),
                              ),
                            if (isPeak)
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
                                decoration: BoxDecoration(color: Colors.amber, borderRadius: BorderRadius.circular(4)),
                                child: const Text("★ أعلى يوم مبيعات", style: TextStyle(color: Colors.black87, fontSize: 10, fontWeight: FontWeight.bold)),
                              ),
                            Text(
                              "${day.invoiceCount} فاتورة مبيعات",
                              style: TextStyle(fontSize: 11, color: AppColors.getTextMuted(isDark)),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: () => Navigator.pop(ctx),
                  ),
                ],
              ),

              const Divider(height: 24),

              // Breakdown 2-Column Grid
              GridView.count(
                crossAxisCount: 2,
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                childAspectRatio: 2.2,
                crossAxisSpacing: 10,
                mainAxisSpacing: 10,
                children: [
                  _buildModalDetailTile(isDark, "إجمالي المبيعات", "${_currencyFormatter.format(day.totalSales)} ج.م", AppColors.success, Icons.point_of_sale_rounded),
                  _buildModalDetailTile(isDark, "صافي المبيعات", "${_currencyFormatter.format(day.netSales)} ج.م", AppColors.success, Icons.check_circle_outline_rounded),
                  _buildModalDetailTile(isDark, "المبيعات النقدية (كاش)", "${_currencyFormatter.format(day.cashSales)} ج.م", AppColors.primaryLight, Icons.money_rounded),
                  _buildModalDetailTile(isDark, "مبيعات آجلة (ديون معلقة)", "${_currencyFormatter.format(day.creditSales)} ج.م", AppColors.warning, Icons.alarm_rounded),
                  _buildModalDetailTile(isDark, "تحصيلات ديون قديمة", "${_currencyFormatter.format(day.debtCollections)} ج.م", AppColors.cyan, Icons.payments_rounded),
                  _buildModalDetailTile(isDark, "المقبوض الكلي (الخزينة)", "${_currencyFormatter.format(day.totalPaid)} ج.م", AppColors.primaryLight, Icons.account_balance_wallet_rounded),
                  _buildModalDetailTile(isDark, "المرتجعات", "${_currencyFormatter.format(day.totalReturns)} ج.م", AppColors.danger, Icons.replay_rounded),
                  _buildModalDetailTile(isDark, "المشتريات", "${_currencyFormatter.format(day.totalPurchases)} ج.م", AppColors.purple, Icons.shopping_bag_rounded),
                  _buildModalDetailTile(isDark, "المصروفات", "${_currencyFormatter.format(day.totalExpenses)} ج.م", AppColors.danger, Icons.outbox_rounded),
                  _buildModalDetailTile(isDark, "الصافي النهائي لليوم", "${_currencyFormatter.format(day.net)} ج.م", day.net >= 0 ? AppColors.cyan : AppColors.danger, Icons.trending_up_rounded),
                ],
              ),

              const SizedBox(height: 18),

              // Action button to see invoices
              ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primaryLight,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                ),
                onPressed: () {
                  Navigator.pop(ctx);
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => const SalesListScreen(),
                    ),
                  );
                },
                icon: const Icon(Icons.receipt_long_rounded),
                label: const Text("استعراض فواتير مبيعات هذا اليوم", style: TextStyle(fontWeight: FontWeight.bold)),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildModalDetailTile(bool isDark, String title, String val, Color color, IconData icon) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: AppColors.getBackground(isDark),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: AppColors.getBorder(isDark)),
      ),
      child: Row(
        children: [
          Icon(icon, size: 18, color: color),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(title, style: TextStyle(fontSize: 10, color: AppColors.getTextMuted(isDark)), maxLines: 1, overflow: TextOverflow.ellipsis),
                const SizedBox(height: 2),
                FittedBox(
                  fit: BoxFit.scaleDown,
                  alignment: Alignment.centerRight,
                  child: Text(val, style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: color)),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ==========================================
  // Month & Year Picker Bottom Sheet
  // ==========================================
  void _showMonthPickerSheet(bool isDark) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        return Container(
          decoration: BoxDecoration(
            color: AppColors.getSurface(isDark),
            borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
          ),
          padding: EdgeInsets.only(
            top: 16,
            left: 16,
            right: 16,
            bottom: MediaQuery.of(ctx).padding.bottom + 16,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(color: AppColors.getBorder(isDark), borderRadius: BorderRadius.circular(2)),
                ),
              ),
              const SizedBox(height: 12),
              Text("اختر الشهر والسنة", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: AppColors.getTextPrimary(isDark))),
              const SizedBox(height: 12),

              // Year Selector
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  IconButton(
                    icon: const Icon(Icons.arrow_back_ios_rounded, size: 16),
                    onPressed: () {
                      setState(() => _selectedYear--);
                      Navigator.pop(ctx);
                      _fetchReport();
                    },
                  ),
                  Text("$_selectedYear", style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppColors.primaryLight)),
                  IconButton(
                    icon: const Icon(Icons.arrow_forward_ios_rounded, size: 16),
                    onPressed: () {
                      setState(() => _selectedYear++);
                      Navigator.pop(ctx);
                      _fetchReport();
                    },
                  ),
                ],
              ),

              const SizedBox(height: 8),

              // 12 Months Grid
              GridView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 4,
                  mainAxisSpacing: 8,
                  crossAxisSpacing: 8,
                  childAspectRatio: 2.2,
                ),
                itemCount: 12,
                itemBuilder: (context, idx) {
                  final mNum = idx + 1;
                  final isSelected = mNum == _selectedMonth;
                  return InkWell(
                    onTap: () {
                      setState(() => _selectedMonth = mNum);
                      Navigator.pop(ctx);
                      _fetchReport();
                    },
                    borderRadius: BorderRadius.circular(8),
                    child: Container(
                      decoration: BoxDecoration(
                        color: isSelected ? AppColors.primaryLight : AppColors.getBackground(isDark),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: isSelected ? AppColors.primaryLight : AppColors.getBorder(isDark)),
                      ),
                      alignment: Alignment.center,
                      child: Text(
                        _arabicMonths[idx],
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          color: isSelected ? Colors.white : AppColors.getTextPrimary(isDark),
                        ),
                      ),
                    ),
                  );
                },
              ),
            ],
          ),
        );
      },
    );
  }
}
