using System;
using System.Diagnostics;
using System.IO;
using System.Linq;
using System.Text;
using POS.Desktop.Services.Api;

namespace POS.Desktop.Services
{
    public static class WhatsAppInvoiceHelper
    {
        /// <summary>
        /// Cleans and formats phone number for international WhatsApp link (e.g. Egypt 201xxxxxxxxx).
        /// </summary>
        public static string FormatPhone(string? phone)
        {
            if (string.IsNullOrWhiteSpace(phone)) return string.Empty;
            
            var digits = new string(phone.Where(char.IsDigit).ToArray());
            if (string.IsNullOrEmpty(digits)) return string.Empty;

            // Remove international prefix 00
            if (digits.StartsWith("00"))
            {
                digits = digits.Substring(2);
            }

            // Egyptian standard numbers
            if (digits.StartsWith("0"))
            {
                digits = "2" + digits; // 010... -> 2010...
            }
            else if (digits.Length == 10 && digits.StartsWith("1"))
            {
                digits = "20" + digits;
            }

            return digits;
        }

        /// <summary>
        /// Constructs a formatted Arabic invoice receipt message optimized for WhatsApp messaging.
        /// </summary>
        public static string BuildInvoiceMessage(SaleDto sale, string? storeName = null, string? storePhone = null, string? footerMsg = null)
        {
            var sb = new StringBuilder();
            var sName = string.IsNullOrWhiteSpace(storeName) ? "نظام المبيعات والأجهزة" : storeName.Trim();

            sb.AppendLine($"*فاتورة مبيعات — {sName}*");
            sb.AppendLine("════════════════");
            sb.AppendLine($"*رقم الفاتورة:* `{sale.InvoiceNumber}`");
            sb.AppendLine($"*التاريخ:* {sale.SaleDate:yyyy/MM/dd hh:mm tt}");
            
            if (!string.IsNullOrWhiteSpace(sale.CustomerName) && sale.CustomerName != "Walk-in Customer")
            {
                sb.AppendLine($"*العميل:* {sale.CustomerName}");
            }
            if (!string.IsNullOrWhiteSpace(sale.CashierName))
            {
                sb.AppendLine($"*الكاشير:* {sale.CashierName}");
            }

            sb.AppendLine("────────────────");
            sb.AppendLine("*تفاصيل الأصناف:*");

            if (sale.Items != null && sale.Items.Count > 0)
            {
                foreach (var item in sale.Items)
                {
                    var qtyStr = item.Quantity % 1 == 0 ? item.Quantity.ToString("N0") : item.Quantity.ToString("N2");
                    sb.AppendLine($"• *{item.ProductName}*");
                    sb.AppendLine($"   {qtyStr} × {item.UnitPrice:N2} = {item.Total:N2} ج.م");
                    if (!string.IsNullOrWhiteSpace(item.SerialNumber))
                    {
                        sb.AppendLine($"   (سيريال: `{item.SerialNumber}`)");
                    }
                }
            }
            else
            {
                sb.AppendLine($"• إجمالي المشتريات: {sale.TotalAmount:N2} ج.م");
            }

            sb.AppendLine("────────────────");
            sb.AppendLine($"*المجموع:* {sale.SubTotal:N2} ج.م");
            
            if (sale.DiscountAmount > 0)
            {
                sb.AppendLine($"*الخصم:* -{sale.DiscountAmount:N2} ج.م");
            }
            if (sale.DeliveryFee > 0)
            {
                sb.AppendLine($"*خدمة التوصيل:* +{sale.DeliveryFee:N2} ج.م");
            }
            if (sale.TaxAmount > 0)
            {
                sb.AppendLine($"*الضريبة:* +{sale.TaxAmount:N2} ج.م");
            }    
            sb.AppendLine($"*الإجمالي النهائي:* *{sale.TotalAmount:N2} ج.م*");
            sb.AppendLine($"*المدفوع:* {sale.PaidAmount:N2} ج.م");
            if (sale.RemainingAmount > 0)
            {
                sb.AppendLine($"*المتبقي (مديونية):* *{sale.RemainingAmount:N2} ج.م*");
            }
            if (sale.IsInstallment)
            {
                sb.AppendLine("*نظام الفاتورة:* تقسيط شهري");
            }

            sb.AppendLine("════════════════");
            
            if (!string.IsNullOrWhiteSpace(footerMsg))
            {
                sb.AppendLine(footerMsg.Trim());
            }
            else
            {
                sb.AppendLine("شكراً لتعاملكم معنا ونسعد دائماً بخدمتكم!");
            }

            if (!string.IsNullOrWhiteSpace(storePhone))
            {
                sb.AppendLine($"خدمة العملاء والاستفسار: {storePhone.Trim()}");
            }

            return sb.ToString();
        }

        /// <summary>
        /// Opens WhatsApp Web or WhatsApp Desktop app with the target phone and encoded message.
        /// </summary>
        public static bool OpenWhatsApp(string? phone, string message)
        {
            try
            {
                var cleanPhone = FormatPhone(phone);
                var encoded = Uri.EscapeDataString(message);
                var url = string.IsNullOrWhiteSpace(cleanPhone)
                    ? $"https://wa.me/?text={encoded}"
                    : $"https://wa.me/{cleanPhone}?text={encoded}";

                Process.Start(new ProcessStartInfo
                {
                    FileName = url,
                    UseShellExecute = true
                });
                return true;
            }
            catch (Exception ex)
            {
                Console.WriteLine($"Error opening WhatsApp: {ex.Message}");
                return false;
            }
        }

        /// <summary>
        /// Opens a direct WhatsApp chat without predefined message text.
        /// </summary>
        public static bool OpenDirectChat(string? phone)
        {
            try
            {
                var cleanPhone = FormatPhone(phone);
                if (string.IsNullOrWhiteSpace(cleanPhone)) return false;

                var url = $"https://wa.me/{cleanPhone}";
                Process.Start(new ProcessStartInfo
                {
                    FileName = url,
                    UseShellExecute = true
                });
                return true;
            }
            catch (Exception ex)
            {
                Console.WriteLine($"Error opening WhatsApp chat: {ex.Message}");
                return false;
            }
        }

        /// <summary>
        /// Saves invoice PDF bytes to a dedicated local directory and returns the full path.
        /// </summary>
        public static string SaveInvoicePdf(byte[] pdfBytes, string invoiceNumber)
        {
            try
            {
                var folder = Path.Combine(Environment.GetFolderPath(Environment.SpecialFolder.MyDocuments), "POS_Invoices");
                if (!Directory.Exists(folder))
                {
                    Directory.CreateDirectory(folder);
                }

                var cleanInv = string.Concat(invoiceNumber.Split(Path.GetInvalidFileNameChars()));
                var fileName = $"فاتورة_{cleanInv}.pdf";
                var fullPath = Path.Combine(folder, fileName);

                File.WriteAllBytes(fullPath, pdfBytes);
                return fullPath;
            }
            catch (Exception ex)
            {
                Console.WriteLine($"Error saving invoice PDF: {ex.Message}");
                var tempPath = Path.Combine(Path.GetTempPath(), $"فاتورة_{invoiceNumber}.pdf");
                File.WriteAllBytes(tempPath, pdfBytes);
                return tempPath;
            }
        }

        /// <summary>
        /// Copies the specified file to the Windows Clipboard, allowing the user to paste (Ctrl+V)
        /// directly into WhatsApp Web or WhatsApp Desktop as an attachment.
        /// </summary>
        public static bool CopyFileToClipboard(string filePath)
        {
            try
            {
                if (!File.Exists(filePath)) return false;

                if (System.Windows.Application.Current != null)
                {
                    System.Windows.Application.Current.Dispatcher.Invoke(() =>
                    {
                        var list = new System.Collections.Specialized.StringCollection { filePath };
                        System.Windows.Clipboard.SetFileDropList(list);
                    });
                    return true;
                }
                return false;
            }
            catch (Exception ex)
            {
                Console.WriteLine($"Error copying file to clipboard: {ex.Message}");
                return false;
            }
        }

        /// <summary>
        /// Opens Windows Explorer with the generated invoice PDF file selected.
        /// </summary>
        public static bool ShowFileInExplorer(string filePath)
        {
            try
            {
                if (!File.Exists(filePath)) return false;

                Process.Start(new ProcessStartInfo
                {
                    FileName = "explorer.exe",
                    Arguments = $"/select,\"{filePath}\"",
                    UseShellExecute = true
                });
                return true;
            }
            catch (Exception ex)
            {
                Console.WriteLine($"Error showing file in explorer: {ex.Message}");
                return false;
            }
        }

        /// <summary>
        /// Opens WhatsApp chat with a clean intro message introducing the attached invoice file.
        /// </summary>
        public static bool OpenWhatsAppChatForPdf(string? phone, string invoiceNumber, string? storeName = null)
        {
            var sName = string.IsNullOrWhiteSpace(storeName) ? "نظام المبيعات والأجهزة" : storeName.Trim();
            var intro = $"*فاتورة مبيعات — {sName}*\nمرحباً بحضرتك، مرفق ملف فاتورة الشراء المطبوعة رقم: *#{invoiceNumber}* (ملف PDF)";
            return OpenWhatsApp(phone, intro);
        }
    }
}

