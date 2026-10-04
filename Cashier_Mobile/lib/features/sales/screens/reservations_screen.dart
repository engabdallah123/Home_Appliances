import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../../../core/constants/api_endpoints.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/network/api_client.dart';
import '../../../core/theme/theme_provider.dart';
import '../../../core/widgets/offline_banner.dart';
import '../models/sale_model.dart';
import 'mobile_pos_screen.dart';

class ReservationsScreen extends StatefulWidget {
  const ReservationsScreen({super.key});

  @override
  State<ReservationsScreen> createState() => _ReservationsScreenState();
}

class _ReservationsScreenState extends State<ReservationsScreen> {
  final ApiClient _apiClient = ApiClient();
  final TextEditingController _searchCtrl = TextEditingController();
  final NumberFormat _currencyFormatter = NumberFormat("#,##0.00", "ar_EG");

  bool _isLoading = false;
  String? _errorMessage;
  List<SaleSummaryModel> _reservations = [];
  int _selectedFilter = -1; // -1: All, 1: Stored in warehouse, 2: Partial delivery, 3: Completed

  final ScrollController _scrollController = ScrollController();
  int _currentPage = 1;
  bool _hasMore = true;
  bool _isLoadingMore = false;
  static const int _pageSize = 20;

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
    _fetchReservations();
  }

  @override
  void dispose() {
    _scrollController.removeListener(_onScroll);
    _scrollController.dispose();
    _searchCtrl.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (_scrollController.position.pixels >= _scrollController.position.maxScrollExtent - 200 &&
        !_isLoadingMore &&
        _hasMore &&
        !_isLoading) {
      _loadMoreReservations();
    }
  }

  Future<void> _fetchReservations({bool refresh = true}) async {
    if (refresh) {
      setState(() {
        _isLoading = true;
        _errorMessage = null;
        _currentPage = 1;
        _hasMore = true;
      });
    }

    try {
      final res = await _apiClient.get(
        ApiEndpoints.sales,
        queryParams: {
          'isReserved': 'true',
          'page': _currentPage,
          'pageSize': _pageSize,
        },
      );

      List<SaleSummaryModel> loaded = [];
      if (res != null && res is List) {
        loaded = res.map((i) => SaleSummaryModel.fromJson(i)).toList();
      } else if (res != null && res is Map<String, dynamic> && res['items'] != null) {
        loaded = (res['items'] as List).map((i) => SaleSummaryModel.fromJson(i)).toList();
      }

      setState(() {
        if (refresh) {
          _reservations = loaded;
        } else {
          _reservations.addAll(loaded);
        }
        _hasMore = loaded.length >= _pageSize;
        _isLoading = false;
        _isLoadingMore = false;
      });
    } catch (e) {
      setState(() {
        _errorMessage = e.toString();
        _isLoading = false;
        _isLoadingMore = false;
      });
    }
  }

  Future<void> _loadMoreReservations() async {
    if (_isLoadingMore || !_hasMore || _isLoading) return;
    setState(() {
      _isLoadingMore = true;
      _currentPage++;
    });
    await _fetchReservations(refresh: false);
  }

  int _effectiveStatus(SaleSummaryModel r) {
    if (r.reservationStatus > 0) return r.reservationStatus;
    return 1; // Default to Reserved (In Warehouse)
  }

  String _getStatusText(int status, bool isReserved) {
    switch (status) {
      case 1:
        return "محجوز بالمخزن 🏠";
      case 2:
        return "تسليم جزئي 🚚";
      case 3:
        return "تم التسليم بالكامل ✓";
      case 4:
        return "ملغي / مسترجع ↩";
        
      default:
        return isReserved ? "محجوز بالمخزن 🏠" : "عادي";
    }
  }

  Color _getStatusColor(int status) {
    switch (status) {
      case 1:
        return AppColors.warning;
      case 2:
        return AppColors.cyan;
      case 3:
        return AppColors.success;
      case 4:
        return AppColors.danger;
      default:
        return AppColors.primary;
    }
  }

  List<SaleSummaryModel> get _filteredReservations {
    var list = _reservations;

    final query = _searchCtrl.text.trim().toLowerCase();
    if (query.isNotEmpty) {
      list = list.where((r) {
        final inv = r.invoiceNumber.toLowerCase();
        final name = (r.customerName ?? '').toLowerCase();
        final phone = (r.customerPhone ?? '').toLowerCase();
        return inv.contains(query) || name.contains(query) || phone.contains(query);
      }).toList();
    }

    if (_selectedFilter != -1) {
      list = list.where((r) => _effectiveStatus(r) == _selectedFilter).toList();
    }

    return list;
  }

  double get _totalReservedValue => _reservations.fold(0.0, (sum, r) => sum + r.totalAmount);
  int get _storedCount => _reservations.where((r) => _effectiveStatus(r) == 1).length;
  int get _partialCount => _reservations.where((r) => _effectiveStatus(r) == 2).length;
  int get _deliveredCount => _reservations.where((r) => _effectiveStatus(r) == 3).length;

  @override
  Widget build(BuildContext context) {
    final isDark = Provider.of<ThemeProvider>(context).isDarkMode;
    final filtered = _filteredReservations;

    return Scaffold(
      backgroundColor: AppColors.getBackground(isDark),
      appBar: AppBar(
        backgroundColor: AppColors.getSurface(isDark),
        elevation: 0,
        title: Text(
          "حجوزات الأجهزة الكهربائية",
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: AppColors.getTextPrimary(isDark)),
        ),
        actions: [
          IconButton(
            icon: Icon(Icons.refresh_rounded, color: AppColors.getTextPrimary(isDark)),
            tooltip: "تحديث",
            onPressed: _fetchReservations,
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: AppColors.primary,
        icon: const Icon(Icons.bookmark_add_rounded, color: Colors.white),
        label: const Text("تسجيل حجز أجهزة كهربائية (POS)", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
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
                  hintText: "بحث برقم الحجز، اسم العميل، أو الهاتف...",
                  hintStyle: TextStyle(color: AppColors.getTextMuted(isDark), fontSize: 13),
                  prefixIcon: const Icon(Icons.search_rounded, color: AppColors.primary),
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

          // KPI Statistics Cards Row (Safely wrapped)
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              children: [
                Expanded(
                  child: _buildMetricTile(
                    isDark,
                    title: "إجمالي الحجوزات",
                    value: "${_reservations.length}",
                    sub: "طلب حجز أجهزة",
                    color: AppColors.primary,
                    icon: Icons.bookmark_added_rounded,
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: _buildMetricTile(
                    isDark,
                    title: "بضاعة محجوزة بالمخزن",
                    value: "$_storedCount",
                    sub: "بانتظار موعد التسليم",
                    color: AppColors.warning,
                    icon: Icons.warehouse_rounded,
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
                    title: "تم تسليمها",
                    value: "$_deliveredCount",
                    sub: "خرجت للعميل",
                    color: AppColors.success,
                    icon: Icons.check_circle_rounded,
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: _buildMetricTile(
                    isDark,
                    title: "قيمة البضاعة المحجوزة",
                    value: "${_currencyFormatter.format(_totalReservedValue)} ج.م",
                    sub: "إجمالي مالي",
                    color: AppColors.cyan,
                    icon: Icons.paid_rounded,
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 10),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              children: [
                _buildFilterChip(isDark, "الكل (${_reservations.length})", -1),
                const SizedBox(width: 8),
                _buildFilterChip(isDark, "محجوز بالمخزن ($_storedCount)", 1),
                const SizedBox(width: 8),
                _buildFilterChip(isDark, "تسليم جزئي ($_partialCount)", 2),
                const SizedBox(width: 8),
                _buildFilterChip(isDark, "تم التسليم بالكامل ($_deliveredCount)", 3),
              ],
            ),
          ),

          const SizedBox(height: 10),

          // Reservations List
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator(color: AppColors.primary))
                : _errorMessage != null
                    ? Center(
                        child: Padding(
                          padding: const EdgeInsets.all(20),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              const Icon(Icons.error_outline_rounded, color: AppColors.danger, size: 48),
                              const SizedBox(height: 8),
                              Text("خطأ: $_errorMessage", style: TextStyle(color: AppColors.getTextMuted(isDark), fontSize: 13)),
                              const SizedBox(height: 12),
                              ElevatedButton(onPressed: _fetchReservations, child: const Text("إعادة المحاولة")),
                            ],
                          ),
                        ),
                      )
                    : filtered.isEmpty
                        ? Center(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                const Icon(Icons.bookmark_border_rounded, size: 56, color: AppColors.primary),
                                const SizedBox(height: 12),
                                Text("لا توجد حجوزات أجهزة مسجلة", style: TextStyle(color: AppColors.getTextMuted(isDark), fontSize: 14)),
                                const SizedBox(height: 4),
                                Text("يمكنك تفعيل خيار (حجز مسبق للأجهزة) في شاشة البيع POS", style: TextStyle(color: AppColors.getTextMuted(isDark), fontSize: 11)),
                              ],
                            ),
                          )
                        : RefreshIndicator(
                            onRefresh: () => _fetchReservations(refresh: true),
                            child: ListView.separated(
                              controller: _scrollController,
                              padding: const EdgeInsets.fromLTRB(16, 8, 16, 80),
                              itemCount: filtered.length + (_isLoadingMore ? 1 : 0),
                              separatorBuilder: (_, __) => const SizedBox(height: 12),
                              itemBuilder: (ctx, idx) {
                                if (idx == filtered.length) {
                                  return const Padding(
                                    padding: EdgeInsets.symmetric(vertical: 16),
                                    child: Center(
                                      child: CircularProgressIndicator(color: AppColors.primary, strokeWidth: 2),
                                    ),
                                  );
                                }
                                final r = filtered[idx];
                                return _buildReservationCard(r, isDark);
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

  Widget _buildReservationCard(SaleSummaryModel r, bool isDark) {
    final status = _effectiveStatus(r);
    final statusText = _getStatusText(status, r.isReserved);
    final statusColor = _getStatusColor(status);

    return InkWell(
      onTap: () => _showStatusBottomSheet(r, isDark),
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: AppColors.getSurface(isDark),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: statusColor.withOpacity(0.35),
            width: 1.2,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header Row
            Row(
              children: [
                Expanded(
                  child: Row(
                    children: [
                      Icon(Icons.bookmark_added_rounded, size: 16, color: statusColor),
                      const SizedBox(width: 6),
                      Expanded(
                        child: Text(
                          "حجز: ${r.invoiceNumber}",
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
                    color: statusColor.withOpacity(0.15),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    statusText,
                    style: TextStyle(
                      fontSize: 10.5,
                      fontWeight: FontWeight.bold,
                      color: statusColor,
                    ),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 8),

            // Customer line
            Row(
              children: [
                const Icon(Icons.person_rounded, size: 15, color: AppColors.primary),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    r.customerName ?? "عميل حجز أجهزة",
                    style: TextStyle(fontWeight: FontWeight.w600, fontSize: 12.5, color: AppColors.getTextPrimary(isDark)),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                if (r.customerPhone != null && r.customerPhone!.isNotEmpty) ...[
                  const SizedBox(width: 8),
                  const Icon(Icons.phone_outlined, size: 13, color: AppColors.cyan),
                  const SizedBox(width: 4),
                  Text(
                    r.customerPhone!,
                    style: TextStyle(fontSize: 11.5, color: AppColors.getTextMuted(isDark), fontFamily: 'monospace'),
                  ),
                ],
              ],
            ),

            const SizedBox(height: 10),

            // Financial line (Safely wrapped)
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text("قيمة الأجهزة", style: TextStyle(fontSize: 10, color: AppColors.getTextMuted(isDark))),
                      FittedBox(
                        fit: BoxFit.scaleDown,
                        alignment: Alignment.centerRight,
                        child: Text("${_currencyFormatter.format(r.totalAmount)} ج.م", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: AppColors.getTextPrimary(isDark))),
                      ),
                    ],
                  ),
                ),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text("العربون المدفوع", style: TextStyle(fontSize: 10, color: AppColors.getTextMuted(isDark))),
                      FittedBox(
                        fit: BoxFit.scaleDown,
                        alignment: Alignment.centerRight,
                        child: Text("${_currencyFormatter.format(r.paidAmount)} ج.م", style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: AppColors.success)),
                      ),
                    ],
                  ),
                ),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text("المتبقي عند الاستلام", style: TextStyle(fontSize: 10, color: AppColors.getTextMuted(isDark))),
                      FittedBox(
                        fit: BoxFit.scaleDown,
                        alignment: Alignment.centerRight,
                        child: Text("${_currencyFormatter.format(r.remainingAmount)} ج.م", style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: AppColors.danger)),
                      ),
                    ],
                  ),
                ),
              ],
            ),

            const SizedBox(height: 8),
            const Divider(height: 1),
            const SizedBox(height: 6),

            // Interactive prompt
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Text(
                    "تاريخ الحجز: ${DateFormat('yyyy/MM/dd').format(r.saleDate)}",
                    style: TextStyle(fontSize: 10, color: AppColors.getTextMuted(isDark)),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                const SizedBox(width: 8),
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      "تعديل حالة الحجز",
                      style: TextStyle(fontSize: 10.5, fontWeight: FontWeight.bold, color: statusColor),
                    ),
                    const SizedBox(width: 4),
                    Icon(Icons.touch_app_rounded, size: 14, color: statusColor),
                  ],
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  void _showStatusBottomSheet(SaleSummaryModel r, bool isDark) {
    int currentStatus = _effectiveStatus(r);
    int selectedStatus = currentStatus;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.getSurface(isDark),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            return Padding(
              padding: EdgeInsets.fromLTRB(
                20,
                16,
                20,
                MediaQuery.of(context).viewInsets.bottom + 24,
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Center(
                    child: Container(
                      width: 40,
                      height: 4,
                      decoration: BoxDecoration(
                        color: AppColors.getTextMuted(isDark).withOpacity(0.3),
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  ),
                  const SizedBox(height: 14),
                  Text(
                    "تعديل حالة الحجز: ${r.invoiceNumber}",
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 15,
                      color: AppColors.getTextPrimary(isDark),
                    ),
                    textAlign: TextAlign.center,
                  ),
                  if (r.customerName != null) ...[
                    const SizedBox(height: 4),
                    Text(
                      "العميل: ${r.customerName}",
                      style: TextStyle(
                        fontSize: 12.5,
                        color: AppColors.getTextMuted(isDark),
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ],
                  const SizedBox(height: 16),
                  _buildStatusOption(
                    setModalState,
                    isDark,
                    title: "محجوز بالمخزن (لم يتم التسليم بعد)",
                    statusValue: 1,
                    selectedValue: selectedStatus,
                    color: AppColors.warning,
                    icon: Icons.warehouse_rounded,
                    onSelected: (val) => setModalState(() => selectedStatus = val),
                  ),
                  _buildStatusOption(
                    setModalState,
                    isDark,
                    title: "تسليم جزئي (تم تسليم جزء من الأجهزة)",
                    statusValue: 2,
                    selectedValue: selectedStatus,
                    color: AppColors.cyan,
                    icon: Icons.local_shipping_rounded,
                    onSelected: (val) => setModalState(() => selectedStatus = val),
                  ),
                  _buildStatusOption(
                    setModalState,
                    isDark,
                    title: "تم التسليم بالكامل (خرجت البضاعة للعميل)",
                    statusValue: 3,
                    selectedValue: selectedStatus,
                    color: AppColors.success,
                    icon: Icons.check_circle_rounded,
                    onSelected: (val) => setModalState(() => selectedStatus = val),
                  ),
                  _buildStatusOption(
                    setModalState,
                    isDark,
                    title: "إلغاء الحجز / استرجاع",
                    statusValue: 4,
                    selectedValue: selectedStatus,
                    color: AppColors.danger,
                    icon: Icons.cancel_outlined,
                    onSelected: (val) => setModalState(() => selectedStatus = val),
                  ),
                  const SizedBox(height: 18),
                  ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 13),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    onPressed: () async {
                      Navigator.pop(ctx);
                      await _updateReservationStatus(r, selectedStatus);
                    },
                    child: const Text("حفظ التعديل والمزامنة", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildStatusOption(
    void Function(void Function()) setModalState,
    bool isDark, {
    required String title,
    required int statusValue,
    required int selectedValue,
    required Color color,
    required IconData icon,
    required ValueChanged<int> onSelected,
  }) {
    final isSelected = statusValue == selectedValue;
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: InkWell(
        onTap: () => onSelected(statusValue),
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          decoration: BoxDecoration(
            color: isSelected ? color.withOpacity(0.12) : AppColors.getBackground(isDark),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: isSelected ? color : AppColors.getBorder(isDark),
              width: isSelected ? 1.5 : 1,
            ),
          ),
          child: Row(
            children: [
              Icon(icon, color: isSelected ? color : AppColors.getTextMuted(isDark), size: 20),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  title,
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                    color: isSelected ? color : AppColors.getTextPrimary(isDark),
                  ),
                ),
              ),
              if (isSelected) Icon(Icons.check_circle_rounded, color: color, size: 18),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _updateReservationStatus(SaleSummaryModel r, int newStatus) async {
    try {
      await _apiClient.post(
        "api/cloud/sales/${r.id}/reservation-status",
        data: {'status': newStatus},
      );
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("تم تحديث حالة الحجز بنجاح ومزامنته"),
            backgroundColor: AppColors.success,
          ),
        );
        _fetchReservations();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text("فشل تحديث الحالة: $e"),
            backgroundColor: AppColors.danger,
          ),
        );
      }
    }
  }
}
