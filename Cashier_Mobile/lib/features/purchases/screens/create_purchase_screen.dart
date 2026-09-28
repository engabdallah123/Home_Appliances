import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/theme/theme_provider.dart';
import '../../../core/widgets/custom_button.dart';
import '../../../core/widgets/custom_text_field.dart';
import '../../../core/widgets/offline_banner.dart';
import '../../../core/widgets/camera_barcode_scanner.dart';
import '../../products/models/product_model.dart';
import '../../products/providers/products_provider.dart';
import '../../suppliers/models/supplier_model.dart';
import '../../suppliers/providers/suppliers_provider.dart';
import '../../suppliers/screens/suppliers_list_screen.dart';
import '../models/purchase_model.dart';
import '../providers/purchases_provider.dart';

class CreatePurchaseScreen extends StatefulWidget {
  const CreatePurchaseScreen({super.key});

  @override
  State<CreatePurchaseScreen> createState() => _CreatePurchaseScreenState();
}

class _CreatePurchaseScreenState extends State<CreatePurchaseScreen> {
  final _formKey = GlobalKey<FormState>();

  final TextEditingController _invoiceNumController = TextEditingController();
  final TextEditingController _internalNumController = TextEditingController();
  final TextEditingController _discountController = TextEditingController(text: "0");
  final TextEditingController _taxController = TextEditingController(text: "0");
  final TextEditingController _paidController = TextEditingController(text: "0");
  final TextEditingController _notesController = TextEditingController();

  DateTime _purchaseDate = DateTime.now();
  SupplierModel? _selectedSupplier;
  int _paymentMethod = 1; // 1: Cash, 2: Card, 3: Wallet, 4: Credit
  final List<CreatePurchaseItemModel> _items = [];

  @override
  void initState() {
    super.initState();
    final now = DateTime.now();
    _invoiceNumController.text = "PUR-${DateFormat('yyMMdd-HHmm').format(now)}";

    WidgetsBinding.instance.addPostFrameCallback((_) {
      Provider.of<SuppliersProvider>(context, listen: false).fetchSuppliers();
      Provider.of<ProductsProvider>(context, listen: false).fetchProducts();
    });
  }

  @override
  void dispose() {
    _invoiceNumController.dispose();
    _internalNumController.dispose();
    _discountController.dispose();
    _taxController.dispose();
    _paidController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  double get _subTotal => _items.fold(0.0, (sum, i) => sum + i.total);
  double get _discount => double.tryParse(_discountController.text) ?? 0.0;
  double get _tax => double.tryParse(_taxController.text) ?? 0.0;
  double get _total => (_subTotal - _discount + _tax) > 0 ? (_subTotal - _discount + _tax) : 0.0;
  double get _paid => double.tryParse(_paidController.text) ?? 0.0;
  double get _remaining => (_total - _paid) > 0 ? (_total - _paid) : 0.0;

  // Breakdown Metrics
  int get _regularItemsCount => _items.where((i) => !i.isWeighable).length;
  double get _regularItemsTotal => _items.where((i) => !i.isWeighable).fold(0.0, (sum, i) => sum + i.total);
  int get _weighedItemsCount => _items.where((i) => i.isWeighable).length;
  double get _weighedItemsTotal => _items.where((i) => i.isWeighable).fold(0.0, (sum, i) => sum + i.total);
  double get _totalWeighedKg => _items.where((i) => i.isWeighable).fold(0.0, (sum, i) => sum + i.quantity);

  void _setFullPayment() {
    setState(() {
      _paidController.text = _total.toStringAsFixed(2);
    });
  }

  void _setZeroPayment() {
    setState(() {
      _paidController.text = "0";
    });
  }

  Future<void> _scanBarcodeAndAddProduct() async {
    final barcode = await CameraBarcodeScannerScreen.scan(context, title: "مسح باركود صنف الفاتورة");
    if (barcode == null || barcode.trim().isEmpty) return;

    final prov = Provider.of<ProductsProvider>(context, listen: false);
    final clean = barcode.trim().toLowerCase();

    ProductModel? matched;
    try {
      matched = prov.products.firstWhere(
        (p) => p.barcode.trim().toLowerCase() == clean ||
               (p.isWeighable && (clean.contains(p.barcode.trim().toLowerCase()) || p.barcode.trim().toLowerCase().endsWith(clean))),
      );
    } catch (_) {
      matched = null;
    }

    if (matched != null) {
      _openItemConfigDialog(matched);
    } else {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text("الباركود ($clean) غير مسجل في المنتجات، يرجى إضافته أولاً من شاشة المنتجات."),
            backgroundColor: AppColors.danger,
            duration: const Duration(seconds: 4),
          ),
        );
      }
    }
  }

  Future<void> _pickPurchaseDate(BuildContext context, bool isDark) async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _purchaseDate,
      firstDate: DateTime(2020),
      lastDate: DateTime(2035),
      locale: const Locale('ar', 'EG'),
    );
    if (picked != null) {
      setState(() => _purchaseDate = picked);
    }
  }

  // Product Picker Modal with Type Filter (All, Regular, Weighed)
  void _openProductPicker() {
    final prodProv = Provider.of<ProductsProvider>(context, listen: false);
    final searchCtrl = TextEditingController();
    String typeFilter = "all"; // 'all', 'regular', 'weighed'
    final isDark = Provider.of<ThemeProvider>(context, listen: false).isDarkMode;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.getSurface(isDark),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            return Padding(
              padding: EdgeInsets.only(
                bottom: MediaQuery.of(context).viewInsets.bottom,
                top: 16,
                left: 16,
                right: 16,
              ),
              child: SizedBox(
                height: MediaQuery.of(context).size.height * 0.8,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(
                          child: Row(
                            children: [
                              const Icon(Icons.inventory_2_outlined, color: AppColors.primaryLight, size: 22),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  "اختر الصنف لإضافته إلى الفاتورة",
                                  style: TextStyle(color: AppColors.getTextPrimary(isDark), fontWeight: FontWeight.bold, fontSize: 16),
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ],
                          ),
                        ),
                        IconButton(
                          icon: Icon(Icons.close, color: AppColors.getTextSecondary(isDark)),
                          onPressed: () => Navigator.pop(ctx),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    // Search box
                    TextField(
                      controller: searchCtrl,
                      style: TextStyle(color: AppColors.getTextPrimary(isDark), fontSize: 14),
                      onChanged: (val) {
                        prodProv.fetchProducts(search: val);
                        setModalState(() {});
                      },
                      decoration: InputDecoration(
                        hintText: "ابحث بالاسم أو الباركود...",
                        hintStyle: TextStyle(color: AppColors.getTextMuted(isDark), fontSize: 13),
                        prefixIcon: const Icon(Icons.search, color: AppColors.primaryLight),
                        suffixIcon: IconButton(
                          icon: const Icon(Icons.qr_code_scanner_rounded, color: AppColors.cyan),
                          tooltip: "مسح باركود بالكاميرا",
                          onPressed: () async {
                            final scanned = await CameraBarcodeScannerScreen.scan(context, title: "مسح باركود صنف");
                            if (scanned != null && scanned.trim().isNotEmpty) {
                              searchCtrl.text = scanned.trim();
                              prodProv.fetchProducts(search: scanned.trim());
                              setModalState(() {});
                            }
                          },
                        ),
                        filled: true,
                        fillColor: AppColors.getBackground(isDark),
                        contentPadding: const EdgeInsets.symmetric(vertical: 12),
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: AppColors.getBorder(isDark))),
                        enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: AppColors.getBorder(isDark))),
                      ),
                    ),
                    const SizedBox(height: 10),

                    // Filter chips: All, Regular, Weighed
                    SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: Row(
                        children: [
                          _buildPickerChip(isDark, "الكل", typeFilter == "all", () {
                            setModalState(() => typeFilter = "all");
                          }),
                          const SizedBox(width: 8),
                          _buildPickerChip(isDark, "منتجات عادية 📦", typeFilter == "regular", () {
                            setModalState(() => typeFilter = "regular");
                          }),
                          const SizedBox(width: 8),
                          _buildPickerChip(isDark, "منتجات بالوزن ⚖️", typeFilter == "weighed", () {
                            setModalState(() => typeFilter = "weighed");
                          }),
                        ],
                      ),
                    ),
                    const SizedBox(height: 12),

                    // Products list
                    Expanded(
                      child: Consumer<ProductsProvider>(
                        builder: (context, prov, child) {
                          if (prov.isLoading) {
                            return const Center(child: CircularProgressIndicator(color: AppColors.primaryLight));
                          }

                          var filtered = prov.products;
                          if (typeFilter == "regular") {
                            filtered = filtered.where((p) => !p.isWeighable).toList();
                          } else if (typeFilter == "weighed") {
                            filtered = filtered.where((p) => p.isWeighable).toList();
                          }

                          if (filtered.isEmpty) {
                            return Center(
                              child: Text("لا توجد أصناف مطابقة للبحث.", style: TextStyle(color: AppColors.getTextMuted(isDark))),
                            );
                          }

                          return NotificationListener<ScrollNotification>(
                            onNotification: (scrollInfo) {
                              if (scrollInfo.metrics.pixels >= scrollInfo.metrics.maxScrollExtent - 200) {
                                if (prov.hasMore && !prov.isLoadingMore && !prov.isLoading) {
                                  prov.fetchMoreProducts();
                                }
                              }
                              return false;
                            },
                            child: ListView.separated(
                              itemCount: filtered.length + (prov.isLoadingMore ? 1 : 0),
                              separatorBuilder: (_, __) => Divider(color: AppColors.getBorder(isDark), height: 1),
                              itemBuilder: (context, idx) {
                                if (idx == filtered.length) {
                                  return const Padding(
                                    padding: EdgeInsets.symmetric(vertical: 12),
                                    child: Center(
                                      child: SizedBox(
                                        width: 20,
                                        height: 20,
                                        child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.primaryLight),
                                      ),
                                    ),
                                  );
                                }
                                final p = filtered[idx];
                                return ListTile(
                                contentPadding: const EdgeInsets.symmetric(vertical: 4, horizontal: 8),
                                leading: Container(
                                  padding: const EdgeInsets.all(10),
                                  decoration: BoxDecoration(
                                    color: p.isWeighable ? AppColors.cyan.withOpacity(0.12) : AppColors.primary.withOpacity(0.12),
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                  child: Icon(
                                    p.isWeighable ? Icons.scale_rounded : Icons.inventory_2_outlined,
                                    color: p.isWeighable ? AppColors.cyan : AppColors.primaryLight,
                                    size: 22,
                                  ),
                                ),
                                title: Row(
                                  children: [
                                    Expanded(
                                      child: Text(
                                        p.nameAr,
                                        style: TextStyle(color: AppColors.getTextPrimary(isDark), fontWeight: FontWeight.w600, fontSize: 14),
                                      ),
                                    ),
                                    if (p.isWeighable)
                                      Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                        decoration: BoxDecoration(
                                          color: AppColors.cyan.withOpacity(0.15),
                                          borderRadius: BorderRadius.circular(4),
                                        ),
                                        child: const Text("بالوزن ⚖️", style: TextStyle(color: AppColors.cyan, fontSize: 10, fontWeight: FontWeight.bold)),
                                      ),
                                  ],
                                ),
                                subtitle: Wrap(
                                  spacing: 8,
                                  children: [
                                    Text(
                                      p.barcode,
                                      style: TextStyle(color: AppColors.getTextMuted(isDark), fontSize: 11, fontFamily: 'monospace'),
                                    ),
                                    Text(
                                      "شراء: ${p.purchasePrice > 0 ? p.purchasePrice.toStringAsFixed(2) : p.sellingPrice.toStringAsFixed(2)} ج.م${p.isWeighable ? '/كجم' : ''}",
                                      style: const TextStyle(color: AppColors.success, fontSize: 11, fontWeight: FontWeight.w600),
                                    ),
                                    if (p.trackExpiry)
                                      Text(
                                        "صلاحية: ${p.shelfLifeDays} يوم",
                                        style: TextStyle(color: Colors.amber.shade700, fontSize: 11),
                                      ),
                                  ],
                                ),
                                trailing: ElevatedButton(
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: AppColors.primary,
                                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                                  ),
                                  onPressed: () {
                                    Navigator.pop(ctx);
                                    _openItemConfigDialog(p);
                                  },
                                  child: const Text("تحديد", style: TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold)),
                                ),
                              );
                            },
                          ),
                        );
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

  Widget _buildPickerChip(bool isDark, String label, bool isSelected, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.primary : AppColors.getBackground(isDark),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: isSelected ? AppColors.primary : AppColors.getBorder(isDark)),
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

  // Full Feature Item Configuration Dialog (Weighed vs Carton/Piece, Expiry Tracking)
  void _openItemConfigDialog(ProductModel product, [CreatePurchaseItemModel? existingItem]) {
    final isDark = Provider.of<ThemeProvider>(context, listen: false).isDarkMode;
    final isWeighed = product.isWeighable;

    // State variables
    String unitType = (existingItem != null && existingItem.unit == (product.parentUnit ?? 'كرتونة')) ? 'carton' : 'piece';
    double qty = existingItem?.quantity ?? (isWeighed ? 1.0 : 1.0);
    double cost = existingItem?.unitCost ?? (product.purchasePrice > 0 ? product.purchasePrice : product.sellingPrice * 0.8);
    int factor = existingItem?.conversionFactor ?? (product.conversionFactor > 1 ? product.conversionFactor : 1);
    DateTime? expiryDate = existingItem?.expiryDate ?? DateTime.now().add(Duration(days: product.shelfLifeDays > 0 ? product.shelfLifeDays : 365));
    String batch = existingItem?.batchNumber ?? '';

    final qtyCtrl = TextEditingController(text: isWeighed ? qty.toStringAsFixed(3) : qty.toStringAsFixed(0));
    final costCtrl = TextEditingController(text: cost.toStringAsFixed(2));
    final factorCtrl = TextEditingController(text: factor.toString());
    final batchCtrl = TextEditingController(text: batch);

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.getSurface(isDark),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(22)),
      ),
      builder: (ctx) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            final currentQty = double.tryParse(qtyCtrl.text) ?? 0.0;
            final currentCost = double.tryParse(costCtrl.text) ?? 0.0;
            final currentFactor = int.tryParse(factorCtrl.text) ?? 1;
            final itemTotal = currentQty * currentCost;
            final pieceCost = (unitType == 'carton' && currentFactor > 0) ? (currentCost / currentFactor) : currentCost;
            final totalPieces = (unitType == 'carton') ? (currentQty * currentFactor) : currentQty;

            int daysLeft = 0;
            if (expiryDate != null) {
              daysLeft = expiryDate!.difference(DateTime.now()).inDays;
            }

            return Padding(
              padding: EdgeInsets.only(
                bottom: MediaQuery.of(context).viewInsets.bottom,
                top: 16,
                left: 16,
                right: 16,
              ),
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Header
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: isWeighed ? AppColors.cyan.withOpacity(0.15) : AppColors.primary.withOpacity(0.15),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Icon(
                            isWeighed ? Icons.scale_rounded : Icons.all_inbox_rounded,
                            color: isWeighed ? AppColors.cyan : AppColors.primaryLight,
                            size: 24,
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                product.nameAr,
                                style: TextStyle(color: AppColors.getTextPrimary(isDark), fontWeight: FontWeight.bold, fontSize: 16),
                              ),
                              Text(
                                isWeighed ? "صنف بالوزن (كجم)" : "صنف عادي (${product.baseUnit})",
                                style: TextStyle(color: isWeighed ? AppColors.cyan : AppColors.primaryLight, fontSize: 12, fontWeight: FontWeight.w600),
                              ),
                            ],
                          ),
                        ),
                        IconButton(
                          icon: Icon(Icons.close, color: AppColors.getTextSecondary(isDark)),
                          onPressed: () => Navigator.pop(ctx),
                        ),
                      ],
                    ),
                    const Divider(height: 20),

                    // WEIGHED PRODUCT SECTION
                    if (isWeighed) ...[
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: AppColors.cyan.withOpacity(0.08),
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(color: AppColors.cyan.withOpacity(0.3)),
                        ),
                        child: Row(
                          children: [
                            const Icon(Icons.scale_rounded, color: AppColors.cyan, size: 20),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                "توريد بالكيلوجرام (كجم): أدخل الوزن بدقة حتى 3 خانات عشرية",
                                style: const TextStyle(color: AppColors.cyan, fontSize: 12, fontWeight: FontWeight.w600),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 12),

                      // Weight Input
                      Text("الوزن المورّد (كجم) *", style: TextStyle(color: AppColors.getTextSecondary(isDark), fontSize: 13, fontWeight: FontWeight.w600)),
                      const SizedBox(height: 6),
                      TextField(
                        controller: qtyCtrl,
                        keyboardType: const TextInputType.numberWithOptions(decimal: true),
                        style: TextStyle(color: AppColors.getTextPrimary(isDark), fontWeight: FontWeight.bold, fontSize: 16),
                        decoration: InputDecoration(
                          hintText: "مثلاً: 12.500",
                          suffixText: "كجم",
                          filled: true,
                          fillColor: AppColors.getBackground(isDark),
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: AppColors.cyan)),
                        ),
                        onChanged: (_) => setDialogState(() {}),
                      ),
                      const SizedBox(height: 8),

                      // Quick Weight Buttons (+1kg, +5kg, +10kg, +25kg)
                      Wrap(
                        spacing: 8,
                        runSpacing: 6,
                        children: [
                          _buildQuickWeightButton("+1 كجم", 1.0, qtyCtrl, setDialogState),
                          _buildQuickWeightButton("+5 كجم", 5.0, qtyCtrl, setDialogState),
                          _buildQuickWeightButton("+10 كجم", 10.0, qtyCtrl, setDialogState),
                          _buildQuickWeightButton("+25 كجم (شيكارة)", 25.0, qtyCtrl, setDialogState),
                        ],
                      ),
                      const SizedBox(height: 12),

                      // Price per Kg
                      Text("سعر شراء الكيلو (ج.م / كجم) *", style: TextStyle(color: AppColors.getTextSecondary(isDark), fontSize: 13, fontWeight: FontWeight.w600)),
                      const SizedBox(height: 6),
                      TextField(
                        controller: costCtrl,
                        keyboardType: const TextInputType.numberWithOptions(decimal: true),
                        style: TextStyle(color: AppColors.getTextPrimary(isDark), fontWeight: FontWeight.bold, fontSize: 16),
                        decoration: InputDecoration(
                          hintText: "0.00",
                          suffixText: "ج.م / كجم",
                          filled: true,
                          fillColor: AppColors.getBackground(isDark),
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                        ),
                        onChanged: (_) => setDialogState(() {}),
                      ),
                    ] else ...[
                      // REGULAR PRODUCT SECTION (Piece vs Carton)
                      Text("نوع وحدة التوريد *", style: TextStyle(color: AppColors.getTextSecondary(isDark), fontSize: 13, fontWeight: FontWeight.w600)),
                      const SizedBox(height: 6),
                      Row(
                        children: [
                          Expanded(
                            child: InkWell(
                              onTap: () {
                                setDialogState(() {
                                  unitType = 'piece';
                                });
                              },
                              child: Container(
                                padding: const EdgeInsets.symmetric(vertical: 10),
                                decoration: BoxDecoration(
                                  color: unitType == 'piece' ? AppColors.primary.withOpacity(0.18) : AppColors.getBackground(isDark),
                                  borderRadius: BorderRadius.circular(10),
                                  border: Border.all(color: unitType == 'piece' ? AppColors.primaryLight : AppColors.getBorder(isDark), width: 1.5),
                                ),
                                alignment: Alignment.center,
                                child: Text(
                                  "بالقطعة (${product.baseUnit})",
                                  style: TextStyle(
                                    color: unitType == 'piece' ? AppColors.primaryLight : AppColors.getTextSecondary(isDark),
                                    fontWeight: unitType == 'piece' ? FontWeight.bold : FontWeight.normal,
                                    fontSize: 13,
                                  ),
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: InkWell(
                              onTap: () {
                                setDialogState(() {
                                  unitType = 'carton';
                                });
                              },
                              child: Container(
                                padding: const EdgeInsets.symmetric(vertical: 10),
                                decoration: BoxDecoration(
                                  color: unitType == 'carton' ? AppColors.accent.withOpacity(0.18) : AppColors.getBackground(isDark),
                                  borderRadius: BorderRadius.circular(10),
                                  border: Border.all(color: unitType == 'carton' ? AppColors.accent : AppColors.getBorder(isDark), width: 1.5),
                                ),
                                alignment: Alignment.center,
                                child: Text(
                                  "بالكرتونة (${product.parentUnit ?? 'كرتونة'})",
                                  style: TextStyle(
                                    color: unitType == 'carton' ? AppColors.accent : AppColors.getTextSecondary(isDark),
                                    fontWeight: unitType == 'carton' ? FontWeight.bold : FontWeight.normal,
                                    fontSize: 13,
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),

                      if (unitType == 'carton') ...[
                        Row(
                          children: [
                            Expanded(
                              flex: 2,
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text("عدد الكراتين *", style: TextStyle(color: AppColors.getTextSecondary(isDark), fontSize: 12, fontWeight: FontWeight.w600)),
                                  const SizedBox(height: 4),
                                  TextField(
                                    controller: qtyCtrl,
                                    keyboardType: TextInputType.number,
                                    style: TextStyle(color: AppColors.getTextPrimary(isDark), fontWeight: FontWeight.bold),
                                    decoration: InputDecoration(
                                      suffixText: product.parentUnit ?? 'كرتونة',
                                      filled: true,
                                      fillColor: AppColors.getBackground(isDark),
                                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                                    ),
                                    onChanged: (_) => setDialogState(() {}),
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
                                  Text("قطع الكرتونة *", style: TextStyle(color: AppColors.getTextSecondary(isDark), fontSize: 12, fontWeight: FontWeight.w600)),
                                  const SizedBox(height: 4),
                                  TextField(
                                    controller: factorCtrl,
                                    keyboardType: TextInputType.number,
                                    style: TextStyle(color: AppColors.getTextPrimary(isDark), fontWeight: FontWeight.bold),
                                    decoration: InputDecoration(
                                      suffixText: "قطعة",
                                      filled: true,
                                      fillColor: AppColors.getBackground(isDark),
                                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                                    ),
                                    onChanged: (_) => setDialogState(() {}),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        Text("سعر شراء الكرتونة (ج.م) *", style: TextStyle(color: AppColors.getTextSecondary(isDark), fontSize: 12, fontWeight: FontWeight.w600)),
                        const SizedBox(height: 4),
                        TextField(
                          controller: costCtrl,
                          keyboardType: const TextInputType.numberWithOptions(decimal: true),
                          style: TextStyle(color: AppColors.getTextPrimary(isDark), fontWeight: FontWeight.bold),
                          decoration: InputDecoration(
                            hintText: "0.00",
                            suffixText: "ج.م / كرتونة",
                            filled: true,
                            fillColor: AppColors.getBackground(isDark),
                            border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                          ),
                          onChanged: (_) => setDialogState(() {}),
                        ),
                        const SizedBox(height: 8),

                        // Carton Calculation Banner
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                          decoration: BoxDecoration(
                            color: Colors.blue.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: Colors.blue.withOpacity(0.3)),
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                "تكلفة القطعة المحسوبة: ${pieceCost.toStringAsFixed(2)} ج.م",
                                style: const TextStyle(color: Colors.lightBlueAccent, fontWeight: FontWeight.bold, fontSize: 12),
                              ),
                              Text(
                                "يضاف للمخزن: ${totalPieces.toStringAsFixed(0)} ${product.baseUnit}",
                                style: TextStyle(color: AppColors.getTextSecondary(isDark), fontSize: 12),
                              ),
                            ],
                          ),
                        ),
                      ] else ...[
                        // Piece
                        Row(
                          children: [
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text("الكمية (${product.baseUnit}) *", style: TextStyle(color: AppColors.getTextSecondary(isDark), fontSize: 12, fontWeight: FontWeight.w600)),
                                  const SizedBox(height: 4),
                                  TextField(
                                    controller: qtyCtrl,
                                    keyboardType: TextInputType.number,
                                    style: TextStyle(color: AppColors.getTextPrimary(isDark), fontWeight: FontWeight.bold),
                                    decoration: InputDecoration(
                                      suffixText: product.baseUnit,
                                      filled: true,
                                      fillColor: AppColors.getBackground(isDark),
                                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                                    ),
                                    onChanged: (_) => setDialogState(() {}),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text("سعر شراء القطعة (ج.م) *", style: TextStyle(color: AppColors.getTextSecondary(isDark), fontSize: 12, fontWeight: FontWeight.w600)),
                                  const SizedBox(height: 4),
                                  TextField(
                                    controller: costCtrl,
                                    keyboardType: const TextInputType.numberWithOptions(decimal: true),
                                    style: TextStyle(color: AppColors.getTextPrimary(isDark), fontWeight: FontWeight.bold),
                                    decoration: InputDecoration(
                                      suffixText: "ج.م",
                                      filled: true,
                                      fillColor: AppColors.getBackground(isDark),
                                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                                    ),
                                    onChanged: (_) => setDialogState(() {}),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ],
                    ],

                    // EXPIRY TRACKING SECTION
                    if (product.trackExpiry) ...[
                      const SizedBox(height: 14),
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: AppColors.warning.withOpacity(0.08),
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(color: AppColors.warning.withOpacity(0.3)),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                const Icon(Icons.timelapse_rounded, color: AppColors.warning, size: 18),
                                const SizedBox(width: 6),
                                const Text("تتبع الصلاحية وتاريخ الانتهاء", style: TextStyle(color: AppColors.warning, fontWeight: FontWeight.bold, fontSize: 13)),
                              ],
                            ),
                            const SizedBox(height: 10),
                            Row(
                              children: [
                                Expanded(
                                  child: OutlinedButton.icon(
                                    style: OutlinedButton.styleFrom(
                                      padding: const EdgeInsets.symmetric(vertical: 8),
                                      side: BorderSide(color: AppColors.getBorder(isDark)),
                                    ),
                                    icon: const Icon(Icons.calendar_today_rounded, size: 16),
                                    label: Text(
                                      expiryDate != null ? DateFormat('dd/MM/yyyy').format(expiryDate!) : "تاريخ الانتهاء",
                                      style: TextStyle(fontSize: 12, color: AppColors.getTextPrimary(isDark)),
                                    ),
                                    onPressed: () async {
                                      final picked = await showDatePicker(
                                        context: context,
                                        initialDate: expiryDate ?? DateTime.now().add(const Duration(days: 30)),
                                        firstDate: DateTime(2020),
                                        lastDate: DateTime(2035),
                                      );
                                      if (picked != null) {
                                        setDialogState(() => expiryDate = picked);
                                      }
                                    },
                                  ),
                                ),
                                const SizedBox(width: 10),
                                Expanded(
                                  child: TextField(
                                    controller: batchCtrl,
                                    style: TextStyle(color: AppColors.getTextPrimary(isDark), fontSize: 13),
                                    decoration: InputDecoration(
                                      hintText: "رقم التشغيلة (Batch)",
                                      hintStyle: TextStyle(color: AppColors.getTextMuted(isDark), fontSize: 11),
                                      contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            if (expiryDate != null) ...[
                              const SizedBox(height: 6),
                              Row(
                                children: [
                                  Icon(daysLeft <= 0 ? Icons.error_outline : Icons.check_circle_outline, size: 14, color: daysLeft <= 0 ? AppColors.danger : AppColors.success),
                                  const SizedBox(width: 4),
                                  Text(
                                    daysLeft <= 0 ? "تنبيه: الصنف منتهي الصلاحية!" : "متبقي على الصلاحية: $daysLeft يوم",
                                    style: TextStyle(color: daysLeft <= 0 ? AppColors.danger : AppColors.success, fontWeight: FontWeight.bold, fontSize: 11),
                                  ),
                                ],
                              ),
                            ],
                          ],
                        ),
                      ),
                    ],

                    const SizedBox(height: 14),

                    // Live Total Banner
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                      decoration: BoxDecoration(
                        color: AppColors.getBackground(isDark),
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: AppColors.getBorder(isDark)),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text("إجمالي البند:", style: TextStyle(color: AppColors.getTextSecondary(isDark), fontSize: 13)),
                          Text(
                            "${itemTotal.toStringAsFixed(2)} ج.م",
                            style: const TextStyle(color: AppColors.accent, fontWeight: FontWeight.bold, fontSize: 16),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Add / Save Button
                    SizedBox(
                      width: double.infinity,
                      height: 46,
                      child: ElevatedButton.icon(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.primary,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                        icon: const Icon(Icons.add_circle_outline_rounded, color: Colors.white),
                        label: Text(
                          existingItem != null ? "تحديث البند في الفاتورة" : "إضافة البند إلى الفاتورة",
                          style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14),
                        ),
                        onPressed: () {
                          if (currentQty <= 0) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(content: Text("يرجى إدخال كمية أو وزن صحيح.")),
                            );
                            return;
                          }

                          setState(() {
                            if (existingItem != null) {
                              existingItem.quantity = currentQty;
                              existingItem.unitCost = currentCost;
                              existingItem.unit = isWeighed ? (product.baseUnit) : (unitType == 'carton' ? (product.parentUnit ?? 'كرتونة') : product.baseUnit);
                              existingItem.conversionFactor = currentFactor;
                              existingItem.isWeighable = isWeighed;
                              existingItem.expiryDate = expiryDate;
                              existingItem.batchNumber = batchCtrl.text.trim().isNotEmpty ? batchCtrl.text.trim() : null;
                            } else {
                              // Check if item already exists in items list
                              final idx = _items.indexWhere((i) => i.productId == product.id && i.unit == (isWeighed ? product.baseUnit : (unitType == 'carton' ? (product.parentUnit ?? 'كرتونة') : product.baseUnit)));
                              if (idx >= 0) {
                                _items[idx].quantity += currentQty;
                                _items[idx].unitCost = currentCost;
                              } else {
                                _items.add(CreatePurchaseItemModel(
                                  productId: product.id,
                                  productName: product.nameAr,
                                  barcode: product.barcode,
                                  quantity: currentQty,
                                  unitCost: currentCost,
                                  unit: isWeighed ? (product.baseUnit) : (unitType == 'carton' ? (product.parentUnit ?? 'كرتونة') : product.baseUnit),
                                  isWeighable: isWeighed,
                                  conversionFactor: currentFactor,
                                  parentUnit: product.parentUnit,
                                  baseUnit: product.baseUnit,
                                  shelfLifeDays: product.shelfLifeDays,
                                  expiryDate: expiryDate,
                                  batchNumber: batchCtrl.text.trim().isNotEmpty ? batchCtrl.text.trim() : null,
                                ));
                              }
                            }
                          });

                          Navigator.pop(ctx);
                        },
                      ),
                    ),
                    const SizedBox(height: 16),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildQuickWeightButton(String label, double addWeight, TextEditingController qtyCtrl, StateSetter setDialogState) {
    return ActionChip(
      label: Text(label, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: AppColors.cyan)),
      backgroundColor: AppColors.cyan.withOpacity(0.12),
      side: BorderSide(color: AppColors.cyan.withOpacity(0.4)),
      onPressed: () {
        final current = double.tryParse(qtyCtrl.text) ?? 0.0;
        setDialogState(() {
          qtyCtrl.text = (current + addWeight).toStringAsFixed(3);
        });
      },
    );
  }

  void _submitInvoice() async {
    if (!_formKey.currentState!.validate()) return;

    if (_selectedSupplier == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("يرجى اختيار المورد أولاً."),
          backgroundColor: AppColors.syncFailed,
        ),
      );
      return;
    }

    if (_items.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("يجب إضافة صنف واحد على الأقل في الفاتورة."),
          backgroundColor: AppColors.syncFailed,
        ),
      );
      return;
    }

    final purchaseModel = CreatePurchaseModel(
      invoiceNumber: _invoiceNumController.text.trim(),
      internalNumber: _internalNumController.text.trim().isNotEmpty ? _internalNumController.text.trim() : null,
      supplierId: _selectedSupplier!.id,
      purchaseDate: _purchaseDate,
      discountAmount: _discount,
      taxAmount: _tax,
      paidAmount: _paid,
      paymentMethod: _paymentMethod,
      notes: _notesController.text.trim(),
      items: _items,
    );

    final provider = Provider.of<PurchasesProvider>(context, listen: false);
    final success = await provider.createPurchase(purchaseModel);

    if (success && mounted) {
      final isDark = Provider.of<ThemeProvider>(context, listen: false).isDarkMode;
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (ctx) => AlertDialog(
          backgroundColor: AppColors.getSurface(isDark),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.check_circle_rounded, color: AppColors.synced, size: 64),
              const SizedBox(height: 14),
              Text(
                "تم حفظ الفاتورة بنجاح!",
                style: TextStyle(color: AppColors.getTextPrimary(isDark), fontWeight: FontWeight.bold, fontSize: 18),
              ),
              const SizedBox(height: 8),
              Text(
                "حالة الفاتورة الآن [قيد المزامنة ⏳].\nستظهر في كاشير الديسك توب فورياً وتحدث رصيد المخزن والمورد.",
                textAlign: TextAlign.center,
                style: TextStyle(color: AppColors.getTextSecondary(isDark), fontSize: 13, height: 1.4),
              ),
            ],
          ),
          actions: [
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                minimumSize: const Size(double.infinity, 44),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              ),
              onPressed: () {
                Navigator.pop(ctx);
                Navigator.pop(context);
              },
              child: const Text("تم", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
            ),
          ],
        ),
      );
    } else if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(provider.errorMessage ?? "فشل حفظ الفاتورة."),
          backgroundColor: AppColors.syncFailed,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Provider.of<ThemeProvider>(context).isDarkMode;
    final supProv = Provider.of<SuppliersProvider>(context);
    final purchasesProv = Provider.of<PurchasesProvider>(context);
    final currencyFormatter = NumberFormat("#,##0.00", "ar_EG");

    return Scaffold(
      backgroundColor: AppColors.getBackground(isDark),
      appBar: AppBar(
        backgroundColor: AppColors.getSurface(isDark),
        elevation: 0,
        title: Text(
          "تسجيل فاتورة شراء جديدة",
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: AppColors.getTextPrimary(isDark)),
        ),
      ),
      body: Column(
        children: [
          const OfflineBanner(),
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Invoice Header Card
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: AppColors.getSurface(isDark),
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(color: AppColors.getBorder(isDark)),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              const Icon(Icons.receipt_long_rounded, color: AppColors.primaryLight, size: 20),
                              const SizedBox(width: 8),
                              Text("بيانات الفاتورة الأساسية", style: TextStyle(color: AppColors.getTextPrimary(isDark), fontWeight: FontWeight.bold, fontSize: 14)),
                            ],
                          ),
                          const SizedBox(height: 12),

                          // Row 1: Invoice Number & Date Picker
                          Row(
                            children: [
                              Expanded(
                                flex: 3,
                                child: CustomTextField(
                                  controller: _invoiceNumController,
                                  label: "رقم الفاتورة *",
                                  prefixIcon: Icons.tag_rounded,
                                  validator: (val) => (val == null || val.trim().isEmpty) ? "رقم الفاتورة مطلوب" : null,
                                ),
                              ),
                              const SizedBox(width: 10),
                              Expanded(
                                flex: 2,
                                child: InkWell(
                                  onTap: () => _pickPurchaseDate(context, isDark),
                                  borderRadius: BorderRadius.circular(12),
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 14),
                                    decoration: BoxDecoration(
                                      color: isDark ? AppColors.darkSurfaceElevated : AppColors.lightSurfaceElevated,
                                      borderRadius: BorderRadius.circular(12),
                                      border: Border.all(color: AppColors.getBorder(isDark)),
                                    ),
                                    child: Row(
                                      children: [
                                        const Icon(Icons.calendar_today_rounded, size: 16, color: AppColors.primaryLight),
                                        const SizedBox(width: 6),
                                        Expanded(
                                          child: Text(
                                            DateFormat('dd/MM/yyyy').format(_purchaseDate),
                                            style: TextStyle(color: AppColors.getTextPrimary(isDark), fontSize: 12, fontWeight: FontWeight.w600),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),

                          // Supplier Selector Dropdown with Add Button
                          Text("المورد *", style: TextStyle(color: AppColors.getTextSecondary(isDark), fontWeight: FontWeight.w600, fontSize: 13)),
                          const SizedBox(height: 6),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 12),
                            decoration: BoxDecoration(
                              color: isDark ? AppColors.darkSurfaceElevated : AppColors.lightSurfaceElevated,
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(color: AppColors.getBorder(isDark)),
                            ),
                            child: Row(
                              children: [
                                const Icon(Icons.people_alt_outlined, color: AppColors.primaryLight, size: 20),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: DropdownButtonHideUnderline(
                                    child: DropdownButton<SupplierModel>(
                                      value: _selectedSupplier,
                                      hint: Text("اختر المورد...", style: TextStyle(color: AppColors.getTextMuted(isDark), fontSize: 14)),
                                      dropdownColor: AppColors.getSurface(isDark),
                                      isExpanded: true,
                                      items: supProv.suppliers.map((s) {
                                        return DropdownMenuItem<SupplierModel>(
                                          value: s,
                                          child: Text(
                                            "${s.name} ${s.contactPerson != null ? '(${s.contactPerson})' : ''}",
                                            style: TextStyle(color: AppColors.getTextPrimary(isDark), fontSize: 14),
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                        );
                                      }).toList(),
                                      onChanged: (val) {
                                        setState(() => _selectedSupplier = val);
                                      },
                                    ),
                                  ),
                                ),
                                IconButton(
                                  icon: const Icon(Icons.person_add_alt_1_rounded, color: AppColors.success, size: 22),
                                  tooltip: "إضافة مورد جديد",
                                  onPressed: () async {
                                    final newSupplier = await showAddSupplierDialog(context);
                                    if (newSupplier != null) {
                                      setState(() => _selectedSupplier = newSupplier);
                                    }
                                  },
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 12),

                          // Payment Method Dropdown
                          Text("طريقة السداد", style: TextStyle(color: AppColors.getTextSecondary(isDark), fontWeight: FontWeight.w600, fontSize: 13)),
                          const SizedBox(height: 6),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 12),
                            decoration: BoxDecoration(
                              color: isDark ? AppColors.darkSurfaceElevated : AppColors.lightSurfaceElevated,
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(color: AppColors.getBorder(isDark)),
                            ),
                            child: DropdownButtonHideUnderline(
                              child: DropdownButton<int>(
                                value: _paymentMethod,
                                dropdownColor: AppColors.getSurface(isDark),
                                isExpanded: true,
                                items: [
                                  DropdownMenuItem(value: 1, child: Text("نقدي (كاش)", style: TextStyle(color: AppColors.getTextPrimary(isDark)))),
                                  DropdownMenuItem(value: 2, child: Text("بطاقة بنكية", style: TextStyle(color: AppColors.getTextPrimary(isDark)))),
                                  DropdownMenuItem(value: 3, child: Text("محفظة إلكترونية", style: TextStyle(color: AppColors.getTextPrimary(isDark)))),
                                  DropdownMenuItem(value: 4, child: Text("آجل (ذمم)", style: TextStyle(color: AppColors.getTextPrimary(isDark)))),
                                ],
                                onChanged: (val) {
                                  if (val != null) setState(() => _paymentMethod = val);
                                },
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Metrics Summary Separating Regular and Weighed Items
                    if (_items.isNotEmpty)
                      SingleChildScrollView(
                        scrollDirection: Axis.horizontal,
                        child: Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                              decoration: BoxDecoration(
                                color: AppColors.primary.withOpacity(0.12),
                                borderRadius: BorderRadius.circular(10),
                                border: Border.all(color: AppColors.primary.withOpacity(0.3)),
                              ),
                              child: Row(
                                children: [
                                  const Icon(Icons.inventory_2_rounded, size: 16, color: AppColors.primaryLight),
                                  const SizedBox(width: 6),
                                  Text(
                                    "أصناف عادية: $_regularItemsCount صنف (${currencyFormatter.format(_regularItemsTotal)} ج.م)",
                                    style: const TextStyle(color: AppColors.primaryLight, fontWeight: FontWeight.bold, fontSize: 12),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(width: 8),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                              decoration: BoxDecoration(
                                color: AppColors.cyan.withOpacity(0.12),
                                borderRadius: BorderRadius.circular(10),
                                border: Border.all(color: AppColors.cyan.withOpacity(0.3)),
                              ),
                              child: Row(
                                children: [
                                  const Icon(Icons.scale_rounded, size: 16, color: AppColors.cyan),
                                  const SizedBox(width: 6),
                                  Text(
                                    "أصناف بالوزن: $_weighedItemsCount صنف — ${_totalWeighedKg.toStringAsFixed(3)} كجم (${currencyFormatter.format(_weighedItemsTotal)} ج.م)",
                                    style: const TextStyle(color: AppColors.cyan, fontWeight: FontWeight.bold, fontSize: 12),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    if (_items.isNotEmpty) const SizedBox(height: 12),

                    // Items Section
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: AppColors.getSurface(isDark),
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(color: AppColors.getBorder(isDark)),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Wrap(
                            alignment: WrapAlignment.spaceBetween,
                            crossAxisAlignment: WrapCrossAlignment.center,
                            spacing: 8,
                            runSpacing: 8,
                            children: [
                              Text(
                                "أصناف الفاتورة (${_items.length})",
                                style: TextStyle(color: AppColors.getTextPrimary(isDark), fontWeight: FontWeight.bold, fontSize: 14),
                              ),
                              Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  ElevatedButton.icon(
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: AppColors.cyan,
                                      foregroundColor: Colors.white,
                                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 7),
                                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                                    ),
                                    icon: const Icon(Icons.qr_code_scanner_rounded, size: 15),
                                    label: const Text("مسح بالكاميرا", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 11)),
                                    onPressed: _scanBarcodeAndAddProduct,
                                  ),
                                  const SizedBox(width: 6),
                                  ElevatedButton.icon(
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: AppColors.primary,
                                      foregroundColor: Colors.white,
                                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
                                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                                    ),
                                    icon: const Icon(Icons.add, size: 15),
                                    label: const Text("إضافة صنف", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 11)),
                                    onPressed: _openProductPicker,
                                  ),
                                ],
                              ),
                            ],
                          ),
                          const Divider(height: 20),

                          if (_items.isEmpty)
                            Padding(
                              padding: const EdgeInsets.symmetric(vertical: 24),
                              child: Center(
                                child: Text(
                                  "لم تتم إضافة أصناف بعد.\nاضغط 'إضافة صنف' لاختيار الأصناف بالوزن أو بالكرتونة والقطعة.",
                                  textAlign: TextAlign.center,
                                  style: TextStyle(color: AppColors.getTextMuted(isDark), height: 1.5, fontSize: 13),
                                ),
                              ),
                            )
                          else
                            ListView.separated(
                              shrinkWrap: true,
                              physics: const NeverScrollableScrollPhysics(),
                              itemCount: _items.length,
                              separatorBuilder: (_, __) => Divider(color: AppColors.getBorder(isDark), height: 16),
                              itemBuilder: (ctx, idx) {
                                final item = _items[idx];
                                return Container(
                                  padding: const EdgeInsets.all(10),
                                  decoration: BoxDecoration(
                                    color: item.isWeighable ? AppColors.cyan.withOpacity(0.04) : Colors.transparent,
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Row(
                                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                        children: [
                                          Container(
                                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                            decoration: BoxDecoration(
                                              color: item.isWeighable ? AppColors.cyan.withOpacity(0.15) : AppColors.primary.withOpacity(0.15),
                                              borderRadius: BorderRadius.circular(4),
                                            ),
                                            child: Text(
                                              item.isWeighable ? "⚖️ بالوزن" : "📦 عادي",
                                              style: TextStyle(color: item.isWeighable ? AppColors.cyan : AppColors.primaryLight, fontSize: 10, fontWeight: FontWeight.bold),
                                            ),
                                          ),
                                          const SizedBox(width: 8),
                                          Expanded(
                                            child: Text(
                                              item.productName,
                                              style: TextStyle(color: AppColors.getTextPrimary(isDark), fontWeight: FontWeight.bold, fontSize: 14),
                                            ),
                                          ),
                                          IconButton(
                                            icon: const Icon(Icons.delete_outline_rounded, color: AppColors.danger, size: 20),
                                            tooltip: "حذف البند",
                                            onPressed: () {
                                              setState(() => _items.removeAt(idx));
                                            },
                                          ),
                                        ],
                                      ),
                                      const SizedBox(height: 6),
                                       Row(
                                         children: [
                                           Expanded(
                                             flex: 4,
                                             child: Text(
                                               item.isWeighable
                                                   ? "${item.quantity.toStringAsFixed(3)} ${item.unit ?? 'كجم'}"
                                                   : "${item.quantity.toStringAsFixed(0)} ${item.unit ?? 'قطعة'}",
                                               style: TextStyle(color: item.isWeighable ? AppColors.cyan : AppColors.getTextPrimary(isDark), fontWeight: FontWeight.bold, fontSize: 13),
                                               overflow: TextOverflow.ellipsis,
                                             ),
                                           ),
                                           Expanded(
                                             flex: 4,
                                             child: Text(
                                               "سعر: ${item.unitCost.toStringAsFixed(2)} ج.م",
                                               textAlign: TextAlign.center,
                                               style: TextStyle(color: AppColors.getTextSecondary(isDark), fontSize: 12),
                                               overflow: TextOverflow.ellipsis,
                                             ),
                                           ),
                                           Expanded(
                                             flex: 4,
                                             child: Text(
                                               "${currencyFormatter.format(item.total)} ج.م",
                                               textAlign: TextAlign.end,
                                               style: const TextStyle(color: AppColors.success, fontWeight: FontWeight.bold, fontSize: 13),
                                               overflow: TextOverflow.ellipsis,
                                            ),
                                          ),
                                        ],
                                      ),
                                      if (item.expiryDate != null) ...[
                                        const SizedBox(height: 4),
                                        Row(
                                          children: [
                                            const Icon(Icons.timelapse_rounded, size: 12, color: AppColors.warning),
                                            const SizedBox(width: 4),
                                            Text(
                                              "الصلاحية: ${DateFormat('dd/MM/yyyy').format(item.expiryDate!)}${item.batchNumber != null ? ' (تشغيلة: ${item.batchNumber})' : ''}",
                                              style: TextStyle(color: AppColors.getTextMuted(isDark), fontSize: 11),
                                            ),
                                          ],
                                        ),
                                      ],
                                    ],
                                  ),
                                );
                              },
                            ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Financial Summary Card with Quick Payment Buttons
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: AppColors.getSurface(isDark),
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(color: AppColors.getBorder(isDark)),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              const Icon(Icons.calculate_rounded, color: AppColors.accent, size: 20),
                              const SizedBox(width: 8),
                              Text("ملخص الحساب والمدفوعات", style: TextStyle(color: AppColors.getTextPrimary(isDark), fontWeight: FontWeight.bold, fontSize: 14)),
                            ],
                          ),
                          const Divider(height: 20),

                          // Discount and Tax
                          Row(
                            children: [
                              Expanded(
                                child: TextFormField(
                                  controller: _discountController,
                                  style: TextStyle(color: AppColors.getTextPrimary(isDark), fontSize: 14),
                                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                                  decoration: InputDecoration(
                                    labelText: "الخصم",
                                    labelStyle: TextStyle(color: AppColors.getTextSecondary(isDark)),
                                    filled: true,
                                    fillColor: AppColors.getBackground(isDark),
                                    contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                                  ),
                                  onChanged: (_) => setState(() {}),
                                ),
                              ),
                              const SizedBox(width: 10),
                              Expanded(
                                child: TextFormField(
                                  controller: _taxController,
                                  style: TextStyle(color: AppColors.getTextPrimary(isDark), fontSize: 14),
                                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                                  decoration: InputDecoration(
                                    labelText: "الضريبة",
                                    labelStyle: TextStyle(color: AppColors.getTextSecondary(isDark)),
                                    filled: true,
                                    fillColor: AppColors.getBackground(isDark),
                                    contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                                  ),
                                  onChanged: (_) => setState(() {}),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),

                          // Quick Pay Buttons (سداد كامل نقدًا / آجل 0)
                          Wrap(
                            alignment: WrapAlignment.spaceBetween,
                            crossAxisAlignment: WrapCrossAlignment.center,
                            spacing: 8,
                            runSpacing: 6,
                            children: [
                              Text("المبلغ المدفوع للمورد (ج.م) *", style: TextStyle(color: AppColors.getTextSecondary(isDark), fontSize: 12, fontWeight: FontWeight.w600)),
                              Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  InkWell(
                                    onTap: _setFullPayment,
                                    child: Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                      decoration: BoxDecoration(
                                        color: (_paid == _total && _total > 0) ? AppColors.success : AppColors.success.withOpacity(0.15),
                                        borderRadius: BorderRadius.circular(6),
                                      ),
                                      child: Text(
                                        "سداد كامل ✓",
                                        style: TextStyle(
                                          color: (_paid == _total && _total > 0) ? Colors.white : AppColors.success,
                                          fontSize: 11,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 6),
                                  InkWell(
                                    onTap: _setZeroPayment,
                                    child: Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                      decoration: BoxDecoration(
                                        color: _paid == 0 ? AppColors.danger : AppColors.danger.withOpacity(0.15),
                                        borderRadius: BorderRadius.circular(6),
                                      ),
                                      child: Text(
                                        "آجل (0)",
                                        style: TextStyle(
                                          color: _paid == 0 ? Colors.white : AppColors.danger,
                                          fontSize: 11,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                          const SizedBox(height: 6),
                          TextFormField(
                            controller: _paidController,
                            style: const TextStyle(color: AppColors.success, fontSize: 16, fontWeight: FontWeight.bold),
                            keyboardType: const TextInputType.numberWithOptions(decimal: true),
                            decoration: InputDecoration(
                              hintText: "0.00",
                              filled: true,
                              fillColor: AppColors.getBackground(isDark),
                              contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                              border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                            ),
                            onChanged: (_) => setState(() {}),
                          ),
                          const SizedBox(height: 12),

                          CustomTextField(
                            controller: _notesController,
                            label: "ملاحظات الفاتورة",
                            hint: "أي تفاصيل أو ملاحظات...",
                            maxLines: 2,
                          ),
                          const Divider(height: 24),

                          // Calculation Summary Rows
                          _buildSummaryRow(isDark, "المجموع الفرعي:", "${currencyFormatter.format(_subTotal)} ج.م"),
                          if (_discount > 0) _buildSummaryRow(isDark, "الخصم:", "- ${currencyFormatter.format(_discount)} ج.م", color: AppColors.danger),
                          if (_tax > 0) _buildSummaryRow(isDark, "الضريبة:", "+ ${currencyFormatter.format(_tax)} ج.م"),
                          const Divider(height: 16),
                          _buildSummaryRow(isDark, "إجمالي الفاتورة المطلوب:", "${currencyFormatter.format(_total)} ج.م", isBold: true, color: AppColors.accent, fontSize: 16),
                          _buildSummaryRow(isDark, "المدفوع كاش:", "${currencyFormatter.format(_paid)} ج.م", color: AppColors.success),
                          _buildSummaryRow(
                            isDark,
                            "المتبقي (مديونية):",
                            "${currencyFormatter.format(_remaining)} ج.م",
                            isBold: true,
                            color: _remaining > 0 ? AppColors.danger : AppColors.success,
                            fontSize: 15,
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 24),

                    // Submit Button
                    CustomButton(
                      text: "حفظ الفاتورة ومزامنتها سحابياً 🚀",
                      icon: Icons.cloud_upload_rounded,
                      isLoading: purchasesProv.isCreating,
                      onPressed: _submitInvoice,
                    ),
                    const SizedBox(height: 30),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryRow(bool isDark, String label, String value, {bool isBold = false, Color? color, double fontSize = 13}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(
            child: Text(
              label,
              style: TextStyle(
                color: isBold ? AppColors.getTextPrimary(isDark) : AppColors.getTextSecondary(isDark),
                fontWeight: isBold ? FontWeight.bold : FontWeight.normal,
                fontSize: isBold ? 14 : 13,
              ),
            ),
          ),
          Text(
            value,
            style: TextStyle(
              color: color ?? AppColors.getTextPrimary(isDark),
              fontWeight: isBold ? FontWeight.bold : FontWeight.w600,
              fontSize: fontSize,
            ),
          ),
        ],
      ),
    );
  }
}
