import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/widgets/custom_text_field.dart';
import '../../../core/widgets/offline_banner.dart';
import '../models/supplier_model.dart';
import '../providers/suppliers_provider.dart';

Future<SupplierModel?> showAddSupplierDialog(BuildContext context) {
  final nameCtrl = TextEditingController();
  final phoneCtrl = TextEditingController();
  final contactCtrl = TextEditingController();
  final emailCtrl = TextEditingController();
  final addressCtrl = TextEditingController();
  final balanceCtrl = TextEditingController(text: "0");
  final formKey = GlobalKey<FormState>();
  final isDark = Theme.of(context).brightness == Brightness.dark;
  final surface = AppColors.getSurface(isDark);
  final textPrimary = AppColors.getTextPrimary(isDark);
  final textSecondary = AppColors.getTextSecondary(isDark);

  return showDialog<SupplierModel>(
    context: context,
    builder: (ctx) {
      return Consumer<SuppliersProvider>(
        builder: (context, prov, child) {
          return AlertDialog(
            backgroundColor: surface,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            title: Row(
              children: [
                const Icon(Icons.person_add_alt_1_rounded, color: AppColors.accent),
                const SizedBox(width: 8),
                Text("إضافة مورد جديد", style: TextStyle(color: textPrimary, fontSize: 16, fontWeight: FontWeight.bold)),
              ],
            ),
            content: SingleChildScrollView(
              child: Form(
                key: formKey,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    CustomTextField(
                      controller: nameCtrl,
                      label: "اسم المورد / الشركة *",
                      hint: "مثلاً: شركة جهينة",
                      prefixIcon: Icons.business_rounded,
                      validator: (v) => (v == null || v.trim().isEmpty) ? "اسم المورد مطلوب" : null,
                    ),
                    const SizedBox(height: 12),
                    CustomTextField(
                      controller: phoneCtrl,
                      label: "رقم الهاتف *",
                      hint: "01xxxxxxxxx",
                      keyboardType: TextInputType.phone,
                      prefixIcon: Icons.phone_rounded,
                      validator: (v) => (v == null || v.trim().isEmpty) ? "رقم الهاتف مطلوب" : null,
                    ),
                    const SizedBox(height: 12),
                    CustomTextField(
                      controller: balanceCtrl,
                      label: "الرصيد الافتتاحي (ديون سابقة إن وجدت)",
                      hint: "0.00",
                      keyboardType: const TextInputType.numberWithOptions(decimal: true),
                      prefixIcon: Icons.account_balance_wallet_outlined,
                    ),
                    const SizedBox(height: 12),
                    CustomTextField(
                      controller: contactCtrl,
                      label: "مسؤول المورد / جهة الاتصال (اختياري)",
                      hint: "مثلاً: أ/ محمد مندوب المبيعات",
                      prefixIcon: Icons.badge_outlined,
                    ),
                    const SizedBox(height: 12),
                    CustomTextField(
                      controller: emailCtrl,
                      label: "البريد الإلكتروني (اختياري)",
                      hint: "supplier@example.com",
                      keyboardType: TextInputType.emailAddress,
                      prefixIcon: Icons.email_outlined,
                    ),
                    const SizedBox(height: 12),
                    CustomTextField(
                      controller: addressCtrl,
                      label: "العنوان (اختياري)",
                      hint: "المدينة أو المنطقة...",
                      prefixIcon: Icons.location_on_rounded,
                    ),
                  ],
                ),
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(ctx),
                child: Text("إلغاء", style: TextStyle(color: textSecondary)),
              ),
              ElevatedButton(
                style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary),
                onPressed: prov.isAdding
                    ? null
                    : () async {
                        if (!formKey.currentState!.validate()) return;
                        final req = CreateSupplierRequest(
                          name: nameCtrl.text.trim(),
                          phone: phoneCtrl.text.trim(),
                          contactPerson: contactCtrl.text.trim().isNotEmpty ? contactCtrl.text.trim() : null,
                          email: emailCtrl.text.trim().isNotEmpty ? emailCtrl.text.trim() : null,
                          address: addressCtrl.text.trim().isNotEmpty ? addressCtrl.text.trim() : null,
                          balance: double.tryParse(balanceCtrl.text.trim()) ?? 0.0,
                        );
                        final res = await prov.addSupplier(req);
                        if (res != null && ctx.mounted) {
                          Navigator.pop(ctx, res);
                        }
                      },
                child: prov.isAdding
                    ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                    : const Text("حفظ المورد", style: TextStyle(color: Colors.white)),
              ),
            ],
          );
        },
      );
    },
  );
}

class SuppliersListScreen extends StatefulWidget {
  const SuppliersListScreen({super.key});

  @override
  State<SuppliersListScreen> createState() => _SuppliersListScreenState();
}

class _SuppliersListScreenState extends State<SuppliersListScreen> {
  final TextEditingController _searchCtrl = TextEditingController();
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Provider.of<SuppliersProvider>(context, listen: false).fetchSuppliers();
    });
  }

  void _onScroll() {
    if (_scrollController.hasClients &&
        _scrollController.position.pixels >= _scrollController.position.maxScrollExtent - 250) {
      final prov = Provider.of<SuppliersProvider>(context, listen: false);
      if (prov.hasMore && !prov.isLoadingMore && !prov.isLoading) {
        prov.fetchMoreSuppliers();
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
    final prov = Provider.of<SuppliersProvider>(context);
    final currencyFormatter = NumberFormat("#,##0.00", "ar_EG");
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bg = AppColors.getBackground(isDark);
    final surface = AppColors.getSurface(isDark);
    final border = AppColors.getBorder(isDark);
    final textPrimary = AppColors.getTextPrimary(isDark);
    final textSecondary = AppColors.getTextSecondary(isDark);
    final textMuted = AppColors.getTextMuted(isDark);

    return Scaffold(
      backgroundColor: bg,
      appBar: AppBar(
        backgroundColor: surface,
        elevation: 0,
        title: Text("الموردين", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: textPrimary)),
      ),
      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: AppColors.primary,
        icon: const Icon(Icons.person_add_alt_1_rounded, color: Colors.white),
        label: const Text("إضافة مورد", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        onPressed: () => showAddSupplierDialog(context),
      ),
      body: Column(
        children: [
          const OfflineBanner(),
          Padding(
            padding: const EdgeInsets.all(16),
            child: TextField(
              controller: _searchCtrl,
              style: TextStyle(color: textPrimary, fontSize: 14),
              onChanged: (val) => prov.fetchSuppliers(search: val),
              decoration: InputDecoration(
                hintText: "بحث باسم المورد أو رقم الهاتف...",
                hintStyle: TextStyle(color: textMuted, fontSize: 13),
                prefixIcon: Icon(Icons.search_rounded, color: textSecondary, size: 20),
                filled: true,
                fillColor: surface,
                contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide(color: border)),
              ),
            ),
          ),
          Expanded(
            child: prov.isLoading
                ? const Center(child: CircularProgressIndicator(color: AppColors.primaryLight))
                : prov.suppliers.isEmpty
                    ? Center(
                        child: Text("لا يوجد موردين متاحين حالياً.", style: TextStyle(color: textMuted)),
                      )
                    : RefreshIndicator(
                        color: AppColors.primaryLight,
                        backgroundColor: surface,
                        onRefresh: () => prov.fetchSuppliers(search: _searchCtrl.text.trim()),
                        child: ListView.separated(
                          controller: _scrollController,
                          physics: const AlwaysScrollableScrollPhysics(),
                          padding: const EdgeInsets.fromLTRB(16, 0, 16, 80),
                          itemCount: prov.suppliers.length + (prov.isLoadingMore ? 1 : 0),
                          separatorBuilder: (_, __) => const SizedBox(height: 10),
                          itemBuilder: (ctx, idx) {
                            if (idx == prov.suppliers.length) {
                              return const Padding(
                                padding: EdgeInsets.symmetric(vertical: 16),
                                child: Center(
                                  child: SizedBox(
                                    width: 24,
                                    height: 24,
                                    child: CircularProgressIndicator(strokeWidth: 2.5, color: AppColors.primaryLight),
                                  ),
                                ),
                              );
                            }
                            final s = prov.suppliers[idx];
                            return Container(
                              padding: const EdgeInsets.all(14),
                              decoration: BoxDecoration(
                                color: surface,
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(color: border),
                              ),
                              child: Row(
                                children: [
                                  Container(
                                    width: 44,
                                    height: 44,
                                    decoration: BoxDecoration(
                                      color: AppColors.primary.withOpacity(0.15),
                                      borderRadius: BorderRadius.circular(10),
                                    ),
                                    child: Center(
                                      child: Text(
                                        s.name.isNotEmpty ? s.name[0] : "م",
                                        style: const TextStyle(color: AppColors.primaryLight, fontWeight: FontWeight.bold, fontSize: 18),
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          s.name,
                                          style: TextStyle(color: textPrimary, fontWeight: FontWeight.bold, fontSize: 14),
                                        ),
                                        const SizedBox(height: 4),
                                        if (s.contactPerson != null && s.contactPerson!.isNotEmpty)
                                          Row(
                                            children: [
                                              Icon(Icons.badge_outlined, size: 13, color: textMuted),
                                              const SizedBox(width: 4),
                                              Text(s.contactPerson!, style: TextStyle(color: textSecondary, fontSize: 12)),
                                            ],
                                          ),
                                        if (s.phone != null && s.phone!.isNotEmpty)
                                          Row(
                                            children: [
                                              Icon(Icons.phone_outlined, size: 13, color: textMuted),
                                              const SizedBox(width: 4),
                                              Text(s.phone!, style: TextStyle(color: textSecondary, fontSize: 12)),
                                            ],
                                          ),
                                        if (s.address != null && s.address!.isNotEmpty)
                                          Row(
                                            children: [
                                              Icon(Icons.location_on_outlined, size: 13, color: textMuted),
                                              const SizedBox(width: 4),
                                              Expanded(
                                                child: Text(
                                                  s.address!,
                                                  style: TextStyle(color: textMuted, fontSize: 11),
                                                  maxLines: 1,
                                                  overflow: TextOverflow.ellipsis,
                                                ),
                                              ),
                                            ],
                                          ),
                                      ],
                                    ),
                                  ),
                                  Column(
                                    crossAxisAlignment: CrossAxisAlignment.end,
                                    children: [
                                      Text("الرصيد", style: TextStyle(color: textMuted, fontSize: 11)),
                                      const SizedBox(height: 2),
                                      Text(
                                        "${currencyFormatter.format(s.balance)} ج.م",
                                        style: TextStyle(
                                          color: s.balance > 0 ? AppColors.syncFailed : textSecondary,
                                          fontWeight: FontWeight.bold,
                                          fontSize: 13,
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            );
                          },
                        ),
                      ),
          ),
        ],
      ),
    );
  }
}
