import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/theme/theme_provider.dart';
import '../../../core/widgets/offline_banner.dart';
import '../../notifications/screens/low_stock_notifications_screen.dart';
import '../models/product_model.dart';
import '../providers/products_provider.dart';
import 'add_edit_product_screen.dart';
import 'brands_list_screen.dart';
import 'price_check_screen.dart';

class ProductsCatalogScreen extends StatefulWidget {
  const ProductsCatalogScreen({super.key});

  @override
  State<ProductsCatalogScreen> createState() => _ProductsCatalogScreenState();
}

class _ProductsCatalogScreenState extends State<ProductsCatalogScreen> {
  final TextEditingController _searchCtrl = TextEditingController();
  final ScrollController _scrollController = ScrollController();

  Future<void> _refreshData() async {
    final prov = Provider.of<ProductsProvider>(context, listen: false);
    await Future.wait([
      prov.fetchCategories(),
      prov.fetchBrands(),
      prov.fetchProducts(search: _searchCtrl.text),
    ]);
  }

  void _onScroll() {
    if (_scrollController.hasClients &&
        _scrollController.position.pixels >= _scrollController.position.maxScrollExtent - 250) {
      final prov = Provider.of<ProductsProvider>(context, listen: false);
      if (prov.hasMore && !prov.isLoadingMore && !prov.isLoading) {
        prov.fetchMoreProducts();
      }
    }
  }

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _refreshData();
    });
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
    final prov = Provider.of<ProductsProvider>(context);
    final currencyFormatter = NumberFormat("#,##0.00", "ar_EG");

    return Scaffold(
      backgroundColor: AppColors.getBackground(isDark),
      appBar: AppBar(
        backgroundColor: AppColors.getSurface(isDark),
        elevation: 0,
        title: Text(
          "كتالوج الأجهزة والمنتجات",
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: AppColors.getTextPrimary(isDark)),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.price_check_rounded, color: AppColors.cyan),
            tooltip: "استعلام عن سعر منتج (كاميرا + اسم)",
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const PriceCheckScreen()),
              );
            },
          ),
          IconButton(
            icon: const Icon(Icons.verified_rounded, color: AppColors.accent),
            tooltip: "الماركات التجارية",
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const BrandsListScreen()),
              );
            },
          ),
          IconButton(
            icon: const Icon(Icons.inventory_2_outlined, color: AppColors.warning),
            tooltip: "نواقص المخزون",
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const LowStockNotificationsScreen()),
              );
            },
          ),
          IconButton(
            icon: Icon(Icons.refresh_rounded, color: AppColors.getTextPrimary(isDark)),
            tooltip: "تحديث",
            onPressed: _refreshData,
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: AppColors.primary,
        icon: const Icon(Icons.add_rounded, color: Colors.white),
        label: const Text("إضافة منتج", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const AddEditProductScreen()),
          );
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
                  hintText: "بحث بالاسم، الموديل، الماركة أو الباركود...",
                  hintStyle: TextStyle(color: AppColors.getTextMuted(isDark), fontSize: 13),
                  prefixIcon: const Icon(Icons.search_rounded, color: AppColors.primaryLight),
                  suffixIcon: _searchCtrl.text.isNotEmpty
                      ? IconButton(
                          icon: const Icon(Icons.clear_rounded, size: 18),
                          onPressed: () {
                            _searchCtrl.clear();
                            prov.fetchProducts();
                          },
                        )
                      : null,
                  border: InputBorder.none,
                  contentPadding: const EdgeInsets.symmetric(vertical: 14),
                ),
                onSubmitted: (val) => prov.fetchProducts(search: val),
              ),
            ),
          ),

          // Categories Pills Bar
          if (prov.categories.isNotEmpty)
            SizedBox(
              height: 36,
              child: ListView(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 16),
                children: [
                  _buildFilterPill(
                    isDark,
                    label: "كل التصنيفات",
                    isSelected: prov.selectedCategoryId == null,
                    onTap: () => prov.setSelectedCategory(null),
                  ),
                  ...prov.categories.map((c) => _buildFilterPill(
                        isDark,
                        label: c.nameAr,
                        isSelected: prov.selectedCategoryId == c.id,
                        onTap: () => prov.setSelectedCategory(c.id),
                      )),
                ],
              ),
            ),

          const SizedBox(height: 6),

          // Brands Pills Bar (Home Appliances Focus)
          if (prov.brands.isNotEmpty)
            SizedBox(
              height: 34,
              child: ListView(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 16),
                children: [
                  _buildBrandFilterPill(
                    isDark,
                    label: "كل الماركات",
                    isSelected: prov.selectedBrandId == null,
                    onTap: () => prov.setSelectedBrand(null),
                  ),
                  ...prov.brands.map((b) => _buildBrandFilterPill(
                        isDark,
                        label: b.name,
                        isSelected: prov.selectedBrandId == b.id,
                        onTap: () => prov.setSelectedBrand(b.id),
                      )),
                ],
              ),
            ),

          const SizedBox(height: 6),

          // Quick Filter Chips (All, Low Stock, Weighable, Expiry)
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              children: [
                _buildQuickFilter(isDark, "الكل", "all", prov),
                const SizedBox(width: 8),
                _buildQuickFilter(isDark, "نواقص المخزن ⚠️", "low_stock", prov),
                const SizedBox(width: 8),
                _buildQuickFilter(isDark, "بالوزن ⚖️", "weighable", prov),
                const SizedBox(width: 8),
                _buildQuickFilter(isDark, "تتبع الصلاحية ⏳", "expiry", prov),
              ],
            ),
          ),

          const SizedBox(height: 8),

          // Products List
          Expanded(
            child: prov.isLoading
                ? const Center(child: CircularProgressIndicator(color: AppColors.primaryLight))
                : prov.products.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.inventory_2_outlined, size: 54, color: AppColors.getTextMuted(isDark)),
                            const SizedBox(height: 12),
                            Text("لا توجد منتجات مطابقة في الكتالوج", style: TextStyle(color: AppColors.getTextMuted(isDark), fontSize: 14)),
                          ],
                        ),
                      )
                    : RefreshIndicator(
                        onRefresh: _refreshData,
                        child: ListView.separated(
                          controller: _scrollController,
                          physics: const AlwaysScrollableScrollPhysics(),
                          padding: const EdgeInsets.fromLTRB(16, 8, 16, 80),
                          itemCount: prov.products.length + (prov.isLoadingMore ? 1 : 0),
                          separatorBuilder: (_, __) => const SizedBox(height: 10),
                          itemBuilder: (ctx, idx) {
                            if (idx == prov.products.length) {
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
                            final p = prov.products[idx];
                            return _buildProductCard(context, isDark, p, currencyFormatter);
                          },
                        ),
                      ),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterPill(bool isDark, {required String label, required bool isSelected, required VoidCallback onTap}) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(left: 6),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.primary : AppColors.getSurface(isDark),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: isSelected ? AppColors.primary : AppColors.getBorder(isDark)),
        ),
        alignment: Alignment.center,
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

  Widget _buildBrandFilterPill(bool isDark, {required String label, required bool isSelected, required VoidCallback onTap}) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(left: 6),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.accent : AppColors.getSurface(isDark),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: isSelected ? AppColors.accent : AppColors.getBorder(isDark).withOpacity(0.7)),
        ),
        alignment: Alignment.center,
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.verified_rounded, size: 12, color: isSelected ? Colors.white : AppColors.accent),
            const SizedBox(width: 4),
            Text(
              label,
              style: TextStyle(
                color: isSelected ? Colors.white : AppColors.getTextSecondary(isDark),
                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                fontSize: 11,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildQuickFilter(bool isDark, String label, String value, ProductsProvider prov) {
    final isSelected = prov.activeFilter == value;
    return GestureDetector(
      onTap: () => prov.setActiveFilter(value),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.primary.withOpacity(0.18) : Colors.transparent,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: isSelected ? AppColors.primaryLight : AppColors.getBorder(isDark).withOpacity(0.6)),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: isSelected ? AppColors.primaryLight : AppColors.getTextMuted(isDark),
            fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
            fontSize: 11,
          ),
        ),
      ),
    );
  }

  Widget _buildProductCard(BuildContext context, bool isDark, ProductModel p, NumberFormat currencyFormatter) {
    // Stock Breakdown formatting (Home appliances: always in pieces)
    String stockDisplay = "${p.stockQuantity.toStringAsFixed(0)} قطعة";

    final isLowStock = p.stockQuantity <= p.reorderLevel;
    final isAppliance = (p.brandId != null || p.brandName != null || p.modelNumber != null || p.warrantyPeriodMonths > 0);

    return InkWell(
      borderRadius: BorderRadius.circular(14),
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => AddEditProductScreen(product: p)),
        );
      },
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: AppColors.getSurface(isDark),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: isLowStock ? AppColors.warning.withOpacity(0.5) : AppColors.getBorder(isDark)),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Icon / Avatar
            Container(
              height: 48,
              width: 48,
              decoration: BoxDecoration(
                color: isAppliance
                    ? AppColors.accent.withOpacity(0.12)
                    : AppColors.primary.withOpacity(0.12),
                borderRadius: BorderRadius.circular(12),
              ),
              alignment: Alignment.center,
              child: Icon(
                p.isWeighable
                    ? Icons.scale_rounded
                    : (isAppliance ? Icons.tv_rounded : (p.trackExpiry ? Icons.timelapse_rounded : Icons.inventory_2_rounded)),
                color: p.isWeighable
                    ? AppColors.cyan
                    : (isAppliance ? AppColors.accent : (p.trackExpiry ? AppColors.warning : AppColors.primaryLight)),
                size: 24,
              ),
            ),
            const SizedBox(width: 12),

            // Middle: Name, Brand, Model, Barcode, Badges
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    p.nameAr,
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: AppColors.getTextPrimary(isDark)),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),

                  // Brand & Model Line (Appliance highlight)
                  if (p.brandName != null || p.modelNumber != null) ...[
                    const SizedBox(height: 2),
                    Row(
                      children: [
                        if (p.brandName != null && p.brandName!.isNotEmpty) ...[
                          const Icon(Icons.verified_rounded, size: 12, color: AppColors.accent),
                          const SizedBox(width: 3),
                          Text(
                            p.brandName!,
                            style: const TextStyle(fontSize: 11.5, fontWeight: FontWeight.bold, color: AppColors.accent),
                          ),
                          const SizedBox(width: 6),
                        ],
                        if (p.modelNumber != null && p.modelNumber!.isNotEmpty)
                          Expanded(
                            child: Text(
                              "موديل: ${p.modelNumber!}",
                              style: TextStyle(fontSize: 11, color: AppColors.getTextMuted(isDark), fontFamily: 'monospace'),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                      ],
                    ),
                  ],

                  const SizedBox(height: 3),
                  Wrap(
                    crossAxisAlignment: WrapCrossAlignment.center,
                    spacing: 8,
                    runSpacing: 2,
                    children: [
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.qr_code_2_rounded, size: 14, color: AppColors.getTextMuted(isDark)),
                          const SizedBox(width: 4),
                          Text(
                            p.barcode,
                            style: TextStyle(fontSize: 11, color: AppColors.getTextMuted(isDark), fontFamily: 'monospace'),
                          ),
                        ],
                      ),
                      if (p.categoryName != null)
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
                          decoration: BoxDecoration(
                            color: AppColors.primary.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Text(
                            p.categoryName!,
                            style: const TextStyle(fontSize: 10, color: AppColors.primaryLight, fontWeight: FontWeight.w600),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Wrap(
                    spacing: 6,
                    runSpacing: 4,
                    children: [
                      if (p.warrantyPeriodMonths > 0)
                        _buildBadge("ضمان ${p.warrantyPeriodMonths} شهر 🛡️", const Color(0xFF4F46E5)),
                      if (p.hasSerialNumber)
                        _buildBadge("سيريال 🏷️", const Color(0xFF7C3AED)),
                      if (p.color != null && p.color!.isNotEmpty)
                        _buildBadge(p.color!, const Color(0xFF0D9488)),
                      if (p.isWeighable)
                        _buildBadge("بالوزن ⚖️", AppColors.cyan),
                      if (p.trackExpiry)
                        _buildBadge(p.shelfLifeDays > 0 ? "صلاحية: ${p.shelfLifeDays} يوم ⏳" : "تتبع الصلاحية ⏳", AppColors.warning),
                      if (isLowStock)
                        _buildBadge("منخفض ⚠️", AppColors.danger),
                    ],
                  ),
                ],
              ),
            ),

            // Right: Price & Stock
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  "${currencyFormatter.format(p.sellingPrice)} ج.م",
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: AppColors.success),
                ),
                const SizedBox(height: 4),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                  decoration: BoxDecoration(
                    color: isLowStock ? AppColors.danger.withOpacity(0.12) : AppColors.getSurfaceElevated(isDark),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    stockDisplay,
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                      color: isLowStock ? AppColors.danger : AppColors.getTextSecondary(isDark),
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

  Widget _buildBadge(String text, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: color.withOpacity(0.12),
        borderRadius: BorderRadius.circular(4),
        border: Border.all(color: color.withOpacity(0.3), width: 0.8),
      ),
      child: Text(text, style: TextStyle(fontSize: 9.5, color: color, fontWeight: FontWeight.bold)),
    );
  }
}
