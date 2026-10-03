import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../../../core/constants/api_endpoints.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/network/api_client.dart';
import '../../../core/theme/theme_provider.dart';
import '../../../core/widgets/offline_banner.dart';
import '../models/sale_model.dart';
import '../providers/sales_provider.dart';
import 'mobile_pos_screen.dart';

class InstallmentsScreen extends StatefulWidget {
  const InstallmentsScreen({super.key});

  @override
  State<InstallmentsScreen> createState() => _InstallmentsScreenState();
}

class _InstallmentsScreenState extends State<InstallmentsScreen> {
  final ApiClient _apiClient = ApiClient();
  final TextEditingController _searchCtrl = TextEditingController();
  final NumberFormat _currencyFormatter = NumberFormat("#,##0.00", "ar_EG");

  bool _isLoading = false;
  String? _errorMessage;
  List<SaleSummaryModel> _contracts = [];
  int _selectedFilter = -1; // -1: All, 1: Active, 2: Completed, 3: Overdue

  @override
  void initState() {
    super.initState();
    _fetchContracts();
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  Future<void> _fetchContracts() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final res = await _apiClient.get(
        ApiEndpoints.sales,
        queryParams: {
          'isInstallment': 'true',
          'pageSize': 100,
        },
      );

      List<SaleSummaryModel> loaded = [];
      if (res != null && res is List) {
        loaded = res.map((i) => SaleSummaryModel.fromJson(i)).toList();
      } else if (res != null && res is Map<String, dynamic> && res['items'] != null) {
        loaded = (res['items'] as List).map((i) => SaleSummaryModel.fromJson(i)).toList();
      }

      setState(() {
        _contracts = loaded;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _errorMessage = e.toString();
        _isLoading = false;
      });
    }
  }

  List<SaleSummaryModel> get _filteredContracts {
    var list = _contracts;

    // Search filter
    final query = _searchCtrl.text.trim().toLowerCase();
    if (query.isNotEmpty) {
      list = list.where((c) {
        final inv = c.invoiceNumber.toLowerCase();
        final name = (c.customerName ?? '').toLowerCase();
        final phone = (c.customerPhone ?? '').toLowerCase();
        return inv.contains(query) || name.contains(query) || phone.contains(query);
      }).toList();
    }

    // Status filter
    if (_selectedFilter == 1) {
      // Active (Remaining > 0)
      list = list.where((c) => c.remainingAmount > 0.01).toList();
    } else if (_selectedFilter == 2) {
      // Completed (Remaining == 0)
      list = list.where((c) => c.remainingAmount <= 0.01).toList();
    } else if (_selectedFilter == 3) {
      // Overdue (active and older than 30 days)
      final thirtyDaysAgo = DateTime.now().subtract(const Duration(days: 30));
      list = list.where((c) => c.remainingAmount > 0.01 && c.saleDate.isBefore(thirtyDaysAgo)).toList();
    }

    return list;
  }

  double get _totalRemaining => _contracts.fold(0.0, (sum, c) => sum + c.remainingAmount);
  int get _activeCount => _contracts.where((c) => c.remainingAmount > 0.01).length;
  int get _completedCount => _contracts.where((c) => c.remainingAmount <= 0.01).length;
  int get _overdueCount {
    final thirtyDaysAgo = DateTime.now().subtract(const Duration(days: 30));
    return _contracts.where((c) => c.remainingAmount > 0.01 && c.saleDate.isBefore(thirtyDaysAgo)).length;
  }

  void _openPayModal(SaleSummaryModel contract, bool isDark) {
    final amountCtrl = TextEditingController(text: contract.remainingAmount > 0 ? (contract.totalAmount / 12).toStringAsFixed(0) : "0");
    final notesCtrl = TextEditingController();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.getSurface(isDark),
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (ctx) {
        return Padding(
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(ctx).viewInsets.bottom + 16,
            left: 16,
            right: 16,
            top: 16,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: AppColors.success.withOpacity(0.15),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.payments_rounded, color: AppColors.success, size: 22),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          "تحصيل قسط - ${contract.invoiceNumber}",
                          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: AppColors.getTextPrimary(isDark)),
                          overflow: TextOverflow.ellipsis,
                        ),
                        Text(
                          "العميل: ${contract.customerName ?? 'عميل تقسيط'}",
                          style: TextStyle(fontSize: 12, color: AppColors.getTextMuted(isDark)),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const Divider(height: 24),
              Row(
                children: [
                  Expanded(
                    child: _buildInfoTag(
                      isDark,
                      title: "إجمالي العقد",
                      value: "${_currencyFormatter.format(contract.totalAmount)} ج.م",
                      color: AppColors.primaryLight,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: _buildInfoTag(
                      isDark,
                      title: "المتبقي",
                      value: "${_currencyFormatter.format(contract.remainingAmount)} ج.م",
                      color: AppColors.danger,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 14),
              Text(
                "مبلغ القسط المحصل (ج.م) *",
                style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: AppColors.getTextSecondary(isDark)),
              ),
              const SizedBox(height: 6),
              TextField(
                controller: amountCtrl,
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                style: TextStyle(color: AppColors.getTextPrimary(isDark), fontSize: 16, fontWeight: FontWeight.bold),
                decoration: InputDecoration(
                  prefixIcon: const Icon(Icons.monetization_on_outlined, color: AppColors.success),
                  hintText: "أدخل المبلغ...",
                  filled: true,
                  fillColor: AppColors.getInputBackground(isDark),
                ),
              ),
              const SizedBox(height: 12),
              Text(
                "ملاحظات أو إيصال السداد",
                style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: AppColors.getTextSecondary(isDark)),
              ),
              const SizedBox(height: 6),
              TextField(
                controller: notesCtrl,
                style: TextStyle(color: AppColors.getTextPrimary(isDark), fontSize: 13),
                decoration: InputDecoration(
                  prefixIcon: const Icon(Icons.notes_rounded, color: AppColors.primaryLight),
                  hintText: "رقم إيصال استلام، ملاحظة...",
                  filled: true,
                  fillColor: AppColors.getInputBackground(isDark),
                ),
              ),
              const SizedBox(height: 18),
              SizedBox(
                width: double.infinity,
                height: 46,
                child: ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.success,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  icon: const Icon(Icons.check_circle_rounded, color: Colors.white),
                  label: const Text("تأكيد تحصيل وسداد القسط", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14)),
                  onPressed: () async {
                    final amt = double.tryParse(amountCtrl.text) ?? 0;
                    if (amt <= 0) {
                      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("يرجى إدخال مبلغ صحيح أكبر من الصفر.")));
                      return;
                    }
                    Navigator.pop(ctx);
                    await _submitPayInstallment(contract.id, amt, notesCtrl.text.trim());
                  },
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Future<void> _submitPayInstallment(String saleId, double amount, String notes) async {
    setState(() => _isLoading = true);
    try {
      await _apiClient.post(
        ApiEndpoints.paySaleInstallment(saleId),
        body: {
          'amount': amount,
          'notes': notes.isNotEmpty ? notes : null,
        },
      );
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text("تم تسجيل سداد مبلغ ${_currencyFormatter.format(amount)} ج.م بنجاح."),
            backgroundColor: AppColors.success,
          ),
        );
      }
      await _fetchContracts();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text("فشل السداد: $e"),
            backgroundColor: AppColors.danger,
          ),
        );
      }
      setState(() => _isLoading = false);
    }
  }

  Widget _buildInfoTag(bool isDark, {required String title, required String value, required Color color}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: TextStyle(fontSize: 10, color: AppColors.getTextMuted(isDark))),
          const SizedBox(height: 2),
          FittedBox(
            fit: BoxFit.scaleDown,
            alignment: Alignment.centerRight,
            child: Text(value, style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: color)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Provider.of<ThemeProvider>(context).isDarkMode;
    final filtered = _filteredContracts;

    return Scaffold(
      backgroundColor: AppColors.getBackground(isDark),
      appBar: AppBar(
        backgroundColor: AppColors.getSurface(isDark),
        elevation: 0,
        title: Text(
          "عقود التقسيط والتمويل الاستهلاكي",
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: AppColors.getTextPrimary(isDark)),
        ),
        actions: [
          IconButton(
            icon: Icon(Icons.refresh_rounded, color: AppColors.getTextPrimary(isDark)),
            tooltip: "تحديث",
            onPressed: _fetchContracts,
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: AppColors.primary,
        icon: const Icon(Icons.add_shopping_cart_rounded, color: Colors.white),
        label: const Text("عقد تقسيط جديد (POS)", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        onPressed: () {
          Navigator.push(context, MaterialPageRoute(builder: (_) => const MobilePosScreen()));
        },
      ),
      body: Column(
        children: [
          const OfflineBanner(),

          // Search Field
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
            child: Container(
              decoration: BoxDecoration(
                color: AppColors.getSurface(isDark),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: AppColors.getBorder(isDark)),
              ),
              child: TextField(
                controller: _searchCtrl,
                style: TextStyle(color: AppColors.getTextPrimary(isDark), fontSize: 14),
                decoration: InputDecoration(
                  hintText: "بحث برقم العقد، اسم العميل، أو الهاتف...",
                  hintStyle: TextStyle(color: AppColors.getTextMuted(isDark), fontSize: 13),
                  prefixIcon: const Icon(Icons.search_rounded, color: AppColors.primaryLight),
                  suffixIcon: _searchCtrl.text.isNotEmpty
                      ? IconButton(
                          icon: const Icon(Icons.clear_rounded, size: 18),
                          onPressed: () {
                            _searchCtrl.clear();
                            setState(() {});
                          },
                        )
                      : null,
                  border: InputBorder.none,
                  contentPadding: const EdgeInsets.symmetric(vertical: 14),
                ),
                onChanged: (_) => setState(() {}),
              ),
            ),
          ),

          // KPI Statistics Cards Row (Safely wrapped with FittedBox and Expanded to eliminate overflow)
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              children: [
                Expanded(
                  child: _buildMetricTile(
                    isDark,
                    title: "إجمالي العقود",
                    value: "${_contracts.length}",
                    sub: "عقد مسجل",
                    color: AppColors.primaryLight,
                    icon: Icons.assignment_rounded,
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: _buildMetricTile(
                    isDark,
                    title: "المبالغ القائمة",
                    value: "${_currencyFormatter.format(_totalRemaining)} ج.م",
                    sub: "مستحقات آجلة",
                    color: AppColors.success,
                    icon: Icons.account_balance_wallet_rounded,
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
                  child: _buildMetricTile(
                    isDark,
                    title: "جاري السداد",
                    value: "$_activeCount",
                    sub: "عقد نشط",
                    color: AppColors.cyan,
                    icon: Icons.trending_up_rounded,
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: _buildMetricTile(
                    isDark,
                    title: "أقساط متأخرة",
                    value: "$_overdueCount",
                    sub: "تجاوزت الموعد",
                    color: AppColors.danger,
                    icon: Icons.warning_amber_rounded,
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 10),

          // Status Filter Pills Bar (Horizontal Scroll to avoid overflow)
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              children: [
                _buildFilterChip(isDark, "الكل (${_contracts.length})", -1),
                const SizedBox(width: 8),
                _buildFilterChip(isDark, "جاري السداد ($_activeCount)", 1),
                const SizedBox(width: 8),
                _buildFilterChip(isDark, "مسدد بالكامل ($_completedCount)", 2),
                const SizedBox(width: 8),
                _buildFilterChip(isDark, "متأخر ومستحق ($_overdueCount)", 3),
              ],
            ),
          ),

          const SizedBox(height: 10),

          // Contract List
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator(color: AppColors.primaryLight))
                : _errorMessage != null
                    ? Center(
                        child: Padding(
                          padding: const EdgeInsets.all(20),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              const Icon(Icons.error_outline_rounded, color: AppColors.danger, size: 48),
                              const SizedBox(height: 8),
                              Text("خطأ في جلب عقود التقسيط: $_errorMessage", textAlign: TextAlign.center, style: TextStyle(color: AppColors.getTextMuted(isDark), fontSize: 13)),
                              const SizedBox(height: 12),
                              ElevatedButton(onPressed: _fetchContracts, child: const Text("إعادة المحاولة")),
                            ],
                          ),
                        ),
                      )
                    : filtered.isEmpty
                        ? Center(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(Icons.assignment_outlined, size: 56, color: AppColors.getTextMuted(isDark)),
                                const SizedBox(height: 12),
                                Text("لا توجد عقود تقسيط مطابقة", style: TextStyle(color: AppColors.getTextMuted(isDark), fontSize: 14)),
                                const SizedBox(height: 4),
                                Text("يتم إنشاء عقود التقسيط تلقائياً عند بيع أجهزة بالتقسيط من الـ POS", style: TextStyle(color: AppColors.getTextMuted(isDark), fontSize: 11)),
                              ],
                            ),
                          )
                        : RefreshIndicator(
                            onRefresh: _fetchContracts,
                            child: ListView.separated(
                              padding: const EdgeInsets.fromLTRB(16, 8, 16, 80),
                              itemCount: filtered.length,
                              separatorBuilder: (_, __) => const SizedBox(height: 12),
                              itemBuilder: (ctx, idx) {
                                final contract = filtered[idx];
                                return _buildContractCard(contract, isDark);
                              },
                            ),
                          ),
          ),
        ],
      ),
    );
  }

  Widget _buildMetricTile(
    bool isDark, {
    required String title,
    required String value,
    required String sub,
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
                Text(sub, style: TextStyle(fontSize: 9.5, color: AppColors.getTextMuted(isDark)), maxLines: 1, overflow: TextOverflow.ellipsis),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterChip(bool isDark, String label, int filterVal) {
    final isSelected = _selectedFilter == filterVal;
    return GestureDetector(
      onTap: () => setState(() => _selectedFilter = filterVal),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.primary : AppColors.getSurface(isDark),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: isSelected ? AppColors.primary : AppColors.getBorder(isDark)),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: isSelected ? Colors.white : AppColors.getTextSecondary(isDark),
            fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
            fontSize: 12,
          ),
        ),
      ),
    );
  }

  Widget _buildContractCard(SaleSummaryModel c, bool isDark) {
    final isCompleted = c.remainingAmount <= 0.01;
    final progress = c.totalAmount > 0 ? (c.paidAmount / c.totalAmount).clamp(0.0, 1.0) : 1.0;

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.getSurface(isDark),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isCompleted ? AppColors.success.withOpacity(0.3) : AppColors.getBorder(isDark),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Row 1: Invoice #, Date, Status
          Row(
            children: [
              Expanded(
                child: Row(
                  children: [
                    Icon(Icons.description_rounded, size: 16, color: AppColors.primaryLight),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Text(
                        "عقد: ${c.invoiceNumber}",
                        style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13.5, color: AppColors.getTextPrimary(isDark)),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: isCompleted ? AppColors.success.withOpacity(0.15) : AppColors.primary.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  isCompleted ? "مسدد بالكامل ✓" : "ساري الدفع",
                  style: TextStyle(
                    fontSize: 10.5,
                    fontWeight: FontWeight.bold,
                    color: isCompleted ? AppColors.success : AppColors.primaryLight,
                  ),
                ),
              ),
            ],
          ),

          const SizedBox(height: 8),

          // Row 2: Customer Name & Phone
          Row(
            children: [
              const Icon(Icons.person_outline_rounded, size: 15, color: AppColors.cyan),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  c.customerName ?? "عميل تقسيط",
                  style: TextStyle(fontWeight: FontWeight.w600, fontSize: 12.5, color: AppColors.getTextPrimary(isDark)),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              if (c.customerPhone != null && c.customerPhone!.isNotEmpty) ...[
                const SizedBox(width: 8),
                const Icon(Icons.phone_outlined, size: 13, color: AppColors.cyan),
                const SizedBox(width: 4),
                Text(
                  c.customerPhone!,
                  style: TextStyle(fontSize: 11.5, color: AppColors.getTextMuted(isDark), fontFamily: 'monospace'),
                ),
              ],
            ],
          ),

          const SizedBox(height: 10),

          // Progress Bar
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: progress,
              backgroundColor: isDark ? AppColors.darkSurfaceElevated : AppColors.lightSurfaceElevated,
              valueColor: AlwaysStoppedAnimation<Color>(isCompleted ? AppColors.success : AppColors.primaryLight),
              minHeight: 6,
            ),
          ),

          const SizedBox(height: 10),

          // Row 3: Totals Breakdown (Safely contained)
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text("إجمالي العقد", style: TextStyle(fontSize: 10, color: AppColors.getTextMuted(isDark))),
                    FittedBox(
                      fit: BoxFit.scaleDown,
                      alignment: Alignment.centerRight,
                      child: Text("${_currencyFormatter.format(c.totalAmount)} ج.م", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: AppColors.getTextPrimary(isDark))),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text("المسدد", style: TextStyle(fontSize: 10, color: AppColors.getTextMuted(isDark))),
                    FittedBox(
                      fit: BoxFit.scaleDown,
                      alignment: Alignment.centerRight,
                      child: Text("${_currencyFormatter.format(c.paidAmount)} ج.م", style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: AppColors.success)),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text("المتبقي", style: TextStyle(fontSize: 10, color: AppColors.getTextMuted(isDark))),
                    FittedBox(
                      fit: BoxFit.scaleDown,
                      alignment: Alignment.centerRight,
                      child: Text("${_currencyFormatter.format(c.remainingAmount)} ج.م", style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: AppColors.danger)),
                    ),
                  ],
                ),
              ),
            ],
          ),

          if (!isCompleted) ...[
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              height: 38,
              child: ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  elevation: 0,
                ),
                icon: const Icon(Icons.payments_rounded, size: 16, color: Colors.white),
                label: const Text("سداد / تحصيل قسط", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 12)),
                onPressed: () => _openPayModal(c, isDark),
              ),
            ),
          ],
        ],
      ),
    );
  }
}
