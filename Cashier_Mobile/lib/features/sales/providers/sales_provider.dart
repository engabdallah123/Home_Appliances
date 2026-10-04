import 'package:flutter/material.dart';
import '../../../core/constants/api_endpoints.dart';
import '../../../core/network/api_client.dart';
import '../../../core/widgets/camera_barcode_scanner.dart';
import '../../products/models/product_model.dart';
import '../models/sale_model.dart';

class SalesProvider with ChangeNotifier {
  final ApiClient _apiClient = ApiClient();

  // Cart State
  final List<CartItemModel> _cartItems = [];

  // Customer State
  String? _customerId;
  String? _customerName;
  String? _customerPhone;

  // Payment & Totals State
  String _paymentMethod = "Cash"; // Cash, Card, Installment, Credit
  double _discountAmount = 0;
  double _paidAmount = 0;
  String? _notes;

  // Delivery State (الأجهزة الكبيرة: توصيل وتركيب)
  bool _isDelivery = false;
  String? _recipientName;
  String? _recipientPhone;
  String? _deliveryAddress;
  String? _deliveryFloor;
  double _deliveryFee = 0;

  // Installment State (الأقساط الشهرية)
  bool _isInstallment = false;
  String? _guarantorName;
  String? _guarantorPhone;
  String? _guarantorNationalId;
  String? _guarantorAddress;
  String? _guarantorNotes;
  double _interestPercentage = 0;
  int _numberOfMonths = 12;

  // Reservation State (حجز مسبق)
  bool _isReserved = false;
  DateTime? _targetDeliveryDate;

  // Provider Status
  bool _isCreating = false;
  bool _isLoading = false;
  bool _isLoadingMore = false;
  String? _errorMessage;

  // Invoices History
  List<SaleSummaryModel> _sales = [];
  int _currentPage = 1;
  bool _hasMore = true;
  static const int _pageSize = 20;

  // Getters
  List<CartItemModel> get cartItems => List.unmodifiable(_cartItems);
  int get itemCount => _cartItems.length;
  double get totalQuantity => _cartItems.fold(0.0, (sum, i) => sum + i.quantity);

  String? get customerId => _customerId;
  String? get customerName => _customerName;
  String? get customerPhone => _customerPhone;

  String get paymentMethod => _paymentMethod;
  double get discountAmount => _discountAmount;
  double get paidAmount => _paidAmount;
  String? get notes => _notes;

  bool get isDelivery => _isDelivery;
  String? get recipientName => _recipientName;
  String? get recipientPhone => _recipientPhone;
  String? get deliveryAddress => _deliveryAddress;
  String? get deliveryFloor => _deliveryFloor;
  double get deliveryFee => _deliveryFee;

  bool get isInstallment => _isInstallment;
  String? get guarantorName => _guarantorName;
  String? get guarantorPhone => _guarantorPhone;
  String? get guarantorNationalId => _guarantorNationalId;
  String? get guarantorAddress => _guarantorAddress;
  String? get guarantorNotes => _guarantorNotes;
  double get interestPercentage => _interestPercentage;
  int get numberOfMonths => _numberOfMonths;

  bool get isReserved => _isReserved;
  DateTime? get targetDeliveryDate => _targetDeliveryDate;

  bool get isCreating => _isCreating;
  bool get isLoading => _isLoading;
  bool get isLoadingMore => _isLoadingMore;
  String? get errorMessage => _errorMessage;
  List<SaleSummaryModel> get sales => _sales;
  bool get hasMore => _hasMore;

  // Financial Calculations
  double get subTotal => _cartItems.fold(0.0, (sum, i) => sum + i.total);
  double get grandTotal {
    double total = subTotal - _discountAmount + (_isDelivery ? _deliveryFee : 0);
    if (_isInstallment && _interestPercentage > 0) {
      total += total * (_interestPercentage / 100);
    }
    return total < 0 ? 0 : total;
  }

  double get remainingAmount {
    double remaining = grandTotal - _paidAmount;
    return remaining < 0 ? 0 : remaining;
  }

  double get monthlyInstallmentAmount {
    if (!_isInstallment || _numberOfMonths <= 0) return 0;
    return grandTotal / _numberOfMonths;
  }

  // Cart Management
  void addProduct(ProductModel product, {String? serialNumber, double quantity = 1}) {
    // If appliance has serial number, keep as separate item so each SN is distinct
    final existingIndex = _cartItems.indexWhere(
      (item) => item.productId == product.id && (product.hasSerialNumber ? item.serialNumber == serialNumber : true),
    );

    if (existingIndex >= 0 && !product.hasSerialNumber) {
      _cartItems[existingIndex].quantity += quantity;
    } else {
      _cartItems.add(
        CartItemModel(
          productId: product.id,
          productName: product.nameAr,
          barcode: product.barcode,
          modelNumber: product.modelNumber,
          brandName: product.brandName,
          quantity: quantity,
          unitPrice: product.sellingPrice,
          serialNumber: serialNumber,
          warrantyPeriodMonths: product.warrantyPeriodMonths,
          stockQuantity: product.stockQuantity,
        ),
      );
    }

    _autoSyncPaidAmount();
    notifyListeners();
  }

  void incrementQuantity(int index) {
    if (index >= 0 && index < _cartItems.length) {
      _cartItems[index].quantity += 1;
      _autoSyncPaidAmount();
      notifyListeners();
    }
  }

  void decrementQuantity(int index) {
    if (index >= 0 && index < _cartItems.length) {
      if (_cartItems[index].quantity > 1) {
        _cartItems[index].quantity -= 1;
      } else {
        _cartItems.removeAt(index);
      }
      _autoSyncPaidAmount();
      notifyListeners();
    }
  }

  void setQuantity(int index, double quantity) {
    if (index >= 0 && index < _cartItems.length) {
      if (quantity <= 0) {
        _cartItems.removeAt(index);
      } else {
        _cartItems[index].quantity = quantity;
      }
      _autoSyncPaidAmount();
      notifyListeners();
    }
  }

  void setUnitPrice(int index, double price) {
    if (index >= 0 && index < _cartItems.length) {
      _cartItems[index].unitPrice = price >= 0 ? price : 0;
      _autoSyncPaidAmount();
      notifyListeners();
    }
  }

  void setItemDiscount(int index, double discount) {
    if (index >= 0 && index < _cartItems.length) {
      _cartItems[index].discount = discount >= 0 ? discount : 0;
      _autoSyncPaidAmount();
      notifyListeners();
    }
  }

  void setSerialNumber(int index, String? serialNumber) {
    if (index >= 0 && index < _cartItems.length) {
      _cartItems[index].serialNumber = serialNumber?.trim();
      notifyListeners();
    }
  }

  void removeItem(int index) {
    if (index >= 0 && index < _cartItems.length) {
      _cartItems.removeAt(index);
      _autoSyncPaidAmount();
      notifyListeners();
    }
  }

  void clearCart() {
    _cartItems.clear();
    _customerId = null;
    _customerName = null;
    _customerPhone = null;
    _discountAmount = 0;
    _paidAmount = 0;
    _notes = null;
    _isDelivery = false;
    _recipientName = null;
    _recipientPhone = null;
    _deliveryAddress = null;
    _deliveryFloor = null;
    _deliveryFee = 0;
    _isInstallment = false;
    _guarantorName = null;
    _guarantorPhone = null;
    _guarantorNationalId = null;
    _guarantorAddress = null;
    _guarantorNotes = null;
    _interestPercentage = 0;
    _numberOfMonths = 12;
    _isReserved = false;
    _targetDeliveryDate = null;
    _paymentMethod = "Cash";
    notifyListeners();
  }

  // Customer & Payment Setters
  void setCustomer({String? name, String? phone, String? id}) {
    _customerName = name?.trim();
    _customerPhone = phone?.trim();
    _customerId = id;
    notifyListeners();
  }

  void setPaymentMethod(String method) {
    _paymentMethod = method;
    _autoSyncPaidAmount();
    notifyListeners();
  }

  void setDiscountAmount(double discount) {
    _discountAmount = discount >= 0 ? discount : 0;
    _autoSyncPaidAmount();
    notifyListeners();
  }

  void setPaidAmount(double paid) {
    _paidAmount = paid >= 0 ? paid : 0;
    notifyListeners();
  }

  void setNotes(String? text) {
    _notes = text?.trim();
    notifyListeners();
  }

  void setDelivery({
    required bool enabled,
    String? recipientName,
    String? recipientPhone,
    String? address,
    String? floor,
    double fee = 0,
  }) {
    _isDelivery = enabled;
    _recipientName = recipientName?.trim();
    _recipientPhone = recipientPhone?.trim();
    _deliveryAddress = address?.trim();
    _deliveryFloor = floor?.trim();
    _deliveryFee = fee >= 0 ? fee : 0;
    _autoSyncPaidAmount();
    notifyListeners();
  }

  void setInstallment({
    required bool enabled,
    String? guarantorName,
    String? guarantorPhone,
    String? guarantorNationalId,
    String? guarantorAddress,
    String? guarantorNotes,
    int numberOfMonths = 12,
    double interestPercentage = 0,
    double? downPayment,
  }) {
    _isInstallment = enabled;
    _guarantorName = guarantorName?.trim();
    _guarantorPhone = guarantorPhone?.trim();
    _guarantorNationalId = guarantorNationalId?.trim();
    _guarantorAddress = guarantorAddress?.trim();
    _guarantorNotes = guarantorNotes?.trim();
    _numberOfMonths = numberOfMonths > 0 ? numberOfMonths : 12;
    _interestPercentage = interestPercentage >= 0 ? interestPercentage : 0;
    if (enabled) {
      _paymentMethod = "Installment";
      if (downPayment != null && downPayment >= 0) {
        _paidAmount = downPayment;
      } else if (_paidAmount == 0 || _paidAmount == grandTotal) {
        _paidAmount = (grandTotal * 0.20).roundToDouble(); // 20% down payment
      }
    }
    _autoSyncPaidAmount();
    notifyListeners();
  }

  void applyOffer(Map<String, dynamic> offer, List<ProductModel> catalog) {
    final items = offer['items'];
    if (items is List && items.isNotEmpty) {
      for (final rawItem in items) {
        final itm = rawItem is Map<String, dynamic> ? rawItem : <String, dynamic>{};
        final pId = itm['productId']?.toString();
        final pName = itm['productName']?.toString();
        final qty = (itm['quantity'] as num?)?.toDouble() ?? 1.0;
        final specialPrice = (itm['specialPrice'] as num?)?.toDouble();

        ProductModel? prod;
        if (pId != null && pId.isNotEmpty) {
          prod = catalog.where((p) => p.id == pId).firstOrNull;
        }
        if (prod == null && pName != null && pName.isNotEmpty) {
          prod = catalog.where((p) => p.nameAr.toLowerCase() == pName.toLowerCase()).firstOrNull;
        }
        if (prod != null) {
          addProduct(prod, quantity: qty);
        } else if (pId != null && pId.isNotEmpty) {
          // Fallback placeholder item
          _cartItems.add(
            CartItemModel(
              productId: pId,
              productName: pName ?? "جهاز كهربائي",
              quantity: qty,
              unitPrice: specialPrice ?? 0,
              warrantyPeriodMonths: 12,
            ),
          );
        }
      }
    }

    final pkgPrice = (offer['packagePrice'] as num?)?.toDouble() ?? 0.0;
    final discountPercent = (offer['discountPercent'] as num?)?.toDouble() ?? 0.0;
    final discountAmount = (offer['discountAmount'] as num?)?.toDouble() ?? 0.0;

    if (pkgPrice > 0) {
      final currentSub = subTotal;
      if (currentSub > pkgPrice) {
        setDiscountAmount(currentSub - pkgPrice);
      } else {
        setDiscountAmount(0);
      }
    } else if (discountPercent > 0) {
      setDiscountAmount(subTotal * (discountPercent / 100));
    } else if (discountAmount > 0) {
      setDiscountAmount(discountAmount);
    }
    _autoSyncPaidAmount();
    notifyListeners();
  }

  void setReservation({required bool enabled, DateTime? deliveryDate}) {
    _isReserved = enabled;
    _targetDeliveryDate = deliveryDate;
    notifyListeners();
  }

  void _autoSyncPaidAmount() {
    if (_paymentMethod == "Cash" || _paymentMethod == "Card") {
      _paidAmount = grandTotal;
    } else if (_paymentMethod == "Installment" || _paymentMethod == "Credit") {
      // In installments, default paid could be down payment (e.g. 0 or previous value)
      if (_paidAmount > grandTotal) {
        _paidAmount = grandTotal;
      }
    }
  }

  // Camera Barcode Scanning Helper
  Future<bool> scanBarcodeAndAdd(
    BuildContext context, {
    required List<ProductModel> catalog,
  }) async {
    final scannedBarcode = await CameraBarcodeScannerScreen.scan(
      context,
      title: "مسح باركود الجهاز",
    );

    if (scannedBarcode == null || scannedBarcode.isEmpty) return false;

    // 1. Try local catalog first (instant, works offline)
    ProductModel? matchedProduct;
    final barcodeClean = scannedBarcode.trim().toLowerCase();
    final modelMatch = catalog.where((p) => p.barcode.trim().toLowerCase() == barcodeClean).toList();

    if (modelMatch.isNotEmpty) {
      matchedProduct = modelMatch.first;
    } else {
      // 2. Fetch from Cloud API if not found locally
      try {
        final res = await _apiClient.get(ApiEndpoints.productByBarcode(scannedBarcode.trim()));
        if (res != null && res is Map<String, dynamic>) {
          matchedProduct = ProductModel.fromJson(res);
        }
      } catch (_) {}
    }

    if (matchedProduct == null) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text("لم يتم العثور على جهاز بالباركود: $scannedBarcode"),
            backgroundColor: Colors.redAccent,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
      return false;
    }

    // 3. If appliance has serial number, optionally ask for it
    String? serialNumber;
    if (matchedProduct.hasSerialNumber && context.mounted) {
      serialNumber = await _showSerialNumberDialog(context, matchedProduct.nameAr);
    }

    addProduct(matchedProduct, serialNumber: serialNumber);

    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("تمت إضافة: ${matchedProduct.nameAr}"),
          backgroundColor: const Color(0xFF10B981),
          duration: const Duration(seconds: 2),
          behavior: SnackBarBehavior.floating,
        ),
      );
    }

    return true;
  }

  Future<String?> _showSerialNumberDialog(BuildContext context, String productName) async {
    final controller = TextEditingController();
    return showDialog<String>(
      context: context,
      builder: (dialogCtx) {
        return AlertDialog(
          backgroundColor: const Color(0xFF1E293B),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: Row(
            children: [
              const Icon(Icons.qr_code_2_rounded, color: Color(0xFF38BDF8)),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  "سيريال الجهاز (Serial No)",
                  style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold),
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
                productName,
                style: const TextStyle(color: Colors.white70, fontSize: 13),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 12),
              TextField(
                controller: controller,
                autofocus: true,
                style: const TextStyle(color: Colors.white, fontSize: 15),
                decoration: InputDecoration(
                  hintText: "أدخل السيريال نمبر للجهاز...",
                  hintStyle: const TextStyle(color: Colors.white38, fontSize: 13),
                  filled: true,
                  fillColor: const Color(0xFF0F172A),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                  suffixIcon: IconButton(
                    icon: const Icon(Icons.camera_alt_rounded, color: Color(0xFF38BDF8)),
                    tooltip: "مسح سيريال الجهاز بالكاميرا",
                    onPressed: () async {
                      final sn = await CameraBarcodeScannerScreen.scan(dialogCtx, title: "مسح سيريال الجهاز");
                      if (sn != null && sn.isNotEmpty) {
                        controller.text = sn.trim();
                      }
                    },
                  ),
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogCtx, null),
              child: const Text("تخطي", style: TextStyle(color: Colors.white60)),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF4F46E5),
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
              ),
              onPressed: () => Navigator.pop(dialogCtx, controller.text.trim()),
              child: const Text("تأكيد"),
            ),
          ],
        );
      },
    );
  }

  // Submit Sale & Post to CloudAPI
  Future<SaleSummaryModel?> submitSale() async {
    if (_cartItems.isEmpty) {
      _errorMessage = "سلة المبيعات فارغة، يرجى مسح باركود جهاز أولاً.";
      notifyListeners();
      return null;
    }

    _isCreating = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final req = CreateSaleModel(
        customerId: _customerId,
        customerName: _customerName,
        customerPhone: _customerPhone,
        discountAmount: _discountAmount,
        taxAmount: 0,
        paidAmount: _paidAmount,
        paymentMethod: _paymentMethod,
        notes: _notes,
        items: List.from(_cartItems),
        isDelivery: _isDelivery,
        recipientName: _recipientName ?? _customerName,
        recipientPhone: _recipientPhone ?? _customerPhone,
        deliveryAddress: _deliveryAddress,
        deliveryFloor: _deliveryFloor,
        deliveryFee: _deliveryFee,
        isInstallment: _isInstallment,
        guarantorName: _guarantorName,
        guarantorPhone: _guarantorPhone,
        guarantorNationalId: _guarantorNationalId,
        guarantorAddress: _guarantorAddress,
        guarantorNotes: _guarantorNotes,
        interestPercentage: _interestPercentage,
        numberOfMonths: _numberOfMonths,
        isReserved: _isReserved,
        targetDeliveryDate: _targetDeliveryDate,
      );

      final response = await _apiClient.post(ApiEndpoints.sales, body: req.toJson());

      if (response != null && response is Map<String, dynamic>) {
        final created = SaleSummaryModel.fromJson(response);
        _sales.insert(0, created);
        clearCart();
        _isCreating = false;
        notifyListeners();
        return created;
      } else {
        throw ApiException("فشل حفظ فاتورة المبيعات.");
      }
    } catch (e) {
      _isCreating = false;
      _errorMessage = e.toString();
      notifyListeners();
      return null;
    }
  }

  // Fetch Invoices History
  Future<void> fetchSalesList({String? status, String? search, bool refresh = true}) async {
    if (refresh) {
      _isLoading = true;
      _errorMessage = null;
      _currentPage = 1;
      _hasMore = true;
      notifyListeners();
    }

    try {
      final queryParams = <String, dynamic>{
        'page': _currentPage,
        'pageSize': _pageSize,
      };
      if (status != null && status != 'all') queryParams['status'] = status;
      if (search != null && search.trim().isNotEmpty) queryParams['search'] = search.trim();

      final res = await _apiClient.get(ApiEndpoints.sales, queryParams: queryParams);

      List rawList = [];
      if (res is List) {
        rawList = res;
      } else if (res is Map<String, dynamic> && res['items'] is List) {
        rawList = res['items'] as List;
      }

      if (rawList.isNotEmpty) {
        final loaded = rawList.map((i) => SaleSummaryModel.fromJson(i as Map<String, dynamic>)).toList();
        if (refresh) {
          _sales = loaded;
        } else {
          _sales.addAll(loaded);
        }
        _hasMore = loaded.length >= _pageSize;
      } else {
        if (refresh) _sales = [];
        _hasMore = false;
      }

      _isLoading = false;
      _isLoadingMore = false;
      notifyListeners();
    } catch (e) {
      _isLoading = false;
      _isLoadingMore = false;
      _errorMessage = e.toString();
      notifyListeners();
    }
  }

  Future<void> fetchMoreSales() async {
    if (_isLoadingMore || !_hasMore || _isLoading) return;
    _isLoadingMore = true;
    _currentPage++;
    notifyListeners();
    await fetchSalesList(refresh: false);
  }

  Future<SaleDetailModel?> fetchSaleDetails(String id) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final res = await _apiClient.get(ApiEndpoints.saleDetails(id));
      _isLoading = false;
      notifyListeners();

      if (res != null && res is Map<String, dynamic>) {
        return SaleDetailModel.fromJson(res);
      }
      return null;
    } catch (e) {
      _isLoading = false;
      _errorMessage = e.toString();
      notifyListeners();
      return null;
    }
  }
}
