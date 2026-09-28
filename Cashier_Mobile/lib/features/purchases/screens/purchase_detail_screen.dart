import 'dart:async';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/widgets/offline_banner.dart';
import '../../../core/widgets/sync_status_badge.dart';
import '../providers/purchases_provider.dart';

class PurchaseDetailScreen extends StatefulWidget {
  final String purchaseId;

  const PurchaseDetailScreen({super.key, required this.purchaseId});

  @override
  State<PurchaseDetailScreen> createState() => _PurchaseDetailScreenState();
}

class _PurchaseDetailScreenState extends State<PurchaseDetailScreen> {
  Timer? _pollingTimer;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Provider.of<PurchasesProvider>(context, listen: false).fetchPurchaseDetails(widget.purchaseId);
    });

    _pollingTimer = Timer.periodic(const Duration(seconds: 5), (timer) {
      if (!mounted) return;
      final provider = Provider.of<PurchasesProvider>(context, listen: false);
      if (provider.selectedPurchase != null &&
          provider.selectedPurchase!.syncStatus.toLowerCase() == 'pendingsync') {
        provider.fetchPurchaseDetails(widget.purchaseId);
      }
    });
  }

  @override
  void dispose() {
    _pollingTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final provider = Provider.of<PurchasesProvider>(context);
    final p = provider.selectedPurchase;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bg = AppColors.getBackground(isDark);
    final surface = AppColors.getSurface(isDark);
    final border = AppColors.getBorder(isDark);
    final textPrimary = AppColors.getTextPrimary(isDark);
    final textSecondary = AppColors.getTextSecondary(isDark);
    final textMuted = AppColors.getTextMuted(isDark);

    final currencyFormatter = NumberFormat("#,##0.00", "ar_EG");
    final dateFormatter = DateFormat("dd/MM/yyyy HH:mm");

    return Scaffold(
      backgroundColor: bg,
      appBar: AppBar(
        backgroundColor: surface,
        elevation: 0,
        title: Text(
          p != null ? "فاتورة: ${p.invoiceNumber}" : "تفاصيل الفاتورة",
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: textPrimary),
        ),
        actions: [
          IconButton(
            icon: Icon(Icons.refresh_rounded, color: textPrimary),
            onPressed: () => provider.fetchPurchaseDetails(widget.purchaseId),
          ),
        ],
      ),
      body: Column(
        children: [
          const OfflineBanner(),
          Expanded(
            child: provider.isLoading || p == null
                ? const Center(child: CircularProgressIndicator(color: AppColors.primaryLight))
                : SingleChildScrollView(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Sync Status Information Card
                        _buildSyncStatusCard(p, provider, isDark),
                        const SizedBox(height: 16),

                        // General Invoice Info Card
                        Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: surface,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: border),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                "بيانات الفاتورة والمورد",
                                style: TextStyle(color: textPrimary, fontWeight: FontWeight.bold, fontSize: 14),
                              ),
                              Divider(color: border, height: 20),
                              _buildInfoRow("رقم الفاتورة:", p.invoiceNumber, textSecondary, textPrimary),
                              if (p.internalNumber != null && p.internalNumber!.isNotEmpty)
                                _buildInfoRow("الرقم الداخلي:", p.internalNumber!, textSecondary, textPrimary),
                              _buildInfoRow("اسم المورد:", p.supplierName ?? "مورد عام", textSecondary, textPrimary),
                              _buildInfoRow("تاريخ الشراء:", dateFormatter.format(p.purchaseDate), textSecondary, textPrimary),
                              _buildInfoRow("طريقة الدفع:", _getPaymentMethodLabel(p.paymentMethod), textSecondary, textPrimary),
                              _buildInfoRow("المسؤول:", p.createdByName ?? "صاحب المحل", textSecondary, textPrimary),
                              if (p.notes != null && p.notes!.isNotEmpty)
                                _buildInfoRow("ملاحظات:", p.notes!, textSecondary, textPrimary),
                            ],
                          ),
                        ),
                        const SizedBox(height: 16),

                        // Items List Card
                        Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: surface,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: border),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Text(
                                    "الأصناف المدخلة",
                                    style: TextStyle(color: textPrimary, fontWeight: FontWeight.bold, fontSize: 14),
                                  ),
                                  Text(
                                    "${p.items.length} صنف",
                                    style: const TextStyle(color: AppColors.accent, fontWeight: FontWeight.bold, fontSize: 12),
                                  ),
                                ],
                              ),
                              Divider(color: border, height: 20),
                              ListView.separated(
                                shrinkWrap: true,
                                physics: const NeverScrollableScrollPhysics(),
                                itemCount: p.items.length,
                                separatorBuilder: (_, __) => Divider(color: border, height: 16),
                                itemBuilder: (ctx, idx) {
                                  final item = p.items[idx];
                                  return Row(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Container(
                                        width: 28,
                                        height: 28,
                                        decoration: BoxDecoration(
                                          color: bg,
                                          borderRadius: BorderRadius.circular(6),
                                        ),
                                        child: Center(
                                          child: Text("${idx + 1}", style: TextStyle(color: textMuted, fontSize: 12)),
                                        ),
                                      ),
                                      const SizedBox(width: 10),
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            Text(
                                              item.productName,
                                              style: TextStyle(color: textPrimary, fontWeight: FontWeight.bold, fontSize: 13),
                                            ),
                                            const SizedBox(height: 4),
                                            Text(
                                              "${item.quantity} ${item.unit ?? 'قطعة'} × ${currencyFormatter.format(item.unitCost)} ج.م",
                                              style: TextStyle(color: textSecondary, fontSize: 12),
                                            ),
                                            if (item.expiryDate != null) ...[
                                              const SizedBox(height: 2),
                                              Text(
                                                "صلاحية: ${DateFormat('dd/MM/yyyy').format(item.expiryDate!)}",
                                                style: const TextStyle(color: AppColors.pendingSync, fontSize: 11),
                                              ),
                                            ],
                                          ],
                                        ),
                                      ),
                                      Text(
                                        "${currencyFormatter.format(item.total)} ج.م",
                                        style: TextStyle(
                                          color: isDark ? Colors.white : AppColors.primaryDark,
                                          fontWeight: FontWeight.bold,
                                          fontSize: 14,
                                        ),
                                      ),
                                    ],
                                  );
                                },
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 16),

                        // Financial Summary Card
                        Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: surface,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: border),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                "المجموع والمدفوعات",
                                style: TextStyle(color: textPrimary, fontWeight: FontWeight.bold, fontSize: 14),
                              ),
                              Divider(color: border, height: 20),
                              _buildFinancialRow("المجموع الفرعي:", "${currencyFormatter.format(p.subTotal)} ج.م", textSecondary, textPrimary),
                              if (p.discountAmount > 0)
                                _buildFinancialRow("الخصم:", "- ${currencyFormatter.format(p.discountAmount)} ج.م", textSecondary, textPrimary, color: AppColors.syncFailed),
                              if (p.taxAmount > 0)
                                _buildFinancialRow("الضريبة:", "+ ${currencyFormatter.format(p.taxAmount)} ج.م", textSecondary, textPrimary),
                              Divider(color: border, height: 16),
                              _buildFinancialRow(
                                "الإجمالي النهائي:",
                                "${currencyFormatter.format(p.totalAmount)} ج.م",
                                textSecondary,
                                textPrimary,
                                isBold: true,
                                color: AppColors.primary,
                              ),
                              _buildFinancialRow("المبلغ المدفوع:", "${currencyFormatter.format(p.paidAmount)} ج.م", textSecondary, textPrimary, color: AppColors.synced),
                              _buildFinancialRow(
                                "المبلغ المتبقي:",
                                "${currencyFormatter.format(p.remainingAmount)} ج.م",
                                textSecondary,
                                textPrimary,
                                color: p.remainingAmount > 0 ? AppColors.syncFailed : textMuted,
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 30),
                      ],
                    ),
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildSyncStatusCard(dynamic p, PurchasesProvider provider, bool isDark) {
    Color cardBorder;
    Color iconBg;
    IconData icon;
    String title;
    String desc;

    switch (p.syncStatus.toString().toLowerCase()) {
      case 'synced':
        cardBorder = AppColors.synced;
        iconBg = AppColors.synced.withOpacity(0.15);
        icon = Icons.check_circle_rounded;
        title = "تمت المزامنة بنجاح مع كاشير المحل";
        desc = p.syncedAt != null
            ? "تم سحب الفاتورة إلى قاعدة بيانات SQL المحلية وتحديث المخزون بتاريخ ${DateFormat('dd/MM/yyyy HH:mm').format(p.syncedAt!)}."
            : "تم إدراج الفاتورة في برنامج الكاشير بالمحل وتحديث المخزون.";
        break;
      case 'syncfailed':
      case 'failed':
        cardBorder = AppColors.syncFailed;
        iconBg = AppColors.syncFailed.withOpacity(0.15);
        icon = Icons.error_rounded;
        title = "فشلت المزامنة مع كاشير المحل";
        desc = p.syncError ?? "حدث خطأ أثناء تنزيل الفاتورة في النظام المحلي.";
        break;
      case 'pendingsync':
      case 'pending':
      default:
        cardBorder = AppColors.pendingSync;
        iconBg = AppColors.pendingSync.withOpacity(0.15);
        icon = Icons.cloud_upload_outlined;
        title = "الفاتورة مسجلة بالسحابة [قيد المزامنة]";
        desc = "الفاتورة محفوظة بأمان على السحابة، وفي انتظار تشغيل أو اتصال برنامج الكاشير بالمحل لاستيرادها.";
        break;
    }

    final textSecondary = AppColors.getTextSecondary(isDark);

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: cardBorder.withOpacity(0.08),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: cardBorder.withOpacity(0.4)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(color: iconBg, shape: BoxShape.circle),
                child: Icon(icon, color: cardBorder, size: 22),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  title,
                  style: TextStyle(color: cardBorder, fontWeight: FontWeight.bold, fontSize: 14),
                ),
              ),
              SyncStatusBadge(status: p.syncStatus),
            ],
          ),
          const SizedBox(height: 8),
          Text(desc, style: TextStyle(color: textSecondary, fontSize: 12, height: 1.4)),
          if (p.syncStatus.toString().toLowerCase() == 'syncfailed') ...[
            const SizedBox(height: 12),
            ElevatedButton.icon(
              onPressed: () async {
                final success = await provider.retrySync(p.id);
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(success ? "تمت إعادة الجدولة للمزامنة." : "فشل إعادة المحاولة."),
                      backgroundColor: success ? AppColors.synced : AppColors.syncFailed,
                    ),
                  );
                }
              },
              icon: const Icon(Icons.refresh_rounded, size: 16),
              label: const Text("إعادة المحاولة الآن"),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildInfoRow(String label, String value, Color textSecondary, Color textPrimary) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: TextStyle(color: textSecondary, fontSize: 13)),
          Text(value, style: TextStyle(color: textPrimary, fontWeight: FontWeight.w600, fontSize: 13)),
        ],
      ),
    );
  }

  Widget _buildFinancialRow(String label, String value, Color textSecondary, Color textPrimary, {bool isBold = false, Color? color}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: TextStyle(
              color: isBold ? textPrimary : textSecondary,
              fontWeight: isBold ? FontWeight.bold : FontWeight.normal,
              fontSize: isBold ? 14 : 13,
            ),
          ),
          Text(
            value,
            style: TextStyle(
              color: color ?? textPrimary,
              fontWeight: isBold ? FontWeight.bold : FontWeight.w600,
              fontSize: isBold ? 15 : 13,
            ),
          ),
        ],
      ),
    );
  }

  String _getPaymentMethodLabel(int method) {
    switch (method) {
      case 1:
        return "نقدي (كاش)";
      case 2:
        return "بطاقة بنكية";
      case 3:
        return "محفظة إلكترونية";
      case 4:
        return "آجل (ذمم)";
      default:
        return "نقدي";
    }
  }
}
