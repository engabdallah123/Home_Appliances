import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../../../core/constants/api_endpoints.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/network/api_client.dart';
import '../../../core/theme/theme_provider.dart';
import '../../../core/widgets/offline_banner.dart';
import '../../sales/screens/mobile_pos_screen.dart';

class OffersScreen extends StatefulWidget {
  const OffersScreen({super.key});

  @override
  State<OffersScreen> createState() => _OffersScreenState();
}

class _OffersScreenState extends State<OffersScreen> {
  final ApiClient _apiClient = ApiClient();
  final NumberFormat _currencyFormatter = NumberFormat("#,##0.00", "en_US");

  bool _isLoading = false;
  String? _errorMessage;
  List<dynamic> _offers = [];
  String? _selectedTypeFilter; // null: all, 'BundlePackage', 'BrandDiscount'

  @override
  void initState() {
    super.initState();
    _fetchOffers();
  }

  Future<void> _fetchOffers() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final res = await _apiClient.get(ApiEndpoints.offers);
      setState(() {
        _offers = (res is List) ? res : [];
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _errorMessage = e.toString();
        _isLoading = false;
      });
    }
  }

  List<dynamic> get _filteredOffers {
    if (_selectedTypeFilter == null) return _offers;
    return _offers.where((o) => o['offerType'] == _selectedTypeFilter).toList();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Provider.of<ThemeProvider>(context).isDarkMode;
    final filtered = _filteredOffers;

    return Scaffold(
      backgroundColor: AppColors.getBackground(isDark),
      appBar: AppBar(
        backgroundColor: AppColors.getSurface(isDark),
        elevation: 0,
        title: Text(
          "عروض وبكجات الأجهزة الكهربائية",
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: AppColors.getTextPrimary(isDark)),
        ),
        actions: [
          IconButton(
            icon: Icon(Icons.refresh_rounded, color: AppColors.getTextPrimary(isDark)),
            tooltip: "تحديث",
            onPressed: _fetchOffers,
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: const Color(0xFF8B5CF6),
        icon: const Icon(Icons.point_of_sale_rounded, color: Colors.white),
        label: const Text("بيع عرض بالـ POS", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        onPressed: () {
          Navigator.push(context, MaterialPageRoute(builder: (_) => const MobilePosScreen()));
        },
      ),
      body: Column(
        children: [
          const OfflineBanner(),

          // Filter Chips Row
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 12),
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Row(
                children: [
                  _buildFilterChip(isDark, "جميع العروض (${_offers.length})", null),
                  const SizedBox(width: 8),
                  _buildFilterChip(isDark, "🎁 البكجات المجمعة", "BundlePackage"),
                  const SizedBox(width: 8),
                  _buildFilterChip(isDark, "🏷️ خصومات الماركات", "BrandDiscount"),
                  const SizedBox(width: 8),
                  _buildFilterChip(isDark, "📂 خصومات التصنيفات", "CategoryDiscount"),
                  const SizedBox(width: 8),
                  _buildFilterChip(isDark, "📦 عروض المنتجات", "ProductDiscount"),
                ],
              ),
            ),
          ),

          // Content
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator(color: Color(0xFF8B5CF6)))
                : _errorMessage != null
                    ? Center(
                        child: Padding(
                          padding: const EdgeInsets.all(20),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              const Icon(Icons.error_outline_rounded, color: AppColors.danger, size: 48),
                              const SizedBox(height: 8),
                              Text("خطأ: $_errorMessage", style: TextStyle(color: AppColors.getTextMuted(isDark))),
                              const SizedBox(height: 12),
                              ElevatedButton(onPressed: _fetchOffers, child: const Text("إعادة المحاولة")),
                            ],
                          ),
                        ),
                      )
                    : filtered.isEmpty
                        ? Center(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                const Icon(Icons.card_giftcard_rounded, size: 56, color: Color(0xFF8B5CF6)),
                                const SizedBox(height: 12),
                                Text("لا توجد عروض ترويجية نشطة حالياً", style: TextStyle(color: AppColors.getTextMuted(isDark), fontSize: 14)),
                              ],
                            ),
                          )
                        : RefreshIndicator(
                            onRefresh: _fetchOffers,
                            child: ListView.separated(
                              padding: const EdgeInsets.fromLTRB(16, 4, 16, 80),
                              itemCount: filtered.length,
                              separatorBuilder: (_, __) => const SizedBox(height: 14),
                              itemBuilder: (ctx, idx) {
                                final offer = filtered[idx];
                                return _buildOfferCard(offer, isDark);
                              },
                            ),
                          ),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterChip(bool isDark, String label, String? typeVal) {
    final isSelected = _selectedTypeFilter == typeVal;
    return GestureDetector(
      onTap: () => setState(() => _selectedTypeFilter = typeVal),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFF8B5CF6) : AppColors.getSurface(isDark),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: isSelected ? const Color(0xFF8B5CF6) : AppColors.getBorder(isDark)),
        ),
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

  Widget _buildOfferCard(dynamic o, bool isDark) {
    final title = o['titleAr'] ?? 'عرض خاص';
    final desc = o['description'] ?? '';
    final offerType = o['offerType'] ?? '';
    final isBundle = offerType == 'BundlePackage';
    final isBrand = offerType == 'BrandDiscount';
    final isCategory = offerType == 'CategoryDiscount';
    final isProduct = offerType == 'ProductDiscount';
    final discount = (o['discountPercentage'] as num?)?.toDouble() ?? 0;
    final origPrice = (o['originalPrice'] as num?)?.toDouble() ?? 0;
    final discPrice = (o['discountedPrice'] as num?)?.toDouble() ?? 0;
    final items = (o['items'] as List?) ?? [];

    String bannerLabel;
    if (isBundle) {
      bannerLabel = "بكج أجهزة مجمّع 🎁";
    } else if (isBrand) {
      bannerLabel = "خصم الماركة 🏷️ ${o['targetBrandName'] ?? ''}".trim();
    } else if (isCategory) {
      bannerLabel = "خصم التصنيف 📂 ${o['targetCategoryName'] ?? ''}".trim();
    } else if (isProduct) {
      bannerLabel = "خصم المنتج 📦 ${o['targetProductName'] ?? ''}".trim();
    } else {
      bannerLabel = "عرض ترويجي 🏷️";
    }

    return Container(
      decoration: BoxDecoration(
        color: AppColors.getSurface(isDark),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: isBundle ? AppColors.warning.withOpacity(0.35) : AppColors.getBorder(isDark)),
        boxShadow: [
          BoxShadow(
            color: isBundle ? AppColors.warning.withOpacity(0.06) : Colors.black.withOpacity(0.03),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Banner Badge
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
            decoration: BoxDecoration(
              gradient: isBundle ? AppColors.roseGradient : AppColors.primaryGradient,
              borderRadius: const BorderRadius.vertical(top: Radius.circular(15)),
            ),
            child: Row(
              children: [
                Icon(isBundle ? Icons.card_giftcard_rounded : Icons.local_offer_rounded, color: Colors.white, size: 16),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    bannerLabel,
                    style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 12),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                if (discount > 0)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Text(
                      "خصم ${discount.toStringAsFixed(0)}%",
                      style: TextStyle(
                        color: isBundle ? const Color(0xFFBE185D) : const Color(0xFF4F46E5),
                        fontWeight: FontWeight.bold,
                        fontSize: 11,
                      ),
                    ),
                  ),
              ],
            ),
          ),

          Padding(
            padding: const EdgeInsets.all(14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: AppColors.getTextPrimary(isDark)),
                ),
                if (desc.isNotEmpty) ...[
                  const SizedBox(height: 6),
                  Text(
                    desc,
                    style: TextStyle(fontSize: 12, color: AppColors.getTextSecondary(isDark), height: 1.4),
                  ),
                ],

                if (origPrice > 0 && discPrice > 0) ...[
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text("السعر قبل الخصم", style: TextStyle(fontSize: 10, color: AppColors.getTextMuted(isDark))),
                            Text(
                              "${_currencyFormatter.format(origPrice)} ج.م",
                              style: TextStyle(
                                fontSize: 13,
                                color: AppColors.getTextMuted(isDark),
                                decoration: TextDecoration.lineThrough,
                              ),
                            ),
                          ],
                        ),
                      ),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text("السعر بالبكج", style: TextStyle(fontSize: 10, color: AppColors.success, fontWeight: FontWeight.bold)),
                            FittedBox(
                              fit: BoxFit.scaleDown,
                              alignment: Alignment.centerRight,
                              child: Text(
                                "${_currencyFormatter.format(discPrice)} ج.م",
                                style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppColors.success),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ],

                if (items.isNotEmpty) ...[
                  const SizedBox(height: 12),
                  Text("الأجهزة المشمولة في البكج:", style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: AppColors.getTextSecondary(isDark))),
                  const SizedBox(height: 6),
                  ...items.map((item) => Padding(
                        padding: const EdgeInsets.symmetric(vertical: 2),
                        child: Row(
                          children: [
                            const Icon(Icons.check_circle_outline_rounded, size: 14, color: AppColors.success),
                            const SizedBox(width: 6),
                            Expanded(
                              child: Text(
                                "${item['nameAr'] ?? ''} ${item['brandName'] != null ? '(${item['brandName']})' : ''}",
                                style: TextStyle(fontSize: 11.5, color: AppColors.getTextPrimary(isDark)),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                      )),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}
