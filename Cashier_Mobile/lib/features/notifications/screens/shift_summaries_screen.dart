import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/theme/theme_provider.dart';
import '../providers/notifications_provider.dart';

class ShiftSummariesScreen extends StatelessWidget {
  const ShiftSummariesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final notifProv = Provider.of<NotificationsProvider>(context);
    final isDark = Provider.of<ThemeProvider>(context).isDarkMode;
    final currencyFormatter = NumberFormat("#,##0.00", "en_US");
    final dateFormatter = DateFormat("dd/MM/yyyy HH:mm");

    return Scaffold(
      backgroundColor: AppColors.getBackground(isDark),
      appBar: AppBar(
        title: const Text("تقارير أداء الكاشير وإغلاق الورديات"),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_rounded),
            onPressed: () => notifProv.fetchAllNotifications(),
          ),
        ],
      ),
      body: notifProv.isLoading
          ? const Center(child: CircularProgressIndicator(color: AppColors.primaryLight))
          : notifProv.shiftSummaries.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.access_time_rounded, size: 70, color: AppColors.primaryLight),
                      const SizedBox(height: 16),
                      Text(
                        "لا توجد إشعارات إغلاق ورديات حالياً.",
                        style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: AppColors.getTextPrimary(isDark)),
                      ),
                    ],
                  ),
                )
              : ListView.separated(
                  padding: const EdgeInsets.all(16),
                  itemCount: notifProv.shiftSummaries.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 12),
                  itemBuilder: (ctx, idx) {
                    final s = notifProv.shiftSummaries[idx];
                    final isBalanced = s.cashDifference == 0;
                    final isSurplus = s.cashDifference > 0;

                    return Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: AppColors.getSurface(isDark),
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(
                          color: s.isReadByOwner ? AppColors.getBorder(isDark) : AppColors.primary.withOpacity(0.5),
                          width: s.isReadByOwner ? 1 : 1.5,
                        ),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Row(
                                children: [
                                  const Icon(Icons.person_pin_rounded, color: AppColors.primaryLight),
                                  const SizedBox(width: 8),
                                  Text(
                                    s.cashierName,
                                    style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 16,
                                      color: AppColors.getTextPrimary(isDark),
                                    ),
                                  ),
                                ],
                              ),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                decoration: BoxDecoration(
                                  color: (isBalanced
                                          ? AppColors.success
                                          : (isSurplus ? AppColors.accent : AppColors.danger))
                                      .withOpacity(0.15),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Text(
                                  isBalanced
                                      ? "الدرج متطابق ✅"
                                      : (isSurplus
                                          ? "زيادة (+${currencyFormatter.format(s.cashDifference)} ج.م)"
                                          : "عجز (${currencyFormatter.format(s.cashDifference)} ج.م) ⚠️"),
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 12,
                                    color: isBalanced
                                        ? AppColors.success
                                        : (isSurplus ? AppColors.accent : AppColors.danger),
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 10),
                          Text(
                            "وقت الإغلاق: ${dateFormatter.format(s.closedAt)}",
                            style: TextStyle(fontSize: 12, color: AppColors.getTextSecondary(isDark)),
                          ),
                          const SizedBox(height: 12),
                          const Divider(height: 1),
                          const SizedBox(height: 12),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              _buildMetric(isDark, "إجمالي المبيعات", "${currencyFormatter.format(s.totalSales)} ج.م"),
                              _buildMetric(isDark, "الفواتير", "${s.totalInvoices} فاتورة"),
                              _buildMetric(isDark, "النقدية الفعلية", "${currencyFormatter.format(s.actualClosingCash)} ج.م"),
                            ],
                          ),
                          if (s.closingNotes != null && s.closingNotes!.isNotEmpty) ...[
                            const SizedBox(height: 10),
                            Text(
                              "ملاحظات: ${s.closingNotes}",
                              style: TextStyle(fontSize: 12, color: AppColors.getTextSecondary(isDark), fontStyle: FontStyle.italic),
                            ),
                          ],
                          if (!s.isReadByOwner) ...[
                            const SizedBox(height: 12),
                            Align(
                              alignment: Alignment.centerLeft,
                              child: TextButton.icon(
                                onPressed: () => notifProv.markShiftRead(s.id),
                                icon: const Icon(Icons.mark_email_read_rounded, size: 16),
                                label: const Text("تحديد كمقروء"),
                              ),
                            ),
                          ],
                        ],
                      ),
                    );
                  },
                ),
    );
  }

  Widget _buildMetric(bool isDark, String label, String value) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: TextStyle(fontSize: 11, color: AppColors.getTextMuted(isDark))),
        const SizedBox(height: 2),
        Text(
          value,
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: AppColors.getTextPrimary(isDark)),
        ),
      ],
    );
  }
}
