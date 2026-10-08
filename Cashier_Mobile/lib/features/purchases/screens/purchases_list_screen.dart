import 'dart:async';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/widgets/offline_banner.dart';
import '../../../core/widgets/sync_status_badge.dart';
import '../../products/providers/products_provider.dart';
import '../../suppliers/providers/suppliers_provider.dart';
import '../providers/purchases_provider.dart';
import 'create_purchase_screen.dart';
import 'purchase_detail_screen.dart';

class PurchasesListScreen extends StatefulWidget {
  final String? initialFilter;

  const PurchasesListScreen({super.key, this.initialFilter});

  @override
  State<PurchasesListScreen> createState() => _PurchasesListScreenState();
}

class _PurchasesListScreenState extends State<PurchasesListScreen> {
  final TextEditingController _searchController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  Timer? _autoSyncTimer;

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final provider = Provider.of<PurchasesProvider>(context, listen: false);
      if (widget.initialFilter != null) {
        provider.setFilter(widget.initialFilter!);
      } else {
        provider.fetchPurchases();
      }
    });

    // Auto-refresh when pending invoices are awaiting local POS sync
    _autoSyncTimer = Timer.periodic(const Duration(seconds: 6), (timer) {
      if (!mounted) return;
      final provider = Provider.of<PurchasesProvider>(context, listen: false);
      final hasPending = provider.purchases.any((p) => p.syncStatus.toLowerCase() == 'pendingsync');
      if (hasPending) {
        provider.fetchPurchases(
          status: provider.selectedFilter == 'all' ? null : provider.selectedFilter,
          search: _searchController.text.trim().isEmpty ? null : _searchController.text.trim(),
        );
        // Also refresh product stock and supplier debts
        Provider.of<ProductsProvider>(context, listen: false).fetchProducts();
        Provider.of<SuppliersProvider>(context, listen: false).fetchSuppliers();
      }
    });
  }

  void _onScroll() {
    if (_scrollController.hasClients &&
        _scrollController.position.pixels >= _scrollController.position.maxScrollExtent - 250) {
      final provider = Provider.of<PurchasesProvider>(context, listen: false);
      if (provider.hasMore && !provider.isLoadingMore && !provider.isLoading) {
        provider.fetchMorePurchases();
      }
    }
  }

  @override
  void dispose() {
    _autoSyncTimer?.cancel();
    _scrollController.removeListener(_onScroll);
    _scrollController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final purchasesProv = Provider.of<PurchasesProvider>(context);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bg = AppColors.getBackground(isDark);
    final surface = AppColors.getSurface(isDark);
    final border = AppColors.getBorder(isDark);
    final textPrimary = AppColors.getTextPrimary(isDark);
    final textSecondary = AppColors.getTextSecondary(isDark);
    final textMuted = AppColors.getTextMuted(isDark);

    final currencyFormatter = NumberFormat("#,##0.00", "en_US");
    final dateFormatter = DateFormat("dd/MM/yyyy HH:mm");

    return Scaffold(
      backgroundColor: bg,
      appBar: AppBar(
        backgroundColor: surface,
        elevation: 0,
        title: Text("فواتير المشتريات", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: textPrimary)),
      ),
      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: AppColors.primary,
        icon: const Icon(Icons.add_shopping_cart_rounded, color: Colors.white),
        label: const Text("فاتورة جديدة", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const CreatePurchaseScreen()),
          );
        },
      ),
      body: Column(
        children: [
          const OfflineBanner(),

          // Search Bar
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
            child: TextField(
              controller: _searchController,
              style: TextStyle(color: textPrimary, fontSize: 14),
              onSubmitted: (query) => purchasesProv.fetchPurchases(
                status: purchasesProv.selectedFilter == 'all' ? null : purchasesProv.selectedFilter,
                search: query,
              ),
              decoration: InputDecoration(
                hintText: "بحث برقم الفاتورة أو اسم المورد...",
                hintStyle: TextStyle(color: textMuted, fontSize: 13),
                prefixIcon: Icon(Icons.search_rounded, color: textSecondary, size: 20),
                suffixIcon: _searchController.text.isNotEmpty
                    ? IconButton(
                        icon: Icon(Icons.clear, color: textSecondary, size: 18),
                        onPressed: () {
                          _searchController.clear();
                          purchasesProv.fetchPurchases(
                            status: purchasesProv.selectedFilter == 'all' ? null : purchasesProv.selectedFilter,
                          );
                        },
                      )
                    : null,
                filled: true,
                fillColor: surface,
                contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                  borderSide: BorderSide(color: border),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                  borderSide: BorderSide(color: border),
                ),
              ),
            ),
          ),

          // Filter 2x2 Grid (No horizontal scroll)
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
            child: Column(
              children: [
                Row(
                  children: [
                    Expanded(child: _buildFilterChip("الكل", 'all', purchasesProv, isDark)),
                    const SizedBox(width: 8),
                    Expanded(child: _buildFilterChip("قيد المزامنة ⏳", 'PendingSync', purchasesProv, isDark)),
                  ],
                ),
                const SizedBox(height: 6),
                Row(
                  children: [
                    Expanded(child: _buildFilterChip("تمت المزامنة ✅", 'Synced', purchasesProv, isDark)),
                    const SizedBox(width: 8),
                    Expanded(child: _buildFilterChip("فشلت المزامنة ❌", 'SyncFailed', purchasesProv, isDark)),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 6),

          // Purchases List
          Expanded(
            child: purchasesProv.isLoading
                ? const Center(child: CircularProgressIndicator(color: AppColors.primaryLight))
                : purchasesProv.purchases.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.receipt_long_outlined, size: 64, color: textMuted),
                            const SizedBox(height: 12),
                            Text(
                              "لا توجد فواتير مطابقة لهذا البحث.",
                              style: TextStyle(color: textSecondary, fontSize: 15),
                            ),
                            const SizedBox(height: 8),
                            TextButton(
                              onPressed: () => purchasesProv.fetchPurchases(),
                              child: const Text("تحديث القائمة", style: TextStyle(color: AppColors.accent)),
                            ),
                          ],
                        ),
                      )
                    : RefreshIndicator(
                        color: AppColors.primaryLight,
                        backgroundColor: surface,
                        onRefresh: () async {
                          await purchasesProv.fetchPurchases(
                            status: purchasesProv.selectedFilter == 'all' ? null : purchasesProv.selectedFilter,
                            search: _searchController.text.trim(),
                          );
                          Provider.of<ProductsProvider>(context, listen: false).fetchProducts();
                          Provider.of<SuppliersProvider>(context, listen: false).fetchSuppliers();
                        },
                        child: ListView.separated(
                          controller: _scrollController,
                          physics: const AlwaysScrollableScrollPhysics(),
                          padding: const EdgeInsets.fromLTRB(16, 0, 16, 80),
                          itemCount: purchasesProv.purchases.length + (purchasesProv.isLoadingMore ? 1 : 0),
                          separatorBuilder: (_, __) => const SizedBox(height: 10),
                          itemBuilder: (ctx, idx) {
                            if (idx == purchasesProv.purchases.length) {
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
                            final p = purchasesProv.purchases[idx];
                            return InkWell(
                              onTap: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(builder: (_) => PurchaseDetailScreen(purchaseId: p.id)),
                                );
                              },
                              borderRadius: BorderRadius.circular(12),
                              child: Container(
                                padding: const EdgeInsets.all(14),
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
                                        Row(
                                          children: [
                                            const Icon(Icons.receipt_rounded, size: 18, color: AppColors.primaryLight),
                                            const SizedBox(width: 6),
                                            Text(
                                              p.invoiceNumber,
                                              style: TextStyle(
                                                color: textPrimary,
                                                fontWeight: FontWeight.bold,
                                                fontSize: 15,
                                              ),
                                            ),
                                          ],
                                        ),
                                        SyncStatusBadge(status: p.syncStatus),
                                      ],
                                    ),
                                    const SizedBox(height: 8),
                                    Row(
                                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                      children: [
                                        Text(
                                          p.supplierName ?? "مورد غير محدد",
                                          style: TextStyle(color: textSecondary, fontSize: 13, fontWeight: FontWeight.w500),
                                        ),
                                        Text(
                                          "${currencyFormatter.format(p.totalAmount)} ج.م",
                                          style: TextStyle(
                                            color: isDark ? Colors.white : AppColors.primaryDark,
                                            fontWeight: FontWeight.bold,
                                            fontSize: 15,
                                          ),
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 6),
                                    Row(
                                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                      children: [
                                        Text(
                                          dateFormatter.format(p.purchaseDate),
                                          style: TextStyle(color: textMuted, fontSize: 11),
                                        ),
                                        Text(
                                          "${p.itemsCount} صنف",
                                          style: TextStyle(color: textMuted, fontSize: 11),
                                        ),
                                      ],
                                    ),
                                    if (p.syncError != null && p.syncError!.isNotEmpty) ...[
                                      const SizedBox(height: 8),
                                      Container(
                                        padding: const EdgeInsets.all(6),
                                        decoration: BoxDecoration(
                                          color: AppColors.syncFailed.withOpacity(0.1),
                                          borderRadius: BorderRadius.circular(6),
                                        ),
                                        child: Text(
                                          "خطأ المزامنة: ${p.syncError}",
                                          style: const TextStyle(color: AppColors.syncFailed, fontSize: 11),
                                          maxLines: 2,
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                      ),
                                    ],
                                  ],
                                ),
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

  Widget _buildFilterChip(String label, String value, PurchasesProvider prov, bool isDark) {
    final isSelected = prov.selectedFilter == value;
    final surface = AppColors.getSurface(isDark);
    final border = AppColors.getBorder(isDark);
    final textSecondary = AppColors.getTextSecondary(isDark);

    return InkWell(
      onTap: () => prov.setFilter(value),
      borderRadius: BorderRadius.circular(10),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        alignment: Alignment.center,
        padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 6),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.primary : surface,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: isSelected ? AppColors.primary : border),
        ),
        child: Text(
          label,
          textAlign: TextAlign.center,
          style: TextStyle(
            color: isSelected ? Colors.white : textSecondary,
            fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
            fontSize: 12,
          ),
        ),
      ),
    );
  }
}
