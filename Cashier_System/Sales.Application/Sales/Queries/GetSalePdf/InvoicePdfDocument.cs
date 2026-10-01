using System.Globalization;
using QuestPDF.Fluent;
using QuestPDF.Helpers;
using QuestPDF.Infrastructure;
using Sales.Application.Sales.Queries;

namespace Sales.Application.Sales.Queries.GetSalePdf
{
    public class InvoicePdfDocument : IDocument
    {
        private static readonly CultureInfo ArabicCulture = new("ar-EG");
        private readonly ReceiptResponse _receipt;
        private readonly bool _isThermal;
        private readonly byte[]? _faintWatermarkBytes;

        public InvoicePdfDocument(ReceiptResponse receipt, bool isThermal = false)
        {
            _receipt = receipt;
            _isThermal = isThermal;
            if (_receipt.LogoBytes != null && _receipt.LogoBytes.Length > 0)
            {
                _faintWatermarkBytes = WatermarkHelper.MakeFaintWatermark(_receipt.LogoBytes, 0.15f);
            }
        }

        public DocumentMetadata GetMetadata() => DocumentMetadata.Default;

        public void Compose(IDocumentContainer container)
        {
            container.Page(page =>
            {
                page.Size(PageSizes.A4);
                page.Margin(20, Unit.Point);
                page.PageColor(Colors.White);
                page.DefaultTextStyle(x => x.FontSize(10).FontFamily("Cairo", "Segoe UI", "Tahoma", "Arial"));

                page.Content().Column(column =>
                {
                    // 1. Header Image (or fallback)
                    if (_receipt.HeaderImageBytes != null && _receipt.HeaderImageBytes.Length > 0)
                    {
                        column.Item().AlignCenter().Height(90).Image(_receipt.HeaderImageBytes).FitArea();
                    }
                    else
                    {
                        ComposeFallbackHeader(column);
                    }

                    // 2. Info Section (Customer Name, Date, Phone, Address, Payment Type, Delivery / Driver)
                    column.Item().PaddingTop(4).PaddingBottom(6).Column(infoCol =>
                    {
                        var dateStr = _receipt.SaleDate.ToString("yyyy / MM / dd");
                        var customerName = !string.IsNullOrWhiteSpace(_receipt.CustomerName) ? _receipt.CustomerName : "........................................";
                        var customerPhone = !string.IsNullOrWhiteSpace(_receipt.CustomerPhone) ? _receipt.CustomerPhone : (!string.IsNullOrWhiteSpace(_receipt.RecipientPhone) ? _receipt.RecipientPhone : "....................");
                        var customerAddress = !string.IsNullOrWhiteSpace(_receipt.CustomerAddress) ? _receipt.CustomerAddress : (!string.IsNullOrWhiteSpace(_receipt.DeliveryAddress) ? _receipt.DeliveryAddress : "........................................");

                        string saleTypeDisplay = _receipt.SaleType switch
                        {
                            "تقسيط" => "تقسيط",
                            "آجل" => "آجل",
                            "كاش" => "كاش (نقدي)",
                            _ => (!string.IsNullOrWhiteSpace(_receipt.PaymentMethod) ? _receipt.PaymentMethod : "كاش")
                        };

                        // Row 1: Date, Invoice #, Customer Name
                        infoCol.Item().Row(r1 =>
                        {
                            r1.ConstantItem(170).AlignLeft().Text(FormatRtl($"التاريخ : {dateStr}")).FontSize(11f).Bold();

                            if (!string.IsNullOrWhiteSpace(_receipt.InvoiceNumber))
                            {
                                r1.RelativeItem().AlignCenter().Text(FormatRtl($"فاتورة رقم : {_receipt.InvoiceNumber}")).FontSize(10.5f).SemiBold().FontColor(Colors.Grey.Darken3);
                            }
                            else
                            {
                                r1.RelativeItem();
                            }

                            r1.ConstantItem(260).AlignRight().Text(FormatRtl($"الإسم : {customerName}")).FontSize(11.5f).Bold();
                        });

                        // Row 2: Phone, Payment Type, Address
                        infoCol.Item().PaddingTop(3).Row(r2 =>
                        {
                            r2.ConstantItem(170).AlignLeft().Text(FormatRtl($"الرقم : {customerPhone}")).FontSize(10.5f).SemiBold();

                            r2.RelativeItem().AlignCenter().Text(t =>
                            {
                                t.Span(FormatRtl("الدفع : ")).FontSize(10f).Bold();
                                var typeSpan = t.Span(FormatRtl($"[ {saleTypeDisplay} ]")).FontSize(10.5f).ExtraBold();
                                if (saleTypeDisplay.Contains("تقسيط"))
                                    typeSpan.FontColor(Colors.Blue.Darken2);
                                else if (saleTypeDisplay.Contains("آجل"))
                                    typeSpan.FontColor(Colors.Red.Darken2);
                                else
                                    typeSpan.FontColor(Colors.Green.Darken2);
                            });

                            r2.ConstantItem(260).AlignRight().Text(FormatRtl($"العنوان : {customerAddress}")).FontSize(10.5f).SemiBold();
                        });

                        // Row 3: If Delivery or Driver is present
                        if (_receipt.IsDelivery || !string.IsNullOrWhiteSpace(_receipt.DriverName))
                        {
                            infoCol.Item().PaddingTop(3).Row(r3 =>
                            {
                                if (_receipt.DeliveryFee > 0)
                                {
                                    r3.ConstantItem(170).AlignLeft().Text(FormatRtl($"خدمة التوصيل : {_receipt.DeliveryFee:N2} {_receipt.Currency}")).FontSize(10f).Bold();
                                }
                                else
                                {
                                    r3.ConstantItem(170).AlignLeft().Text(FormatRtl("توصيل : ديليفري")).FontSize(10f).Bold().FontColor(Colors.Blue.Darken2);
                                }

                                var driverDisplay = !string.IsNullOrWhiteSpace(_receipt.DriverName) ? _receipt.DriverName : "....................";
                                r3.RelativeItem().AlignCenter().Text(FormatRtl($"مندوب التوصيل : {driverDisplay}")).FontSize(10.5f).Bold().FontColor(Colors.Indigo.Darken2);

                                r3.ConstantItem(260).AlignRight().Text(FormatRtl("النوع : توصيل طلبات (ديليفري)")).FontSize(10f).SemiBold();
                            });
                        }

                        // If installment summary exists
                        if (_receipt.IsInstallment && !string.IsNullOrWhiteSpace(_receipt.InstallmentSummary))
                        {
                            infoCol.Item().PaddingTop(3).Background(Colors.Grey.Lighten4).Padding(3).AlignCenter()
                                .Text(FormatRtl(_receipt.InstallmentSummary)).FontSize(9.5f).Bold().FontColor(Colors.Blue.Darken3);
                        }
                    });

                    // 3. Main Table & Watermark in a Bordered Container
                    column.Item().Border(1.8f).BorderColor(Colors.Black).Layers(layers =>
                    {
                        // Watermark Layer (Ultra-faint, subtle background watermark)
                        if (_faintWatermarkBytes != null && _faintWatermarkBytes.Length > 0)
                        {
                            layers.Layer().AlignCenter().AlignMiddle().Width(240).Height(240).Image(_faintWatermarkBytes).FitArea();
                        }

                        // Table Content
                        layers.PrimaryLayer().Column(boxCol =>
                        {
                            boxCol.Item().Table(table =>
                            {
                                table.ColumnsDefinition(columns =>
                                {
                                    columns.ConstantColumn(85);  // الإجمالي
                                    columns.ConstantColumn(80);  // سعر الوحدة
                                    columns.ConstantColumn(55);  // العدد
                                    columns.RelativeColumn(1);   // الصــــنـــــف
                                    columns.ConstantColumn(38);  // الرقم
                                });

                                // Header Row
                                table.Header(header =>
                                {
                                    header.Cell().BorderRight(1.2f).BorderColor(Colors.Black).BorderBottom(1.5f).BorderColor(Colors.Black)
                                        .PaddingVertical(5).AlignCenter().Text("الإجمالي").FontSize(11.5f).Bold();

                                    header.Cell().BorderRight(1.2f).BorderColor(Colors.Black).BorderBottom(1.5f).BorderColor(Colors.Black)
                                        .PaddingVertical(2).AlignCenter().Column(c =>
                                        {
                                            c.Item().AlignCenter().Text("ســعــر").FontSize(9.5f).Bold();
                                            c.Item().AlignCenter().Text("الوحدة").FontSize(9.5f).Bold();
                                        });

                                    header.Cell().BorderRight(1.2f).BorderColor(Colors.Black).BorderBottom(1.5f).BorderColor(Colors.Black)
                                        .PaddingVertical(5).AlignCenter().Text("العدد").FontSize(11.5f).Bold();

                                    header.Cell().BorderRight(1.2f).BorderColor(Colors.Black).BorderBottom(1.5f).BorderColor(Colors.Black)
                                        .PaddingVertical(5).AlignCenter().Text("الصـــــنـــــف").FontSize(13.5f).Bold();

                                    header.Cell().BorderBottom(1.5f).BorderColor(Colors.Black)
                                        .PaddingVertical(5).AlignCenter().Text("الرقم").FontSize(11.5f).Bold();
                                });

                                // Body rows (At least 15 rows)
                                int totalRows = Math.Max(_receipt.Items.Count, 15);
                                for (int i = 0; i < totalRows; i++)
                                {
                                    bool hasItem = i < _receipt.Items.Count;
                                    var item = hasItem ? _receipt.Items[i] : null;
                                    bool isLastRow = i == totalRows - 1;

                                    // Col 0: الإجمالي
                                    RenderTableCell(table.Cell(), isLastRow, true, c =>
                                    {
                                        if (hasItem && item != null)
                                            c.AlignCenter().Text($"{item.Total:N2}").FontSize(10.5f).Bold();
                                    });

                                    // Col 1: سعر الوحدة
                                    RenderTableCell(table.Cell(), isLastRow, true, c =>
                                    {
                                        if (hasItem && item != null)
                                            c.AlignCenter().Text($"{item.UnitPrice:N2}").FontSize(10f);
                                    });

                                    // Col 2: العدد
                                    RenderTableCell(table.Cell(), isLastRow, true, c =>
                                    {
                                        if (hasItem && item != null)
                                            c.AlignCenter().Text($"{item.Quantity:G29}").FontSize(10.5f).Bold();
                                    });

                                    // Col 3: الصنف
                                    RenderTableCell(table.Cell(), isLastRow, true, c =>
                                    {
                                        if (hasItem && item != null)
                                            c.AlignRight().PaddingRight(6).Text(FormatRtl(item.ProductName)).FontSize(10.5f).SemiBold();
                                    });

                                    // Col 4: الرقم
                                    RenderTableCell(table.Cell(), isLastRow, false, c =>
                                    {
                                        c.AlignCenter().Text($"{i + 1}").FontSize(10.5f).Bold();
                                    });
                                }
                            });

                            // Bottom Summary Row inside the table box with Total Amount & Total Pieces
                            var totalPieces = _receipt.Items.Sum(i => i.Quantity);
                            boxCol.Item().BorderTop(1.5f).BorderColor(Colors.Black).MinHeight(32).Row(bRow =>
                            {
                                // Box with total amount (under Col 0: الإجمالي)
                                bRow.ConstantItem(85).BorderRight(1.2f).BorderColor(Colors.Black).PaddingVertical(4).AlignCenter().AlignMiddle()
                                    .Text($"{_receipt.TotalAmount:N2}").FontSize(12f).ExtraBold();

                                // Label الإجمالي النهائي (under Col 1: سعر الوحدة)
                                bRow.ConstantItem(80).BorderRight(1.2f).BorderColor(Colors.Black).PaddingVertical(4).AlignCenter().AlignMiddle()
                                    .Text(FormatRtl("الإجمالي النهائي")).FontSize(10.5f).ExtraBold();

                                // Total Pieces Count (under Col 2: العدد)
                                bRow.ConstantItem(55).BorderRight(1.2f).BorderColor(Colors.Black).PaddingVertical(4).AlignCenter().AlignMiddle()
                                    .Text($"{totalPieces:G29}").FontSize(11f).ExtraBold();

                                // Under Col 3 & 4: Total Pieces label + Signature area
                                bRow.RelativeItem().PaddingHorizontal(10).AlignMiddle().Row(subRow =>
                                {
                                    subRow.ConstantItem(150).AlignLeft().Text(FormatRtl($"إجمالي عدد القطع : {totalPieces:G29} قطعة")).FontSize(10.5f).Bold();
                                    subRow.RelativeItem().AlignRight().Text(FormatRtl("التوقيع / .....................................................")).FontSize(10.5f).Bold();
                                });
                            });
                        });
                    });

                    // 4. Footer Section
                    if (_receipt.FooterImageBytes != null && _receipt.FooterImageBytes.Length > 0)
                    {
                        column.Item().PaddingTop(8).AlignCenter().Height(65).Image(_receipt.FooterImageBytes).FitArea();
                    }
                    else
                    {
                        ComposeFallbackFooter(column);
                    }
                });
            });
        }

        private static void RenderTableCell(IContainer cell, bool isLastRow, bool hasRightBorder, Action<IContainer> content)
        {
            var c = cell;
            if (hasRightBorder)
            {
                c = c.BorderRight(1.2f).BorderColor(Colors.Black);
            }

            if (!isLastRow)
            {
                c = c.BorderBottom(0.6f).BorderColor(Colors.Grey.Darken1);
            }

            c.MinHeight(19).PaddingVertical(1.5f).PaddingHorizontal(3).Element(content);
        }

        private void ComposeFallbackHeader(ColumnDescriptor column)
        {
            column.Item().Row(row =>
            {
                row.RelativeItem().Column(c =>
                {
                    c.Item().Text(FormatRtl(_receipt.StoreName)).FontSize(18).Bold().FontColor(Colors.Black);
                    if (!string.IsNullOrWhiteSpace(_receipt.Address))
                        c.Item().Text(FormatRtl(_receipt.Address)).FontSize(9.5f).FontColor(Colors.Grey.Darken2);
                    if (!string.IsNullOrWhiteSpace(_receipt.Phone))
                        c.Item().Text(FormatRtl($"هاتف: {_receipt.Phone}")).FontSize(9.5f).FontColor(Colors.Grey.Darken2);
                });

                if (_receipt.LogoBytes != null && _receipt.LogoBytes.Length > 0)
                {
                    row.ConstantItem(75).Height(75).Image(_receipt.LogoBytes).FitArea();
                }
            });
        }

        private void ComposeFallbackFooter(ColumnDescriptor column)
        {
            column.Item().PaddingTop(8).Column(fc =>
            {
                // Pill 1: Store name & phone
                fc.Item().PaddingBottom(4).Background(Colors.Black).PaddingVertical(4).PaddingHorizontal(16).Row(r =>
                {
                    if (!string.IsNullOrWhiteSpace(_receipt.Phone))
                    {
                        r.RelativeItem().AlignLeft().Text(FormatRtl($"جوال / {_receipt.Phone}")).FontSize(9.5f).Bold().FontColor(Colors.White);
                    }
                    r.RelativeItem().AlignRight().Text(FormatRtl(_receipt.StoreName)).FontSize(10f).Bold().FontColor(Colors.White);
                });

                // Pill 2: Address
                if (!string.IsNullOrWhiteSpace(_receipt.Address))
                {
                    fc.Item().Background(Colors.Black).PaddingVertical(4).PaddingHorizontal(16).AlignCenter()
                        .Text(FormatRtl($"العنوان / {_receipt.Address}")).FontSize(9.5f).Bold().FontColor(Colors.White);
                }
            });
        }

        private static string FormatRtl(string? text)
        {
            if (string.IsNullOrWhiteSpace(text)) return string.Empty;
            return $"\u202B\u200F{text}\u200F\u202C";
        }
    }
}
