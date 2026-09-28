import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/theme/theme_provider.dart';
import '../../products/models/product_model.dart';
import '../../products/providers/products_provider.dart';
import '../models/notification_models.dart';
import '../providers/notifications_provider.dart';

class ExpiryNotificationsScreen extends StatefulWidget {
  const ExpiryNotificationsScreen({super.key});

  @override
  State<ExpiryNotificationsScreen> createState() => _ExpiryNotificationsScreenState();
}

class _ExpiryNotificationsScreenState extends State<ExpiryNotificationsScreen> {
  final _dateFormatter = DateFormat("dd/MM/yyyy");

  int _getProductShelfDays(ExpiryNotificationModel notif) {
    try {
      final productsProv = Provider.of<ProductsProvider>(context, listen: false);
      final product = productsProv.products.cast<ProductModel?>().firstWhere(
        (p) => p != null && (p.id == notif.productId || (notif.barcode != null && notif.barcode!.isNotEmpty && p.barcode == notif.barcode) || p.nameAr == notif.productName),
        orElse: () => null,
      );
      if (product != null && product.shelfLifeDays > 0) {
        return product.shelfLifeDays;
      }
    } catch (_) {}
    return 180; // fallback if product not loaded yet
  }

  void _showResolveConfirm(ExpiryNotificationModel notif) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text("تأكيد سلامة البضاعة"),
        content: Text("هل أنت متأكد من أن بضاعة (${notif.productName}) صالحة ولا يوجد بها أي هالك أو تلف؟"),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text("إلغاء")),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.success),
            onPressed: () async {
              Navigator.pop(ctx);
              final prov = Provider.of<NotificationsProvider>(context, listen: false);
              final success = await prov.sendExpiryAction(notif.id, actionType: "OK");
              if (success && mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text("تم تأكيد سلامة البضاعة وحفظ الإجراء بنجاح ✅")),
                );
              }
            },
            child: const Text("نعم، البضاعة تمام", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  void _showWasteModal(ExpiryNotificationModel notif, bool isDark) {
    final qtyCtrl = TextEditingController(text: notif.remainingQuantity.toInt().toString());
    final reasonCtrl = TextEditingController(text: "انتهاء صلاحية");
    final notesCtrl = TextEditingController();

    showModalBottomSheet(
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
                const Icon(Icons.delete_sweep_rounded, color: AppColors.danger),
                const SizedBox(width: 8),
                Text(
                  "تسجيل هالك للمنتج: ${notif.productName}",
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: AppColors.getTextPrimary(isDark)),
                ),
              ],
            ),
            const SizedBox(height: 14),
            TextField(
              controller: qtyCtrl,
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              decoration: InputDecoration(
                labelText: "الكمية التالفة (${notif.unit}) *",
                hintText: "الحد الأقصى: ${notif.remainingQuantity.toInt()}",
                prefixIcon: const Icon(Icons.numbers_rounded, color: AppColors.primaryLight),
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: reasonCtrl,
              decoration: const InputDecoration(
                labelText: "سبب الهالك",
                prefixIcon: Icon(Icons.info_outline_rounded, color: AppColors.primaryLight),
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: notesCtrl,
              decoration: const InputDecoration(
                labelText: "ملاحظات إضافية",
                prefixIcon: Icon(Icons.notes_rounded, color: AppColors.primaryLight),
              ),
            ),
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              height: 48,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.danger,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                onPressed: () async {
                  final qty = double.tryParse(qtyCtrl.text.trim()) ?? 0;
                  if (qty <= 0 || qty > notif.remainingQuantity) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text("يرجى إدخال كمية صحيحة لا تتجاوز الرصيد المتاح.")),
                    );
                    return;
                  }

                  Navigator.pop(ctx);
                  final prov = Provider.of<NotificationsProvider>(context, listen: false);
                  final success = await prov.sendExpiryAction(
                    notif.id,
                    actionType: "Waste",
                    quantity: qty,
                    reason: reasonCtrl.text.trim(),
                    notes: notesCtrl.text.trim(),
                  );

                  if (success && mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text("تم تسجيل الهالك وجاري اعتماده بالكاشير 🗑️")),
                    );
                  }
                },
                child: const Text("تأكيد تسجيل الهالك", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showSupplierReplacementModal(ExpiryNotificationModel notif, bool isDark) {
    final int shelfDays = _getProductShelfDays(notif);
    DateTime productionDate = DateTime.now();
    DateTime expiryDate = productionDate.add(Duration(days: shelfDays));
    final batchCtrl = TextEditingController();
    final notesCtrl = TextEditingController(text: "تبديل من المورد للدفعة ${notif.batchNumber ?? ''}".trim());

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.getSurface(isDark),
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (ctx) => StatefulBuilder(
        builder: (modalCtx, setModalState) => Padding(
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
              // Header
              Row(
                children: [
                  const Icon(Icons.sync_alt_rounded, color: AppColors.primaryLight),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      "تبديل من المورد: ${notif.productName}",
                      style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: AppColors.getTextPrimary(isDark)),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: AppColors.primaryLight.withOpacity(0.08),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: AppColors.primaryLight.withOpacity(0.2)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      "الكمية المستبدلة: ${notif.remainingQuantity.toInt()} ${notif.unit} | رقم التشغيلة الحالي: ${notif.batchNumber ?? 'افتراضي'}",
                      style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: AppColors.getTextPrimary(isDark)),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      "الاستبدال من المورد يحدّث تاريخ الصلاحية للكمية المتبقية دون تسجيل أي خسارة مالية على المحل.",
                      style: TextStyle(color: AppColors.getTextSecondary(isDark), fontSize: 11.5),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 14),

              // Production Date & Expiry Date row
              Row(
                children: [
                  // Production Date
                  Expanded(
                    child: InkWell(
                      onTap: () async {
                        final picked = await showDatePicker(
                          context: context,
                          initialDate: productionDate,
                          firstDate: DateTime.now().subtract(const Duration(days: 365)),
                          lastDate: DateTime.now().add(const Duration(days: 30)),
                        );
                        if (picked != null) {
                          setModalState(() {
                            productionDate = picked;
                            expiryDate = productionDate.add(Duration(days: shelfDays));
                          });
                        }
                      },
                      borderRadius: BorderRadius.circular(10),
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                        decoration: BoxDecoration(
                          color: isDark ? const Color(0xFF0F172A) : const Color(0xFFF1F5F9),
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(color: AppColors.getBorder(isDark)),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                const Icon(Icons.event_available_rounded, size: 16, color: AppColors.primaryLight),
                                const SizedBox(width: 4),
                                Text(
                                  "تاريخ الإنتاج الجديد *",
                                  style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: AppColors.getTextSecondary(isDark)),
                                ),
                              ],
                            ),
                            const SizedBox(height: 6),
                            Text(
                              _dateFormatter.format(productionDate),
                              style: TextStyle(fontSize: 13.5, fontWeight: FontWeight.bold, color: AppColors.getTextPrimary(isDark)),
                            ),
                            const SizedBox(height: 2),
                            const Text(
                              "تاريخ إنتاج البضاعة",
                              style: TextStyle(fontSize: 10, color: AppColors.primaryLight),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),

                  // Expiry Date (Auto-calculated, clickable to adjust if needed)
                  Expanded(
                    child: InkWell(
                      onTap: () async {
                        final picked = await showDatePicker(
                          context: context,
                          initialDate: expiryDate,
                          firstDate: productionDate,
                          lastDate: DateTime.now().add(const Duration(days: 365 * 10)),
                        );
                        if (picked != null) {
                          setModalState(() {
                            expiryDate = picked;
                          });
                        }
                      },
                      borderRadius: BorderRadius.circular(10),
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                        decoration: BoxDecoration(
                          color: isDark ? const Color(0xFF0F172A) : const Color(0xFFF1F5F9),
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(color: AppColors.success.withOpacity(0.5)),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Row(
                              children: [
                                Icon(Icons.event_note_rounded, size: 16, color: AppColors.success),
                                SizedBox(width: 4),
                                Text(
                                  "تاريخ الانتهاء الجديد *",
                                  style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: AppColors.success),
                                ),
                              ],
                            ),
                            const SizedBox(height: 6),
                            Text(
                              _dateFormatter.format(expiryDate),
                              style: const TextStyle(fontSize: 13.5, fontWeight: FontWeight.bold, color: AppColors.success),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              "✨ محسوب (صلاحية: $shelfDays يوم)",
                              style: const TextStyle(fontSize: 9.5, color: AppColors.cyan, fontWeight: FontWeight.w600),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),

              // Batch Number Text Field
              TextField(
                controller: batchCtrl,
                decoration: const InputDecoration(
                  labelText: "رقم التشغيلة الجديد (Batch Number)",
                  hintText: "اختياري: مثلاً BATCH-2026-X",
                  prefixIcon: Icon(Icons.qr_code_rounded, color: AppColors.primaryLight),
                ),
              ),
              const SizedBox(height: 12),

              // Notes Text Field
              TextField(
                controller: notesCtrl,
                decoration: const InputDecoration(
                  labelText: "ملاحظات الاستبدال",
                  hintText: "اسم المندوب أو تفاصيل إذن التبديل...",
                  prefixIcon: Icon(Icons.notes_rounded, color: AppColors.primaryLight),
                ),
              ),
              const SizedBox(height: 20),

              // Submit Button
              SizedBox(
                width: double.infinity,
                height: 48,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  onPressed: () async {
                    Navigator.pop(ctx);
                    final prov = Provider.of<NotificationsProvider>(context, listen: false);
                    final success = await prov.sendExpiryAction(
                      notif.id,
                      actionType: "SupplierReplacement",
                      newExpiryDate: expiryDate,
                      newBatchNumber: batchCtrl.text.trim().isNotEmpty ? batchCtrl.text.trim() : null,
                      notes: notesCtrl.text.trim(),
                    );

                    if (success && mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text("تم تسجيل الاستبدال بالصلاحية الجديدة بنجاح 🔄")),
                      );
                    }
                  },
                  child: const Text("تأكيد الاستبدال من المورد", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final notifProv = Provider.of<NotificationsProvider>(context);
    final isDark = Provider.of<ThemeProvider>(context).isDarkMode;

    return Scaffold(
      backgroundColor: AppColors.getBackground(isDark),
      appBar: AppBar(
        title: const Text("تنبيهات الصلاحية العاجلة"),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_rounded),
            onPressed: () => notifProv.fetchAllNotifications(),
          ),
        ],
      ),
      body: notifProv.isLoading
          ? const Center(child: CircularProgressIndicator(color: AppColors.primaryLight))
          : notifProv.expiryNotifications.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.verified_rounded, size: 70, color: AppColors.success),
                      const SizedBox(height: 16),
                      Text(
                        "جميع تواريخ الصلاحية بالمخزن منضبطة ولا توجد أي دفعات بحاجة لإجراء.",
                        textAlign: TextAlign.center,
                        style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: AppColors.getTextPrimary(isDark)),
                      ),
                    ],
                  ),
                )
              : ListView.separated(
                  padding: const EdgeInsets.all(16),
                  itemCount: notifProv.expiryNotifications.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 12),
                  itemBuilder: (ctx, idx) {
                    final n = notifProv.expiryNotifications[idx];
                    return Container(
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: AppColors.getSurface(isDark),
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(
                          color: n.isExpired ? AppColors.danger.withOpacity(0.5) : AppColors.warning.withOpacity(0.5),
                        ),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Container(
                                padding: const EdgeInsets.all(8),
                                decoration: BoxDecoration(
                                  color: (n.isExpired ? AppColors.danger : AppColors.warning).withOpacity(0.12),
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                child: Icon(
                                  n.isExpired ? Icons.warning_amber_rounded : Icons.schedule_rounded,
                                  color: n.isExpired ? AppColors.danger : AppColors.warning,
                                  size: 24,
                                ),
                              ),
                              const SizedBox(width: 10),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      n.productName,
                                      style: TextStyle(
                                        fontWeight: FontWeight.bold,
                                        fontSize: 15,
                                        color: AppColors.getTextPrimary(isDark),
                                      ),
                                    ),
                                    const SizedBox(height: 3),
                                    Text(
                                      "رقم التشغيلة: ${n.batchNumber ?? 'افتراضي'} | المتبقي: ${n.remainingQuantity.toInt()} ${n.unit}",
                                      style: TextStyle(fontSize: 12, color: AppColors.getTextSecondary(isDark)),
                                    ),
                                  ],
                                ),
                              ),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                decoration: BoxDecoration(
                                  color: (n.isExpired ? AppColors.danger : AppColors.warning).withOpacity(0.15),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Text(
                                  n.isExpired ? "منتهي الصلاحية" : "ينتهي خلال ${n.daysRemaining} يوم",
                                  style: TextStyle(
                                    color: n.isExpired ? AppColors.danger : AppColors.warning,
                                    fontWeight: FontWeight.bold,
                                    fontSize: 11,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),
                          const Divider(height: 1),
                          const SizedBox(height: 10),
                          Wrap(
                            spacing: 8,
                            runSpacing: 6,
                            children: [
                              ElevatedButton.icon(
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: AppColors.success.withOpacity(0.12),
                                  foregroundColor: AppColors.success,
                                  elevation: 0,
                                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                                ),
                                icon: const Icon(Icons.check_circle_outline_rounded, size: 16),
                                label: const Text("صلاحية تمام", style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                                onPressed: () => _showResolveConfirm(n),
                              ),
                              ElevatedButton.icon(
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: AppColors.primary.withOpacity(0.12),
                                  foregroundColor: AppColors.primaryLight,
                                  elevation: 0,
                                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                                ),
                                icon: const Icon(Icons.swap_horiz_rounded, size: 16),
                                label: const Text("تبديل من المورد", style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                                onPressed: () => _showSupplierReplacementModal(n, isDark),
                              ),
                              ElevatedButton.icon(
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: AppColors.danger.withOpacity(0.12),
                                  foregroundColor: AppColors.danger,
                                  elevation: 0,
                                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                                ),
                                icon: const Icon(Icons.delete_outline_rounded, size: 16),
                                label: const Text("تسجيل هالك", style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                                onPressed: () => _showWasteModal(n, isDark),
                              ),
                            ],
                          ),
                        ],
                      ),
                    );
                  },
                ),
    );
  }
}
