import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../../../core/constants/app_colors.dart';
import '../models/sale_model.dart';
import '../providers/sales_provider.dart';
import 'installments_screen.dart';
import 'reservations_screen.dart';

class SalesListScreen extends StatefulWidget {
  const SalesListScreen({super.key});

  @override
  State<SalesListScreen> createState() => _SalesListScreenState();
}

class _SalesListScreenState extends State<SalesListScreen> {
  final TextEditingController _searchController = TextEditingController();

  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Provider.of<SalesProvider>(context, listen: false).fetchSalesList();
    });
  }

  @override
  void dispose() {
    _scrollController.removeListener(_onScroll);
    _scrollController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (_scrollController.position.pixels >= _scrollController.position.maxScrollExtent - 200) {
      Provider.of<SalesProvider>(context, listen: false).fetchMoreSales();
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final salesProv = Provider.of<SalesProvider>(context);

    return Scaffold(
      backgroundColor: AppColors.getBackground(isDark),
      appBar: AppBar(
        title: const Text(
          "فواتير مبيعات الصالة",
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.request_quote_rounded, color: AppColors.purple),
            tooltip: "دفتر الأقساط",
            onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const InstallmentsScreen())),
          ),
          IconButton(
            icon: const Icon(Icons.bookmark_added_rounded, color: AppColors.accent),
            tooltip: "حجوزات الأجهزة",
            onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const ReservationsScreen())),
          ),
          IconButton(
            icon: const Icon(Icons.refresh_rounded),
            tooltip: "تحديث",
            onPressed: () => salesProv.fetchSalesList(search: _searchController.text.trim()),
          ),
        ],
      ),
      body: Column(
        children: [
          // Search Bar
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: "بحث برقم الفاتورة أو اسم العميل...",
                prefixIcon: const Icon(Icons.search),
                suffixIcon: _searchController.text.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear),
                        onPressed: () {
                          _searchController.clear();
                          salesProv.fetchSalesList();
                        },
                      )
                    : null,
              ),
              onSubmitted: (query) {
                salesProv.fetchSalesList(search: query.trim());
              },
            ),
          ),

          // Invoices List
          Expanded(
            child: salesProv.isLoading && salesProv.sales.isEmpty
                ? const Center(child: CircularProgressIndicator())
                : salesProv.sales.isEmpty
                    ? _buildEmptyState(isDark)
                    : RefreshIndicator(
                        onRefresh: () => salesProv.fetchSalesList(search: _searchController.text.trim()),
                        child: ListView.separated(
                          controller: _scrollController,
                          padding: const EdgeInsets.all(16),
                          itemCount: salesProv.sales.length + (salesProv.isLoadingMore ? 1 : 0),
                          separatorBuilder: (_, __) => const SizedBox(height: 12),
                          itemBuilder: (ctx, index) {
                            if (index == salesProv.sales.length) {
                              return const Padding(
                                padding: EdgeInsets.symmetric(vertical: 16),
                                child: Center(
                                  child: CircularProgressIndicator(color: AppColors.primaryLight, strokeWidth: 2),
                                ),
                              );
                            }
                            final sale = salesProv.sales[index];
                            return _buildSaleCard(context, sale, salesProv, isDark);
                          },
                        ),
                      ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState(bool isDark) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.receipt_long_outlined, size: 64, color: AppColors.getTextMuted(isDark)),
          const SizedBox(height: 12),
          Text(
            "لا توجد فواتير مبيعات مسجلة بعد",
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: AppColors.getTextPrimary(isDark),
            ),
          ),
          const SizedBox(height: 6),
          Text(
            "الفواتير المنشأة من شاشة POS ستظهر هنا مباشرة.",
            style: TextStyle(fontSize: 12, color: AppColors.getTextMuted(isDark)),
          ),
        ],
      ),
    );
  }

  Widget _buildSaleCard(
    BuildContext context,
    SaleSummaryModel sale,
    SalesProvider salesProv,
    bool isDark,
  ) {
    final surface = AppColors.getSurface(isDark);
    final border = AppColors.getBorder(isDark);
    final dateFormat = DateFormat('yyyy/MM/dd - hh:mm a');
    final isSynced = sale.syncStatus == "Synced";

    return InkWell(
      onTap: () => _showInvoiceDetails(context, sale.id, salesProv, isDark),
      borderRadius: BorderRadius.circular(14),
      child: Container(
        decoration: BoxDecoration(
          color: surface,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: border),
        ),
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Top Row: Invoice Number & Sync Badge
            Row(
              children: [
                Expanded(
                  child: Text(
                    sale.invoiceNumber,
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                      color: AppColors.getTextPrimary(isDark),
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                _buildSyncBadge(isSynced),
              ],
            ),

            const SizedBox(height: 8),

            // Date and Customer
            Row(
              children: [
                const Icon(Icons.person_outline, size: 14, color: Colors.grey),
                const SizedBox(width: 4),
                Expanded(
                  child: Text(
                    sale.customerName ?? "عميل نقدي",
                    style: TextStyle(
                      fontSize: 12,
                      color: AppColors.getTextPrimary(isDark),
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                Text(
                  dateFormat.format(sale.saleDate),
                  style: TextStyle(fontSize: 11, color: AppColors.getTextMuted(isDark)),
                ),
              ],
            ),

            const Divider(height: 16),

            // Bottom Row: Amounts and Payment Method (Protected from overflow)
            Row(
              children: [
                Expanded(
                  child: Wrap(
                    spacing: 6,
                    runSpacing: 4,
                    crossAxisAlignment: WrapCrossAlignment.center,
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(
                          color: const Color(0xFF4F46E5).withOpacity(0.1),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          _formatPaymentMethod(sale.paymentMethod),
                          style: const TextStyle(
                            color: Color(0xFF4F46E5),
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      if (sale.isDelivery)
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
                          decoration: BoxDecoration(
                            color: const Color(0xFF06B6D4).withOpacity(0.1),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: const Text(
                            "توصيل",
                            style: TextStyle(color: Color(0xFF06B6D4), fontSize: 10, fontWeight: FontWeight.bold),
                          ),
                        ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                FittedBox(
                  fit: BoxFit.scaleDown,
                  alignment: Alignment.centerLeft,
                  child: Text(
                    "${sale.totalAmount.toStringAsFixed(0)} ج.م",
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                      color: Color(0xFF10B981),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSyncBadge(bool isSynced) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: isSynced
            ? const Color(0xFF10B981).withOpacity(0.12)
            : const Color(0xFFF59E0B).withOpacity(0.12),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: isSynced
              ? const Color(0xFF10B981).withOpacity(0.3)
              : const Color(0xFFF59E0B).withOpacity(0.3),
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            isSynced ? Icons.cloud_done_rounded : Icons.cloud_upload_outlined,
            size: 13,
            color: isSynced ? const Color(0xFF10B981) : const Color(0xFFF59E0B),
          ),
          const SizedBox(width: 4),
          Text(
            isSynced ? "متزامن مع الديسكتوب" : "بانتظار المزامنة",
            style: TextStyle(
              fontSize: 10.5,
              fontWeight: FontWeight.bold,
              color: isSynced ? const Color(0xFF10B981) : const Color(0xFFF59E0B),
            ),
          ),
        ],
      ),
    );
  }

  String _formatPaymentMethod(String method) {
    switch (method.toLowerCase()) {
      case "card":
        return "فيزا / بطاقة";
      case "installment":
        return "تقسيط";
      case "credit":
        return "آجل";
      default:
        return "نقداً";
    }
  }

  Future<void> _showInvoiceDetails(
    BuildContext context,
    String saleId,
    SalesProvider salesProv,
    bool isDark,
  ) async {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.getSurface(isDark),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) {
        return FutureBuilder<SaleDetailModel?>(
          future: salesProv.fetchSaleDetails(saleId),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const SizedBox(
                height: 250,
                child: Center(child: CircularProgressIndicator()),
              );
            }

            final detail = snapshot.data;
            if (detail == null) {
              return const SizedBox(
                height: 200,
                child: Center(child: Text("تعذر جلب تفاصيل الفاتورة")),
              );
            }

            return Padding(
              padding: const EdgeInsets.all(16),
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Center(
                      child: Container(
                        width: 40,
                        height: 4,
                        decoration: BoxDecoration(
                          color: Colors.grey.withOpacity(0.3),
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            "فاتورة: ${detail.invoiceNumber}",
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: AppColors.getTextPrimary(isDark),
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        _buildSyncBadge(detail.syncStatus == "Synced"),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Text(
                      "العميل: ${detail.customerName ?? 'نقدي'}",
                      style: TextStyle(color: AppColors.getTextMuted(isDark), fontSize: 13),
                    ),
                    if (detail.recipientPhone != null && detail.recipientPhone!.isNotEmpty)
                      Text(
                        "الهاتف: ${detail.recipientPhone}",
                        style: TextStyle(color: AppColors.getTextMuted(isDark), fontSize: 13),
                      )
                    else if (detail.customerPhone != null && detail.customerPhone!.isNotEmpty)
                      Text(
                        "الهاتف: ${detail.customerPhone}",
                        style: TextStyle(color: AppColors.getTextMuted(isDark), fontSize: 13),
                      ),
                    if (detail.isDelivery && detail.deliveryAddress != null)
                      Text(
                        "عنوان التوصيل: ${detail.deliveryAddress}",
                        style: const TextStyle(color: Color(0xFF06B6D4), fontSize: 13),
                      ),
                    Text(
                      "طريقة الدفع: ${detail.isInstallment ? 'تقسيط' : (detail.paymentMethod == 'Credit' || detail.paymentMethod == 'آجل' ? 'آجل' : 'كاش (نقدي)')}",
                      style: TextStyle(
                        color: detail.isInstallment ? const Color(0xFF6366F1) : (detail.paymentMethod == 'Credit' || detail.paymentMethod == 'آجل' ? const Color(0xFFF59E0B) : const Color(0xFF10B981)),
                        fontSize: 13,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const Divider(height: 20),
                    const Text(
                      "الأجهزة المشتراة:",
                      style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                    ),
                    const SizedBox(height: 8),
                    ...detail.items.map((i) {
                      return Padding(
                        padding: const EdgeInsets.symmetric(vertical: 4),
                        child: Row(
                          children: [
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    i.productName,
                                    style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 12.5,
                                      color: AppColors.getTextPrimary(isDark),
                                    ),
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                  if (i.serialNumber != null && i.serialNumber!.isNotEmpty)
                                    Text(
                                      "سيريال: ${i.serialNumber}",
                                      style: const TextStyle(fontSize: 11, color: Color(0xFF10B981)),
                                    ),
                                ],
                              ),
                            ),
                            Text(
                              "${i.quantity.toInt()} × ${i.unitPrice.toStringAsFixed(0)} = ${i.total.toStringAsFixed(0)} ج.م",
                              style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
                            ),
                          ],
                        ),
                      );
                    }),
                    const Divider(height: 20),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text("إجمالي عدد القطع:", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                        Text(
                          "${detail.items.fold<double>(0, (sum, item) => sum + item.quantity).toInt()} قطعة",
                          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: Color(0xFF6366F1)),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text("الإجمالي النهائي:", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                        Text(
                          "${detail.totalAmount.toStringAsFixed(0)} ج.م",
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 18,
                            color: Color(0xFF10B981),
                          ),
                        ),
                      ],
                    ),
                    if (detail.isInstallment) ...[
                      const SizedBox(height: 14),
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: const Color(0xFF6366F1).withOpacity(0.08),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: const Color(0xFF6366F1).withOpacity(0.25)),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Row(
                              children: [
                                Icon(Icons.calculate_rounded, size: 18, color: Color(0xFF6366F1)),
                                SizedBox(width: 6),
                                Text(
                                  "تفاصيل عقد التقسيط والفوائد:",
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 13,
                                    color: Color(0xFF6366F1),
                                  ),
                                ),
                              ],
                            ),
                            const Divider(height: 14),
                            _buildDetailRow("سعر الأجهزة نقداً:", "${detail.cashTotal.toStringAsFixed(0)} ج.م", isDark),
                            const SizedBox(height: 5),
                            _buildDetailRow("المقدم المدفوع:", "${detail.paidAmount.toStringAsFixed(0)} ج.م", isDark, valueColor: const Color(0xFF10B981)),
                            const SizedBox(height: 5),
                            _buildDetailRow(
                              "نسبة وقيمة الفائدة:",
                              "${detail.interestPercentage.toStringAsFixed(0)}% (+${detail.interestAmount.toStringAsFixed(0)} ج.م)",
                              isDark,
                              valueColor: const Color(0xFFF59E0B),
                            ),
                            const Divider(height: 14),
                            _buildDetailRow("إجمالي العقد بالفوائد:", "${detail.totalAmount.toStringAsFixed(0)} ج.م", isDark, isBold: true, valueColor: const Color(0xFF6366F1)),
                            const SizedBox(height: 5),
                            _buildDetailRow("المتبقي للأقساط:", "${detail.remainingAmount.toStringAsFixed(0)} ج.م", isDark, isBold: true),
                            const SizedBox(height: 5),
                            _buildDetailRow("القسط الشهري:", "${detail.monthlyInstallmentAmount.toStringAsFixed(0)} ج.م / شهر (${detail.numberOfMonths} شهر)", isDark, isBold: true, valueColor: const Color(0xFF6366F1)),
                            if (detail.guarantorName != null && detail.guarantorName!.isNotEmpty) ...[
                              const Divider(height: 14),
                              _buildDetailRow("الضامن:", "${detail.guarantorName} (${detail.guarantorPhone ?? '-'})", isDark),
                            ],
                          ],
                        ),
                      ),
                    ],
                    const SizedBox(height: 16),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildDetailRow(
    String label,
    String value,
    bool isDark, {
    bool isBold = false,
    Color? valueColor,
  }) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 12,
            fontWeight: isBold ? FontWeight.bold : FontWeight.normal,
            color: isBold ? AppColors.getTextPrimary(isDark) : AppColors.getTextMuted(isDark),
          ),
        ),
        Text(
          value,
          style: TextStyle(
            fontSize: isBold ? 13 : 12,
            fontWeight: isBold ? FontWeight.bold : FontWeight.w600,
            color: valueColor ?? AppColors.getTextPrimary(isDark),
          ),
        ),
      ],
    );
  }
}
