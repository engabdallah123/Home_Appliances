import 'dart:math';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/theme/theme_provider.dart';
import '../../../core/widgets/custom_text_field.dart';
import '../../../core/widgets/camera_barcode_scanner.dart';
import '../models/product_model.dart';
import '../models/brand_model.dart';
import '../providers/products_provider.dart';
import 'brands_list_screen.dart';

class AddEditProductScreen extends StatefulWidget {
  final ProductModel? product; // null for add, non-null for edit

  const AddEditProductScreen({super.key, this.product});

  @override
  State<AddEditProductScreen> createState() => _AddEditProductScreenState();
}

class _AddEditProductScreenState extends State<AddEditProductScreen> {
  final _formKey = GlobalKey<FormState>();

  late TextEditingController _nameArCtrl;
  late TextEditingController _nameEnCtrl;
  late TextEditingController _barcodeCtrl;
  late TextEditingController _baseUnitCtrl;
  late TextEditingController _parentUnitCtrl;
  late TextEditingController _factorCtrl;
  late TextEditingController _purchasePriceCtrl;
  late TextEditingController _sellingPriceCtrl;
  late TextEditingController _wholesalePriceCtrl;
  late TextEditingController _stockCtrl;
  late TextEditingController _reorderLevelCtrl;
  late TextEditingController _shelfLifeCountCtrl;
  late TextEditingController _expiryAlertDaysCtrl;

  // Home Appliances controllers
  late TextEditingController _modelNumberCtrl;
  late TextEditingController _colorCtrl;
  late TextEditingController _warrantyMonthsCtrl;
  late TextEditingController _maintenanceAgentCtrl;
  bool _hasSerialNumber = false;
  String? _selectedBrandId;

  String? _selectedCategoryId;
  bool _isWeighable = false;
  bool _trackExpiry = false;
  String _shelfLifeUnit = "month"; // 'day', 'month', 'year'
  bool _isSaving = false;

  bool get isEdit => widget.product != null;

  @override
  void initState() {
    super.initState();
    final p = widget.product;

    _isWeighable = p?.isWeighable ?? false;
    _trackExpiry = p?.trackExpiry ?? false;

    _nameArCtrl = TextEditingController(text: p?.nameAr ?? '');
    _nameEnCtrl = TextEditingController(text: p?.nameEn ?? '');
    _barcodeCtrl = TextEditingController(text: p?.barcode ?? (_isWeighable ? _generateScalePluCode() : _generateBarcode()));
    _baseUnitCtrl = TextEditingController(text: p?.baseUnit ?? (_isWeighable ? 'كيلوجرام' : 'قطعة'));
    _parentUnitCtrl = TextEditingController(text: p?.parentUnit ?? (_isWeighable ? '' : 'قطعة'));
    _factorCtrl = TextEditingController(text: (p?.conversionFactor ?? 1).toString());
    _purchasePriceCtrl = TextEditingController(text: p != null && p.purchasePrice > 0 ? p.purchasePrice.toStringAsFixed(2) : '');
    _sellingPriceCtrl = TextEditingController(text: p != null && p.sellingPrice > 0 ? p.sellingPrice.toStringAsFixed(2) : '');
    _wholesalePriceCtrl = TextEditingController(text: p != null && p.wholesalePrice > 0 ? p.wholesalePrice.toStringAsFixed(2) : '');
    _stockCtrl = TextEditingController(text: (p?.stockQuantity ?? 0).toStringAsFixed(_isWeighable ? 3 : 0));
    _reorderLevelCtrl = TextEditingController(text: (p?.reorderLevel ?? 5).toStringAsFixed(_isWeighable ? 2 : 0));

    // Home Appliances fields
    _selectedBrandId = p?.brandId;
    _modelNumberCtrl = TextEditingController(text: p?.modelNumber ?? '');
    _colorCtrl = TextEditingController(text: p?.color ?? '');
    _warrantyMonthsCtrl = TextEditingController(text: (p?.warrantyPeriodMonths ?? 12).toString());
    _maintenanceAgentCtrl = TextEditingController(text: p?.maintenanceAgent ?? '');
    _hasSerialNumber = p?.hasSerialNumber ?? false;

    int shelfDays = p?.shelfLifeDays ?? 30;
    if (shelfDays % 365 == 0 && shelfDays > 0) {
      _shelfLifeUnit = "year";
      _shelfLifeCountCtrl = TextEditingController(text: (shelfDays ~/ 365).toString());
    } else if (shelfDays % 30 == 0 && shelfDays > 0) {
      _shelfLifeUnit = "month";
      _shelfLifeCountCtrl = TextEditingController(text: (shelfDays ~/ 30).toString());
    } else {
      _shelfLifeUnit = "day";
      _shelfLifeCountCtrl = TextEditingController(text: shelfDays.toString());
    }

    _expiryAlertDaysCtrl = TextEditingController(text: (p?.expiryAlertDays ?? 3).toString());
    _selectedCategoryId = p?.categoryId;

    WidgetsBinding.instance.addPostFrameCallback((_) {
      final prov = Provider.of<ProductsProvider>(context, listen: false);
      prov.fetchCategories();
      prov.fetchBrands();
    });
  }

  @override
  void dispose() {
    _nameArCtrl.dispose();
    _nameEnCtrl.dispose();
    _barcodeCtrl.dispose();
    _baseUnitCtrl.dispose();
    _parentUnitCtrl.dispose();
    _factorCtrl.dispose();
    _purchasePriceCtrl.dispose();
    _sellingPriceCtrl.dispose();
    _wholesalePriceCtrl.dispose();
    _stockCtrl.dispose();
    _reorderLevelCtrl.dispose();
    _shelfLifeCountCtrl.dispose();
    _expiryAlertDaysCtrl.dispose();
    _modelNumberCtrl.dispose();
    _colorCtrl.dispose();
    _warrantyMonthsCtrl.dispose();
    _maintenanceAgentCtrl.dispose();
    super.dispose();
  }

  Future<void> _scanBarcodeWithCamera() async {
    final scanned = await CameraBarcodeScannerScreen.scan(context, title: "مسح باركود المنتج بالكاميرا");
    if (scanned != null && scanned.trim().isNotEmpty) {
      setState(() {
        _barcodeCtrl.text = scanned.trim();
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text("تم مسح الباركود بنجاح: $scanned"),
            backgroundColor: AppColors.success,
            duration: const Duration(seconds: 2),
          ),
        );
      }
    }
  }

  String _generateBarcode() {
    final rand = Random();
    final ts = DateTime.now().millisecondsSinceEpoch.toString().substring(5);
    final r = rand.nextInt(900) + 100;
    return "$ts$r";
  }

  String _generateScalePluCode() {
    final rand = Random();
    final r = rand.nextInt(90) + 10;
    return "01$r";
  }

  void _onWeighableChanged(bool weighable) {
    setState(() {
      _isWeighable = weighable;
      if (weighable) {
        if (_barcodeCtrl.text.length > 6 || _barcodeCtrl.text.isEmpty) {
          _barcodeCtrl.text = _generateScalePluCode();
        }
        _baseUnitCtrl.text = "كيلوجرام";
        _parentUnitCtrl.text = "";
        _factorCtrl.text = "1";
      } else {
        if (_barcodeCtrl.text.length <= 4) {
          _barcodeCtrl.text = _generateBarcode();
        }
        _baseUnitCtrl.text = "قطعة";
        _parentUnitCtrl.text = "قطعة";
        _factorCtrl.text = "1";
      }
    });
  }

  int _calculateShelfLifeDays() {
    int count = int.tryParse(_shelfLifeCountCtrl.text.trim()) ?? 30;
    if (_shelfLifeUnit == "year") return count * 365;
    if (_shelfLifeUnit == "month") return count * 30;
    return count;
  }

  Future<void> _showAddCategoryDialog() async {
    final catCtrl = TextEditingController();
    final isDark = Provider.of<ThemeProvider>(context, listen: false).isDarkMode;

    await showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.getSurface(isDark),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text("إضافة تصنيف جديد", style: TextStyle(color: AppColors.getTextPrimary(isDark), fontWeight: FontWeight.bold, fontSize: 16)),
        content: CustomTextField(
          controller: catCtrl,
          label: "اسم التصنيف *",
          hint: "مثلاً: ألبان وأجبان، مشروبات...",
          prefixIcon: Icons.category_rounded,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text("إلغاء", style: TextStyle(color: AppColors.getTextMuted(isDark))),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary),
            onPressed: () async {
              if (catCtrl.text.trim().isNotEmpty) {
                final success = await Provider.of<ProductsProvider>(context, listen: false).createCategory(catCtrl.text.trim(), null);
                if (success && mounted) {
                  final cats = Provider.of<ProductsProvider>(context, listen: false).categories;
                  setState(() {
                    _selectedCategoryId = cats.last.id;
                  });
                  Navigator.pop(ctx);
                }
              }
            },
            child: const Text("حفظ التصنيف", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isSaving = true);
    final prov = Provider.of<ProductsProvider>(context, listen: false);

    final cats = prov.categories;
    final catObj = cats.where((c) => c.id == _selectedCategoryId).firstOrNull;

    final brands = prov.brands;
    final brandObj = brands.where((b) => b.id == _selectedBrandId).firstOrNull;

    final productModel = ProductModel(
      id: widget.product?.id ?? '',
      barcode: _barcodeCtrl.text.trim(),
      nameAr: _nameArCtrl.text.trim(),
      nameEn: _nameEnCtrl.text.trim().isNotEmpty ? _nameEnCtrl.text.trim() : null,
      baseUnit: _isWeighable ? (_baseUnitCtrl.text.trim().isNotEmpty ? _baseUnitCtrl.text.trim() : 'كيلوجرام') : 'قطعة',
      parentUnit: _isWeighable ? null : 'قطعة',
      conversionFactor: 1,
      purchasePrice: double.tryParse(_purchasePriceCtrl.text.trim()) ?? 0.0,
      sellingPrice: double.tryParse(_sellingPriceCtrl.text.trim()) ?? 0.0,
      wholesalePrice: double.tryParse(_wholesalePriceCtrl.text.trim()) ?? 0.0,
      stockQuantity: double.tryParse(_stockCtrl.text.trim()) ?? 0.0,
      categoryId: _selectedCategoryId,
      categoryName: catObj?.nameAr,
      isWeighable: _isWeighable,
      shelfLifeDays: _calculateShelfLifeDays(),
      expiryAlertDays: int.tryParse(_expiryAlertDaysCtrl.text.trim()) ?? 3,
      reorderLevel: double.tryParse(_reorderLevelCtrl.text.trim()) ?? 5.0,
      trackExpiry: _trackExpiry,
      isActive: true,
      syncStatus: 'PendingSync',
      brandId: _selectedBrandId,
      brandName: brandObj?.name,
      modelNumber: _modelNumberCtrl.text.trim().isNotEmpty ? _modelNumberCtrl.text.trim() : null,
      color: _colorCtrl.text.trim().isNotEmpty ? _colorCtrl.text.trim() : null,
      warrantyPeriodMonths: int.tryParse(_warrantyMonthsCtrl.text.trim()) ?? 12,
      maintenanceAgent: _maintenanceAgentCtrl.text.trim().isNotEmpty ? _maintenanceAgentCtrl.text.trim() : null,
      hasSerialNumber: _hasSerialNumber,
    );

    final success = await prov.saveProduct(productModel, isEdit: isEdit);
    setState(() => _isSaving = false);

    if (success && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          backgroundColor: AppColors.success,
          content: Text(isEdit ? "تم تحديث بيانات المنتج بنجاح." : "تمت إضافة المنتج بنجاح وجاري مزامنته مع الكاشير."),
        ),
      );
      Navigator.pop(context);
    } else if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          backgroundColor: AppColors.danger,
          content: Text(prov.errorMessage ?? "فشل حفظ المنتج، تأكد من صحة البيانات."),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Provider.of<ThemeProvider>(context).isDarkMode;
    final prov = Provider.of<ProductsProvider>(context);

    return Scaffold(
      backgroundColor: AppColors.getBackground(isDark),
      appBar: AppBar(
        backgroundColor: AppColors.getSurface(isDark),
        elevation: 0,
        title: Text(
          isEdit ? "تعديل المنتج: ${_nameArCtrl.text}" : "إضافة منتج جديد",
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 17, color: AppColors.getTextPrimary(isDark)),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Product Type Selector (Regular vs Weighed/Scale)
              _buildProductTypeSelector(isDark),
              const SizedBox(height: 16),

              // Barcode / PLU Section
              _buildBarcodeSection(isDark),
              const SizedBox(height: 16),

              // Basic Information Section (Name, Brand, Category)
              _buildBasicInfoSection(isDark, prov),
              const SizedBox(height: 16),

              // Appliance Specifications Section (Model, Color, Warranty, Agent, Serial)
              _buildApplianceSpecsSection(isDark),
              const SizedBox(height: 16),

              // Units Section (Changes based on Regular vs Weighed)
              if (_isWeighable)
                _buildWeighedUnitsSection(isDark)
              else
                _buildRegularUnitsSection(isDark),
              const SizedBox(height: 16),

              // Pricing & Stock Section (Labels dynamically adapt)
              _buildPricingAndStockSection(isDark),
              const SizedBox(height: 16),

              // Expiry & Tracking Section
              _buildExpiryTrackingSection(isDark),
              const SizedBox(height: 24),

              // Submit Button
              SizedBox(
                width: double.infinity,
                height: 52,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _isWeighable ? AppColors.cyan : AppColors.primary,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                    elevation: 4,
                  ),
                  onPressed: _isSaving ? null : _submit,
                  child: _isSaving
                      ? const SizedBox(height: 24, width: 24, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2.5))
                      : Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(isEdit ? Icons.check_circle_outline_rounded : Icons.add_task_rounded, color: Colors.white),
                            const SizedBox(width: 8),
                            Text(
                              isEdit ? "حفظ التعديلات" : (_isWeighable ? "إضافة صنف الميزان ومزامنته ⚖️" : "إضافة المنتج ومزامنته 📦"),
                              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white),
                            ),
                          ],
                        ),
                ),
              ),
              const SizedBox(height: 30),
            ],
          ),
        ),
      ),
    );
  }

  // 1. Prominent Product Type Selector (Desktop Parity)
  Widget _buildProductTypeSelector(bool isDark) {
    return Row(
      children: [
        // Regular Product Card
        Expanded(
          child: InkWell(
            borderRadius: BorderRadius.circular(14),
            onTap: () => _onWeighableChanged(false),
            child: Container(
              padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 12),
              decoration: BoxDecoration(
                color: !_isWeighable
                    ? (isDark ? AppColors.primary.withOpacity(0.2) : const Color(0xFFEFF6FF))
                    : AppColors.getSurface(isDark),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(
                  color: !_isWeighable ? AppColors.primary : AppColors.getBorder(isDark),
                  width: !_isWeighable ? 2 : 1,
                ),
              ),
              child: Column(
                children: [
                  Icon(
                    Icons.inventory_2_rounded,
                    size: 32,
                    color: !_isWeighable ? AppColors.primaryLight : AppColors.getTextSecondary(isDark),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    "منتج عادي (بالقطعة)",
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 13,
                      color: !_isWeighable ? AppColors.primaryLight : AppColors.getTextPrimary(isDark),
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    "معلبات، كراتين، مشروبات",
                    style: TextStyle(
                      fontSize: 10,
                      color: AppColors.getTextMuted(isDark),
                    ),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
          ),
        ),
        const SizedBox(width: 12),

        // Weighed Product Card
        Expanded(
          child: InkWell(
            borderRadius: BorderRadius.circular(14),
            onTap: () => _onWeighableChanged(true),
            child: Container(
              padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 12),
              decoration: BoxDecoration(
                color: _isWeighable
                    ? (isDark ? AppColors.cyan.withOpacity(0.2) : const Color(0xFFECFDF5))
                    : AppColors.getSurface(isDark),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(
                  color: _isWeighable ? AppColors.cyan : AppColors.getBorder(isDark),
                  width: _isWeighable ? 2 : 1,
                ),
              ),
              child: Column(
                children: [
                  Icon(
                    Icons.scale_rounded,
                    size: 32,
                    color: _isWeighable ? AppColors.cyan : AppColors.getTextSecondary(isDark),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    "منتج بالوزن / ميزان",
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 13,
                      color: _isWeighable ? AppColors.cyan : AppColors.getTextPrimary(isDark),
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    "جبن، خضار، فواكه، لحوم",
                    style: TextStyle(
                      fontSize: 10,
                      color: AppColors.getTextMuted(isDark),
                    ),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }

  // 2. Barcode or PLU Section
  Widget _buildBarcodeSection(bool isDark) {
    if (_isWeighable) {
      return Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: isDark ? AppColors.cyan.withOpacity(0.08) : const Color(0xFFECFDF5),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: AppColors.cyan.withOpacity(0.4), width: 1.5),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.scale_rounded, color: AppColors.cyan, size: 20),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    "كود الميزان (PLU Code) أو الباركود *",
                    style: TextStyle(color: isDark ? AppColors.cyan : const Color(0xFF047857), fontWeight: FontWeight.bold, fontSize: 13),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                const SizedBox(width: 6),
                Text(
                  "مثلاً: 101 أو 0101",
                  style: TextStyle(color: AppColors.getTextMuted(isDark), fontSize: 11),
                ),
              ],
            ),
            const SizedBox(height: 10),
            Row(
              children: [
                Expanded(
                  child: CustomTextField(
                    controller: _barcodeCtrl,
                    label: "كود الميزان (PLU Code) *",
                    hint: "مثال: 0101 أو 101",
                    prefixIcon: Icons.qr_code_2_rounded,
                    validator: (v) => (v == null || v.trim().isEmpty) ? "كود الميزان مطلوب" : null,
                  ),
                ),
                const SizedBox(width: 8),
                Padding(
                  padding: const EdgeInsets.only(top: 22),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      IconButton(
                        style: IconButton.styleFrom(
                          backgroundColor: AppColors.cyan,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                          minimumSize: const Size(40, 40),
                          padding: EdgeInsets.zero,
                        ),
                        icon: const Icon(Icons.camera_alt_rounded, color: Colors.white, size: 20),
                        tooltip: "مسح كود الميزان بالكاميرا",
                        onPressed: _scanBarcodeWithCamera,
                      ),
                      const SizedBox(width: 6),
                      IconButton(
                        style: IconButton.styleFrom(
                          backgroundColor: AppColors.cyan.withOpacity(0.15),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                          minimumSize: const Size(40, 40),
                          padding: EdgeInsets.zero,
                        ),
                        icon: const Icon(Icons.auto_awesome, color: AppColors.cyan, size: 20),
                        tooltip: "توليد كود تلقائي",
                        onPressed: () => setState(() => _barcodeCtrl.text = _generateScalePluCode()),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                const Icon(Icons.info_outline_rounded, size: 14, color: AppColors.cyan),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    "الكاشير يتعرف تلقائياً على هذا الصنف عند قراءة ملصق الميزان ويستخرج الوزن فوراً.",
                    style: TextStyle(color: isDark ? AppColors.cyan : const Color(0xFF065F46), fontSize: 11),
                  ),
                ),
              ],
            ),
          ],
        ),
      );
    } else {
      return _buildSectionCard(
        isDark,
        title: "رمز الباركود",
        icon: Icons.qr_code_rounded,
        children: [
          Row(
            children: [
              Expanded(
                child: CustomTextField(
                  controller: _barcodeCtrl,
                  label: "الباركود الدولي أو المحلي *",
                  hint: "امسح أو أدخل رقم الباركود...",
                  prefixIcon: Icons.qr_code_rounded,
                  validator: (v) => (v == null || v.trim().isEmpty) ? "الباركود مطلوب" : null,
                ),
              ),
              const SizedBox(width: 8),
              Padding(
                padding: const EdgeInsets.only(top: 22),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    IconButton(
                      style: IconButton.styleFrom(
                        backgroundColor: AppColors.primary,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                        minimumSize: const Size(40, 40),
                        padding: EdgeInsets.zero,
                      ),
                      icon: const Icon(Icons.camera_alt_rounded, color: Colors.white, size: 20),
                      tooltip: "مسح الباركود بالكاميرا",
                      onPressed: _scanBarcodeWithCamera,
                    ),
                    const SizedBox(width: 6),
                    IconButton(
                      style: IconButton.styleFrom(
                        backgroundColor: AppColors.primary.withOpacity(0.15),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                        minimumSize: const Size(40, 40),
                        padding: EdgeInsets.zero,
                      ),
                      icon: const Icon(Icons.autorenew_rounded, color: AppColors.primaryLight, size: 20),
                      tooltip: "توليد باركود تلقائي",
                      onPressed: () => setState(() => _barcodeCtrl.text = _generateBarcode()),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      );
    }
  }

  // 3. Basic Information (Name, Brand, Category)
  Widget _buildBasicInfoSection(bool isDark, ProductsProvider prov) {
    return _buildSectionCard(
      isDark,
      title: "بيانات الصنف الأساسية",
      icon: Icons.edit_note_rounded,
      children: [
        CustomTextField(
          controller: _nameArCtrl,
          label: "اسم المنتج (بالعربي) *",
          hint: _isWeighable ? "مثال: جبنة رومي قديمة بطارخ" : "مثال: ثلاجة 16 قدم نوفروست أو شاشة 43 بوصة سمارت",
          prefixIcon: Icons.shopping_bag_outlined,
          validator: (v) => (v == null || v.trim().isEmpty) ? "اسم المنتج بالعربي مطلوب" : null,
        ),
        const SizedBox(height: 12),
        CustomTextField(
          controller: _nameEnCtrl,
          label: "اسم المنتج (بالإنجليزي - اختياري)",
          hint: _isWeighable ? "مثال: Aged Roumi Cheese" : "مثال: 16 Cu.Ft Refrigerator or 43 Inch Smart TV",
          prefixIcon: Icons.language_rounded,
        ),
        const SizedBox(height: 14),

        // Brand Dropdown with Add Brand Button
        Row(
          children: [
            Expanded(
              child: DropdownButtonFormField<String?>(
                value: _selectedBrandId,
                dropdownColor: AppColors.getSurface(isDark),
                style: TextStyle(color: AppColors.getTextPrimary(isDark), fontSize: 13),
                decoration: InputDecoration(
                  labelText: "الماركة التجارية (اختياري)",
                  labelStyle: TextStyle(color: AppColors.getTextSecondary(isDark), fontSize: 12),
                  prefixIcon: const Icon(Icons.branding_watermark_outlined, color: AppColors.accent, size: 20),
                  filled: true,
                  fillColor: isDark ? AppColors.darkSurfaceElevated : Colors.white,
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: AppColors.getBorder(isDark))),
                  enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: AppColors.getBorder(isDark))),
                ),
                items: [
                  DropdownMenuItem<String?>(
                    value: null,
                    child: Text("بدون ماركة (عام)", style: TextStyle(color: AppColors.getTextMuted(isDark))),
                  ),
                  ...prov.brands.map((b) => DropdownMenuItem<String?>(
                        value: b.id,
                        child: Text(b.name, overflow: TextOverflow.ellipsis),
                      )),
                ],
                onChanged: (val) => setState(() => _selectedBrandId = val),
              ),
            ),
            const SizedBox(width: 8),
            IconButton(
              style: IconButton.styleFrom(
                backgroundColor: AppColors.accent.withOpacity(0.15),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              ),
              icon: const Icon(Icons.add_circle_outline_rounded, color: AppColors.accent),
              tooltip: "إضافة ماركة جديدة",
              onPressed: () async {
                final newBrand = await showAddBrandDialog(context);
                if (newBrand != null && mounted) {
                  setState(() => _selectedBrandId = newBrand.id);
                }
              },
            ),
          ],
        ),
        const SizedBox(height: 12),

        // Category Dropdown with Add Category Button
        Row(
          children: [
            Expanded(
              child: DropdownButtonFormField<String?>(
                value: _selectedCategoryId,
                dropdownColor: AppColors.getSurface(isDark),
                style: TextStyle(color: AppColors.getTextPrimary(isDark), fontSize: 13),
                decoration: InputDecoration(
                  labelText: "التصنيف (اختياري)",
                  labelStyle: TextStyle(color: AppColors.getTextSecondary(isDark), fontSize: 12),
                  prefixIcon: const Icon(Icons.category_outlined, color: AppColors.primaryLight, size: 20),
                  filled: true,
                  fillColor: isDark ? AppColors.darkSurfaceElevated : Colors.white,
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: AppColors.getBorder(isDark))),
                  enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: AppColors.getBorder(isDark))),
                ),
                items: [
                  DropdownMenuItem<String?>(
                    value: null,
                    child: Text("بدون تصنيف (عام)", style: TextStyle(color: AppColors.getTextMuted(isDark))),
                  ),
                  ...prov.categories.map((c) => DropdownMenuItem<String?>(
                        value: c.id,
                        child: Text(c.nameAr, overflow: TextOverflow.ellipsis),
                      )),
                ],
                onChanged: (val) => setState(() => _selectedCategoryId = val),
              ),
            ),
            const SizedBox(width: 8),
            IconButton(
              style: IconButton.styleFrom(
                backgroundColor: AppColors.success.withOpacity(0.15),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              ),
              icon: const Icon(Icons.add_circle_outline_rounded, color: AppColors.success),
              tooltip: "إضافة تصنيف جديد",
              onPressed: _showAddCategoryDialog,
            ),
          ],
        ),
      ],
    );
  }

  // 3B. Appliance Specifications Section (Desktop Parity for Home Appliances)
  Widget _buildApplianceSpecsSection(bool isDark) {
    return _buildSectionCard(
      isDark,
      title: "مواصفات وبيانات الجهاز الكهربائي",
      icon: Icons.tv_rounded,
      children: [
        Row(
          children: [
            Expanded(
              child: CustomTextField(
                controller: _modelNumberCtrl,
                label: "رقم الموديل (Model)",
                hint: "مثال: GR-EF40P أو 43LM5500",
                prefixIcon: Icons.memory_rounded,
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: CustomTextField(
                controller: _colorCtrl,
                label: "اللون",
                hint: "سيلفر، أسود، ستانلس...",
                prefixIcon: Icons.color_lens_outlined,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: CustomTextField(
                controller: _warrantyMonthsCtrl,
                label: "مدة الضمان (بالشهور)",
                hint: "12",
                keyboardType: TextInputType.number,
                prefixIcon: Icons.shield_outlined,
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: CustomTextField(
                controller: _maintenanceAgentCtrl,
                label: "مركز الصيانة / الوكيل",
                hint: "مثال: العربي جروب 19319",
                prefixIcon: Icons.support_agent_rounded,
              ),
            ),
          ],
        ),
        const SizedBox(height: 14),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          decoration: BoxDecoration(
            color: isDark ? AppColors.primary.withOpacity(0.08) : const Color(0xFFEFF6FF),
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: AppColors.primary.withOpacity(0.25)),
          ),
          child: Row(
            children: [
              Checkbox(
                value: _hasSerialNumber,
                activeColor: AppColors.primary,
                onChanged: (val) => setState(() => _hasSerialNumber = val ?? false),
              ),
              const SizedBox(width: 4),
              Expanded(
                child: GestureDetector(
                  onTap: () => setState(() => _hasSerialNumber = !_hasSerialNumber),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        "تتبع الرقم التسلسلي (Serial Number) لكل جهاز",
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 13,
                          color: AppColors.getTextPrimary(isDark),
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        "تفعيل تسجيل أرقام السيريال عند الشراء والبيع للضمان والصيانة",
                        style: TextStyle(
                          fontSize: 11,
                          color: AppColors.getTextMuted(isDark),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  // 4A. Weighed Product Units Section (Desktop Parity)
  Widget _buildWeighedUnitsSection(bool isDark) {
    return _buildSectionCard(
      isDark,
      title: "وحدة قياس الوزن بالميزان",
      icon: Icons.scale_rounded,
      children: [
        DropdownButtonFormField<String>(
          value: _baseUnitCtrl.text.isNotEmpty ? _baseUnitCtrl.text : "كيلوجرام",
          dropdownColor: AppColors.getSurface(isDark),
          style: TextStyle(color: AppColors.getTextPrimary(isDark), fontSize: 14, fontWeight: FontWeight.bold),
          decoration: InputDecoration(
            labelText: "الوحدة الأساسية للوزن *",
            labelStyle: TextStyle(color: AppColors.getTextSecondary(isDark), fontSize: 13),
            prefixIcon: const Icon(Icons.scale_rounded, color: AppColors.cyan, size: 20),
            filled: true,
            fillColor: isDark ? AppColors.darkSurfaceElevated : Colors.white,
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
            enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: AppColors.getBorder(isDark))),
          ),
          items: const [
            DropdownMenuItem(value: "كيلوجرام", child: Text("كيلوجرام (كجم)")),
            DropdownMenuItem(value: "جرام", child: Text("جرام (جم)")),
          ],
          onChanged: (val) {
            if (val != null) setState(() => _baseUnitCtrl.text = val);
          },
        ),
        const SizedBox(height: 10),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          decoration: BoxDecoration(
            color: isDark ? AppColors.cyan.withOpacity(0.08) : const Color(0xFFF0FDF4),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: AppColors.cyan.withOpacity(0.3)),
          ),
          child: Row(
            children: [
              const Icon(Icons.check_circle_outline_rounded, color: AppColors.cyan, size: 16),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  "الأسعار والكميات والمخزون تُحسب وتُسجل لكل 1 ${_baseUnitCtrl.text}",
                  style: TextStyle(color: isDark ? AppColors.cyan : const Color(0xFF166534), fontSize: 12, fontWeight: FontWeight.w600),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  // 4B. Regular Product Units Section (Home Appliances: Piece only)
  Widget _buildRegularUnitsSection(bool isDark) {
    return _buildSectionCard(
      isDark,
      title: "وحدة القياس والتعبئة",
      icon: Icons.all_inbox_rounded,
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          decoration: BoxDecoration(
            color: isDark ? AppColors.primary.withOpacity(0.08) : const Color(0xFFEFF6FF),
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: AppColors.primary.withOpacity(0.3)),
          ),
          child: Row(
            children: [
              const Icon(Icons.check_circle_outline_rounded, color: AppColors.primaryLight, size: 20),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  "وحدة الصنف: قطعة (الأجهزة الكهربائية والمنزلية تُباع وتُخزن بالقطعة)",
                  style: TextStyle(
                    color: isDark ? AppColors.primaryLight : const Color(0xFF1E40AF),
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  // 5. Pricing & Stock Section (Dynamically adjusts based on Weighable vs Regular)
  Widget _buildPricingAndStockSection(bool isDark) {
    final unitLabel = _isWeighable ? "الكيلو" : "القطعة";
    final unitSuffix = _isWeighable ? "كجم" : "قطعة";

    return _buildSectionCard(
      isDark,
      title: "الأسعار والمخزون",
      icon: Icons.price_change_rounded,
      children: [
        Row(
          children: [
            Expanded(
              child: CustomTextField(
                controller: _purchasePriceCtrl,
                label: "سعر شراء $unitLabel (ج.م) *",
                hint: "0.00",
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                prefixIcon: Icons.arrow_downward_rounded,
                validator: (v) => (double.tryParse(v ?? "") == null) ? "سعر غير صحيح" : null,
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: CustomTextField(
                controller: _sellingPriceCtrl,
                label: "سعر بيع $unitLabel قطاعي (ج.م) *",
                hint: "0.00",
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                prefixIcon: Icons.arrow_upward_rounded,
                validator: (v) => (double.tryParse(v ?? "") == null) ? "سعر غير صحيح" : null,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: CustomTextField(
                controller: _wholesalePriceCtrl,
                label: "سعر بيع $unitLabel جملة (ج.م)",
                hint: "0.00",
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                prefixIcon: Icons.storefront_outlined,
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: CustomTextField(
                controller: _reorderLevelCtrl,
                label: "حد إعادة الطلب ($unitSuffix)",
                hint: "5",
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                prefixIcon: Icons.warning_amber_rounded,
              ),
            ),
          ],
        ),
        if (!isEdit) ...[
          const SizedBox(height: 12),
          CustomTextField(
            controller: _stockCtrl,
            label: "الرصيد الافتتاحي في المخزن ($unitSuffix)",
            hint: "0",
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            prefixIcon: Icons.warehouse_rounded,
          ),
        ],
      ],
    );
  }

  // 6. Expiry & Tracking Section
  Widget _buildExpiryTrackingSection(bool isDark) {
    return _buildSectionCard(
      isDark,
      title: "تتبع الصلاحية والدفعات",
      icon: Icons.timelapse_rounded,
      children: [
        SwitchListTile(
          contentPadding: EdgeInsets.zero,
          activeColor: AppColors.warning,
          title: const Text("تتبع الصلاحية وتاريخ الانتهاء (Expiry Tracking)", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
          subtitle: Text("لتتبع دفعات التوريد وتواريخ انتهاء الصلاحية والتنبيه المبكر", style: TextStyle(color: AppColors.getTextMuted(isDark), fontSize: 12)),
          value: _trackExpiry,
          onChanged: (v) => setState(() => _trackExpiry = v),
        ),
        if (_trackExpiry) ...[
          const Divider(height: 20),
          Row(
            children: [
              Expanded(
                flex: 2,
                child: CustomTextField(
                  controller: _shelfLifeCountCtrl,
                  label: "مدة الصلاحية الافتراضية *",
                  hint: "1",
                  keyboardType: TextInputType.number,
                  prefixIcon: Icons.calendar_today_rounded,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                flex: 2,
                child: DropdownButtonFormField<String>(
                  value: _shelfLifeUnit,
                  dropdownColor: AppColors.getSurface(isDark),
                  style: TextStyle(color: AppColors.getTextPrimary(isDark), fontSize: 14),
                  decoration: InputDecoration(
                    labelText: "الوحدة",
                    filled: true,
                    fillColor: isDark ? AppColors.darkSurfaceElevated : Colors.white,
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                    enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: AppColors.getBorder(isDark))),
                  ),
                  items: const [
                    DropdownMenuItem(value: "day", child: Text("يوم")),
                    DropdownMenuItem(value: "month", child: Text("شهر")),
                    DropdownMenuItem(value: "year", child: Text("سنة")),
                  ],
                  onChanged: (val) => setState(() => _shelfLifeUnit = val ?? "month"),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          CustomTextField(
            controller: _expiryAlertDaysCtrl,
            label: "تنبيه قبل الانتهاء بـ (أيام)",
            hint: "3",
            keyboardType: TextInputType.number,
            prefixIcon: Icons.notifications_active_outlined,
          ),
          const SizedBox(height: 8),
          Text(
            "الصلاحية المحسوبة: ${_calculateShelfLifeDays()} يوم. سيتم ملء تاريخ الصلاحية تلقائياً عند تسجيل فاتورة شراء لهذا الصنف.",
            style: const TextStyle(color: AppColors.warning, fontSize: 11, fontWeight: FontWeight.w600),
          ),
        ],
      ],
    );
  }

  Widget _buildSectionCard(bool isDark, {required String title, required IconData icon, required List<Widget> children}) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.getSurface(isDark),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.getBorder(isDark)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: AppColors.primaryLight, size: 20),
              const SizedBox(width: 8),
              Text(
                title,
                style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: AppColors.getTextPrimary(isDark)),
              ),
            ],
          ),
          const Divider(height: 20),
          ...children,
        ],
      ),
    );
  }
}
