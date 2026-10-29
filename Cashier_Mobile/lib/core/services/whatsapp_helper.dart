import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart';

class WhatsAppHelper {
  /// Cleans and formats phone number for international WhatsApp link (Egypt 201xxxxxxxxx).
  static String formatPhone(String? phone) {
    if (phone == null || phone.trim().isEmpty) return '';
    final digits = phone.replaceAll(RegExp(r'\D'), '');
    if (digits.isEmpty) return '';

    if (digits.startsWith('00')) {
      return digits.substring(2);
    }
    if (digits.startsWith('0')) {
      return '2$digits';
    }
    if (digits.length == 10 && digits.startsWith('1')) {
      return '20$digits';
    }
    return digits;
  }

  /// Launches WhatsApp directly in the app with target phone and encoded invoice receipt text.
  static Future<bool> openWhatsApp({
    required String? phone,
    required String message,
  }) async {
    try {
      // Copy clean text to clipboard as safety backup
      try {
        await Clipboard.setData(ClipboardData(text: message));
      } catch (_) {}

      final cleanPhone = formatPhone(phone);
      final encoded = Uri.encodeComponent(message);

      // 1. Primary: Direct custom scheme (opens WhatsApp app directly without browser redirect)
      final nativeUrl = cleanPhone.isEmpty
          ? "whatsapp://send?text=$encoded"
          : "whatsapp://send?phone=$cleanPhone&text=$encoded";
      final nativeUri = Uri.parse(nativeUrl);

      if (await canLaunchUrl(nativeUri)) {
        return await launchUrl(nativeUri, mode: LaunchMode.externalApplication);
      }

      // 2. Secondary: Direct API intent URL
      final webApiUrl = cleanPhone.isEmpty
          ? "https://api.whatsapp.com/send?text=$encoded"
          : "https://api.whatsapp.com/send?phone=$cleanPhone&text=$encoded";
      final webApiUri = Uri.parse(webApiUrl);

      if (await canLaunchUrl(webApiUri)) {
        return await launchUrl(webApiUri, mode: LaunchMode.externalApplication);
      }

      // 3. Fallback: wa.me
      final waMeUrl = cleanPhone.isEmpty
          ? "https://wa.me/?text=$encoded"
          : "https://wa.me/$cleanPhone?text=$encoded";
      final waMeUri = Uri.parse(waMeUrl);

      return await launchUrl(waMeUri, mode: LaunchMode.externalApplication);
    } catch (e) {
      debugPrint("Error opening WhatsApp: $e");
      return false;
    }
  }

  /// Opens direct chat with a phone number in the WhatsApp app directly.
  static Future<bool> openDirectChat(String? phone) async {
    try {
      final cleanPhone = formatPhone(phone);
      if (cleanPhone.isEmpty) return false;

      // 1. Direct custom scheme
      final nativeUri = Uri.parse("whatsapp://send?phone=$cleanPhone");
      if (await canLaunchUrl(nativeUri)) {
        return await launchUrl(nativeUri, mode: LaunchMode.externalApplication);
      }

      // 2. API scheme
      final webApiUri = Uri.parse("https://api.whatsapp.com/send?phone=$cleanPhone");
      if (await canLaunchUrl(webApiUri)) {
        return await launchUrl(webApiUri, mode: LaunchMode.externalApplication);
      }

      // 3. Fallback wa.me
      final waMeUri = Uri.parse("https://wa.me/$cleanPhone");
      return await launchUrl(waMeUri, mode: LaunchMode.externalApplication);
    } catch (e) {
      debugPrint("Error opening direct WhatsApp chat: $e");
      return false;
    }
  }

  /// Builds a beautifully structured WhatsApp invoice message in Arabic with comprehensive details.
  static String buildInvoiceReceiptMessage({
    required String invoiceNumber,
    required String? customerName,
    String? customerPhone,
    String? cashierName,
    required DateTime date,
    required double totalAmount,
    required double paidAmount,
    required double remainingAmount,
    double subTotal = 0,
    double discountAmount = 0,
    double deliveryFee = 0,
    double taxAmount = 0,
    String? paymentMethod,
    List<Map<String, dynamic>>? items,
    String? storeName,
    String? storePhone,
    bool isInstallment = false,
    int numberOfMonths = 12,
    double monthlyInstallmentAmount = 0,
    String? guarantorName,
    String? guarantorPhone,
    bool isDelivery = false,
    String? deliveryAddress,
    String? deliveryFloor,
    String? recipientName,
    String? recipientPhone,
    bool isReserved = false,
    DateTime? targetDeliveryDate,
  }) {
    final currencyFmt = NumberFormat("#,##0.00", "ar_EG");
    final dateFmt = DateFormat("yyyy/MM/dd hh:mm a");
    final dayFmt = DateFormat("yyyy/MM/dd");

    final sName = (storeName != null && storeName.trim().isNotEmpty) ? storeName.trim() : "نظام المبيعات والأجهزة";
    final buffer = StringBuffer();

    buffer.writeln("*فاتورة مبيعات — $sName*");
    buffer.writeln("══════════════════");
    buffer.writeln("*رقم الفاتورة:* `$invoiceNumber`");
    buffer.writeln("*التاريخ:* ${dateFmt.format(date)}");

    if (customerName != null && customerName.trim().isNotEmpty && customerName != "Walk-in Customer") {
      buffer.writeln("*العميل:* ${customerName.trim()}");
    }
    if (customerPhone != null && customerPhone.trim().isNotEmpty) {
      buffer.writeln("*هاتف العميل:* ${customerPhone.trim()}");
    }
    if (cashierName != null && cashierName.trim().isNotEmpty) {
      buffer.writeln("*المسؤول / الكاشير:* ${cashierName.trim()}");
    }

    buffer.writeln("──────────────────");
    buffer.writeln("*تفاصيل الأصناف المطلوبة:*");

    if (items != null && items.isNotEmpty) {
      for (final item in items) {
        final name = item['productName'] ?? item['name'] ?? 'صنف';
        final qty = item['quantity'] ?? 1;
        final price = (item['unitPrice'] ?? item['price'] ?? 0.0) as num;
        final total = (item['total'] ?? (qty * price.toDouble())) as num;

        final qtyStr = (qty is num && qty % 1 == 0) ? qty.toInt().toString() : qty.toString();
        buffer.writeln("• *$name*");
        buffer.writeln("   $qtyStr × ${currencyFmt.format(price)} = ${currencyFmt.format(total)} ج.م");

        final serial = item['serialNumber'];
        if (serial != null && serial.toString().isNotEmpty) {
          buffer.writeln("   (سيريال: `$serial`)");
        }
      }
    } else {
      buffer.writeln("• إجمالي المشتريات: ${currencyFmt.format(totalAmount)} ج.م");
    }

    buffer.writeln("──────────────────");
    if (subTotal > 0) {
      buffer.writeln("*المجموع:* ${currencyFmt.format(subTotal)} ج.م");
    }
    if (discountAmount > 0) {
      buffer.writeln("*الخصم:* -${currencyFmt.format(discountAmount)} ج.م");
    }
    if (isDelivery || deliveryFee > 0) {
      buffer.writeln("*خدمة التوصيل:* ${deliveryFee > 0 ? "+${currencyFmt.format(deliveryFee)} ج.م" : "مشترك (مجاناً)"}");
      buffer.writeln("*تكلفة التوصيل:* ${currencyFmt.format(deliveryFee)} ج.م");
    }
    if (taxAmount > 0) {
      buffer.writeln("*الضريبة:* +${currencyFmt.format(taxAmount)} ج.م");
    }

    buffer.writeln("*الإجمالي النهائي:* *${currencyFmt.format(totalAmount)} ج.م*");
    buffer.writeln("*المدفوع:* ${currencyFmt.format(paidAmount)} ج.م");

    if (remainingAmount > 0 && !isInstallment) {
      buffer.writeln("*المتبقي (مديونية):* *${currencyFmt.format(remainingAmount)} ج.م*");
    }

    // Delivery Details
    if (isDelivery) {
      buffer.writeln("──────────────────");
      buffer.writeln("*تفاصيل التوصيل والتركيب للأجهزة:*");
      buffer.writeln("• حالة التوصيل: مشترك في خدمة التوصيل");
      buffer.writeln("• تكلفة التوصيل: ${currencyFmt.format(deliveryFee)} ج.م");
      if (deliveryAddress != null && deliveryAddress.trim().isNotEmpty) {
        buffer.writeln("• عنوان التوصيل: ${deliveryAddress.trim()}");
      }
      if (deliveryFloor != null && deliveryFloor.trim().isNotEmpty) {
        buffer.writeln("• الدور / الشقة: ${deliveryFloor.trim()}");
      }
      if (recipientName != null && recipientName.trim().isNotEmpty) {
        buffer.writeln("• اسم المستلم: ${recipientName.trim()}");
      }
      if (recipientPhone != null && recipientPhone.trim().isNotEmpty) {
        buffer.writeln("• هاتف المستلم: ${recipientPhone.trim()}");
      }
    }

    // Payment / Installment / Reservation / Credit Details
    if (isInstallment || paymentMethod == 'Installment') {
      buffer.writeln("──────────────────");
      buffer.writeln("*تفاصيل نظام التقسيط الشهري:*");
      final months = numberOfMonths > 0 ? numberOfMonths : 12;
      final monthly = monthlyInstallmentAmount > 0
          ? monthlyInstallmentAmount
          : (remainingAmount > 0 ? (remainingAmount / months) : 0);

      buffer.writeln("• المقدم المدفوع: ${currencyFmt.format(paidAmount)} ج.م");
      buffer.writeln("• متبقي إجمالي الأقساط: ${currencyFmt.format(remainingAmount)} ج.م");
      buffer.writeln("• مدة التقسيط: $months شهر");
      buffer.writeln("• قيمة القسط الشهري: ${currencyFmt.format(monthly)} ج.م / شهرياً");

      if (guarantorName != null && guarantorName.trim().isNotEmpty) {
        final gPhone = guarantorPhone != null && guarantorPhone.trim().isNotEmpty ? " (${guarantorPhone.trim()})" : "";
        buffer.writeln("• الضامن: ${guarantorName.trim()}$gPhone");
      }
    } else if (isReserved) {
      buffer.writeln("──────────────────");
      buffer.writeln("*تفاصيل الحجز المسبق (تسليم مؤجل / جهاز عرائس):*");
      buffer.writeln("• المدفوع (عربون): ${currencyFmt.format(paidAmount)} ج.م");
      buffer.writeln("• المتبقي عند الاستلام: ${currencyFmt.format(remainingAmount)} ج.م");
      if (targetDeliveryDate != null) {
        buffer.writeln("• تاريخ التسليم المتوقع: ${dayFmt.format(targetDeliveryDate)}");
      }
    } else if (paymentMethod == 'Credit' || (remainingAmount > 0 && paymentMethod != 'Installment')) {
      buffer.writeln("──────────────────");
      buffer.writeln("*طريقة الدفع:* آجل (حساب مديونية)");
      buffer.writeln("• المتبقي بذمة العميل: ${currencyFmt.format(remainingAmount)} ج.م");
    } else if (paymentMethod != null && paymentMethod.isNotEmpty) {
      buffer.writeln("──────────────────");
      final methodAr = switch (paymentMethod) {
        'Cash' => 'نقداً',
        'Card' || 'Visa' => 'بطاقة بنكية',
        'Credit' => 'آجل (دين)',
        'Installment' => 'تقسيط شهري',
        _ => paymentMethod,
      };
      buffer.writeln("*طريقة الدفع:* $methodAr");
    }

    buffer.writeln("══════════════════");
    buffer.writeln("شكراً لتعاملكم معنا ونسعد دائماً بخدمتكم!");

    if (storePhone != null && storePhone.trim().isNotEmpty) {
      buffer.writeln("خدمة العملاء والاستفسار: ${storePhone.trim()}");
    }

    return buffer.toString();
  }
}
