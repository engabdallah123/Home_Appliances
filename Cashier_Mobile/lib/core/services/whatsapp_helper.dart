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

  /// Launches WhatsApp with target phone and encoded invoice receipt text.
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
      final url = cleanPhone.isEmpty
          ? "https://wa.me/?text=$encoded"
          : "https://wa.me/$cleanPhone?text=$encoded";

      final uri = Uri.parse(url);
      if (await canLaunchUrl(uri)) {
        return await launchUrl(uri, mode: LaunchMode.externalApplication);
      }
      return false;
    } catch (e) {
      debugPrint("Error opening WhatsApp: $e");
      return false;
    }
  }

  /// Opens direct chat with a phone number.
  static Future<bool> openDirectChat(String? phone) async {
    try {
      final cleanPhone = formatPhone(phone);
      if (cleanPhone.isEmpty) return false;

      final uri = Uri.parse("https://wa.me/$cleanPhone");
      if (await canLaunchUrl(uri)) {
        return await launchUrl(uri, mode: LaunchMode.externalApplication);
      }
      return false;
    } catch (e) {
      debugPrint("Error opening direct WhatsApp chat: $e");
      return false;
    }
  }

  /// Builds a beautifully structured WhatsApp invoice message in Arabic without emojis to prevent '?' encoding bugs.
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
  }) {
    final currencyFmt = NumberFormat("#,##0.00", "ar_EG");
    final dateFmt = DateFormat("yyyy/MM/dd hh:mm a");

    final sName = (storeName != null && storeName.trim().isNotEmpty) ? storeName.trim() : "نظام المبيعات والأجهزة";
    final buffer = StringBuffer();

    buffer.writeln("*فاتورة مبيعات — $sName*");
    buffer.writeln("══════════════════");
    buffer.writeln("*رقم الفاتورة:* `$invoiceNumber`");
    buffer.writeln("*التاريخ:* ${dateFmt.format(date)}");

    if (customerName != null && customerName.trim().isNotEmpty && customerName != "Walk-in Customer") {
      buffer.writeln("*العميل:* ${customerName.trim()}");
    }
    if (cashierName != null && cashierName.trim().isNotEmpty) {
      buffer.writeln("*المسؤول:* ${cashierName.trim()}");
    }

    buffer.writeln("──────────────────");
    buffer.writeln("*تفاصيل الأصناف:*");

    if (items != null && items.isNotEmpty) {
      for (final item in items) {
        final name = item['productName'] ?? item['name'] ?? 'صنف';
        final qty = item['quantity'] ?? 1;
        final price = item['unitPrice'] ?? item['price'] ?? 0.0;
        final total = item['total'] ?? (qty * price);

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
    if (deliveryFee > 0) {
      buffer.writeln("*خدمة التوصيل:* +${currencyFmt.format(deliveryFee)} ج.م");
    }
    if (taxAmount > 0) {
      buffer.writeln("*الضريبة:* +${currencyFmt.format(taxAmount)} ج.م");
    }

    buffer.writeln("*الإجمالي النهائي:* *${currencyFmt.format(totalAmount)} ج.م*");
    buffer.writeln("*المدفوع:* ${currencyFmt.format(paidAmount)} ج.م");

    if (remainingAmount > 0) {
      buffer.writeln("*المتبقي (مديونية):* *${currencyFmt.format(remainingAmount)} ج.م*");
    }

    if (paymentMethod != null && paymentMethod.isNotEmpty) {
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

