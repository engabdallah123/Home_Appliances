import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../../../core/constants/api_endpoints.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/network/api_client.dart';
import '../../../core/widgets/camera_barcode_scanner.dart';
import '../../products/models/product_model.dart';
import '../../products/providers/products_provider.dart';
import '../models/sale_model.dart';
import '../providers/sales_provider.dart';
import 'sales_list_screen.dart';

class MobilePosScreen extends StatefulWidget {
  const MobilePosScreen({super.key});

  @override
  State<MobilePosScreen> createState() => _MobilePosScreenState();
}

class _MobilePosScreenState extends State<MobilePosScreen> {
  final TextEditingController _searchController = TextEditingController();
  bool _isSearchExpanded = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final prodProv = Provider.of<ProductsProvider>(context, listen: false);
      if (prodProv.products.isEmpty) {
        prodProv.fetchProducts();
      }
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final surface = AppColors.getSurface(isDark);
    final border = AppColors.getBorder(isDark);
    final salesProv = Provider.of<SalesProvider>(context);
    final prodProv = Provider.of<ProductsProvider>(context);

    return Scaffold(
      backgroundColor: AppColors.getBackground(isDark),
      appBar: AppBar(
        title: const Text(
          "كاشير الصالة المتنقل (POS)",
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
        ),
        centerTitle: false,
        actions: [
          if (salesProv.cartItems.isNotEmpty)
            IconButton(
              tooltip: "إفراغ السلة",
              icon: const Icon(Icons.delete_sweep_rounded, color: Colors.redAccent),
              onPressed: () => _confirmClearCart(context, salesProv),
            ),
          IconButton(
            tooltip: "فواتير المبيعات",
            icon: const Icon(Icons.receipt_long_rounded),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const SalesListScreen()),
              );
            },
          ),
        ],
      ),
      body: SafeArea(
        child: Column(
          children: [
            // Top Barcode Scanner & Quick Actions Banner
            _buildTopScannerBanner(context, salesProv, prodProv, isDark),

            // Customer & Delivery Information Bar
            _buildCustomerBar(context, salesProv, isDark),

            // Cart Items List
            Expanded(
              child: salesProv.cartItems.isEmpty
                  ? _buildEmptyCartPlaceholder(context, salesProv, prodProv, isDark)
                  : ListView.separated(
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                      itemCount: salesProv.cartItems.length,
                      separatorBuilder: (_, __) => const SizedBox(height: 10),
                      itemBuilder: (ctx, index) {
                        final item = salesProv.cartItems[index];
                        return _buildCartItemCard(context, salesProv, item, index, isDark);
                      },
                    ),
            ),

            // Sticky Bottom Checkout Panel
            if (salesProv.cartItems.isNotEmpty)
              _buildCheckoutPanel(context, salesProv, isDark),
          ],
        ),
      ),
    );
  }

  // 1. Top Barcode Scan Banner
  Widget _buildTopScannerBanner(
    BuildContext context,
    SalesProvider salesProv,
    ProductsProvider prodProv,
    bool isDark,
  ) {
    return Container(
      margin: const EdgeInsets.fromLTRB(14, 10, 14, 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF4F46E5), Color(0xFF06B6D4)],
          begin: Alignment.centerRight,
          end: Alignment.centerLeft,
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF4F46E5).withOpacity(0.3),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              Expanded(
                flex: 3,
                child: ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.white,
                    foregroundColor: const Color(0xFF4F46E5),
                    elevation: 0,
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  icon: const Icon(Icons.qr_code_scanner_rounded, size: 20),
                  label: const FittedBox(
                    fit: BoxFit.scaleDown,
                    child: Text(
                      "مسح باركود الجهاز",
                      style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                    ),
                  ),
                  onPressed: () async {
                    await salesProv.scanBarcodeAndAdd(context, catalog: prodProv.products);
                  },
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                flex: 2,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF10B981),
                    foregroundColor: Colors.white,
                    elevation: 0,
                    padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 6),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  onPressed: () => _showOffersAndBundlesModal(context, salesProv, prodProv, isDark),
                  child: const Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.local_offer_rounded, size: 16),
                      SizedBox(width: 4),
                      Flexible(
                        child: Text(
                          "عروض وبكجات",
                          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(width: 6),
              Container(
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: IconButton(
                  tooltip: "بحث يدوي في الكتالوج",
                  icon: Icon(
                    _isSearchExpanded ? Icons.close_rounded : Icons.search_rounded,
                    color: Colors.white,
                  ),
                  onPressed: () {
                    setState(() {
                      _isSearchExpanded = !_isSearchExpanded;
                      if (!_isSearchExpanded) _searchController.clear();
                    });
                  },
                ),
              ),
            ],
          ),

          // Search Dropdown / Autocomplete
          if (_isSearchExpanded) ...[
            const SizedBox(height: 10),
            TextField(
              controller: _searchController,
              autofocus: true,
              style: const TextStyle(color: Colors.white, fontSize: 14),
              onChanged: (_) => setState(() {}),
              decoration: InputDecoration(
                hintText: "ابحث بالاسم أو الموديل أو الماركة...",
                hintStyle: const TextStyle(color: Colors.white70, fontSize: 13),
                filled: true,
                fillColor: Colors.black.withOpacity(0.25),
                prefixIcon: const Icon(Icons.search, color: Colors.white),
                contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                  borderSide: BorderSide.none,
                ),
              ),
            ),
            if (_searchController.text.trim().isNotEmpty) ...[
              const SizedBox(height: 6),
              Container(
                constraints: const BoxConstraints(maxHeight: 180),
                decoration: BoxDecoration(
                  color: AppColors.getSurface(isDark),
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: const [BoxShadow(color: Colors.black26, blurRadius: 8)],
                ),
                child: _buildSearchResultsList(context, salesProv, prodProv, isDark),
              ),
            ],
          ],
        ],
      ),
    );
  }

  Widget _buildSearchResultsList(
    BuildContext context,
    SalesProvider salesProv,
    ProductsProvider prodProv,
    bool isDark,
  ) {
    final query = _searchController.text.trim().toLowerCase();
    final matches = prodProv.products.where((p) {
      final name = p.nameAr.toLowerCase();
      final model = (p.modelNumber ?? '').toLowerCase();
      final brand = (p.brandName ?? '').toLowerCase();
      final barcode = p.barcode.toLowerCase();
      return name.contains(query) || model.contains(query) || brand.contains(query) || barcode.contains(query);
    }).take(8).toList();

    if (matches.isEmpty) {
      return const Padding(
        padding: EdgeInsets.all(12),
        child: Center(
          child: Text(
            "لا يوجد جهاز مطابق للبحث",
            style: TextStyle(color: Colors.grey, fontSize: 13),
          ),
        ),
      );
    }

    return ListView.separated(
      shrinkWrap: true,
      itemCount: matches.length,
      separatorBuilder: (_, __) => const Divider(height: 1),
      itemBuilder: (ctx, i) {
        final p = matches[i];
        return ListTile(
          dense: true,
          title: Text(
            p.nameAr,
            style: TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 13,
              color: AppColors.getTextPrimary(isDark),
            ),
            overflow: TextOverflow.ellipsis,
          ),
          subtitle: Text(
            "${p.brandName ?? ''} ${p.modelNumber != null ? 'موديل: ${p.modelNumber}' : ''}",
            style: TextStyle(fontSize: 11, color: AppColors.getTextMuted(isDark)),
            overflow: TextOverflow.ellipsis,
          ),
          trailing: Text(
            "${p.sellingPrice.toStringAsFixed(0)} ج.م",
            style: const TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF10B981)),
          ),
          onTap: () {
            salesProv.addProduct(p);
            _searchController.clear();
            setState(() {
              _isSearchExpanded = false;
            });
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text("تمت إضافة: ${p.nameAr}"),
                backgroundColor: const Color(0xFF10B981),
                duration: const Duration(seconds: 1),
                behavior: SnackBarBehavior.floating,
              ),
            );
          },
        );
      },
    );
  }

  // 2. Customer & Options Bar
  Widget _buildCustomerBar(BuildContext context, SalesProvider salesProv, bool isDark) {
    final surface = AppColors.getSurface(isDark);
    final border = AppColors.getBorder(isDark);
    final hasCustomer = salesProv.customerName != null && salesProv.customerName!.isNotEmpty;

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: border),
      ),
      child: Row(
        children: [
          Icon(
            hasCustomer ? Icons.person_rounded : Icons.person_outline_rounded,
            color: hasCustomer ? const Color(0xFF06B6D4) : Colors.grey,
            size: 20,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  hasCustomer ? salesProv.customerName! : "عميل نقدي / مباشر",
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 12.5,
                    color: AppColors.getTextPrimary(isDark),
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
                if (hasCustomer && salesProv.customerPhone != null && salesProv.customerPhone!.isNotEmpty)
                  Text(
                    salesProv.customerPhone!,
                    style: TextStyle(fontSize: 11, color: AppColors.getTextMuted(isDark)),
                    overflow: TextOverflow.ellipsis,
                  ),
                if (salesProv.isDelivery)
                  Row(
                    children: [
                      const Icon(Icons.local_shipping_outlined, size: 12, color: Color(0xFF38BDF8)),
                      const SizedBox(width: 4),
                      Expanded(
                        child: Text(
                          "توصيل منزلي (${salesProv.deliveryAddress ?? 'لم يحدد العنوان'})",
                          style: const TextStyle(fontSize: 10.5, color: Color(0xFF38BDF8)),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
              ],
            ),
          ),
          TextButton.icon(
            style: TextButton.styleFrom(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              minimumSize: Size.zero,
              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
            ),
            icon: const Icon(Icons.edit_note_rounded, size: 16),
            label: Text(
              hasCustomer ? "تعديل" : "بيانات العميل",
              style: const TextStyle(fontSize: 11.5, fontWeight: FontWeight.bold),
            ),
            onPressed: () => _showCustomerDetailsDialog(context, salesProv, isDark),
          ),
        ],
      ),
    );
  }

  // 3. Cart Item Card (Guaranteed Zero Right-Overflow)
  Widget _buildCartItemCard(
    BuildContext context,
    SalesProvider salesProv,
    CartItemModel item,
    int index,
    bool isDark,
  ) {
    final surface = AppColors.getSurface(isDark);
    final border = AppColors.getBorder(isDark);

    return Container(
      decoration: BoxDecoration(
        color: surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: border),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(isDark ? 0.2 : 0.04),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      padding: const EdgeInsets.all(12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Row 1: Appliance Icon + Name + Delete button
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: const Color(0xFF4F46E5).withOpacity(0.12),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(Icons.kitchen_rounded, color: Color(0xFF4F46E5), size: 20),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      item.productName,
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 13.5,
                        color: AppColors.getTextPrimary(isDark),
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    // Wrap for brand, model, and barcode (zero horizontal overflow guaranteed!)
                    Wrap(
                      spacing: 6,
                      runSpacing: 4,
                      children: [
                        if (item.brandName != null && item.brandName!.isNotEmpty)
                          _buildBadge(item.brandName!, const Color(0xFF4F46E5)),
                        if (item.modelNumber != null && item.modelNumber!.isNotEmpty)
                          _buildBadge("موديل: ${item.modelNumber}", const Color(0xFF06B6D4)),
                        if (item.warrantyPeriodMonths > 0)
                          _buildBadge("ضمان ${item.warrantyPeriodMonths} شهر", const Color(0xFF10B981)),
                      ],
                    ),
                  ],
                ),
              ),
              IconButton(
                icon: const Icon(Icons.close_rounded, color: Colors.redAccent, size: 20),
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(),
                onPressed: () => salesProv.removeItem(index),
              ),
            ],
          ),

          const SizedBox(height: 10),

          // Row 2: Serial Number Pill (Very crucial for Home Appliances)
          InkWell(
            onTap: () => _editSerialNumberDialog(context, salesProv, item, index, isDark),
            borderRadius: BorderRadius.circular(8),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(
                color: item.serialNumber != null && item.serialNumber!.isNotEmpty
                    ? const Color(0xFF10B981).withOpacity(0.1)
                    : const Color(0xFFF59E0B).withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: item.serialNumber != null && item.serialNumber!.isNotEmpty
                      ? const Color(0xFF10B981).withOpacity(0.3)
                      : const Color(0xFFF59E0B).withOpacity(0.3),
                ),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.qr_code_2_rounded,
                    size: 16,
                    color: item.serialNumber != null && item.serialNumber!.isNotEmpty
                        ? const Color(0xFF10B981)
                        : const Color(0xFFF59E0B),
                  ),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      item.serialNumber != null && item.serialNumber!.isNotEmpty
                          ? "سيريال: ${item.serialNumber}"
                          : "اضغط لإدخال أو مسح سيريال الجهاز (S/N) 🏷️",
                      style: TextStyle(
                        fontSize: 11.5,
                        fontWeight: FontWeight.w600,
                        color: item.serialNumber != null && item.serialNumber!.isNotEmpty
                            ? const Color(0xFF10B981)
                            : const Color(0xFFF59E0B),
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  const Icon(Icons.edit, size: 14, color: Colors.grey),
                ],
              ),
            ),
          ),

          const SizedBox(height: 10),

          // Row 3: Quantity Stepper & Price Calculation
          Row(
            children: [
              // Quantity stepper
              Container(
                decoration: BoxDecoration(
                  color: isDark ? const Color(0xFF0F172A) : const Color(0xFFF1F5F9),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: border),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    _buildStepperBtn(
                      icon: Icons.remove,
                      onTap: () => salesProv.decrementQuantity(index),
                    ),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 10),
                      child: Text(
                        item.quantity % 1 == 0
                            ? item.quantity.toInt().toString()
                            : item.quantity.toStringAsFixed(1),
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 14,
                          color: AppColors.getTextPrimary(isDark),
                        ),
                      ),
                    ),
                    _buildStepperBtn(
                      icon: Icons.add,
                      onTap: () => salesProv.incrementQuantity(index),
                    ),
                  ],
                ),
              ),

              const SizedBox(width: 8),

              // Unit price & Line total
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      "${item.unitPrice.toStringAsFixed(0)} ج.م للقطعة",
                      style: TextStyle(
                        fontSize: 11,
                        color: AppColors.getTextMuted(isDark),
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                    Text(
                      "${item.total.toStringAsFixed(0)} ج.م",
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 15,
                        color: Color(0xFF10B981),
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
            ],
          ),

          if (item.discount > 0) ...[
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: const Color(0xFF10B981).withOpacity(0.12),
                borderRadius: BorderRadius.circular(6),
                border: Border.all(color: const Color(0xFF10B981).withOpacity(0.35)),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.local_offer_rounded, size: 12, color: Color(0xFF10B981)),
                  const SizedBox(width: 4),
                  Flexible(
                    child: Text(
                      "خصم العرض: -${item.discount.toStringAsFixed(0)} ج.م ${item.appliedOfferTitle != null ? '(${item.appliedOfferTitle})' : ''}",
                      style: const TextStyle(
                        fontSize: 10.5,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF10B981),
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildBadge(String text, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: color.withOpacity(0.12),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Text(
        text,
        style: TextStyle(
          color: color,
          fontSize: 10,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  Widget _buildStepperBtn({required IconData icon, required VoidCallback onTap}) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(6),
      child: Padding(
        padding: const EdgeInsets.all(6),
        child: Icon(icon, size: 16, color: const Color(0xFF4F46E5)),
      ),
    );
  }

  // 4. Empty Cart Placeholder
  Widget _buildEmptyCartPlaceholder(
    BuildContext context,
    SalesProvider salesProv,
    ProductsProvider prodProv,
    bool isDark,
  ) {
    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: const Color(0xFF4F46E5).withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.point_of_sale_rounded,
                size: 64,
                color: Color(0xFF4F46E5),
              ),
            ),
            const SizedBox(height: 16),
            Text(
              "سلة المبيعات فارغة",
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: AppColors.getTextPrimary(isDark),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              "توجه نحو الجهاز في صالة العرض واضغط على زر المسح بالكاميرا لإضافته مباشرة للفاتورة.",
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 13,
                color: AppColors.getTextMuted(isDark),
                height: 1.4,
              ),
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF4F46E5),
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              icon: const Icon(Icons.qr_code_scanner_rounded),
              label: const Text(
                "مسح باركود أول جهاز الآن",
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              onPressed: () async {
                await salesProv.scanBarcodeAndAdd(context, catalog: prodProv.products);
              },
            ),
          ],
        ),
      ),
    );
  }

  // 5. Sticky Bottom Checkout Panel (Guaranteed Zero Right-Overflow)
  Widget _buildCheckoutPanel(BuildContext context, SalesProvider salesProv, bool isDark) {
    final surface = AppColors.getSurface(isDark);
    final border = AppColors.getBorder(isDark);

    return Container(
      decoration: BoxDecoration(
        color: surface,
        border: Border(top: BorderSide(color: border, width: 1.5)),
        boxShadow: const [
          BoxShadow(
            color: Colors.black12,
            blurRadius: 10,
            offset: Offset(0, -3),
          ),
        ],
      ),
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Row 1: Payment method chips
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                _buildPaymentMethodChip("Cash", "نقداً", Icons.payments_outlined, salesProv, isDark),
                const SizedBox(width: 8),
                _buildPaymentMethodChip("Card", "فيزا / بطاقة", Icons.credit_card_rounded, salesProv, isDark),
                const SizedBox(width: 8),
                _buildPaymentMethodChip("Installment", "تقسيط", Icons.event_repeat_rounded, salesProv, isDark),
                const SizedBox(width: 8),
                _buildPaymentMethodChip("Credit", "آجل / ذمم", Icons.account_balance_wallet_outlined, salesProv, isDark),
              ],
            ),
          ),

          if (salesProv.isInstallment) ...[
            const SizedBox(height: 8),
            InkWell(
              onTap: () => _showInstallmentOptionsModal(context, salesProv, isDark),
              borderRadius: BorderRadius.circular(8),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                decoration: BoxDecoration(
                  color: const Color(0xFF6366F1).withOpacity(0.12),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: const Color(0xFF6366F1).withOpacity(0.35)),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.description_rounded, size: 16, color: Color(0xFF6366F1)),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Text(
                        "عقد تقسيط: ${salesProv.numberOfMonths} شهر | فائدة ${salesProv.interestPercentage.toStringAsFixed(0)}% | قسط: ${salesProv.monthlyInstallmentAmount.toStringAsFixed(0)} ج.م/ش",
                        style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Color(0xFF6366F1)),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    const Icon(Icons.edit_note_rounded, size: 16, color: Color(0xFF6366F1)),
                  ],
                ),
              ),
            ),
          ],

          const SizedBox(height: 10),

          // Row 2: Totals and Confirm Button
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      "${salesProv.itemCount} أجهزة (${salesProv.totalQuantity.toInt()} قطع)",
                      style: TextStyle(
                        fontSize: 11,
                        color: AppColors.getTextMuted(isDark),
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                    Text(
                      "${salesProv.grandTotal.toStringAsFixed(0)} ج.م",
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: AppColors.getTextPrimary(isDark),
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                    if (salesProv.isInstallment)
                      Text(
                        "قسط: ${salesProv.monthlyInstallmentAmount.toStringAsFixed(0)} ج/ش (${salesProv.numberOfMonths} شهر)",
                        style: const TextStyle(fontSize: 10.5, color: Color(0xFFF59E0B), fontWeight: FontWeight.bold),
                        overflow: TextOverflow.ellipsis,
                      ),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF10B981),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  elevation: 2,
                ),
                icon: salesProv.isCreating
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                      )
                    : const Icon(Icons.check_circle_rounded, size: 20),
                label: Text(
                  salesProv.isCreating ? "جاري الحفظ..." : "إتمام الفاتورة",
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                ),
                onPressed: salesProv.isCreating ? null : () => _confirmAndSubmitSale(context, salesProv),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildPaymentMethodChip(
    String method,
    String label,
    IconData icon,
    SalesProvider salesProv,
    bool isDark,
  ) {
    final isSelected = salesProv.paymentMethod == method;
    return ChoiceChip(
      selected: isSelected,
      onSelected: (_) {
        salesProv.setPaymentMethod(method);
        if (method == "Installment") {
          _showInstallmentOptionsModal(context, salesProv, isDark);
        }
      },
      avatar: Icon(
        icon,
        size: 16,
        color: isSelected ? Colors.white : const Color(0xFF4F46E5),
      ),
      label: Text(
        label,
        style: TextStyle(
          fontSize: 12,
          fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
          color: isSelected ? Colors.white : null,
        ),
      ),
      selectedColor: const Color(0xFF4F46E5),
      backgroundColor: Colors.transparent,
      padding: const EdgeInsets.symmetric(horizontal: 4),
    );
  }

  // Dialogs
  Future<void> _editSerialNumberDialog(
    BuildContext context,
    SalesProvider salesProv,
    CartItemModel item,
    int index,
    bool isDark,
  ) async {
    final controller = TextEditingController(text: item.serialNumber ?? '');
    await showDialog(
      context: context,
      builder: (dialogCtx) {
        return AlertDialog(
          backgroundColor: AppColors.getSurface(isDark),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: Row(
            children: [
              const Icon(Icons.qr_code_2_rounded, color: Color(0xFF06B6D4)),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  "سيريال الجهاز (Serial Number)",
                  style: TextStyle(
                    color: AppColors.getTextPrimary(isDark),
                    fontSize: 15,
                    fontWeight: FontWeight.bold,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                item.productName,
                style: TextStyle(color: AppColors.getTextMuted(isDark), fontSize: 12.5),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 12),
              TextField(
                controller: controller,
                autofocus: true,
                style: TextStyle(color: AppColors.getTextPrimary(isDark), fontSize: 14),
                decoration: InputDecoration(
                  hintText: "أدخل السيريال نمبر للجهاز...",
                  filled: true,
                  fillColor: AppColors.getInputBackground(isDark),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                  suffixIcon: IconButton(
                    icon: const Icon(Icons.camera_alt_rounded, color: Color(0xFF06B6D4)),
                    tooltip: "مسح السيريال بالكاميرا",
                    onPressed: () async {
                      final scanned = await CameraBarcodeScannerScreen.scan(
                        dialogCtx,
                        title: "مسح سيريال الجهاز",
                      );
                      if (scanned != null && scanned.isNotEmpty) {
                        controller.text = scanned.trim();
                      }
                    },
                  ),
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogCtx),
              child: const Text("إلغاء"),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF4F46E5),
                foregroundColor: Colors.white,
              ),
              onPressed: () {
                salesProv.setSerialNumber(index, controller.text.trim());
                Navigator.pop(dialogCtx);
              },
              child: const Text("حفظ"),
            ),
          ],
        );
      },
    );
  }

  Future<void> _showCustomerDetailsDialog(
    BuildContext context,
    SalesProvider salesProv,
    bool isDark,
  ) async {
    final nameCtrl = TextEditingController(text: salesProv.customerName ?? '');
    final phoneCtrl = TextEditingController(text: salesProv.customerPhone ?? '');
    final addressCtrl = TextEditingController(text: salesProv.deliveryAddress ?? '');
    final floorCtrl = TextEditingController(text: salesProv.deliveryFloor ?? '');
    final feeCtrl = TextEditingController(text: salesProv.deliveryFee > 0 ? salesProv.deliveryFee.toStringAsFixed(0) : '');
    bool isDelivery = salesProv.isDelivery;

    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.getSurface(isDark),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (sheetCtx) {
        return StatefulBuilder(
          builder: (ctx, setSheetState) {
            return Padding(
              padding: EdgeInsets.only(
                left: 16,
                right: 16,
                top: 16,
                bottom: MediaQuery.of(sheetCtx).viewInsets.bottom + 16,
              ),
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Center(
                      child: Container(
                        width: 40,
                        height: 4,
                        decoration: BoxDecoration(
                          color: Colors.grey.withOpacity(0.3),
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      "بيانات العميل والتوصيل",
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                        color: AppColors.getTextPrimary(isDark),
                      ),
                    ),
                    const SizedBox(height: 14),
                    TextField(
                      controller: nameCtrl,
                      decoration: const InputDecoration(
                        labelText: "اسم العميل",
                        prefixIcon: Icon(Icons.person_outline),
                      ),
                    ),
                    const SizedBox(height: 10),
                    TextField(
                      controller: phoneCtrl,
                      keyboardType: TextInputType.phone,
                      decoration: const InputDecoration(
                        labelText: "رقم هاتف العميل",
                        prefixIcon: Icon(Icons.phone_outlined),
                      ),
                    ),
                    const SizedBox(height: 14),
                    SwitchListTile(
                      contentPadding: EdgeInsets.zero,
                      title: const Text("خدمة توصيل وتركيب للأجهزة المنزلية"),
                      subtitle: const Text("توصيل الثلاجة/الغسالة لعنوان العميل"),
                      value: isDelivery,
                      onChanged: (val) {
                        setSheetState(() => isDelivery = val);
                      },
                    ),
                    if (isDelivery) ...[
                      const SizedBox(height: 10),
                      TextField(
                        controller: addressCtrl,
                        decoration: const InputDecoration(
                          labelText: "عنوان التوصيل التفصيلي",
                          prefixIcon: Icon(Icons.location_on_outlined),
                        ),
                      ),
                      const SizedBox(height: 10),
                      Row(
                        children: [
                          Expanded(
                            child: TextField(
                              controller: floorCtrl,
                              decoration: const InputDecoration(
                                labelText: "الدور / الشقة",
                              ),
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: TextField(
                              controller: feeCtrl,
                              keyboardType: TextInputType.number,
                              decoration: const InputDecoration(
                                labelText: "رسوم التوصيل (ج.م)",
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                    const SizedBox(height: 18),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF4F46E5),
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                        ),
                        onPressed: () {
                          salesProv.setCustomer(
                            name: nameCtrl.text,
                            phone: phoneCtrl.text,
                          );
                          salesProv.setDelivery(
                            enabled: isDelivery,
                            address: addressCtrl.text,
                            floor: floorCtrl.text,
                            fee: double.tryParse(feeCtrl.text) ?? 0,
                          );
                          Navigator.pop(sheetCtx);
                        },
                        child: const Text("حفظ البيانات", style: TextStyle(fontWeight: FontWeight.bold)),
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  Future<void> _confirmClearCart(BuildContext context, SalesProvider salesProv) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text("إفراغ السلة"),
        content: const Text("هل تريد بالتأكيد إفراغ جميع الأجهزة من السلة؟"),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text("إلغاء"),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.redAccent),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text("إفراغ", style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      salesProv.clearCart();
    }
  }

  Future<void> _confirmAndSubmitSale(BuildContext context, SalesProvider salesProv) async {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    // Show Confirmation Dialog before submitting if it's an installment sale
    if (salesProv.isInstallment) {
      final confirmed = await showDialog<bool>(
        context: context,
        builder: (ctx) {
          return AlertDialog(
            backgroundColor: AppColors.getSurface(isDark),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
            title: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: const Color(0xFF6366F1).withOpacity(0.15),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(Icons.event_repeat_rounded, color: Color(0xFF6366F1), size: 24),
                ),
                const SizedBox(width: 10),
                const Expanded(
                  child: Text(
                    "تأكيد عملية البيع بالتقسيط",
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                  ),
                ),
              ],
            ),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: const Color(0xFF6366F1).withOpacity(0.08),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: const Color(0xFF6366F1).withOpacity(0.25)),
                    ),
                    child: Column(
                      children: [
                        _buildInstallmentConfirmRow("سعر الأجهزة نقداً:", "${salesProv.cashTotal.toStringAsFixed(0)} ج.م", isDark),
                        const SizedBox(height: 6),
                        _buildInstallmentConfirmRow("المقدم المدفوع الآن:", "${salesProv.paidAmount.toStringAsFixed(0)} ج.م", isDark, valueColor: const Color(0xFF10B981)),
                        const SizedBox(height: 6),
                        _buildInstallmentConfirmRow("أصل التمويل المتبقي:", "${salesProv.financedBase.toStringAsFixed(0)} ج.م", isDark),
                        const SizedBox(height: 6),
                        _buildInstallmentConfirmRow("نسبة الفائدة / الأرباح:", "${salesProv.interestPercentage.toStringAsFixed(0)}% (+${salesProv.interestAmount.toStringAsFixed(0)} ج.م)", isDark, valueColor: const Color(0xFFF59E0B)),
                        const Divider(height: 16),
                        _buildInstallmentConfirmRow("إجمالي الفاتورة بالفوائد:", "${salesProv.grandTotal.toStringAsFixed(0)} ج.م", isDark, isBold: true, valueColor: const Color(0xFF6366F1)),
                        const SizedBox(height: 6),
                        _buildInstallmentConfirmRow("المتبقي للأقساط:", "${salesProv.remainingAmount.toStringAsFixed(0)} ج.م", isDark, isBold: true),
                        const SizedBox(height: 6),
                        _buildInstallmentConfirmRow("القسط الشهري المستحق:", "${salesProv.monthlyInstallmentAmount.toStringAsFixed(0)} ج.م / شهر", isDark, isBold: true, valueColor: const Color(0xFF6366F1)),
                        const SizedBox(height: 6),
                        _buildInstallmentConfirmRow("مدة التقسيط:", "${salesProv.numberOfMonths} شهر", isDark),
                      ],
                    ),
                  ),
                  if (salesProv.customerName != null && salesProv.customerName!.isNotEmpty) ...[
                    const SizedBox(height: 10),
                    Text("العميل: ${salesProv.customerName} (${salesProv.customerPhone ?? '-'})", style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: AppColors.getTextPrimary(isDark))),
                  ],
                  if (salesProv.guarantorName != null && salesProv.guarantorName!.isNotEmpty) ...[
                    const SizedBox(height: 4),
                    Text("الضامن: ${salesProv.guarantorName} (${salesProv.guarantorPhone ?? '-'})", style: TextStyle(fontSize: 12, color: AppColors.getTextMuted(isDark))),
                  ],
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(ctx, false),
                child: const Text("رجوع للتعديل"),
              ),
              ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF10B981),
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                ),
                icon: const Icon(Icons.check_circle_rounded, size: 18),
                label: const Text("تأكيد وإصدار الفاتورة", style: TextStyle(fontWeight: FontWeight.bold)),
                onPressed: () => Navigator.pop(ctx, true),
              ),
            ],
          );
        },
      );

      if (confirmed != true) return;
    }

    final created = await salesProv.submitSale();
    if (!context.mounted) return;

    if (created != null) {
      await showDialog(
        context: context,
        barrierDismissible: false,
        builder: (dialogCtx) {
          return AlertDialog(
            backgroundColor: const Color(0xFF1E293B),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: const Color(0xFF10B981).withOpacity(0.15),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.check_circle_rounded,
                    color: Color(0xFF10B981),
                    size: 54,
                  ),
                ),
                const SizedBox(height: 16),
                const Text(
                  "تم حفظ الفاتورة بنجاح!",
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  "رقم الفاتورة: ${created.invoiceNumber}",
                  style: const TextStyle(
                    color: Color(0xFF38BDF8),
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: const Color(0xFF0F172A),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.sync_rounded, color: Color(0xFF10B981), size: 20),
                      const SizedBox(width: 8),
                      const Expanded(
                        child: Text(
                          "الفاتورة جاهزة للمزامنة التلقائية مع كاشير الديسكتوب فوراً.",
                          style: TextStyle(color: Colors.white70, fontSize: 11.5),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () {
                  Navigator.pop(dialogCtx);
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const SalesListScreen()),
                  );
                },
                child: const Text("عرض قائمة الفواتير", style: TextStyle(color: Colors.white70)),
              ),
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF10B981),
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                ),
                onPressed: () => Navigator.pop(dialogCtx),
                child: const Text("فاتورة جديدة"),
              ),
            ],
          );
        },
      );
    } else if (salesProv.errorMessage != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(salesProv.errorMessage!),
          backgroundColor: Colors.redAccent,
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  static Widget _buildInstallmentConfirmRow(
    String label,
    String value,
    bool isDark, {
    bool isBold = false,
    Color? valueColor,
  }) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 12,
            fontWeight: isBold ? FontWeight.bold : FontWeight.normal,
            color: isBold ? AppColors.getTextPrimary(isDark) : AppColors.getTextMuted(isDark),
          ),
        ),
        Text(
          value,
          style: TextStyle(
            fontSize: isBold ? 13.5 : 12,
            fontWeight: isBold ? FontWeight.bold : FontWeight.w600,
            color: valueColor ?? AppColors.getTextPrimary(isDark),
          ),
        ),
      ],
    );
  }

  Future<void> _showInstallmentOptionsModal(
    BuildContext context,
    SalesProvider salesProv,
    bool isDark,
  ) async {
    int months = salesProv.numberOfMonths > 0 ? salesProv.numberOfMonths : 12;
    double interestPct = salesProv.interestPercentage;
    final total = salesProv.grandTotal;
    double downPayment = salesProv.paidAmount > 0 && salesProv.paidAmount < total
        ? salesProv.paidAmount
        : (total * 0.20).roundToDouble();

    final downPaymentCtrl = TextEditingController(text: downPayment.toStringAsFixed(0));
    final interestCtrl = TextEditingController(text: interestPct.toStringAsFixed(1));
    final nameCtrl = TextEditingController(text: salesProv.guarantorName ?? '');
    final phoneCtrl = TextEditingController(text: salesProv.guarantorPhone ?? '');
    final nationalIdCtrl = TextEditingController(text: salesProv.guarantorNationalId ?? '');
    final addressCtrl = TextEditingController(text: salesProv.guarantorAddress ?? '');
    final notesCtrl = TextEditingController(text: salesProv.guarantorNotes ?? '');

    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.getSurface(isDark),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (sheetCtx) {
        return StatefulBuilder(
          builder: (ctx, setModalState) {
            final curDown = double.tryParse(downPaymentCtrl.text) ?? 0.0;
            final curInterest = double.tryParse(interestCtrl.text) ?? 0.0;
            final financedPrincipal = (total - curDown) > 0 ? (total - curDown) : 0.0;
            final totalInterest = financedPrincipal * (curInterest / 100) * (months / 12);
            final totalFinancedWithInterest = financedPrincipal + totalInterest;
            final monthlyAmount = months > 0 ? (totalFinancedWithInterest / months) : 0.0;

            return Padding(
              padding: EdgeInsets.only(
                left: 16,
                right: 16,
                top: 14,
                bottom: MediaQuery.of(sheetCtx).viewInsets.bottom + 16,
              ),
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Center(
                      child: Container(
                        width: 40,
                        height: 4,
                        decoration: BoxDecoration(
                          color: Colors.grey.withOpacity(0.3),
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(6),
                          decoration: BoxDecoration(
                            color: const Color(0xFF6366F1).withOpacity(0.15),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: const Icon(Icons.assignment_turned_in_rounded, color: Color(0xFF6366F1), size: 20),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                "عقد تمويل وتقسيط الأجهزة الكهربائية",
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 15,
                                  color: AppColors.getTextPrimary(isDark),
                                ),
                                overflow: TextOverflow.ellipsis,
                              ),
                              Text(
                                "خيارات التمويل، جدول الأقساط الشهرية، وبيانات الضامن المعتمد",
                                style: TextStyle(fontSize: 11, color: AppColors.getTextMuted(isDark)),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const Divider(height: 20),

                    // Months and Interest Row
                    Row(
                      children: [
                        Expanded(
                          flex: 3,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text("مدة التقسيط", style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                              const SizedBox(height: 4),
                              DropdownButtonFormField<int>(
                                value: months,
                                decoration: InputDecoration(
                                  contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                                ),
                                items: const [
                                  DropdownMenuItem(value: 3, child: Text("3 أشهر")),
                                  DropdownMenuItem(value: 6, child: Text("6 أشهر")),
                                  DropdownMenuItem(value: 9, child: Text("9 أشهر")),
                                  DropdownMenuItem(value: 12, child: Text("12 شهر (سنة)")),
                                  DropdownMenuItem(value: 18, child: Text("18 شهر")),
                                  DropdownMenuItem(value: 24, child: Text("24 شهر (سنتين)")),
                                  DropdownMenuItem(value: 30, child: Text("30 شهر")),
                                  DropdownMenuItem(value: 36, child: Text("36 شهر (3 سنين)")),
                                  DropdownMenuItem(value: 48, child: Text("48 شهر")),
                                  DropdownMenuItem(value: 60, child: Text("60 شهر (5 سنين)")),
                                ],
                                onChanged: (val) {
                                  if (val != null) setModalState(() => months = val);
                                },
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          flex: 2,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text("الفائدة السنوية (%)", style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                              const SizedBox(height: 4),
                              TextField(
                                controller: interestCtrl,
                                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                                onChanged: (_) => setModalState(() {}),
                                decoration: InputDecoration(
                                  contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                                  suffixText: "%",
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 10),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text("المقدم المدفوع (ج.م)", style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                        const SizedBox(height: 4),
                        TextField(
                          controller: downPaymentCtrl,
                          keyboardType: const TextInputType.numberWithOptions(decimal: true),
                          onChanged: (_) => setModalState(() {}),
                          decoration: InputDecoration(
                            contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                            border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                            prefixIcon: const Icon(Icons.payments_outlined, size: 18),
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 12),

                    // Financial Calculations Card
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: const Color(0xFF6366F1).withOpacity(0.08),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: const Color(0xFF6366F1).withOpacity(0.3)),
                      ),
                      child: Column(
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text("المقدم المدفوع:", style: TextStyle(fontSize: 12, color: AppColors.getTextMuted(isDark))),
                              FittedBox(
                                fit: BoxFit.scaleDown,
                                child: Text("${curDown.toStringAsFixed(0)} ج.م", style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Color(0xFF10B981))),
                              ),
                            ],
                          ),
                          const SizedBox(height: 4),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text("أصل التمويل المتبقي:", style: TextStyle(fontSize: 12, color: AppColors.getTextMuted(isDark))),
                              FittedBox(
                                fit: BoxFit.scaleDown,
                                child: Text("${financedPrincipal.toStringAsFixed(0)} ج.م", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: AppColors.getTextPrimary(isDark))),
                              ),
                            ],
                          ),
                          const SizedBox(height: 4),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text("إجمالي الفائدة المحتسبة:", style: TextStyle(fontSize: 12, color: AppColors.getTextMuted(isDark))),
                              FittedBox(
                                fit: BoxFit.scaleDown,
                                child: Text("+${totalInterest.toStringAsFixed(0)} ج.م", style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Color(0xFFF59E0B))),
                              ),
                            ],
                          ),
                          const Divider(height: 12),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              const Text("القسط الشهري المستحق:", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Color(0xFF6366F1))),
                              Flexible(
                                child: FittedBox(
                                  fit: BoxFit.scaleDown,
                                  child: Text("${monthlyAmount.toStringAsFixed(0)} ج.م / شهر", style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 16, color: Color(0xFF6366F1))),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 14),

                    // Guarantor Section
                    Text("بيانات الضامن (اختياري / موثق):", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: AppColors.getTextPrimary(isDark))),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Expanded(
                          child: TextField(
                            controller: nameCtrl,
                            decoration: const InputDecoration(
                              labelText: "اسم الضامن",
                              contentPadding: EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: TextField(
                            controller: phoneCtrl,
                            keyboardType: TextInputType.phone,
                            decoration: const InputDecoration(
                              labelText: "هاتف الضامن",
                              contentPadding: EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Expanded(
                          child: TextField(
                            controller: nationalIdCtrl,
                            keyboardType: TextInputType.number,
                            decoration: const InputDecoration(
                              labelText: "الرقم القومي للضامن",
                              contentPadding: EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: TextField(
                            controller: addressCtrl,
                            decoration: const InputDecoration(
                              labelText: "عنوان ومحل سكن الضامن",
                              contentPadding: EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    TextField(
                      controller: notesCtrl,
                      decoration: const InputDecoration(
                        labelText: "ملاحظات الضامن / جهة العمل",
                        contentPadding: EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                      ),
                    ),

                    const SizedBox(height: 16),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton.icon(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF6366F1),
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                        ),
                        icon: const Icon(Icons.check_circle_rounded),
                        label: const Text("تأكيد وتطبيق شروط التقسيط", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                        onPressed: () {
                          salesProv.setInstallment(
                            enabled: true,
                            numberOfMonths: months,
                            interestPercentage: double.tryParse(interestCtrl.text) ?? 0,
                            downPayment: double.tryParse(downPaymentCtrl.text),
                            guarantorName: nameCtrl.text,
                            guarantorPhone: phoneCtrl.text,
                            guarantorNationalId: nationalIdCtrl.text,
                            guarantorAddress: addressCtrl.text,
                            guarantorNotes: notesCtrl.text,
                          );
                          Navigator.pop(sheetCtx);
                        },
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  Future<void> _showOffersAndBundlesModal(
    BuildContext context,
    SalesProvider salesProv,
    ProductsProvider prodProv,
    bool isDark,
  ) async {
    final apiClient = ApiClient();
    List<dynamic> offers = [];
    bool isLoading = true;
    String? error;

    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.getSurface(isDark),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(22)),
      ),
      builder: (sheetCtx) {
        return StatefulBuilder(
          builder: (ctx, setSheetState) {
            if (isLoading) {
              apiClient.get(ApiEndpoints.offers).then((res) {
                if (sheetCtx.mounted) {
                  setSheetState(() {
                    isLoading = false;
                    offers = res is List ? res : [];
                  });
                }
              }).catchError((e) {
                if (sheetCtx.mounted) {
                  setSheetState(() {
                    isLoading = false;
                    error = e.toString();
                  });
                }
              });
            }

            return Container(
              constraints: BoxConstraints(maxHeight: MediaQuery.of(sheetCtx).size.height * 0.85),
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 20),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Center(
                    child: Container(
                      width: 44,
                      height: 4,
                      decoration: BoxDecoration(
                        color: Colors.grey.withOpacity(0.3),
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(6),
                        decoration: BoxDecoration(
                          color: const Color(0xFFF59E0B).withOpacity(0.15),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Icon(Icons.card_giftcard_rounded, color: Color(0xFFF59E0B), size: 22),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              "عروض وبكجات الأجهزة الكهربائية",
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 15,
                                color: AppColors.getTextPrimary(isDark),
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                            Text(
                              "اختر البكج لإضافته دفعة واحدة للسلة مع تطبيق السعر الترويجي",
                              style: TextStyle(fontSize: 11, color: AppColors.getTextMuted(isDark)),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.close_rounded),
                        onPressed: () => Navigator.pop(sheetCtx),
                      ),
                    ],
                  ),
                  const Divider(height: 16),
                  if (isLoading)
                    const Expanded(
                      child: Center(
                        child: CircularProgressIndicator(),
                      ),
                    )
                  else if (error != null)
                    Expanded(
                      child: Center(
                        child: Text("خطأ في جلب العروض: $error", style: const TextStyle(color: Colors.redAccent)),
                      ),
                    )
                  else if (offers.isEmpty)
                    Expanded(
                      child: Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Icon(Icons.card_giftcard_outlined, size: 48, color: Colors.grey),
                            const SizedBox(height: 10),
                            Text(
                              "لا توجد عروض أو بكجات نشطة حالياً",
                              style: TextStyle(color: AppColors.getTextMuted(isDark), fontSize: 14),
                            ),
                          ],
                        ),
                      ),
                    )
                  else
                    Expanded(
                      child: ListView.separated(
                        itemCount: offers.length,
                        separatorBuilder: (_, __) => const SizedBox(height: 12),
                        itemBuilder: (c, idx) {
                          final off = offers[idx] as Map<String, dynamic>;
                          final title = off['titleAr']?.toString() ?? 'عرض ترويجي';
                          final desc = off['description']?.toString() ?? '';
                          final isBundle = off['offerType'] == 'BundlePackage';
                          final pkgPrice = (off['packagePrice'] as num?)?.toDouble() ?? 0.0;
                          final discPct = (off['discountPercent'] as num?)?.toDouble() ?? 0.0;
                          final items = (off['items'] as List?) ?? [];

                          return Container(
                            decoration: BoxDecoration(
                              color: isDark ? const Color(0xFF1E293B) : const Color(0xFFF8FAFC),
                              borderRadius: BorderRadius.circular(14),
                              border: Border.all(
                                color: isBundle
                                    ? const Color(0xFFF59E0B).withOpacity(0.4)
                                    : const Color(0xFF6366F1).withOpacity(0.4),
                              ),
                            ),
                            padding: const EdgeInsets.all(12),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Expanded(
                                      child: Text(
                                        title,
                                        style: TextStyle(
                                          fontWeight: FontWeight.bold,
                                          fontSize: 14,
                                          color: AppColors.getTextPrimary(isDark),
                                        ),
                                      ),
                                    ),
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                      decoration: BoxDecoration(
                                        color: isBundle
                                            ? const Color(0xFFF59E0B).withOpacity(0.15)
                                            : const Color(0xFF6366F1).withOpacity(0.15),
                                        borderRadius: BorderRadius.circular(6),
                                      ),
                                      child: Text(
                                        isBundle ? "🎁 بكج مجمّع" : "🏷️ خصم ترويجي",
                                        style: TextStyle(
                                          color: isBundle ? const Color(0xFFF59E0B) : const Color(0xFF6366F1),
                                          fontSize: 10.5,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                                if (desc.isNotEmpty) ...[
                                  const SizedBox(height: 4),
                                  Text(
                                    desc,
                                    style: TextStyle(fontSize: 11.5, color: AppColors.getTextSecondary(isDark)),
                                  ),
                                ],
                                if (items.isNotEmpty) ...[
                                  const SizedBox(height: 8),
                                  Container(
                                    padding: const EdgeInsets.all(8),
                                    decoration: BoxDecoration(
                                      color: isDark ? const Color(0xFF0F172A) : Colors.white,
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        const Text(
                                          "الأجهزة المشمولة في البكج:",
                                          style: TextStyle(fontSize: 10.5, fontWeight: FontWeight.bold, color: Colors.grey),
                                        ),
                                        const SizedBox(height: 4),
                                        ...items.map((it) {
                                          final pName = it['productName']?.toString() ?? 'جهاز';
                                          final q = (it['quantity'] as num?)?.toDouble() ?? 1.0;
                                          return Padding(
                                            padding: const EdgeInsets.symmetric(vertical: 1.5),
                                            child: Row(
                                              children: [
                                                const Icon(Icons.check, size: 12, color: Color(0xFF10B981)),
                                                const SizedBox(width: 4),
                                                Expanded(
                                                  child: Text(
                                                    "$pName (${q.toInt()} قطعة)",
                                                    style: const TextStyle(fontSize: 11),
                                                    overflow: TextOverflow.ellipsis,
                                                  ),
                                                ),
                                              ],
                                            ),
                                          );
                                        }),
                                      ],
                                    ),
                                  ),
                                ],
                                const SizedBox(height: 10),
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    if (pkgPrice > 0)
                                      Text(
                                        "${pkgPrice.toStringAsFixed(0)} ج.م",
                                        style: const TextStyle(
                                          fontSize: 17,
                                          fontWeight: FontWeight.w900,
                                          color: Color(0xFFF59E0B),
                                        ),
                                      )
                                    else if (discPct > 0)
                                      Text(
                                        "خصم ${discPct.toStringAsFixed(0)}%",
                                        style: const TextStyle(
                                          fontSize: 15,
                                          fontWeight: FontWeight.bold,
                                          color: Color(0xFFF59E0B),
                                        ),
                                      )
                                    else
                                      const SizedBox.shrink(),
                                    ElevatedButton.icon(
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor: isBundle ? const Color(0xFFF59E0B) : const Color(0xFF4F46E5),
                                        foregroundColor: Colors.white,
                                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                                      ),
                                      icon: const Icon(Icons.add_shopping_cart_rounded, size: 16),
                                      label: Text(
                                        isBundle ? "إضافة الباكدج للسلة" : "تطبيق الخصم",
                                        style: const TextStyle(fontSize: 11.5, fontWeight: FontWeight.bold),
                                      ),
                                      onPressed: () {
                                        final error = salesProv.applyOffer(off, prodProv.products);
                                        Navigator.pop(sheetCtx);
                                        if (error != null) {
                                          ScaffoldMessenger.of(context).showSnackBar(
                                            SnackBar(
                                              content: Text(error),
                                              backgroundColor: const Color(0xFFD97706),
                                              behavior: SnackBarBehavior.floating,
                                            ),
                                          );
                                          return;
                                        }
                                        ScaffoldMessenger.of(context).showSnackBar(
                                          SnackBar(
                                            content: Text("تم تطبيق: $title بنجاح!"),
                                            backgroundColor: const Color(0xFF10B981),
                                            behavior: SnackBarBehavior.floating,
                                          ),
                                        );
                                      },
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          );
                        },
                      ),
                    ),
                ],
              ),
            );
          },
        );
      },
    );
  }
}
