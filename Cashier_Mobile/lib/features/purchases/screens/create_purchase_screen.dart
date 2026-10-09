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
import '../../auth/providers/auth_provider.dart';

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

  // Total pieces count for appliances
  int get _totalPieces => _items.fold(0, (sum, i) => sum + i.quantity.toInt());

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
        (p) => p.barcode.trim().toLowerCase() == clean,
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
                                  "اختر الجهاز لإضافته إلى الفاتورة",
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
                        hintText: "ابحث بالاسم، الموديل أو الباركود...",
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
                    const SizedBox(height: 12),

                    // Products list
                    Expanded(
                      child: Consumer<ProductsProvider>(
                        builder: (context, prov, child) {
                          if (prov.isLoading) {
                            return const Center(child: CircularProgressIndicator(color: AppColors.primaryLight));
                          }

                          final filtered = prov.products;

                          if (filtered.isEmpty) {
                            return Center(
                              child: Text("لا توجد أجهزة مطابقة للبحث.", style: TextStyle(color: AppColors.getTextMuted(isDark))),
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
                                      color: AppColors.primary.withOpacity(0.12),
                                      borderRadius: BorderRadius.circular(10),
                                    ),
                                    child: const Icon(
                                      Icons.inventory_2_outlined,
                                      color: AppColors.primaryLight,
                                      size: 22,
                                    ),
                                  ),
                                  title: Text(
                                    p.nameAr,
                                    style: TextStyle(color: AppColors.getTextPrimary(isDark), fontWeight: FontWeight.w600, fontSize: 14),
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                  subtitle: Wrap(
                                    spacing: 8,
                                    children: [
                                      Text(
                                        p.barcode,
                                        style: TextStyle(color: AppColors.getTextMuted(isDark), fontSize: 11, fontFamily: 'monospace'),
                                      ),
                                      Text(
                                        "شراء: ${p.purchasePrice > 0 ? p.purchasePrice.toStringAsFixed(2) : p.sellingPrice.toStringAsFixed(2)} ج.م",
                                        style: const TextStyle(color: AppColors.success, fontSize: 11, fontWeight: FontWeight.w600),
                                      ),
                                      if (p.modelNumber != null && p.modelNumber!.isNotEmpty)
                                        Text(
                                          "موديل: ${p.modelNumber}",
                                          style: TextStyle(color: AppColors.accent, fontSize: 11),
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

  // Item Configuration Dialog for Home Appliances
  void _openItemConfigDialog(ProductModel product, [CreatePurchaseItemModel? existingItem]) {
    final isDark = Provider.of<ThemeProvider>(context, listen: false).isDarkMode;

    double qty = existingItem?.quantity ?? 1.0;
    double cost = existingItem?.unitCost ?? (product.purchasePrice > 0 ? product.purchasePrice : product.sellingPrice * 0.8);
    final qtyCtrl = TextEditingController(text: qty.toInt().toString());
    final costCtrl = TextEditingController(text: cost.toStringAsFixed(2));

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
            final itemTotal = currentQty * currentCost;

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
                            color: AppColors.primary.withOpacity(0.15),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: const Icon(
                            Icons.all_inbox_rounded,
                            color: AppColors.primaryLight,
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
                                "جهاز كهربائي (${product.modelNumber ?? 'عام'}) - وحدة الصنف: قطعة",
                                style: const TextStyle(color: AppColors.primaryLight, fontSize: 12, fontWeight: FontWeight.w600),
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

                    // Quantity and Unit Price
                    Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text("الكمية المورّدة (قطعة) *", style: TextStyle(color: AppColors.getTextSecondary(isDark), fontSize: 12, fontWeight: FontWeight.w600)),
                              const SizedBox(height: 6),
                              TextField(
                                controller: qtyCtrl,
                                keyboardType: TextInputType.number,
                                style: TextStyle(color: AppColors.getTextPrimary(isDark), fontWeight: FontWeight.bold, fontSize: 16),
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
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text("سعر شراء القطعة (ج.م) *", style: TextStyle(color: AppColors.getTextSecondary(isDark), fontSize: 12, fontWeight: FontWeight.w600)),
                              const SizedBox(height: 6),
                              TextField(
                                controller: costCtrl,
                                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                                style: TextStyle(color: AppColors.getTextPrimary(isDark), fontWeight: FontWeight.bold, fontSize: 16),
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

                    if (product.hasSerialNumber) ...[
                      const SizedBox(height: 12),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                        decoration: BoxDecoration(
                          color: AppColors.primary.withOpacity(0.08),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: AppColors.primary.withOpacity(0.25)),
                        ),
                        child: const Row(
                          children: [
                            Icon(Icons.qr_code_2_rounded, size: 16, color: AppColors.primaryLight),
                            SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                "هذا الجهاز يدعم تتبع أرقام السيريال للضمان.",
                                style: TextStyle(color: AppColors.primaryLight, fontSize: 12, fontWeight: FontWeight.w600),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],

                    const SizedBox(height: 16),

                    // Live Total Banner
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                      decoration: BoxDecoration(
                        color: AppColors.getBackground(isDark),
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: AppColors.getBorder(isDark)),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text("إجمالي البند:", style: TextStyle(color: AppColors.getTextSecondary(isDark), fontSize: 13, fontWeight: FontWeight.bold)),
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
                      height: 48,
                      child: ElevatedButton.icon(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.primary,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                        icon: const Icon(Icons.add_circle_outline_rounded, color: Colors.white),
                        label: Text(
                          existingItem != null ? "تحديث البند في الفاتورة" : "إضافة الجهاز إلى الفاتورة",
                          style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14),
                        ),
                        onPressed: () {
                          if (currentQty <= 0) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(content: Text("يرجى إدخال كمية صحيحة.")),
                            );
                            return;
                          }

                          setState(() {
                            if (existingItem != null) {
                              existingItem.quantity = currentQty;
                              existingItem.unitCost = currentCost;
                              existingItem.unit = 'قطعة';
                              existingItem.conversionFactor = 1;
                              existingItem.isWeighable = false;
                            } else {
                              final idx = _items.indexWhere((i) => i.productId == product.id);
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
                                  unit: 'قطعة',
                                  isWeighable: false,
                                  conversionFactor: 1,
                                  parentUnit: 'قطعة',
                                  baseUnit: 'قطعة',
                                  shelfLifeDays: null,
                                  expiryDate: null,
                                  batchNumber: null,
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
      createdByName: Provider.of<AuthProvider>(context, listen: false).userName,
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
    final currencyFormatter = NumberFormat("#,##0.00", "en_US");

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

                    // Metrics Summary for Appliances Items
                    if (_items.isNotEmpty)
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                        decoration: BoxDecoration(
                          color: AppColors.primary.withOpacity(0.12),
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(color: AppColors.primary.withOpacity(0.3)),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(Icons.inventory_2_rounded, size: 16, color: AppColors.primaryLight),
                            const SizedBox(width: 8),
                            Text(
                              "إجمالي الأجهزة: $_totalPieces قطعة (${currencyFormatter.format(_subTotal)} ج.م)",
                              style: const TextStyle(color: AppColors.primaryLight, fontWeight: FontWeight.bold, fontSize: 12),
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
                                  "لم تتم إضافة أصناف بعد.\nاضغط 'إضافة صنف' لاختيار الأجهزة.",
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
                                    color: Colors.transparent,
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
                                              color: AppColors.primary.withOpacity(0.15),
                                              borderRadius: BorderRadius.circular(4),
                                            ),
                                            child: const Text(
                                              "📦 جهاز",
                                              style: TextStyle(color: AppColors.primaryLight, fontSize: 10, fontWeight: FontWeight.bold),
                                            ),
                                          ),
                                          const SizedBox(width: 8),
                                          Expanded(
                                            child: Text(
                                              item.productName,
                                              style: TextStyle(color: AppColors.getTextPrimary(isDark), fontWeight: FontWeight.bold, fontSize: 14),
                                              overflow: TextOverflow.ellipsis,
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
                                              "${item.quantity.toInt()} قطعة",
                                              style: TextStyle(color: AppColors.getTextPrimary(isDark), fontWeight: FontWeight.bold, fontSize: 13),
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
