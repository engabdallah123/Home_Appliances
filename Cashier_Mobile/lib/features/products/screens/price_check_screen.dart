import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/theme/theme_provider.dart';
import '../../../core/widgets/camera_barcode_scanner.dart';
import '../models/product_model.dart';
import '../providers/products_provider.dart';

class PriceCheckScreen extends StatefulWidget {
  final String? initialBarcode;

  const PriceCheckScreen({super.key, this.initialBarcode});

  @override
  State<PriceCheckScreen> createState() => _PriceCheckScreenState();
}

class _PriceCheckScreenState extends State<PriceCheckScreen> {
  final TextEditingController _searchCtrl = TextEditingController();
  final FocusNode _searchFocusNode = FocusNode();

  bool _isLoading = false;
  bool _hasSearched = false;
  ProductModel? _selectedProduct;
  List<ProductModel> _filteredSuggestions = [];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final prov = Provider.of<ProductsProvider>(context, listen: false);
      if (prov.products.isEmpty) {
        prov.fetchProducts();
      }

      if (widget.initialBarcode != null && widget.initialBarcode!.isNotEmpty) {
        _searchByBarcode(widget.initialBarcode!);
      }
    });
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    _searchFocusNode.dispose();
    super.dispose();
  }

  void _onSearchChanged(String query) {
    if (query.trim().isEmpty) {
      setState(() {
        _filteredSuggestions = [];
      });
      return;
    }

    final prov = Provider.of<ProductsProvider>(context, listen: false);
    final q = query.trim().toLowerCase();

    setState(() {
      _filteredSuggestions = prov.products.where((p) {
        final nameAr = p.nameAr.toLowerCase();
        final nameEn = (p.nameEn ?? '').toLowerCase();
        final barcode = p.barcode.toLowerCase();
        final brand = (p.brandName ?? '').toLowerCase();
        return nameAr.contains(q) || nameEn.contains(q) || barcode.contains(q) || brand.contains(q);
      }).toList();
    });
  }

  Future<void> _searchByBarcode(String barcode) async {
    final cleanBarcode = barcode.trim();
    if (cleanBarcode.isEmpty) return;

    _searchCtrl.text = cleanBarcode;
    setState(() {
      _isLoading = true;
      _hasSearched = true;
      _filteredSuggestions = [];
      _selectedProduct = null;
    });

    final prov = Provider.of<ProductsProvider>(context, listen: false);
    final product = await prov.fetchByBarcode(cleanBarcode);

    if (mounted) {
      setState(() {
        _isLoading = false;
        _selectedProduct = product;
      });

      if (product == null) {
        // Fallback: search in loaded products
        final match = prov.products.firstWhere(
          (p) => p.barcode.trim().toLowerCase() == cleanBarcode.toLowerCase(),
          orElse: () => ProductModel(id: '', barcode: '', nameAr: ''),
        );
        if (match.id.isNotEmpty) {
          setState(() {
            _selectedProduct = match;
          });
        }
      }
    }
  }

  Future<void> _startCameraScan() async {
    final scannedBarcode = await CameraBarcodeScannerScreen.scan(
      context,
      title: "مسح باركود المنتج للاستعلام عن السعر",
    );

    if (scannedBarcode != null && scannedBarcode.trim().isNotEmpty) {
      await _searchByBarcode(scannedBarcode.trim());
    }
  }

  void _selectProduct(ProductModel product) {
    _searchFocusNode.unfocus();
    setState(() {
      _selectedProduct = product;
      _hasSearched = true;
      _searchCtrl.text = product.nameAr;
      _filteredSuggestions = [];
    });
  }

  void _clearSearch() {
    _searchCtrl.clear();
    setState(() {
      _selectedProduct = null;
      _hasSearched = false;
      _filteredSuggestions = [];
    });
    _searchFocusNode.requestFocus();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Provider.of<ThemeProvider>(context).isDarkMode;
    final currencyFormatter = NumberFormat("#,##0.00", "ar_EG");

    return Scaffold(
      backgroundColor: AppColors.getBackground(isDark),
      appBar: AppBar(
        backgroundColor: AppColors.getSurface(isDark),
        elevation: 0,
        title: Text(
          "الاستعلام عن سعر المنتج",
          style: TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 18,
            color: AppColors.getTextPrimary(isDark),
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.qr_code_scanner_rounded, color: AppColors.cyan, size: 26),
            tooltip: "مسح باركود بالكاميرا",
            onPressed: _startCameraScan,
          ),
          if (_selectedProduct != null || _searchCtrl.text.isNotEmpty)
            IconButton(
              icon: const Icon(Icons.refresh_rounded),
              tooltip: "بحث جديد",
              onPressed: _clearSearch,
            ),
        ],
      ),
      body: Column(
        children: [
          // Search & Scanner Header Card
          Container(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
            decoration: BoxDecoration(
              color: AppColors.getSurface(isDark),
              border: Border(bottom: BorderSide(color: AppColors.getBorder(isDark), width: 1)),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.04),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Column(
              children: [
                Row(
                  children: [
                    // Text Search Input
                    Expanded(
                      child: Container(
                        height: 48,
                        decoration: BoxDecoration(
                          color: isDark ? const Color(0xFF0F172A) : const Color(0xFFF1F5F9),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: _searchFocusNode.hasFocus ? AppColors.primary : AppColors.getBorder(isDark),
                            width: 1.5,
                          ),
                        ),
                        child: TextField(
                          controller: _searchCtrl,
                          focusNode: _searchFocusNode,
                          onChanged: _onSearchChanged,
                          style: TextStyle(
                            fontSize: 14.5,
                            fontWeight: FontWeight.w600,
                            color: AppColors.getTextPrimary(isDark),
                          ),
                          decoration: InputDecoration(
                            hintText: "ابحث بالاسم أو اكتب الباركود...",
                            hintStyle: TextStyle(
                              color: AppColors.getTextMuted(isDark),
                              fontSize: 13,
                            ),
                            prefixIcon: Icon(
                              Icons.search_rounded,
                              color: AppColors.getTextMuted(isDark),
                              size: 22,
                            ),
                            suffixIcon: _searchCtrl.text.isNotEmpty
                                ? IconButton(
                                    icon: const Icon(Icons.clear_rounded, size: 18),
                                    onPressed: _clearSearch,
                                  )
                                : null,
                            border: InputBorder.none,
                            contentPadding: const EdgeInsets.symmetric(vertical: 12),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),

                    // Dedicated Camera Scan Action Button
                    InkWell(
                      onTap: _startCameraScan,
                      borderRadius: BorderRadius.circular(12),
                      child: Container(
                        height: 48,
                        padding: const EdgeInsets.symmetric(horizontal: 14),
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(
                            colors: [Color(0xFF4F46E5), Color(0xFF0284C7)],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                          borderRadius: BorderRadius.circular(12),
                          boxShadow: [
                            BoxShadow(
                              color: const Color(0xFF4F46E5).withOpacity(0.35),
                              blurRadius: 8,
                              offset: const Offset(0, 3),
                            ),
                          ],
                        ),
                        child: const Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.camera_alt_rounded, color: Colors.white, size: 20),
                            SizedBox(width: 6),
                            Text(
                              "كاميرا",
                              style: TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                                fontSize: 13,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),

                // Live Suggestions List while typing
                if (_filteredSuggestions.isNotEmpty)
                  Container(
                    margin: const EdgeInsets.only(top: 10),
                    constraints: const BoxConstraints(maxHeight: 260),
                    decoration: BoxDecoration(
                      color: AppColors.getSurface(isDark),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: AppColors.primary.withOpacity(0.4), width: 1.5),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(isDark ? 0.4 : 0.08),
                          blurRadius: 16,
                          offset: const Offset(0, 6),
                        ),
                      ],
                    ),
                    child: ListView.separated(
                      shrinkWrap: true,
                      itemCount: _filteredSuggestions.length,
                      separatorBuilder: (_, __) => Divider(height: 1, color: AppColors.getBorder(isDark)),
                      itemBuilder: (context, idx) {
                        final item = _filteredSuggestions[idx];
                        return ListTile(
                          dense: true,
                          title: Text(
                            item.nameAr,
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 13.5,
                              color: AppColors.getTextPrimary(isDark),
                            ),
                          ),
                          subtitle: Text(
                            "${item.brandName != null ? '${item.brandName} • ' : ''}باركود: ${item.barcode}",
                            style: TextStyle(
                              fontSize: 11,
                              color: AppColors.getTextMuted(isDark),
                            ),
                          ),
                          trailing: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            crossAxisAlignment: CrossAxisAlignment.end,
                            children: [
                              Text(
                                "${currencyFormatter.format(item.sellingPrice)} ج.م",
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 13.5,
                                  color: AppColors.success,
                                ),
                              ),
                              Text(
                                item.stockQuantity > 0 ? "متوفر (${item.stockQuantity.toInt()})" : "نفد المخزون",
                                style: TextStyle(
                                  fontSize: 10,
                                  fontWeight: FontWeight.w600,
                                  color: item.stockQuantity > 0 ? AppColors.success : AppColors.danger,
                                ),
                              ),
                            ],
                          ),
                          onTap: () => _selectProduct(item),
                        );
                      },
                    ),
                  ),
              ],
            ),
          ),

          // Main Display Body
          Expanded(
            child: _buildBodyContent(isDark, currencyFormatter),
          ),
        ],
      ),
    );
  }

  Widget _buildBodyContent(bool isDark, NumberFormat currencyFormatter) {
    if (_isLoading) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const CircularProgressIndicator(color: AppColors.primary),
            const SizedBox(height: 16),
            Text(
              "جاري استرجاع تفاصيل المنتج والأسعار...",
              style: TextStyle(
                color: AppColors.getTextMuted(isDark),
                fontSize: 13.5,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      );
    }

    if (_selectedProduct != null) {
      return _buildProductHeroCard(isDark, currencyFormatter, _selectedProduct!);
    }

    if (_hasSearched) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 32),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: AppColors.danger.withOpacity(0.12),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.search_off_rounded, color: AppColors.danger, size: 54),
              ),
              const SizedBox(height: 18),
              Text(
                "لم يتم العثور على أي منتج!",
                style: TextStyle(
                  color: AppColors.getTextPrimary(isDark),
                  fontSize: 17,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                "تأكد من صحة كود الباركود أو اسم المنتج وجرب مرة أخرى.",
                style: TextStyle(
                  color: AppColors.getTextMuted(isDark),
                  fontSize: 13,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 24),
              ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                onPressed: _startCameraScan,
                icon: const Icon(Icons.camera_alt_rounded, size: 18),
                label: const Text("المسح بالكاميرا مجدداً", style: TextStyle(fontWeight: FontWeight.bold)),
              ),
            ],
          ),
        ),
      );
    }

    // Default Standby Welcome State
    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(28),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    const Color(0xFF6366F1).withOpacity(0.15),
                    const Color(0xFF0284C7).withOpacity(0.15),
                  ],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                shape: BoxShape.circle,
                border: Border.all(color: const Color(0xFF6366F1).withOpacity(0.3), width: 2),
              ),
              child: const Icon(
                Icons.qr_code_scanner_rounded,
                color: Color(0xFF6366F1),
                size: 64,
              ),
            ),
            const SizedBox(height: 22),
            Text(
              "شاشة الاستعلام عن الأسعار",
              style: TextStyle(
                color: AppColors.getTextPrimary(isDark),
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              "امسح باركود المنتج بكاميرا الهاتف أو ابحث بالاسم في شريط البحث أعلاه لمعرفة سعر البيع والمخزون فوراً.",
              style: TextStyle(
                color: AppColors.getTextMuted(isDark),
                fontSize: 13,
                height: 1.5,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 28),
            ElevatedButton.icon(
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF4F46E5),
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                elevation: 4,
              ),
              onPressed: _startCameraScan,
              icon: const Icon(Icons.camera_alt_rounded, size: 20),
              label: const Text(
                "تشغيل قارئ الباركود بالكاميرا",
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildProductHeroCard(bool isDark, NumberFormat currencyFormatter, ProductModel product) {
    final inStock = product.stockQuantity > 0;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Hero Price Card
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: isDark
                    ? [const Color(0xFF1E1B4B), const Color(0xFF0F172A)]
                    : [const Color(0xFFEEF2FF), const Color(0xFFE0E7FF)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: const Color(0xFF6366F1), width: 2),
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFF6366F1).withOpacity(0.2),
                  blurRadius: 16,
                  offset: const Offset(0, 6),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        const Icon(Icons.local_offer_rounded, color: Color(0xFF6366F1), size: 18),
                        const SizedBox(width: 6),
                        Text(
                          "سعر البيع النهائي",
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.bold,
                            color: isDark ? const Color(0xFFA5B4FC) : const Color(0xFF4338CA),
                          ),
                        ),
                      ],
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: inStock ? AppColors.success.withOpacity(0.15) : AppColors.danger.withOpacity(0.15),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: inStock ? AppColors.success : AppColors.danger, width: 1),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            inStock ? Icons.check_circle_rounded : Icons.cancel_rounded,
                            color: inStock ? AppColors.success : AppColors.danger,
                            size: 14,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            inStock ? "متوفر للبيع" : "غير متوفر بالمخزن",
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.bold,
                              color: inStock ? AppColors.success : AppColors.danger,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),

                // Big Selling Price Display (Guaranteed Zero Overflow)
                FittedBox(
                  fit: BoxFit.scaleDown,
                  alignment: Alignment.centerRight,
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.baseline,
                    textBaseline: TextBaseline.alphabetic,
                    children: [
                      Text(
                        currencyFormatter.format(product.sellingPrice),
                        style: const TextStyle(
                          fontSize: 34,
                          fontWeight: FontWeight.w900,
                          color: AppColors.success,
                          letterSpacing: -0.5,
                        ),
                      ),
                      const SizedBox(width: 6),
                      Text(
                        "ج.م",
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: AppColors.getTextMuted(isDark),
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 12),
                Divider(color: const Color(0xFF6366F1).withOpacity(0.3), height: 1),
                const SizedBox(height: 10),

                // Sub-prices (Wholesale & Stock)
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    if (product.wholesalePrice > 0)
                      Flexible(
                        child: Text(
                          "سعر الجملة: ${currencyFormatter.format(product.wholesalePrice)} ج.م",
                          style: TextStyle(
                            fontSize: 12.5,
                            fontWeight: FontWeight.w600,
                            color: AppColors.getTextSecondary(isDark),
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      )
                    else
                      const SizedBox.shrink(),
                    const SizedBox(width: 8),
                    Flexible(
                      child: Text(
                        "رصيد المخزن: ${product.stockQuantity.toInt()} ${product.baseUnit}",
                        style: TextStyle(
                          fontSize: 12.5,
                          fontWeight: FontWeight.bold,
                          color: inStock ? AppColors.success : AppColors.danger,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),

          const SizedBox(height: 16),

          // Product Details Card
          Container(
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              color: AppColors.getSurface(isDark),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: AppColors.getBorder(isDark)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Product Name
                Text(
                  product.nameAr,
                  style: TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.bold,
                    color: AppColors.getTextPrimary(isDark),
                  ),
                ),
                if (product.nameEn != null && product.nameEn!.isNotEmpty) ...[
                  const SizedBox(height: 3),
                  Text(
                    product.nameEn!,
                    style: TextStyle(
                      fontSize: 13,
                      color: AppColors.getTextMuted(isDark),
                    ),
                  ),
                ],
                const SizedBox(height: 16),

                // Specs Grid
                _buildSpecRow(isDark, "الباركود", product.barcode, icon: Icons.qr_code_rounded, isMonospace: true),
                if (product.brandName != null && product.brandName!.isNotEmpty)
                  _buildSpecRow(isDark, "الماركة / التوكيل", product.brandName!, icon: Icons.verified_rounded, highlight: true),
                if (product.categoryName != null && product.categoryName!.isNotEmpty)
                  _buildSpecRow(isDark, "التصنيف", product.categoryName!, icon: Icons.category_rounded),
                if (product.modelNumber != null && product.modelNumber!.isNotEmpty)
                  _buildSpecRow(isDark, "الموديل / الكود", product.modelNumber!, icon: Icons.tag_rounded),
                if (product.color != null && product.color!.isNotEmpty)
                  _buildSpecRow(isDark, "اللون", product.color!, icon: Icons.palette_rounded),
                if (product.warrantyPeriodMonths > 0)
                  _buildSpecRow(isDark, "مدة الضمان", "${product.warrantyPeriodMonths} شهر معتمد", icon: Icons.shield_rounded),
                if (product.maintenanceAgent != null && product.maintenanceAgent!.isNotEmpty)
                  _buildSpecRow(isDark, "مركز الصيانة", product.maintenanceAgent!, icon: Icons.support_agent_rounded),
              ],
            ),
          ),

          const SizedBox(height: 20),

          // Action Buttons
          Row(
            children: [
              Expanded(
                flex: 2,
                child: ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF4F46E5),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                    elevation: 3,
                  ),
                  onPressed: _startCameraScan,
                  icon: const Icon(Icons.camera_alt_rounded, size: 20),
                  label: const Text(
                    "مسح منتج آخر بالكاميرا",
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13.5),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                flex: 1,
                child: OutlinedButton.icon(
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppColors.getTextPrimary(isDark),
                    side: BorderSide(color: AppColors.getBorder(isDark)),
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                  ),
                  onPressed: _clearSearch,
                  icon: const Icon(Icons.search_rounded, size: 18),
                  label: const Text(
                    "بحث اسم",
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSpecRow(bool isDark, String label, String value, {IconData? icon, bool isMonospace = false, bool highlight = false}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (icon != null) ...[
            Icon(icon, size: 16, color: highlight ? const Color(0xFF6366F1) : AppColors.getTextMuted(isDark)),
            const SizedBox(width: 8),
          ],
          SizedBox(
            width: 110,
            child: Text(
              label,
              style: TextStyle(
                fontSize: 12.5,
                color: AppColors.getTextMuted(isDark),
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.bold,
                fontFamily: isMonospace ? 'monospace' : null,
                color: highlight ? const Color(0xFF6366F1) : AppColors.getTextPrimary(isDark),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
