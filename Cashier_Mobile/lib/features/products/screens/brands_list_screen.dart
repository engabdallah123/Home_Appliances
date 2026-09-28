import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/theme/theme_provider.dart';
import '../../../core/widgets/custom_text_field.dart';
import '../../../core/widgets/offline_banner.dart';
import '../models/brand_model.dart';
import '../providers/brands_provider.dart';
import '../providers/products_provider.dart';

Future<BrandModel?> showAddBrandDialog(BuildContext context) {
  final nameArCtrl = TextEditingController();
  final nameEnCtrl = TextEditingController();
  final originCountryCtrl = TextEditingController();
  final agentContactCtrl = TextEditingController();
  final descCtrl = TextEditingController();
  final formKey = GlobalKey<FormState>();
  final isDark = Theme.of(context).brightness == Brightness.dark;
  final surface = AppColors.getSurface(isDark);
  final textPrimary = AppColors.getTextPrimary(isDark);
  final textSecondary = AppColors.getTextSecondary(isDark);

  return showDialog<BrandModel>(
    context: context,
    builder: (ctx) {
      return Consumer<BrandsProvider>(
        builder: (context, prov, child) {
          return AlertDialog(
            backgroundColor: surface,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            title: Row(
              children: [
                const Icon(Icons.verified_rounded, color: AppColors.accent),
                const SizedBox(width: 8),
                Text(
                  "إضافة ماركة تجارية جديدة",
                  style: TextStyle(color: textPrimary, fontSize: 16, fontWeight: FontWeight.bold),
                ),
              ],
            ),
            content: SingleChildScrollView(
              child: Form(
                key: formKey,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    CustomTextField(
                      controller: nameArCtrl,
                      label: "اسم الماركة (بالعربي)",
                      hint: "مثلاً: توشيبا، شارب، فريش، بوش...",
                      prefixIcon: Icons.branding_watermark_rounded,
                    ),
                    const SizedBox(height: 12),
                    CustomTextField(
                      controller: nameEnCtrl,
                      label: "اسم الماركة (بالإنجليزية - اختياري)",
                      hint: "مثلاً: Toshiba, Sharp, Fresh...",
                      prefixIcon: Icons.language_rounded,
                    ),
                    const SizedBox(height: 12),
                    CustomTextField(
                      controller: originCountryCtrl,
                      label: "بلد المنشأ / التصنيع (اختياري)",
                      hint: "مثلاً: اليابان، مصر، تركيا...",
                      prefixIcon: Icons.public_rounded,
                    ),
                    const SizedBox(height: 12),
                    CustomTextField(
                      controller: agentContactCtrl,
                      label: "هاتف الوكيل / الخط الساخن (اختياري)",
                      hint: "مثلاً: 19319، 19099...",
                      keyboardType: TextInputType.phone,
                      prefixIcon: Icons.support_agent_rounded,
                    ),
                    const SizedBox(height: 12),
                    CustomTextField(
                      controller: descCtrl,
                      label: "ملاحظات أو وصف الماركة (اختياري)",
                      hint: "مثلاً: وكيل معتمد العربي جروب...",
                      prefixIcon: Icons.notes_rounded,
                      maxLines: 2,
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
                onPressed: prov.isSaving
                    ? null
                    : () async {
                        final ar = nameArCtrl.text.trim();
                        final en = nameEnCtrl.text.trim();
                        final finalName = ar.isNotEmpty ? ar : (en.isNotEmpty ? en : "ماركة جديدة");

                        final req = CreateBrandRequest(
                          name: finalName,
                          nameAr: ar.isNotEmpty ? ar : null,
                          nameEn: en.isNotEmpty ? en : null,
                          originCountry: originCountryCtrl.text.trim().isNotEmpty ? originCountryCtrl.text.trim() : null,
                          agentContactNumber: agentContactCtrl.text.trim().isNotEmpty ? agentContactCtrl.text.trim() : null,
                          description: descCtrl.text.trim().isNotEmpty ? descCtrl.text.trim() : null,
                        );

                        final res = await prov.createBrand(req);
                        if (res != null && ctx.mounted) {
                          // Also refresh in products provider
                          Provider.of<ProductsProvider>(context, listen: false).fetchBrands();
                          Navigator.pop(ctx, res);
                        }
                      },
                child: prov.isSaving
                    ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                    : const Text("حفظ الماركة", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
              ),
            ],
          );
        },
      );
    },
  );
}

class BrandsListScreen extends StatefulWidget {
  const BrandsListScreen({super.key});

  @override
  State<BrandsListScreen> createState() => _BrandsListScreenState();
}

class _BrandsListScreenState extends State<BrandsListScreen> {
  final TextEditingController _searchCtrl = TextEditingController();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Provider.of<BrandsProvider>(context, listen: false).fetchBrands();
    });
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Provider.of<ThemeProvider>(context).isDarkMode;
    final prov = Provider.of<BrandsProvider>(context);

    return Scaffold(
      backgroundColor: AppColors.getBackground(isDark),
      appBar: AppBar(
        backgroundColor: AppColors.getSurface(isDark),
        elevation: 0,
        title: Text(
          "الماركات التجارية للأجهزة",
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: AppColors.getTextPrimary(isDark)),
        ),
        actions: [
          IconButton(
            icon: Icon(Icons.refresh_rounded, color: AppColors.getTextPrimary(isDark)),
            tooltip: "تحديث",
            onPressed: () => prov.fetchBrands(forceRefresh: true),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: AppColors.primary,
        icon: const Icon(Icons.add_rounded, color: Colors.white),
        label: const Text("إضافة ماركة", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        onPressed: () async {
          await showAddBrandDialog(context);
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
                  hintText: "بحث عن ماركة أو بلد المنشأ...",
                  hintStyle: TextStyle(color: AppColors.getTextMuted(isDark), fontSize: 13),
                  prefixIcon: const Icon(Icons.search_rounded, color: AppColors.primaryLight),
                  suffixIcon: _searchCtrl.text.isNotEmpty
                      ? IconButton(
                          icon: const Icon(Icons.clear_rounded, size: 18),
                          onPressed: () {
                            _searchCtrl.clear();
                            prov.setSearchQuery(null);
                          },
                        )
                      : null,
                  border: InputBorder.none,
                  contentPadding: const EdgeInsets.symmetric(vertical: 14),
                ),
                onChanged: (val) => prov.setSearchQuery(val),
              ),
            ),
          ),

          // Total Brands Count Info Bar
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 4),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  "إجمالي الماركات المسجلة: ${prov.brands.length}",
                  style: TextStyle(color: AppColors.getTextMuted(isDark), fontSize: 12, fontWeight: FontWeight.w600),
                ),
                Text(
                  "خاص بالأجهزة المنزلية والكهربائية",
                  style: TextStyle(color: AppColors.primaryLight, fontSize: 11, fontWeight: FontWeight.bold),
                ),
              ],
            ),
          ),

          const SizedBox(height: 6),

          // Brands List
          Expanded(
            child: prov.isLoading
                ? const Center(child: CircularProgressIndicator(color: AppColors.primaryLight))
                : prov.brands.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.branding_watermark_outlined, size: 54, color: AppColors.getTextMuted(isDark)),
                            const SizedBox(height: 12),
                            Text(
                              "لا توجد ماركات مسجلة حالياً",
                              style: TextStyle(color: AppColors.getTextMuted(isDark), fontSize: 14),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              "اضغط على زر (إضافة ماركة) لإضافة ماركة أجهزة جديدة",
                              style: TextStyle(color: AppColors.getTextSecondary(isDark), fontSize: 12),
                            ),
                          ],
                        ),
                      )
                    : RefreshIndicator(
                        onRefresh: () => prov.fetchBrands(forceRefresh: true),
                        child: ListView.separated(
                          padding: const EdgeInsets.fromLTRB(16, 8, 16, 80),
                          itemCount: prov.brands.length,
                          separatorBuilder: (_, __) => const SizedBox(height: 10),
                          itemBuilder: (ctx, idx) {
                            final b = prov.brands[idx];
                            return _buildBrandCard(context, isDark, b, prov);
                          },
                        ),
                      ),
          ),
        ],
      ),
    );
  }

  Widget _buildBrandCard(BuildContext context, bool isDark, BrandModel b, BrandsProvider prov) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.getSurface(isDark),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.getBorder(isDark)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Brand Logo Badge
          Container(
            height: 48,
            width: 48,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [AppColors.primary.withOpacity(0.18), AppColors.accent.withOpacity(0.12)],
              ),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppColors.primary.withOpacity(0.25)),
            ),
            alignment: Alignment.center,
            child: Text(
              b.name.isNotEmpty ? b.name.substring(0, 1).toUpperCase() : "B",
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 20, color: AppColors.primaryLight),
            ),
          ),
          const SizedBox(width: 14),

          // Brand Details
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Text(
                        b.name,
                        style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: AppColors.getTextPrimary(isDark)),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    if (b.originCountry != null && b.originCountry!.isNotEmpty)
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                        decoration: BoxDecoration(
                          color: AppColors.accent.withOpacity(0.12),
                          borderRadius: BorderRadius.circular(6),
                          border: Border.all(color: AppColors.accent.withOpacity(0.3)),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(Icons.public_rounded, size: 12, color: AppColors.accent),
                            const SizedBox(width: 4),
                            Text(
                              b.originCountry!,
                              style: const TextStyle(color: AppColors.accent, fontSize: 10, fontWeight: FontWeight.bold),
                            ),
                          ],
                        ),
                      ),
                  ],
                ),
                if (b.nameEn != null && b.nameEn!.isNotEmpty && b.nameEn != b.name) ...[
                  const SizedBox(height: 2),
                  Text(
                    b.nameEn!,
                    style: TextStyle(fontSize: 12, color: AppColors.getTextMuted(isDark), fontFamily: 'sans-serif'),
                  ),
                ],
                if (b.agentContactNumber != null && b.agentContactNumber!.isNotEmpty) ...[
                  const SizedBox(height: 6),
                  Row(
                    children: [
                      const Icon(Icons.phone_in_talk_rounded, size: 13, color: AppColors.success),
                      const SizedBox(width: 4),
                      Text(
                        "الخط الساخن / الوكيل: ${b.agentContactNumber!}",
                        style: const TextStyle(fontSize: 11.5, color: AppColors.success, fontWeight: FontWeight.bold),
                      ),
                    ],
                  ),
                ],
                if (b.description != null && b.description!.isNotEmpty) ...[
                  const SizedBox(height: 4),
                  Text(
                    b.description!,
                    style: TextStyle(fontSize: 11.5, color: AppColors.getTextSecondary(isDark)),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ],
            ),
          ),

          // Delete Action
          IconButton(
            icon: Icon(Icons.delete_outline_rounded, size: 20, color: AppColors.getTextMuted(isDark)),
            tooltip: "حذف الماركة",
            onPressed: () async {
              final confirm = await showDialog<bool>(
                context: context,
                builder: (ctx) => AlertDialog(
                  backgroundColor: AppColors.getSurface(isDark),
                  title: const Text("تأكيد الحذف", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                  content: Text("هل أنت متأكد من رغبتك في حذف ماركة (${b.name})؟"),
                  actions: [
                    TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text("إلغاء")),
                    ElevatedButton(
                      style: ElevatedButton.styleFrom(backgroundColor: AppColors.danger),
                      onPressed: () => Navigator.pop(ctx, true),
                      child: const Text("حذف", style: TextStyle(color: Colors.white)),
                    ),
                  ],
                ),
              );

              if (confirm == true) {
                await prov.deleteBrand(b.id);
                if (context.mounted) {
                  Provider.of<ProductsProvider>(context, listen: false).fetchBrands();
                }
              }
            },
          ),
        ],
      ),
    );
  }
}
