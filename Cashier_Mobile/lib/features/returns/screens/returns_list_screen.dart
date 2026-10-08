import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/theme/theme_provider.dart';
import '../../../core/widgets/offline_banner.dart';
import '../models/return_model.dart';
import '../providers/returns_provider.dart';

class ReturnsListScreen extends StatefulWidget {
  const ReturnsListScreen({super.key});

  @override
  State<ReturnsListScreen> createState() => _ReturnsListScreenState();
}

class _ReturnsListScreenState extends State<ReturnsListScreen> {
  final TextEditingController _searchCtrl = TextEditingController();
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Provider.of<ReturnsProvider>(context, listen: false).fetchReturns();
    });

    _scrollController.addListener(_onScroll);
  }

  void _onScroll() {
    if (_scrollController.hasClients &&
        _scrollController.position.pixels >= _scrollController.position.maxScrollExtent - 250) {
      final prov = Provider.of<ReturnsProvider>(context, listen: false);
      if (!prov.isLoadingMore && !prov.isLoading && prov.hasMore) {
        prov.fetchMoreReturns();
      }
    }
  }

  @override
  void dispose() {
    _scrollController.removeListener(_onScroll);
    _scrollController.dispose();
    _searchCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Provider.of<ThemeProvider>(context).isDarkMode;
    final prov = Provider.of<ReturnsProvider>(context);
    final currencyFormatter = NumberFormat("#,##0.00", "en_US");
    final dateFormatter = DateFormat("yyyy/MM/dd - hh:mm a");

    return Scaffold(
      backgroundColor: AppColors.getBackground(isDark),
      appBar: AppBar(
        backgroundColor: AppColors.getSurface(isDark),
        elevation: 0,
        title: Text(
          "سجل المرتجعات",
          style: TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 18,
            color: AppColors.getTextPrimary(isDark),
          ),
        ),
        actions: [
          IconButton(
            icon: Icon(Icons.refresh_rounded, color: AppColors.getTextPrimary(isDark)),
            onPressed: () => prov.fetchReturns(search: _searchCtrl.text),
          ),
        ],
      ),
      body: Column(
        children: [
          const OfflineBanner(),

          // Summary Statistics
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Expanded(
                  child: _buildSummaryCard(
                    isDark,
                    title: "مرتجعات مبيعات",
                    amount: prov.totalSalesReturnsAmount,
                    count: prov.salesReturnsCount,
                    icon: Icons.assignment_return_rounded,
                    color: const Color(0xFFEF4444),
                    currencyFormatter: currencyFormatter,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildSummaryCard(
                    isDark,
                    title: "مرتجعات مشتريات",
                    amount: prov.totalPurchasesReturnsAmount,
                    count: prov.purchasesReturnsCount,
                    icon: Icons.keyboard_return_rounded,
                    color: const Color(0xFFF59E0B),
                    currencyFormatter: currencyFormatter,
                  ),
                ),
              ],
            ),
          ),

          // Search Box
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: TextField(
              controller: _searchCtrl,
              decoration: InputDecoration(
                hintText: "بحث برقم المرتجع أو الفاتورة أو الطرف...",
                hintStyle: TextStyle(fontSize: 13, color: AppColors.getTextSecondary(isDark)),
                prefixIcon: Icon(Icons.search_rounded, color: AppColors.getTextSecondary(isDark)),
                suffixIcon: _searchCtrl.text.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear_rounded),
                        onPressed: () {
                          _searchCtrl.clear();
                          prov.fetchReturns(search: '');
                        },
                      )
                    : null,
                filled: true,
                fillColor: AppColors.getSurface(isDark),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: AppColors.getBorder(isDark)),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: AppColors.getBorder(isDark)),
                ),
                contentPadding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
              ),
              onChanged: (val) => prov.fetchReturns(search: val),
            ),
          ),

          const SizedBox(height: 12),

          // Filter Tabs (All / Sales / Purchases)
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Container(
              padding: const EdgeInsets.all(4),
              decoration: BoxDecoration(
                color: AppColors.getSurface(isDark),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppColors.getBorder(isDark)),
              ),
              child: Row(
                children: [
                  _buildTabButton(isDark, "الكل", "All", prov),
                  _buildTabButton(isDark, "مرتجع مبيعات", "Sale", prov),
                  _buildTabButton(isDark, "مرتجع مشتريات", "Purchase", prov),
                ],
              ),
            ),
          ),

          const SizedBox(height: 12),

          // Main List Content
          Expanded(
            child: prov.isLoading
                ? const Center(child: CircularProgressIndicator())
                : prov.returns.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.assignment_return_outlined,
                              size: 64,
                              color: AppColors.getTextSecondary(isDark).withOpacity(0.4),
                            ),
                            const SizedBox(height: 12),
                            Text(
                              "لا توجد عمليات مرتجعات مسجلة",
                              style: TextStyle(
                                fontSize: 15,
                                fontWeight: FontWeight.bold,
                                color: AppColors.getTextSecondary(isDark),
                              ),
                            ),
                          ],
                        ),
                      )
                    : RefreshIndicator(
                        onRefresh: () => prov.fetchReturns(search: _searchCtrl.text),
                        child: ListView.separated(
                          controller: _scrollController,
                          padding: const EdgeInsets.all(16),
                          itemCount: prov.returns.length + (prov.isLoadingMore ? 1 : 0),
                          separatorBuilder: (_, __) => const SizedBox(height: 12),
                          itemBuilder: (ctx, i) {
                            if (i == prov.returns.length) {
                              return const Padding(
                                padding: EdgeInsets.all(16.0),
                                child: Center(child: CircularProgressIndicator()),
                              );
                            }
                            return _buildReturnCard(
                              isDark,
                              prov.returns[i],
                              currencyFormatter,
                              dateFormatter,
                            );
                          },
                        ),
                      ),
          ),
        ],
      ),
    );
  }

  Widget _buildTabButton(bool isDark, String title, String type, ReturnsProvider prov) {
    final isSelected = prov.activeTypeFilter.toLowerCase() == type.toLowerCase();
    return Expanded(
      child: GestureDetector(
        onTap: () => prov.setTypeFilter(type),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 8),
          decoration: BoxDecoration(
            color: isSelected ? AppColors.primary : Colors.transparent,
            borderRadius: BorderRadius.circular(8),
          ),
          alignment: Alignment.center,
          child: Text(
            title,
            style: TextStyle(
              fontSize: 13,
              fontWeight: isSelected ? FontWeight.bold : FontWeight.w600,
              color: isSelected ? Colors.white : AppColors.getTextSecondary(isDark),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSummaryCard(
    bool isDark, {
    required String title,
    required double amount,
    required int count,
    required IconData icon,
    required Color color,
    required NumberFormat currencyFormatter,
  }) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.getSurface(isDark),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: color.withOpacity(0.3), width: 1.5),
        boxShadow: [
          BoxShadow(
            color: color.withOpacity(0.05),
            blurRadius: 8,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(icon, color: color, size: 18),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  title,
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: AppColors.getTextSecondary(isDark),
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            "${currencyFormatter.format(amount)} ج.م",
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            "$count عملية مرتجع",
            style: TextStyle(
              fontSize: 11,
              color: AppColors.getTextSecondary(isDark),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildReturnCard(
    bool isDark,
    ReturnModel item,
    NumberFormat currencyFormatter,
    DateFormat dateFormatter,
  ) {
    final isSale = item.isSale;
    final badgeColor = isSale ? const Color(0xFFEF4444) : const Color(0xFFF59E0B);
    final typeLabel = isSale ? "مرتجع مبيعات" : "مرتجع مشتريات";

    return Container(
      decoration: BoxDecoration(
        color: AppColors.getSurface(isDark),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.getBorder(isDark)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(isDark ? 0.2 : 0.03),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(14),
          onTap: () => _showReturnDetailsModal(context, isDark, item, currencyFormatter, dateFormatter),
          child: Padding(
            padding: const EdgeInsets.all(14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header row: Return Number + Type Badge
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        Icon(
                          isSale ? Icons.assignment_return_rounded : Icons.keyboard_return_rounded,
                          color: badgeColor,
                          size: 20,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          item.returnNumber,
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 14,
                            color: AppColors.getTextPrimary(isDark),
                          ),
                        ),
                      ],
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: badgeColor.withOpacity(0.12),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: badgeColor.withOpacity(0.3)),
                      ),
                      child: Text(
                        typeLabel,
                        style: TextStyle(
                          color: badgeColor,
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 8),

                // Party Name & Original Invoice
                if (item.partyName != null && item.partyName!.isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 4),
                    child: Row(
                      children: [
                        Icon(
                          isSale ? Icons.person_outline_rounded : Icons.storefront_outlined,
                          size: 15,
                          color: AppColors.getTextSecondary(isDark),
                        ),
                        const SizedBox(width: 6),
                        Expanded(
                          child: Text(
                            item.partyName!,
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                              color: AppColors.getTextPrimary(isDark),
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                  ),

                if (item.originalInvoiceNumber != null && item.originalInvoiceNumber!.isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 4),
                    child: Row(
                      children: [
                        Icon(
                          Icons.receipt_long_rounded,
                          size: 15,
                          color: AppColors.getTextSecondary(isDark),
                        ),
                        const SizedBox(width: 6),
                        Expanded(
                          child: Text(
                            "فاتورة أصلية: ${item.originalInvoiceNumber!}",
                            style: TextStyle(
                              fontSize: 12,
                              color: AppColors.getTextSecondary(isDark),
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                  ),

                const Divider(height: 16),

                // Footer row: Items Count + Total Amount + Details button
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            dateFormatter.format(item.returnDate),
                            style: TextStyle(
                              fontSize: 11,
                              color: AppColors.getTextSecondary(isDark),
                            ),
                          ),
                          const SizedBox(height: 4),
                          Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                decoration: BoxDecoration(
                                  color: AppColors.primary.withOpacity(0.1),
                                  borderRadius: BorderRadius.circular(6),
                                ),
                                child: Text(
                                  "${item.itemsCount} أصناف",
                                  style: const TextStyle(
                                    fontSize: 11,
                                    color: AppColors.primary,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                              if (item.reason != null && item.reason!.isNotEmpty) ...[
                                const SizedBox(width: 6),
                                Expanded(
                                  child: Text(
                                    "(${item.reason})",
                                    style: TextStyle(
                                      fontSize: 11,
                                      color: AppColors.getTextSecondary(isDark),
                                    ),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                              ],
                            ],
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 8),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text(
                          "${currencyFormatter.format(item.totalAmount)} ج.م",
                          style: TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.bold,
                            color: badgeColor,
                          ),
                        ),
                        const SizedBox(height: 4),
                        const Row(
                          children: [
                            Text(
                              "تفاصيل البنود",
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.bold,
                                color: AppColors.primary,
                              ),
                            ),
                            SizedBox(width: 2),
                            Icon(Icons.arrow_forward_ios_rounded, size: 10, color: AppColors.primary),
                          ],
                        ),
                      ],
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _showReturnDetailsModal(
    BuildContext context,
    bool isDark,
    ReturnModel item,
    NumberFormat currencyFormatter,
    DateFormat dateFormatter,
  ) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.getSurface(isDark),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => DraggableScrollableSheet(
        initialChildSize: 0.7,
        minChildSize: 0.4,
        maxChildSize: 0.92,
        expand: false,
        builder: (_, scrollCtrl) => Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Modal Handle
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  margin: const EdgeInsets.only(bottom: 16),
                  decoration: BoxDecoration(
                    color: AppColors.getBorder(isDark),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),

              // Title and Return Number
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        item.isSale ? "تفاصيل مرتجع مبيعات" : "تفاصيل مرتجع مشتريات",
                        style: TextStyle(
                          fontSize: 17,
                          fontWeight: FontWeight.bold,
                          color: AppColors.getTextPrimary(isDark),
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        item.returnNumber,
                        style: TextStyle(
                          fontSize: 13,
                          color: AppColors.getTextSecondary(isDark),
                        ),
                      ),
                    ],
                  ),
                  IconButton(
                    icon: const Icon(Icons.close_rounded),
                    onPressed: () => Navigator.pop(ctx),
                  ),
                ],
              ),

              const SizedBox(height: 12),

              // Info chips
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppColors.getBackground(isDark),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Column(
                  children: [
                    _buildDetailRow(isDark, "تاريخ المرتجع:", dateFormatter.format(item.returnDate)),
                    if (item.partyName != null)
                      _buildDetailRow(isDark, item.isSale ? "العميل:" : "المورد:", item.partyName!),
                    if (item.originalInvoiceNumber != null)
                      _buildDetailRow(isDark, "رقم الفاتورة الأصلية:", item.originalInvoiceNumber!),
                    if (item.refundMethod != null)
                      _buildDetailRow(isDark, "طريقة رد المبلغ:", item.refundMethod!),
                    if (item.reason != null && item.reason!.isNotEmpty)
                      _buildDetailRow(isDark, "السبب:", item.reason!),
                    if (item.notes != null && item.notes!.isNotEmpty)
                      _buildDetailRow(isDark, "ملاحظات:", item.notes!),
                  ],
                ),
              ),

              const SizedBox(height: 16),

              Text(
                "الأصناف المرتجعة (${item.items.length})",
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: AppColors.getTextPrimary(isDark),
                ),
              ),

              const SizedBox(height: 8),

              // Items List
              Expanded(
                child: item.items.isEmpty
                    ? Center(
                        child: Text(
                          "لا تتوفر بنود مفصلة لهذا المرتجع",
                          style: TextStyle(color: AppColors.getTextSecondary(isDark)),
                        ),
                      )
                    : ListView.separated(
                        controller: scrollCtrl,
                        itemCount: item.items.length,
                        separatorBuilder: (_, __) => const Divider(height: 12),
                        itemBuilder: (context, idx) {
                          final returnItem = item.items[idx];
                          return Row(
                            children: [
                              Container(
                                width: 32,
                                height: 32,
                                decoration: BoxDecoration(
                                  color: AppColors.primary.withOpacity(0.1),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                alignment: Alignment.center,
                                child: Text(
                                  "${idx + 1}",
                                  style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                    color: AppColors.primary,
                                  ),
                                ),
                              ),
                              const SizedBox(width: 10),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      returnItem.productName,
                                      style: TextStyle(
                                        fontWeight: FontWeight.w600,
                                        fontSize: 13,
                                        color: AppColors.getTextPrimary(isDark),
                                      ),
                                    ),
                                    if (returnItem.barcode != null && returnItem.barcode!.isNotEmpty)
                                      Text(
                                        returnItem.barcode!,
                                        style: TextStyle(
                                          fontSize: 11,
                                          color: AppColors.getTextSecondary(isDark),
                                        ),
                                      ),
                                    if (returnItem.reason != null && returnItem.reason!.isNotEmpty)
                                      Text(
                                        "سبب الإرجاع: ${returnItem.reason!}",
                                        style: const TextStyle(
                                          fontSize: 11,
                                          color: Color(0xFFEF4444),
                                        ),
                                      ),
                                  ],
                                ),
                              ),
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.end,
                                children: [
                                  Text(
                                    "${currencyFormatter.format(returnItem.total)} ج.م",
                                    style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 13,
                                      color: item.isSale ? const Color(0xFFEF4444) : const Color(0xFFF59E0B),
                                    ),
                                  ),
                                  Text(
                                    "${returnItem.quantity} × ${currencyFormatter.format(returnItem.unitPrice)}",
                                    style: TextStyle(
                                      fontSize: 11,
                                      color: AppColors.getTextSecondary(isDark),
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          );
                        },
                      ),
              ),

              const Divider(height: 20),

              // Total Summary
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    "إجمالي قيمة المرتجع:",
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.bold,
                      color: AppColors.getTextPrimary(isDark),
                    ),
                  ),
                  Text(
                    "${currencyFormatter.format(item.totalAmount)} ج.م",
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w800,
                      color: item.isSale ? const Color(0xFFEF4444) : const Color(0xFFF59E0B),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDetailRow(bool isDark, String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: TextStyle(fontSize: 12, color: AppColors.getTextSecondary(isDark)),
          ),
          Flexible(
            child: Text(
              value,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: AppColors.getTextPrimary(isDark),
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }
}
