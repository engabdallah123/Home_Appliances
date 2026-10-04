import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../core/network/api_client.dart';
import '../../../core/services/notification_service.dart';
import '../models/notification_models.dart';

class NotificationsProvider extends ChangeNotifier {
  final ApiClient _apiClient = ApiClient();
  final LocalNotificationService _notificationService = LocalNotificationService();

  List<ExpiryNotificationModel> _expiryNotifications = [];
  List<LowStockProductModel> _lowStockProducts = [];
  List<ShiftSummaryModel> _shiftSummaries = [];

  bool _isLoading = false;
  String? _error;
  Timer? _pollingTimer;
  final Set<String> _notifiedItemKeys = {};

  List<ExpiryNotificationModel> get expiryNotifications => _expiryNotifications;
  List<LowStockProductModel> get lowStockProducts => _lowStockProducts;
  List<ShiftSummaryModel> get shiftSummaries => _shiftSummaries;
  bool get isLoading => _isLoading;
  String? get error => _error;

  int get totalAlertsCount =>
      _lowStockProducts.length +
      _shiftSummaries.where((s) => !s.isReadByOwner).length;

  NotificationsProvider() {
    _loadNotifiedKeys();
    startPeriodicCheck();
  }

  Future<void> _loadNotifiedKeys() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final saved = prefs.getStringList('notified_keys') ?? [];
      _notifiedItemKeys.addAll(saved);
    } catch (_) {}
  }

  Future<void> _saveNotifiedKey(String key) async {
    _notifiedItemKeys.add(key);
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setStringList('notified_keys', _notifiedItemKeys.toList());
    } catch (_) {}
  }

  void startPeriodicCheck() {
    _pollingTimer?.cancel();
    fetchAllNotifications();
    // Poll every 15 seconds for rapid updates
    _pollingTimer = Timer.periodic(const Duration(seconds: 15), (_) {
      fetchAllNotifications(silent: true);
    });
  }

  Future<void> fetchAllNotifications({bool silent = false}) async {
    if (!silent) {
      _isLoading = true;
      _error = null;
      notifyListeners();
    }

    try {
      await Future.wait([
        fetchLowStockNotifications(),
        fetchShiftSummaries(),
      ]);
      _checkAndTriggerSystemNotifications();
    } catch (e) {
      _error = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> fetchExpiryNotifications() async {
    // Expiry notifications disabled for Home Appliances
    _expiryNotifications = [];
  }

  Future<void> fetchLowStockNotifications() async {
    try {
      final res = await _apiClient.get('/api/cloud/notifications/low-stock');
      if (res is List) {
        _lowStockProducts = res.map((item) => LowStockProductModel.fromJson(item)).toList();
      }
    } catch (e) {
      debugPrint('fetchLowStockNotifications error: $e');
    }
  }

  Future<void> fetchShiftSummaries() async {
    try {
      final res = await _apiClient.get('/api/cloud/notifications/shifts');
      if (res is List) {
        _shiftSummaries = res.map((item) => ShiftSummaryModel.fromJson(item)).toList();
      }
    } catch (e) {
      debugPrint('fetchShiftSummaries error: $e');
    }
  }

  void _checkAndTriggerSystemNotifications() {
    // Expiry alerts removed for Home Appliances per requirement

    // 2. Low Stock and Out-of-Stock Notifications
    for (final prod in _lowStockProducts) {
      final isOutOfStock = prod.stockQuantity <= 0;
      final key = 'stock_${prod.id}_${prod.stockQuantity.toInt()}';
      if (!_notifiedItemKeys.contains(key)) {
        _saveNotifiedKey(key);
        _notificationService.showNotification(
          id: prod.id.hashCode,
          title: isOutOfStock
              ? '🚨 نفاد مخزون: ${prod.nameAr}'
              : '⚠️ اقتراب نفاد المخزون: ${prod.nameAr}',
          body: isOutOfStock
              ? 'تنبيه عاجل: نفدت كمية الصنف تماماً من المخزن (الرصيد: ${prod.stockQuantity.toInt()})!'
              : 'الرصيد الحالي (${prod.stockQuantity.toInt()}) وصل لحد إعادة الطلب (${prod.reorderLevel.toInt()}) أو أقل!',
          isUrgent: true,
        );
      }
    }

    // 3. Shift Close Performance Notifications
    for (final shift in _shiftSummaries.where((s) => !s.isReadByOwner)) {
      final key = 'shift_${shift.id}';
      if (!_notifiedItemKeys.contains(key)) {
        _saveNotifiedKey(key);
        final diffText = shift.cashDifference == 0
            ? 'متطابق تماماً ✅'
            : (shift.cashDifference > 0
                ? 'زيادة +${shift.cashDifference.toStringAsFixed(2)} ج.م'
                : 'عجز ${shift.cashDifference.toStringAsFixed(2)} ج.م ⚠️');

        _notificationService.showNotification(
          id: shift.id.hashCode,
          title: '🛎️ إغلاق وردية: ${shift.cashierName}',
          body: 'المبيعات: ${shift.totalSales.toStringAsFixed(0)} ج.م | الفواتير: ${shift.totalInvoices} | فرق الدرج: $diffText',
          isUrgent: true,
        );
      }
    }
  }

  Future<void> triggerTestNotification() async {
    await _notificationService.showNotification(
      id: 9999,
      title: '🔔 اختبار تنبيهات نظام الكاشير',
      body: 'نظام الإشعارات مفعل ويعمل بنجاح بالصوت والاهتزاز! ✅',
      isUrgent: true,
    );
  }

  Future<bool> sendExpiryAction(
    String notificationId, {
    required String actionType, // "OK", "Waste", "SupplierReplacement"
    double quantity = 0,
    String? reason,
    DateTime? newExpiryDate,
    String? newBatchNumber,
    String? notes,
  }) async {
    try {
      final body = {
        'ActionType': actionType,
        'Quantity': quantity,
        'Reason': reason,
        'NewExpiryDate': newExpiryDate?.toIso8601String(),
        'NewBatchNumber': newBatchNumber,
        'Notes': notes,
      };

      await _apiClient.post('/api/cloud/notifications/$notificationId/action', body: body);
      _expiryNotifications.removeWhere((n) => n.id == notificationId);
      notifyListeners();
      return true;
    } catch (_) {
      return false;
    }
  }

  Future<void> markShiftRead(String shiftSummaryId) async {
    try {
      await _apiClient.post('/api/cloud/notifications/shifts/$shiftSummaryId/read');
      final idx = _shiftSummaries.indexWhere((s) => s.id == shiftSummaryId);
      if (idx != -1) {
        final current = _shiftSummaries[idx];
        _shiftSummaries[idx] = ShiftSummaryModel(
          id: current.id,
          shiftId: current.shiftId,
          cashierName: current.cashierName,
          openedAt: current.openedAt,
          closedAt: current.closedAt,
          openingCash: current.openingCash,
          actualClosingCash: current.actualClosingCash,
          systemCash: current.systemCash,
          cashDifference: current.cashDifference,
          totalSales: current.totalSales,
          totalCash: current.totalCash,
          totalCard: current.totalCard,
          totalWallet: current.totalWallet,
          totalCredit: current.totalCredit,
          totalInvoices: current.totalInvoices,
          totalReturns: current.totalReturns,
          closingNotes: current.closingNotes,
          isReadByOwner: true,
          createdAt: current.createdAt,
        );
        notifyListeners();
      }
    } catch (_) {}
  }

  @override
  void dispose() {
    _pollingTimer?.cancel();
    super.dispose();
  }
}
