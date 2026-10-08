import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/theme/theme_provider.dart';
import '../../purchases/screens/create_purchase_screen.dart';
import '../models/notification_models.dart';
import '../providers/notifications_provider.dart';

class LowStockNotificationsScreen extends StatefulWidget {
  const LowStockNotificationsScreen({super.key});

  @override
  State<LowStockNotificationsScreen> createState() => _LowStockNotificationsScreenState();
}

class _LowStockNotificationsScreenState extends State<LowStockNotificationsScreen> {
  final TextEditingController _searchController = TextEditingController();
  final NumberFormat _currencyFormatter = NumberFormat("#,##0.##", "en_US");
  String _selectedFilter = "all"; // "all", "out_of_stock", "near_low"

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Provider.of<NotificationsProvider>(context, listen: false).fetchLowStockNotifications();
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _shareShortageList(List<LowStockProductModel> items) {
    if (items.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("لا توجد نواقص لمشاركتها")),
      );
      return;
    }

    final buffer = StringBuffer();
    buffer.writeln("📋 *قائمة نواقص المخزن والمنتجات المطلوبة:*");
    buffer.writeln("التاريخ: ${DateFormat('yyyy/MM/dd HH:mm').format(DateTime.now())}");
    buffer.writeln("-----------------------------------------");

    for (int i = 0; i < items.length; i++) {
      final p = items[i];
      final status = p.stockQuantity <= 0 ? "🚨 (منتهي تماماً)" : "⚠️ (رصيد منخفض)";
      buffer.writeln("${i + 1}. ${p.nameAr}");
      if (p.barcode.isNotEmpty) buffer.writeln("   الباركود: ${p.barcode}");
      buffer.writeln("   الرصيد المتبقي: ${p.stockQuantity.toInt()} ${p.baseUnit} | حد الطلب: ${p.reorderLevel.toInt()} $status");
      buffer.writeln("");
    }

    buffer.writeln("-----------------------------------------");
    buffer.writeln("إجمالي الأصناف المطلوبة: ${items.length} صنف");

    Clipboard.setData(ClipboardData(text: buffer.toString()));
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text("تم نسخ قائمة النواقص للحافظة! يمكنك لصقها وإرسالها للمورد عبر واتساب ✅"),
        duration: Duration(seconds: 3),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Provider.of<ThemeProvider>(context);
    final isDark = theme.isDarkMode;
    final notifProvider = Provider.of<NotificationsProvider>(context);
    final allItems = notifProvider.lowStockProducts;

    // Filter items
    final query = _searchController.text.trim().toLowerCase();
    final filtered = allItems.where((item) {
      // Search filter
      final matchesQuery = query.isEmpty ||
          item.nameAr.toLowerCase().contains(query) ||
          item.barcode.toLowerCase().contains(query) ||
          (item.categoryName?.toLowerCase().contains(query) ?? false);

      if (!matchesQuery) return false;

      // Status filter
      if (_selectedFilter == "out_of_stock") {
        return item.stockQuantity <= 0;
      } else if (_selectedFilter == "near_low") {
        return item.stockQuantity > 0;
      }
      return true;
    }).toList();

    final outOfStockCount = allItems.where((p) => p.stockQuantity <= 0).length;
    final nearLowCount = allItems.where((p) => p.stockQuantity > 0).length;

    return Scaffold(
      backgroundColor: AppColors.getBackground(isDark),
      appBar: AppBar(
        title: const Text(
          "نواقص المخزون والحد الأدنى",
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
        ),
        actions: [
          IconButton(
            tooltip: "مشاركة قائمة النواقص",
            icon: const Icon(Icons.share_rounded, color: AppColors.primaryLight),
            onPressed: () => _shareShortageList(filtered.isNotEmpty ? filtered : allItems),
          ),
          IconButton(
            tooltip: "تحديث",
            icon: const Icon(Icons.refresh_rounded),
            onPressed: () => notifProvider.fetchLowStockNotifications(),
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () => notifProvider.fetchLowStockNotifications(),
        color: AppColors.primary,
        child: Column(
          children: [
            // 1. Statistics Cards
            Container(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
              color: AppColors.getSurface(isDark),
              child: Row(
                children: [
                  _buildStatCard(
                    isDark: isDark,
                    title: "إجمالي النواقص",
                    value: "${allItems.length}",
                    color: AppColors.primaryLight,
                    icon: Icons.inventory_2_outlined,
                  ),
                  const SizedBox(width: 8),
                  _buildStatCard(
                    isDark: isDark,
                    title: "نفد تماماً (0)",
                    value: "$outOfStockCount",
                    color: AppColors.danger,
                    icon: Icons.cancel_outlined,
                  ),
                  const SizedBox(width: 8),
                  _buildStatCard(
                    isDark: isDark,
                    title: "قارب على النفاد",
                    value: "$nearLowCount",
                    color: AppColors.warning,
                    icon: Icons.warning_amber_rounded,
                  ),
                ],
              ),
            ),

            // 2. Search & Filter Bar
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              color: AppColors.getSurface(isDark),
              child: Column(
                children: [
                  // Search Field
                  TextField(
                    controller: _searchController,
                    onChanged: (_) => setState(() {}),
                    decoration: InputDecoration(
                      hintText: "ابحث باسم الصنف أو الباركود أو التصنيف...",
                      prefixIcon: const Icon(Icons.search_rounded, size: 20),
                      suffixIcon: _searchController.text.isNotEmpty
                          ? IconButton(
                              icon: const Icon(Icons.clear_rounded, size: 18),
                              onPressed: () {
                                _searchController.clear();
                                setState(() {});
                              },
                            )
                          : null,
                      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                      filled: true,
                      fillColor: isDark ? const Color(0xFF0F172A) : const Color(0xFFF1F5F9),
                    ),
                  ),
                  const SizedBox(height: 10),

                  // Filter Chips
                  SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Row(
                      children: [
                        _buildFilterChip("all", "الكل (${allItems.length})", isDark),
                        const SizedBox(width: 8),
                        _buildFilterChip("out_of_stock", "نفد المخزون ($outOfStockCount)", isDark, color: AppColors.danger),
                        const SizedBox(width: 8),
                        _buildFilterChip("near_low", "قارب على النفاد ($nearLowCount)", isDark, color: AppColors.warning),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            const Divider(height: 1),

            // 3. Products List
            Expanded(
              child: notifProvider.isLoading && allItems.isEmpty
                  ? const Center(child: CircularProgressIndicator())
                  : filtered.isEmpty
                      ? _buildEmptyState(isDark)
                      : ListView.separated(
                          padding: const EdgeInsets.all(16),
                          itemCount: filtered.length,
                          separatorBuilder: (_, __) => const SizedBox(height: 12),
                          itemBuilder: (context, index) {
                            final item = filtered[index];
                            return _buildProductCard(context, item, isDark);
                          },
                        ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: allItems.isNotEmpty
          ? Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppColors.getSurface(isDark),
                border: Border(top: BorderSide(color: AppColors.getBorder(isDark))),
              ),
              child: ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 13),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                icon: const Icon(Icons.add_shopping_cart_rounded, size: 20),
                label: const Text(
                  "إنشاء فاتورة مشتريات لتغطية النواقص",
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                ),
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const CreatePurchaseScreen()),
                  );
                },
              ),
            )
          : null,
    );
  }

  Widget _buildStatCard({
    required bool isDark,
    required String title,
    required String value,
    required Color color,
    required IconData icon,
  }) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 8),
        decoration: BoxDecoration(
          color: color.withOpacity(isDark ? 0.12 : 0.08),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: color.withOpacity(0.3)),
        ),
        child: Column(
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(icon, color: color, size: 16),
                const SizedBox(width: 4),
                Text(
                  value,
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                    color: color,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 3),
            Text(
              title,
              style: TextStyle(
                fontSize: 10.5,
                color: AppColors.getTextSecondary(isDark),
                fontWeight: FontWeight.w600,
              ),
              textAlign: TextAlign.center,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFilterChip(String value, String label, bool isDark, {Color? color}) {
    final isSelected = _selectedFilter == value;
    final chipColor = color ?? AppColors.primary;

    return ChoiceChip(
      selected: isSelected,
      label: Text(label),
      labelStyle: TextStyle(
        fontSize: 12,
        fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
        color: isSelected ? Colors.white : AppColors.getTextSecondary(isDark),
      ),
      selectedColor: chipColor,
      backgroundColor: isDark ? const Color(0xFF1E293B) : const Color(0xFFE2E8F0),
      side: BorderSide(
        color: isSelected ? chipColor : AppColors.getBorder(isDark),
      ),
      onSelected: (selected) {
        if (selected) {
          setState(() {
            _selectedFilter = value;
          });
        }
      },
    );
  }

  Widget _buildProductCard(BuildContext context, LowStockProductModel item, bool isDark) {
    final isOutOfStock = item.stockQuantity <= 0;
    final statusColor = isOutOfStock ? AppColors.danger : AppColors.warning;
    final statusText = isOutOfStock ? "نفد من المخزن تماماً" : "قارب على النفاد";

    return Container(
      decoration: BoxDecoration(
        color: AppColors.getSurface(isDark),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: isOutOfStock ? AppColors.danger.withOpacity(0.35) : AppColors.getBorder(isDark),
          width: isOutOfStock ? 1.5 : 1,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(isDark ? 0.2 : 0.04),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Top Row: Category + Status Badge
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    if (item.categoryName != null && item.categoryName!.isNotEmpty)
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(
                          color: AppColors.primaryLight.withOpacity(0.12),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          item.categoryName!,
                          style: const TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                            color: AppColors.primaryLight,
                          ),
                        ),
                      )
                    else
                      const SizedBox.shrink(),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: statusColor.withOpacity(0.12),
                        borderRadius: BorderRadius.circular(6),
                        border: Border.all(color: statusColor.withOpacity(0.4)),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            isOutOfStock ? Icons.cancel_rounded : Icons.warning_amber_rounded,
                            color: statusColor,
                            size: 13,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            statusText,
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.bold,
                              color: statusColor,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),

                // Product Name
                Text(
                  item.nameAr,
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 15,
                    color: AppColors.getTextPrimary(isDark),
                  ),
                ),
                const SizedBox(height: 6),

                // Barcode with copy button
                if (item.barcode.isNotEmpty)
                  InkWell(
                    onTap: () {
                      Clipboard.setData(ClipboardData(text: item.barcode));
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text("تم نسخ الباركود (${item.barcode}) ✅"),
                          duration: const Duration(seconds: 2),
                        ),
                      );
                    },
                    borderRadius: BorderRadius.circular(6),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(vertical: 2),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.qr_code_rounded, size: 14, color: AppColors.getTextMuted(isDark)),
                          const SizedBox(width: 4),
                          Text(
                            item.barcode,
                            style: TextStyle(
                              fontSize: 12,
                              fontFamily: 'monospace',
                              color: AppColors.getTextMuted(isDark),
                            ),
                          ),
                          const SizedBox(width: 4),
                          Icon(Icons.copy_rounded, size: 12, color: AppColors.getTextMuted(isDark)),
                        ],
                      ),
                    ),
                  ),

                const SizedBox(height: 12),

                // Stock Level & Reorder Progress
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: isDark ? const Color(0xFF0F172A) : const Color(0xFFF8FAFC),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: AppColors.getBorder(isDark)),
                  ),
                  child: Column(
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                "الرصيد المتاح حالياً",
                                style: TextStyle(fontSize: 11, color: AppColors.getTextMuted(isDark)),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                "${item.stockQuantity.toInt()} ${item.baseUnit}",
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 14,
                                  color: isOutOfStock ? AppColors.danger : AppColors.warning,
                                ),
                              ),
                            ],
                          ),
                          Container(
                            height: 28,
                            width: 1,
                            color: AppColors.getBorder(isDark),
                          ),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.end,
                            children: [
                              Text(
                                "الحد الأدنى للطلب",
                                style: TextStyle(fontSize: 11, color: AppColors.getTextMuted(isDark)),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                "${item.reorderLevel.toInt()} ${item.baseUnit}",
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 14,
                                  color: AppColors.getTextPrimary(isDark),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                      if (item.purchasePrice > 0 || item.sellingPrice > 0) ...[
                        const SizedBox(height: 8),
                        const Divider(height: 1),
                        const SizedBox(height: 8),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            if (item.purchasePrice > 0)
                              Flexible(
                                child: Text(
                                  "سعر الشراء: ${_currencyFormatter.format(item.purchasePrice)} ج.م",
                                  style: TextStyle(fontSize: 11, color: AppColors.getTextSecondary(isDark)),
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            if (item.sellingPrice > 0)
                              Flexible(
                                child: Text(
                                  "سعر البيع: ${_currencyFormatter.format(item.sellingPrice)} ج.م",
                                  style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: AppColors.success),
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                          ],
                        ),
                      ],
                    ],
                  ),
                ),
              ],
            ),
          ),

          // Bottom Quick Action
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF1E293B).withOpacity(0.5) : const Color(0xFFF1F5F9),
              borderRadius: const BorderRadius.vertical(bottom: Radius.circular(14)),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                TextButton.icon(
                  style: TextButton.styleFrom(
                    foregroundColor: AppColors.primaryLight,
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  ),
                  icon: const Icon(Icons.add_shopping_cart_rounded, size: 16),
                  label: const Text(
                    "طلب شراء الصنف",
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12),
                  ),
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => const CreatePurchaseScreen()),
                    );
                  },
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState(bool isDark) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: AppColors.success.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.check_circle_outline_rounded,
                color: AppColors.success,
                size: 64,
              ),
            ),
            const SizedBox(height: 20),
            Text(
              "المخزون مكتمل وممتاز! 🎉",
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 18,
                color: AppColors.getTextPrimary(isDark),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              "لا توجد أصناف وصلت للحد الأدنى أو نفدت كميتها حالياً.",
              style: TextStyle(
                fontSize: 13,
                color: AppColors.getTextMuted(isDark),
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}
