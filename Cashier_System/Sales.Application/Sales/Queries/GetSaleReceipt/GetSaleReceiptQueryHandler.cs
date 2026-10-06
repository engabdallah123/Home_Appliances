using Dapper;
using POS.Shared.Application.Database;
using POS.Shared.Application.IService;
using POS.Shared.Application.Messaging;
using POS.Shared.Domain;
using Sales.Domain.Sales;

namespace Sales.Application.Sales.Queries.GetSaleReceipt
{
    internal sealed class GetSaleReceiptQueryHandler : IQueryHandler<GetSaleReceiptQuery, ReceiptResponse>
    {
        private readonly ISqlConnectionFactory _sqlConnectionFactory;
        private readonly IFileService _fileService;

        public GetSaleReceiptQueryHandler(
            ISqlConnectionFactory sqlConnectionFactory,
            IFileService fileService)
        {
            _sqlConnectionFactory = sqlConnectionFactory;
            _fileService = fileService;
        }

        public async Task<Result<ReceiptResponse>> Handle(GetSaleReceiptQuery request, CancellationToken cancellationToken)
        {
            using var connection = _sqlConnectionFactory.CreateConnection();

            const string settingsSql = """
                SELECT TOP 1
                    StoreName, Address, Phone, Currency, InvoiceFooterMessage, LogoUrl, HeaderImageUrl, FooterImageUrl
                FROM [Settings].[StoreSettings]
                """;

            var setting = await connection.QuerySingleOrDefaultAsync(settingsSql);
            var storeName = setting?.StoreName ?? "معرض الأجهزة الكهربائية";
            var address = setting?.Address;
            var phone = setting?.Phone;
            var currency = setting?.Currency ?? "EGP";
            var invoiceFooterMessage = setting?.InvoiceFooterMessage ?? "شكراً لزيارتكم!";
            var logoUrl = (string?)setting?.LogoUrl;
            var headerImageUrl = (string?)setting?.HeaderImageUrl ?? "uploads/invoices/default_header.png";
            var footerImageUrl = (string?)setting?.FooterImageUrl ?? "uploads/invoices/default_footer.png";

            byte[]? logoBytes = null;
            if (!string.IsNullOrWhiteSpace(logoUrl))
            {
                try
                {
                    var logoResult = await _fileService.GetFileAsByteArrayAsync(logoUrl);
                    if (logoResult.IsSuccess && logoResult.Value != null && logoResult.Value.Length > 0)
                    {
                        logoBytes = logoResult.Value;
                    }
                }
                catch { }
            }

            if (logoBytes == null || logoBytes.Length == 0)
            {
                try
                {
                    var watermarkRes = await _fileService.GetFileAsByteArrayAsync("uploads/invoices/default_watermark.png");
                    if (watermarkRes.IsSuccess && watermarkRes.Value != null && watermarkRes.Value.Length > 0)
                    {
                        logoBytes = watermarkRes.Value;
                    }
                }
                catch { }
            }

            byte[]? headerImageBytes = null;
            if (!string.IsNullOrWhiteSpace(headerImageUrl))
            {
                try
                {
                    var headerRes = await _fileService.GetFileAsByteArrayAsync(headerImageUrl);
                    if (headerRes.IsSuccess && headerRes.Value != null && headerRes.Value.Length > 0)
                    {
                        headerImageBytes = headerRes.Value;
                    }
                }
                catch { }
            }

            byte[]? footerImageBytes = null;
            if (!string.IsNullOrWhiteSpace(footerImageUrl))
            {
                try
                {
                    var footerRes = await _fileService.GetFileAsByteArrayAsync(footerImageUrl);
                    if (footerRes.IsSuccess && footerRes.Value != null && footerRes.Value.Length > 0)
                    {
                        footerImageBytes = footerRes.Value;
                    }
                }
                catch { }
            }

            const string saleSql = """
                SELECT 
                    s.InvoiceNumber, s.SaleDate,
                    ISNULL(u.FullName, 'Cashier') AS CashierName,
                    c.Name AS CustomerName,
                    c.Phone AS CustomerPhone,
                    c.Address AS CustomerAddress,
                    s.SubTotal, s.DiscountAmount, s.TaxAmount, s.TotalAmount,
                    s.PaidAmount, s.ChangeAmount, s.PaymentMethod,
                    s.Notes,
                    ISNULL(s.DeliveryFee, 0) AS DeliveryFee,
                    ISNULL(s.IsDelivery, 0) AS IsDelivery,
                    s.RecipientName, s.RecipientPhone, s.DeliveryAddress,
                    s.DriverName,
                    ISNULL(s.IsReserved, 0) AS IsReserved, s.TargetDeliveryDate,
                    ISNULL(s.IsInstallment, 0) AS IsInstallment,
                    inst.MonthlyInstallmentAmount, inst.NumberOfMonths, inst.DownPayment,
                    inst.InterestPercentage, inst.InterestAmount, inst.TotalInstallmentAmount, inst.TotalCashAmount,
                    inst.GuarantorName, inst.GuarantorPhone,
                    ISNULL((
                        SELECT COUNT(*) 
                        FROM [Sales].[Sales] s2 
                        WHERE s2.ShiftId = s.ShiftId 
                          AND (s2.SaleDate < s.SaleDate OR (s2.SaleDate = s.SaleDate AND s2.Id <= s.Id))
                    ), 1) AS OrderNumber
                FROM [Sales].[Sales] s
                LEFT JOIN [Identity].[AspNetUsers] u ON s.CashierId = CAST(u.Id AS uniqueidentifier)
                LEFT JOIN [Sales].[Customers] c ON s.CustomerId = c.Id
                LEFT JOIN [Sales].[InstallmentContracts] inst ON (s.InstallmentContractId = inst.Id OR inst.SaleId = s.Id)
                WHERE s.Id = @SaleId
                """;

            var saleHeader = await connection.QuerySingleOrDefaultAsync(saleSql, new { request.SaleId });
            if (saleHeader is null)
                return Result<ReceiptResponse>.Failure(SaleErrors.NotFound(request.SaleId));

            const string itemsSql = """
                SELECT 
                    i.Id, i.ProductId, p.NameAr AS ProductName, p.Barcode,
                    i.Quantity, i.UnitPrice, i.Discount, i.Tax, i.Total,
                    i.SerialNumber,
                    b.Name AS BrandName, p.ModelNumber, ISNULL(p.WarrantyPeriodMonths, 12) AS WarrantyPeriodMonths, p.MaintenanceAgent,
                    p.BaseUnit, p.ParentUnit, ISNULL(p.ConversionFactor, 1) AS ConversionFactor,
                    ISNULL(p.SellingPrice, 0) AS SellingPrice, ISNULL(p.WholesalePrice, 0) AS WholesalePrice
                FROM [Sales].[SaleItems] i
                LEFT JOIN [Inventory].[Products] p ON i.ProductId = p.Id
                LEFT JOIN [Inventory].[Brands] b ON p.BrandId = b.Id
                WHERE i.SaleId = @SaleId
                """;

            var rawItems = await connection.QueryAsync<dynamic>(itemsSql, new { request.SaleId });
            var items = new List<SaleItemResponse>();
            foreach (var r in rawItems)
            {
                decimal qty = (decimal)r.Quantity;
                decimal unitPrice = (decimal)r.UnitPrice;
                decimal sellingPrice = (decimal)r.SellingPrice;
                decimal wholesalePrice = (decimal)r.WholesalePrice;
                int factor = (int)r.ConversionFactor;
                string baseUnit = !string.IsNullOrWhiteSpace((string?)r.BaseUnit) ? (string)r.BaseUnit : "قطعة";
                string parentUnit = !string.IsNullOrWhiteSpace((string?)r.ParentUnit) ? (string)r.ParentUnit : "كرتونة";

                string priceType = (wholesalePrice > 0 && sellingPrice > wholesalePrice && unitPrice <= wholesalePrice) ? "جملة" : "قطاعي";
                string unitName;
                string packagingInfo;
                decimal displayedQuantity = qty;

                if (factor > 1 && qty >= factor && (qty % factor == 0))
                {
                    int cartons = (int)(qty / factor);
                    unitName = parentUnit;
                    packagingInfo = $"{cartons} {parentUnit} ({qty:G29} {baseUnit})";
                    displayedQuantity = cartons;
                }
                else
                {
                    unitName = baseUnit;
                    packagingInfo = $"{qty:G29} {baseUnit}";
                }

                items.Add(new SaleItemResponse(
                    (Guid)r.Id,
                    (Guid)r.ProductId,
                    (string?)r.ProductName,
                    (string?)r.Barcode,
                    displayedQuantity,
                    unitPrice,
                    (decimal)r.Discount,
                    (decimal)r.Tax,
                    (decimal)r.Total,
                    unitName,
                    priceType,
                    packagingInfo,
                    (string?)r.SerialNumber,
                    (string?)r.BrandName,
                    (string?)r.ModelNumber,
                    (int)(r.WarrantyPeriodMonths ?? 0),
                    (string?)r.MaintenanceAgent));
            }

            string? notes = (string?)saleHeader.Notes;
            string? orderType = (!string.IsNullOrWhiteSpace(notes) && notes != "POS Desktop Sale") ? notes : null;
            int orderNumber = (int)(saleHeader.OrderNumber ?? 1);
            if (orderNumber <= 0) orderNumber = 1;

            bool isDelivery = (bool)(saleHeader.IsDelivery ?? false);
            decimal deliveryFee = (decimal)(saleHeader.DeliveryFee ?? 0);
            string? recipientName = (string?)saleHeader.RecipientName;
            string? recipientPhone = (string?)saleHeader.RecipientPhone;
            string? deliveryAddress = (string?)saleHeader.DeliveryAddress;
            string? driverName = (string?)saleHeader.DriverName;
            string? customerPhone = !string.IsNullOrWhiteSpace(recipientPhone) ? recipientPhone : (string?)saleHeader.CustomerPhone;
            string? customerAddress = !string.IsNullOrWhiteSpace(deliveryAddress) ? deliveryAddress : (string?)saleHeader.CustomerAddress;

            bool isReserved = (bool)(saleHeader.IsReserved ?? false);
            DateTime? targetDeliveryDate = (DateTime?)saleHeader.TargetDeliveryDate;
            bool isInstallment = (bool)(saleHeader.IsInstallment ?? false);

            decimal? instInterestPct = saleHeader.InterestPercentage != null ? (decimal)saleHeader.InterestPercentage : null;
            decimal? instInterestAmt = saleHeader.InterestAmount != null ? (decimal)saleHeader.InterestAmount : null;
            decimal? instTotalCash = saleHeader.TotalCashAmount != null ? (decimal)saleHeader.TotalCashAmount : null;
            decimal? instRemaining = saleHeader.TotalInstallmentAmount != null ? (decimal)saleHeader.TotalInstallmentAmount : null;
            decimal? instMonthly = saleHeader.MonthlyInstallmentAmount != null ? (decimal)saleHeader.MonthlyInstallmentAmount : null;
            int? instMonths = saleHeader.NumberOfMonths != null ? (int)saleHeader.NumberOfMonths : null;
            decimal? instDown = saleHeader.DownPayment != null ? (decimal)saleHeader.DownPayment : null;
            string? guarantorName = (string?)saleHeader.GuarantorName;
            string? guarantorPhone = (string?)saleHeader.GuarantorPhone;

            string? installmentSummary = null;
            if (isInstallment && instMonthly != null)
            {
                installmentSummary = $"تقسيط: نقدي {instTotalCash ?? saleHeader.SubTotal:N2} {currency} | مقدم {instDown ?? saleHeader.PaidAmount:N2} {currency} | فائدة {instInterestPct ?? 0:G29}% ({instInterestAmt ?? 0:N2} {currency}) | قسط {instMonthly:N2} {currency}/شهر ({instMonths ?? 12} شهر)";
            }

            string rawPaymentMethod = (string?)saleHeader.PaymentMethod ?? "Cash";
            string paymentMethod = rawPaymentMethod switch
            {
                "Installment" or "تقسيط" => "تقسيط",
                "Credit" or "آجل" => "آجل",
                "Cash" or "نقدي" or "كاش" => "نقدي",
                "Visa" or "Card" or "بطاقة" or "فيزا" => "فيزا / بطاقة",
                _ => rawPaymentMethod
            };

            string saleType;
            if (isInstallment || rawPaymentMethod is "Installment" or "تقسيط")
            {
                saleType = "تقسيط";
            }
            else if (rawPaymentMethod is "Credit" or "آجل" || (saleHeader.PaidAmount + 0.01m < saleHeader.TotalAmount))
            {
                saleType = "آجل";
            }
            else
            {
                saleType = "كاش";
            }

            var receipt = new ReceiptResponse(
                storeName,
                address,
                phone,
                saleHeader.InvoiceNumber,
                saleHeader.SaleDate,
                saleHeader.CashierName,
                saleHeader.CustomerName,
                items,
                saleHeader.SubTotal,
                saleHeader.DiscountAmount,
                saleHeader.TaxAmount,
                saleHeader.TotalAmount,
                saleHeader.PaidAmount,
                saleHeader.ChangeAmount,
                paymentMethod,
                currency,
                invoiceFooterMessage,
                logoUrl,
                logoBytes,
                headerImageUrl,
                headerImageBytes,
                footerImageUrl,
                footerImageBytes,
                orderType,
                orderNumber,
                isDelivery,
                recipientName,
                recipientPhone,
                deliveryAddress,
                deliveryFee,
                isReserved,
                targetDeliveryDate,
                isInstallment,
                installmentSummary,
                customerPhone,
                customerAddress,
                driverName,
                saleType,
                instInterestPct,
                instInterestAmt,
                instTotalCash,
                instRemaining,
                instMonthly,
                instMonths,
                instDown,
                guarantorName,
                guarantorPhone);

            return Result<ReceiptResponse>.Success(receipt);
        }
    }
}
