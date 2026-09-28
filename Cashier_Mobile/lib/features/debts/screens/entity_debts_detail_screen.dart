import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/theme/theme_provider.dart';
import '../../../core/widgets/custom_text_field.dart';
import '../models/debt_model.dart';
import '../providers/debts_provider.dart';

class EntityDebtsDetailScreen extends StatefulWidget {
  final GroupedDebtEntity entity;

  const EntityDebtsDetailScreen({
    super.key,
    required this.entity,
  });

  @override
  State<EntityDebtsDetailScreen> createState() => _EntityDebtsDetailScreenState();
}

class _EntityDebtsDetailScreenState extends State<EntityDebtsDetailScreen> {
  final currencyFormatter = NumberFormat("#,##0.00", "ar_EG");
  final dateFormatter = DateFormat("dd/MM/yyyy");

  Future<void> _openPayModal(DebtItemModel debt) async {
    final amountCtrl = TextEditingController(text: debt.remainingAmount.toStringAsFixed(2));
    final notesCtrl = TextEditingController();
    final isDark = Provider.of<ThemeProvider>(context, listen: false).isDarkMode;
    final isCustomer = debt.type == 'Customer';

    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.getSurface(isDark),
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (ctx) => Padding(
        padding: EdgeInsets.only(
          left: 16,
          right: 16,
          top: 20,
          bottom: MediaQuery.of(ctx).viewInsets.bottom + 20,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  isCustomer ? Icons.handshake_rounded : Icons.payments_rounded,
                  color: isCustomer ? AppColors.success : AppColors.warning,
                ),
                const SizedBox(width: 8),
                Text(
                  isCustomer ? "تحصيل دفعة من فاتورة" : "سداد دفعة لفاتورة",
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: AppColors.getTextPrimary(isDark)),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              "${isCustomer ? 'العميل' : 'المورد'}: ${debt.entityName}",
              style: TextStyle(fontSize: 13, color: AppColors.getTextSecondary(isDark)),
            ),
            const SizedBox(height: 4),
            Row(
              children: [
                Expanded(
                  child: Text(
                    "رقم الفاتورة: ${debt.invoiceNumber}",
                    style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: AppColors.primaryLight),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  "المتبقي: ${currencyFormatter.format(debt.remainingAmount)} ج.م",
                  style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: isCustomer ? AppColors.success : AppColors.danger),
                ),
              ],
            ),
            const SizedBox(height: 16),
            CustomTextField(
              controller: amountCtrl,
              label: "المبلغ المدفوع *",
              hint: "0.00",
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              prefixIcon: Icons.attach_money_rounded,
            ),
            const SizedBox(height: 12),
            CustomTextField(
              controller: notesCtrl,
              label: "ملاحظات الدفعة (اختياري)",
              hint: "مثلاً: دفعة كاش، تحويل فودافون كاش...",
              prefixIcon: Icons.notes_rounded,
            ),
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              height: 48,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: isCustomer ? AppColors.success : AppColors.primary,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                onPressed: () async {
                  final amt = double.tryParse(amountCtrl.text.trim()) ?? 0;
                  if (amt <= 0) return;

                  Navigator.pop(ctx);
                  final prov = Provider.of<DebtsProvider>(context, listen: false);
                  final success = await prov.payDebt(
                    debtType: debt.type,
                    referenceId: debt.referenceId,
                    amount: amt,
                    notes: notesCtrl.text.trim(),
                  );

                  if (success && mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        backgroundColor: AppColors.success,
                        content: Text("تم تسجيل سداد بقيمة $amt ج.م بنجاح وجاري المزامنة."),
                      ),
                    );
                    setState(() {});
                  }
                },
                child: Text(
                  isCustomer ? "تأكيد تحصيل الفاتورة" : "تأكيد سداد الفاتورة",
                  style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.white, fontSize: 15),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Provider.of<ThemeProvider>(context).isDarkMode;
    final prov = Provider.of<DebtsProvider>(context);

    // Retrieve active invoices for this entity
    final activeInvoices = prov.debts
        .where((d) => d.entityName.trim().toLowerCase() == widget.entity.entityName.trim().toLowerCase())
        .toList();

    final isCustomer = widget.entity.type == 'Customer';
    final totalRemaining = activeInvoices.fold(0.0, (sum, i) => sum + i.remainingAmount);
    final totalOriginal = activeInvoices.fold(0.0, (sum, i) => sum + i.totalAmount);
    final totalPaid = activeInvoices.fold(0.0, (sum, i) => sum + i.paidAmount);

    return Scaffold(
      backgroundColor: AppColors.getBackground(isDark),
      appBar: AppBar(
        backgroundColor: AppColors.getSurface(isDark),
        elevation: 0,
        title: Text(
          isCustomer ? "فواتير العميل: ${widget.entity.entityName}" : "فواتير المورد: ${widget.entity.entityName}",
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: AppColors.getTextPrimary(isDark)),
        ),
        leading: IconButton(
          icon: Icon(Icons.arrow_back_ios_rounded, color: AppColors.getTextPrimary(isDark)),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: Column(
        children: [
          // Header Card with Summary
          Container(
            margin: const EdgeInsets.all(16),
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppColors.getSurface(isDark),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: AppColors.getBorder(isDark)),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            widget.entity.entityName,
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: AppColors.getTextPrimary(isDark),
                            ),
                          ),
                          if (widget.entity.phone != null && widget.entity.phone!.isNotEmpty) ...[
                            const SizedBox(height: 4),
                            Row(
                              children: [
                                const Icon(Icons.phone_rounded, size: 14, color: AppColors.primaryLight),
                                const SizedBox(width: 6),
                                Text(
                                  widget.entity.phone!,
                                  style: TextStyle(
                                    fontSize: 13,
                                    color: AppColors.getTextSecondary(isDark),
                                    fontFamily: 'monospace',
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ],
                      ),
                    ),
                    const SizedBox(width: 8),
                    Flexible(
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                        decoration: BoxDecoration(
                          color: (isCustomer ? AppColors.success : AppColors.danger).withOpacity(0.12),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              isCustomer ? "المحصلة المطلوبة" : "إجمالي المستحق",
                              style: TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.w600,
                                color: isCustomer ? AppColors.success : AppColors.danger,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            Text(
                              "${currencyFormatter.format(totalRemaining)} ج.م",
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.bold,
                                color: isCustomer ? AppColors.success : AppColors.danger,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
                const Divider(height: 20),
                Row(
                  children: [
                    Expanded(child: _buildStatItem(isDark, "عدد الفواتير المعلقة", "${activeInvoices.length} فاتورة")),
                    Expanded(child: _buildStatItem(isDark, "إجمالي المبالغ", "${currencyFormatter.format(totalOriginal)} ج.م")),
                    Expanded(child: _buildStatItem(isDark, "المسدد سابقاً", "${currencyFormatter.format(totalPaid)} ج.م")),
                  ],
                ),
              ],
            ),
          ),

          // Section Title
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
            child: Row(
              children: [
                Icon(Icons.receipt_long_rounded, size: 18, color: isCustomer ? AppColors.success : AppColors.primaryLight),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    "قائمة الفواتير الآجلة (يمكنك سداد أي فاتورة على حدة)",
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.bold,
                      color: AppColors.getTextPrimary(isDark),
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
          ),

          // Invoices List
          Expanded(
            child: activeInvoices.isEmpty
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.check_circle_outline_rounded, size: 56, color: AppColors.success),
                        const SizedBox(height: 12),
                        Text(
                          "تم سداد كافة فواتير هذا الحساب بالكامل 🎉",
                          style: TextStyle(color: AppColors.getTextMuted(isDark), fontSize: 14),
                        ),
                      ],
                    ),
                  )
                : ListView.separated(
                    padding: const EdgeInsets.all(16),
                    itemCount: activeInvoices.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 12),
                    itemBuilder: (context, idx) {
                      final inv = activeInvoices[idx];
                      return _buildInvoiceCard(isDark, inv, isCustomer);
                    },
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatItem(bool isDark, String label, String value) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: TextStyle(fontSize: 11, color: AppColors.getTextMuted(isDark)), maxLines: 1, overflow: TextOverflow.ellipsis),
        const SizedBox(height: 2),
        Text(
          value,
          style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: AppColors.getTextPrimary(isDark)),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
      ],
    );
  }

  Widget _buildInvoiceCard(bool isDark, DebtItemModel inv, bool isCustomer) {
    return Container(
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
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(6),
                      decoration: BoxDecoration(
                        color: AppColors.primary.withOpacity(0.12),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Icon(Icons.receipt_rounded, size: 16, color: AppColors.primaryLight),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        "فاتورة #${inv.invoiceNumber}",
                        style: TextStyle(
                          fontSize: 13.5,
                          fontWeight: FontWeight.bold,
                          color: AppColors.getTextPrimary(isDark),
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Flexible(
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: (isCustomer ? AppColors.success : AppColors.danger).withOpacity(0.12),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    "متبقي: ${currencyFormatter.format(inv.remainingAmount)} ج.م",
                    style: TextStyle(
                      fontSize: 11.5,
                      fontWeight: FontWeight.bold,
                      color: isCustomer ? AppColors.success : AppColors.danger,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Icon(Icons.calendar_today_rounded, size: 12, color: AppColors.getTextMuted(isDark)),
              const SizedBox(width: 4),
              Text(
                "تاريخ الفاتورة: ${dateFormatter.format(inv.date)}",
                style: TextStyle(fontSize: 11.5, color: AppColors.getTextMuted(isDark)),
              ),
            ],
          ),
          const Divider(height: 18),
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      "الإجمالي: ${currencyFormatter.format(inv.totalAmount)} ج.م",
                      style: TextStyle(fontSize: 11, color: AppColors.getTextMuted(isDark)),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 2),
                    Text(
                      "المدفوع: ${currencyFormatter.format(inv.paidAmount)} ج.م",
                      style: TextStyle(fontSize: 11.5, color: AppColors.getTextSecondary(isDark), fontWeight: FontWeight.w600),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: isCustomer ? AppColors.success : AppColors.primary,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                  minimumSize: Size.zero,
                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  elevation: 0,
                ),
                onPressed: () => _openPayModal(inv),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(isCustomer ? Icons.download_rounded : Icons.upload_rounded, size: 13),
                    const SizedBox(width: 4),
                    Text(
                      isCustomer ? "تحصيل الفاتورة" : "سداد الفاتورة",
                      style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
