import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/constants/app_colors.dart';
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
                child: ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.white,
                    foregroundColor: const Color(0xFF4F46E5),
                    elevation: 0,
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  icon: const Icon(Icons.qr_code_scanner_rounded, size: 24),
                  label: const Text(
                    "مسح باركود الجهاز بالكاميرا",
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                  ),
                  onPressed: () async {
                    await salesProv.scanBarcodeAndAdd(context, catalog: prodProv.products);
                  },
                ),
              ),
              const SizedBox(width: 8),
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
                _buildPaymentMethodChip("Cash", "نقداً", Icons.payments_outlined, salesProv),
                const SizedBox(width: 8),
                _buildPaymentMethodChip("Card", "فيزا / بطاقة", Icons.credit_card_rounded, salesProv),
                const SizedBox(width: 8),
                _buildPaymentMethodChip("Installment", "تقسيط", Icons.event_repeat_rounded, salesProv),
                const SizedBox(width: 8),
                _buildPaymentMethodChip("Credit", "آجل / ذمم", Icons.account_balance_wallet_outlined, salesProv),
              ],
            ),
          ),

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
  ) {
    final isSelected = salesProv.paymentMethod == method;
    return ChoiceChip(
      selected: isSelected,
      onSelected: (_) => salesProv.setPaymentMethod(method),
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
}
