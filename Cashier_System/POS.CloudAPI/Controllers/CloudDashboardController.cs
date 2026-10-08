using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
using Microsoft.EntityFrameworkCore;
using POS.CloudAPI.Database;
using POS.CloudAPI.DTOs;
using POS.CloudAPI.Entities;
using System.Security.Claims;

namespace POS.CloudAPI.Controllers
{
    [ApiController]
    [Route("api/cloud/dashboard")]
    [Authorize]
    public class CloudDashboardController : ControllerBase
    {
        private readonly CloudDbContext _db;

        public CloudDashboardController(CloudDbContext db)
        {
            _db = db;
        }

        private Guid GetTenantId()
        {
            var tenantClaim = User.FindFirstValue("TenantId");
            return Guid.TryParse(tenantClaim, out var tenantId) ? tenantId : Guid.Empty;
        }

        [HttpGet]
        public async Task<IActionResult> GetStats()
        {
            var tenantId = GetTenantId();
            if (tenantId == Guid.Empty) return Unauthorized();

            var today = DateTime.UtcNow.Date;
            var startOfMonth = new DateTime(today.Year, today.Month, 1);

            var purchasesQuery = _db.Purchases.AsNoTracking().Where(p => p.TenantId == tenantId);

            var todayPurchases = await purchasesQuery
                .Where(p => p.PurchaseDate >= today)
                .GroupBy(p => 1)
                .Select(g => new { Amount = g.Sum(x => x.TotalAmount), Count = g.Count() })
                .FirstOrDefaultAsync();

            var monthPurchases = await purchasesQuery
                .Where(p => p.PurchaseDate >= startOfMonth)
                .GroupBy(p => 1)
                .Select(g => new { Amount = g.Sum(x => x.TotalAmount), Count = g.Count() })
                .FirstOrDefaultAsync();

            var pendingCount = await purchasesQuery.CountAsync(p => p.SyncStatus == SyncStatus.PendingSync);
            var syncedCount = await purchasesQuery.CountAsync(p => p.SyncStatus == SyncStatus.Synced);
            var failedCount = await purchasesQuery.CountAsync(p => p.SyncStatus == SyncStatus.SyncFailed);

            var totalSuppliers = await _db.Suppliers.AsNoTracking().CountAsync(s => s.TenantId == tenantId && s.IsActive);
            var totalProducts = await _db.Products.AsNoTracking().CountAsync(p => p.TenantId == tenantId && p.IsActive);

            var recentPurchases = await purchasesQuery
                .OrderByDescending(p => p.CreatedAt)
                .Take(6)
                .Select(p => new CloudPurchaseSummaryDto(
                    p.Id,
                    p.InvoiceNumber,
                    p.InternalNumber,
                    p.SupplierId,
                    p.SupplierName,
                    p.PurchaseDate,
                    p.TotalAmount,
                    p.PaidAmount,
                    p.RemainingAmount,
                    (int)p.PaymentMethod,
                    p.Notes,
                    p.SyncStatus.ToString(),
                    p.SyncedAt,
                    p.SyncError,
                    p.CreatedAt,
                    p.Items.Count
                ))
                .ToListAsync();

            // Load Snapshot synced from local POS Desktop
            var snapshot = await _db.DashboardSnapshots.AsNoTracking().FirstOrDefaultAsync(s => s.TenantId == tenantId);

            var installmentSaleIds = _db.Sales
                .Where(s => s.TenantId == tenantId && (s.IsInstallment || s.PaymentMethod == "Installment"))
                .Select(s => s.Id);

            var customerDebtsSum = await _db.DebtItems
                .AsNoTracking()
                .Where(d => d.TenantId == tenantId && d.Type == "Customer" && d.RemainingAmount > 0 && !installmentSaleIds.Contains(d.ReferenceId))
                .SumAsync(d => (decimal?)d.RemainingAmount) ?? 0;

            var supplierDebtsSum = await _db.DebtItems
                .AsNoTracking()
                .Where(d => d.TenantId == tenantId && d.Type == "Supplier" && d.RemainingAmount > 0)
                .SumAsync(d => (decimal?)d.RemainingAmount) ?? 0;

            var todayExpensesSum = await _db.Expenses
                .AsNoTracking()
                .Where(e => e.TenantId == tenantId && e.Date >= today)
                .SumAsync(e => (decimal?)e.Amount) ?? 0;

            var monthExpensesSum = await _db.Expenses
                .AsNoTracking()
                .Where(e => e.TenantId == tenantId && e.Date >= startOfMonth)
                .SumAsync(e => (decimal?)e.Amount) ?? 0;

            var todaySalesQuery = _db.Sales.AsNoTracking().Where(s => s.TenantId == tenantId && s.SaleDate >= today);
            var todayDirectSales = await todaySalesQuery.SumAsync(s => (decimal?)s.TotalAmount) ?? 0;
            var todayDirectPaid = await todaySalesQuery.SumAsync(s => (decimal?)s.PaidAmount) ?? 0;

            var directInstallmentDebts = await _db.Sales
                .AsNoTracking()
                .Where(s => s.TenantId == tenantId && (s.IsInstallment || s.PaymentMethod == "Installment") && s.RemainingAmount > 0)
                .SumAsync(s => (decimal?)s.RemainingAmount) ?? 0;

            var directInstallmentCount = await _db.Sales
                .AsNoTracking()
                .CountAsync(s => s.TenantId == tenantId && (s.IsInstallment || s.PaymentMethod == "Installment") && s.RemainingAmount > 0);

            var response = new DashboardStatsDto(
                TodaySalesAmount: (snapshot != null && snapshot.TodaySales > 0) ? snapshot.TodaySales : todayDirectSales,
                TodayProfitAmount: snapshot != null ? snapshot.TodayProfit : Math.Max(0, todayDirectSales - (todayPurchases?.Amount ?? 0) - todayExpensesSum),
                TodayPurchasesAmount: (snapshot != null && snapshot.TodayPurchases > 0) ? snapshot.TodayPurchases : (todayPurchases?.Amount ?? 0),
                TodayPurchasesCount: todayPurchases?.Count ?? 0,
                TodayExpensesAmount: (snapshot != null && snapshot.TodayExpenses > 0) ? snapshot.TodayExpenses : todayExpensesSum,
                MonthSalesAmount: snapshot?.MonthSales ?? 0,
                MonthProfitAmount: snapshot?.MonthProfit ?? 0,
                MonthPurchasesAmount: (snapshot != null && snapshot.MonthPurchases > 0) ? snapshot.MonthPurchases : (monthPurchases?.Amount ?? 0),
                MonthPurchasesCount: monthPurchases?.Count ?? 0,
                MonthExpensesAmount: (snapshot != null && snapshot.MonthExpenses > 0) ? snapshot.MonthExpenses : monthExpensesSum,
                CustomerDebtsTotal: (snapshot != null && snapshot.CustomerDebtsTotal > 0) ? snapshot.CustomerDebtsTotal : customerDebtsSum,
                SupplierDebtsTotal: (snapshot != null && snapshot.SupplierDebtsTotal > 0) ? snapshot.SupplierDebtsTotal : supplierDebtsSum,
                LowStockProductsCount: snapshot?.LowStockCount ?? 0,
                ExpiryAlertsCount: snapshot?.ExpiryAlertsCount ?? 0,
                PendingSyncPurchasesCount: pendingCount,
                SyncedPurchasesCount: syncedCount,
                FailedSyncPurchasesCount: failedCount,
                TotalSuppliersCount: totalSuppliers,
                TotalProductsCount: totalProducts,
                MonthlySalesJson: snapshot?.MonthlySalesJson,
                RecentPurchases: recentPurchases,
                TodayWasteLossAmount: snapshot?.TodayWasteLoss ?? 0,
                MonthWasteLossAmount: snapshot?.MonthWasteLoss ?? 0,
                TotalWasteLossAmount: snapshot?.TotalWasteLoss ?? 0,
                CustomerCreditDebtsTotal: (snapshot != null && snapshot.CustomerCreditDebtsTotal > 0) ? snapshot.CustomerCreditDebtsTotal : customerDebtsSum,
                InstallmentDebtsTotal: (snapshot != null && snapshot.InstallmentDebtsTotal > 0) ? snapshot.InstallmentDebtsTotal : directInstallmentDebts,
                CustomerCreditDebtsCount: snapshot?.CustomerCreditDebtsCount ?? 0,
                InstallmentContractsCount: (snapshot != null && snapshot.InstallmentContractsCount > 0) ? snapshot.InstallmentContractsCount : directInstallmentCount
            );

            return Ok(response);
        }

        private static readonly string[] ArabicMonthNames = new[]
        {
            "يناير", "فبراير", "مارس", "أبريل", "مايو", "يونيو",
            "يوليو", "أغسطس", "سبتمبر", "أكتوبر", "نوفمبر", "ديسمبر"
        };

        private static readonly string[] ArabicDayNames = new[]
        {
            "السبت", "الأحد", "الإثنين", "الثلاثاء", "الأربعاء", "الخميس", "الجمعة"
        };

        [HttpGet("monthly-report")]
        public async Task<IActionResult> GetMonthlyReport([FromQuery] int? year, [FromQuery] int? month)
        {
            var tenantId = GetTenantId();
            if (tenantId == Guid.Empty) return Unauthorized();

            var targetYear = year ?? DateTime.UtcNow.Year;
            var targetMonth = month ?? DateTime.UtcNow.Month;
            if (targetMonth < 1 || targetMonth > 12) targetMonth = DateTime.UtcNow.Month;

            var startDate = new DateTime(targetYear, targetMonth, 1);
            var daysInMonth = DateTime.DaysInMonth(targetYear, targetMonth);
            var endDate = startDate.AddMonths(1);
            int firstDayDayOfWeek = ((int)startDate.DayOfWeek + 1) % 7; // 0 = السبت, ..., 6 = الجمعة
            string monthNameAr = ArabicMonthNames[targetMonth - 1];

            // 1. Check if current month snapshot from Desktop is available
            CloudDashboardSnapshot? snapshot = null;
            if (targetYear == DateTime.UtcNow.Year && targetMonth == DateTime.UtcNow.Month)
            {
                snapshot = await _db.DashboardSnapshots
                    .AsNoTracking()
                    .Where(s => s.TenantId == tenantId)
                    .OrderByDescending(s => s.UpdatedAt)
                    .FirstOrDefaultAsync();
            }

            // Check if snapshot contains rich MonthlySalesJson
            if (snapshot != null && !string.IsNullOrWhiteSpace(snapshot.MonthlySalesJson))
            {
                try
                {
                    using var doc = System.Text.Json.JsonDocument.Parse(snapshot.MonthlySalesJson);
                    var root = doc.RootElement;

                    if (root.ValueKind == System.Text.Json.JsonValueKind.Object)
                    {
                        // It's the full MonthlySalesCalendarResponse from desktop!
                        decimal totalMonthlySales = root.TryGetProperty("totalMonthlySales", out var tmsP) ? tmsP.GetDecimal() : (root.TryGetProperty("TotalMonthlySales", out var tmsP2) ? tmsP2.GetDecimal() : snapshot.MonthSales);
                        decimal netMonthlySales = root.TryGetProperty("netMonthlySales", out var nmsP) ? nmsP.GetDecimal() : (root.TryGetProperty("NetMonthlySales", out var nmsP2) ? nmsP2.GetDecimal() : totalMonthlySales);
                        decimal totalMonthlyCashSales = root.TryGetProperty("totalMonthlyCashSales", out var tmcsP) ? tmcsP.GetDecimal() : (root.TryGetProperty("TotalMonthlyCashSales", out var tmcsP2) ? tmcsP2.GetDecimal() : 0);
                        decimal totalMonthlyCreditSales = root.TryGetProperty("totalMonthlyCreditSales", out var tmcrP) ? tmcrP.GetDecimal() : (root.TryGetProperty("TotalMonthlyCreditSales", out var tmcrP2) ? tmcrP2.GetDecimal() : 0);
                        decimal totalMonthlyDebtCollections = root.TryGetProperty("totalMonthlyDebtCollections", out var tmdcP) ? tmdcP.GetDecimal() : (root.TryGetProperty("TotalMonthlyDebtCollections", out var tmdcP2) ? tmdcP2.GetDecimal() : 0);
                        decimal totalMonthlyCollected = root.TryGetProperty("totalMonthlyCollected", out var tmcP) ? tmcP.GetDecimal() : (root.TryGetProperty("TotalMonthlyCollected", out var tmcP2) ? tmcP2.GetDecimal() : totalMonthlyCashSales + totalMonthlyDebtCollections);
                        decimal totalMonthlyReturns = root.TryGetProperty("totalMonthlyReturns", out var tmrP) ? tmrP.GetDecimal() : (root.TryGetProperty("TotalMonthlyReturns", out var tmrP2) ? tmrP2.GetDecimal() : 0);
                        decimal totalMonthlyPurchases = root.TryGetProperty("totalMonthlyPurchases", out var tmpP) ? tmpP.GetDecimal() : (root.TryGetProperty("TotalMonthlyPurchases", out var tmpP2) ? tmpP2.GetDecimal() : snapshot.MonthPurchases);
                        decimal totalMonthlyExpenses = root.TryGetProperty("totalMonthlyExpenses", out var tmeP) ? tmeP.GetDecimal() : (root.TryGetProperty("TotalMonthlyExpenses", out var tmeP2) ? tmeP2.GetDecimal() : snapshot.MonthExpenses);
                        int totalMonthlyInvoices = root.TryGetProperty("totalMonthlyInvoices", out var tmiP) ? tmiP.GetInt32() : (root.TryGetProperty("TotalMonthlyInvoices", out var tmiP2) ? tmiP2.GetInt32() : 0);
                        decimal dailyAverageSales = root.TryGetProperty("dailyAverageSales", out var dasP) ? dasP.GetDecimal() : (root.TryGetProperty("DailyAverageSales", out var dasP2) ? dasP2.GetDecimal() : 0);
                        int activeDaysCount = root.TryGetProperty("activeDaysCount", out var adcP) ? adcP.GetInt32() : (root.TryGetProperty("ActiveDaysCount", out var adcP2) ? adcP2.GetInt32() : 0);
                        int highestSalesDay = root.TryGetProperty("highestSalesDay", out var hsdP) ? hsdP.GetInt32() : (root.TryGetProperty("HighestSalesDay", out var hsdP2) ? hsdP2.GetInt32() : 0);
                        decimal highestSalesAmount = root.TryGetProperty("highestSalesAmount", out var hsaP) ? hsaP.GetDecimal() : (root.TryGetProperty("HighestSalesAmount", out var hsaP2) ? hsaP2.GetDecimal() : 0);
                        int lowestSalesDay = root.TryGetProperty("lowestSalesDay", out var lsdP) ? lsdP.GetInt32() : (root.TryGetProperty("LowestSalesDay", out var lsdP2) ? lsdP2.GetInt32() : 0);
                        decimal lowestSalesAmount = root.TryGetProperty("lowestSalesAmount", out var lsaP) ? lsaP.GetDecimal() : (root.TryGetProperty("LowestSalesAmount", out var lsaP2) ? lsaP2.GetDecimal() : 0);
                        decimal netProfit = (snapshot.MonthProfit != 0) ? snapshot.MonthProfit : (totalMonthlyCollected - totalMonthlyPurchases - totalMonthlyExpenses);

                        var daysProp = root.TryGetProperty("days", out var dp) ? dp : (root.TryGetProperty("Days", out var dp2) ? dp2 : default);
                        var parsedDays = new List<object>();

                        if (daysProp.ValueKind == System.Text.Json.JsonValueKind.Array)
                        {
                            foreach (var dEl in daysProp.EnumerateArray())
                            {
                                int dayNum = dEl.TryGetProperty("dayNumber", out var dnP) ? dnP.GetInt32() : (dEl.TryGetProperty("DayNumber", out var dnP2) ? dnP2.GetInt32() : (dEl.TryGetProperty("day", out var dp3) ? dp3.GetInt32() : (dEl.TryGetProperty("Day", out var dp4) ? dp4.GetInt32() : 0)));
                                string dateStr = dEl.TryGetProperty("date", out var dtP) ? dtP.GetString() ?? "" : (dEl.TryGetProperty("Date", out var dtP2) ? dtP2.GetString() ?? "" : "");
                                string dayNameStr = dEl.TryGetProperty("dayNameAr", out var dnaP) ? dnaP.GetString() ?? "" : (dEl.TryGetProperty("DayNameAr", out var dnaP2) ? dnaP2.GetString() ?? "" : (dEl.TryGetProperty("dayName", out var dn3) ? dn3.GetString() ?? "" : ""));
                                int dayOfWeekIdx = dEl.TryGetProperty("dayOfWeekIndex", out var dwiP) ? dwiP.GetInt32() : (dEl.TryGetProperty("DayOfWeekIndex", out var dwiP2) ? dwiP2.GetInt32() : 0);
                                decimal dSales = dEl.TryGetProperty("totalSales", out var tsP) ? tsP.GetDecimal() : (dEl.TryGetProperty("TotalSales", out var tsP2) ? tsP2.GetDecimal() : (dEl.TryGetProperty("sales", out var s3) ? s3.GetDecimal() : 0m));
                                decimal dNetSales = dEl.TryGetProperty("netSales", out var nsP) ? nsP.GetDecimal() : (dEl.TryGetProperty("NetSales", out var nsP2) ? nsP2.GetDecimal() : dSales);
                                decimal dCash = dEl.TryGetProperty("cashSales", out var csP) ? csP.GetDecimal() : (dEl.TryGetProperty("CashSales", out var csP2) ? csP2.GetDecimal() : 0m);
                                decimal dCredit = dEl.TryGetProperty("creditSales", out var crsP) ? crsP.GetDecimal() : (dEl.TryGetProperty("CreditSales", out var crsP2) ? crsP2.GetDecimal() : 0m);
                                decimal dDebtCol = dEl.TryGetProperty("debtCollections", out var dcP) ? dcP.GetDecimal() : (dEl.TryGetProperty("DebtCollections", out var dcP2) ? dcP2.GetDecimal() : 0m);
                                decimal dPaid = dEl.TryGetProperty("totalPaid", out var tpP) ? tpP.GetDecimal() : (dEl.TryGetProperty("TotalPaid", out var tpP2) ? tpP2.GetDecimal() : dCash + dDebtCol);
                                decimal dReturns = dEl.TryGetProperty("totalReturns", out var trP) ? trP.GetDecimal() : (dEl.TryGetProperty("TotalReturns", out var trP2) ? trP2.GetDecimal() : 0m);
                                decimal dPurchases = dEl.TryGetProperty("totalPurchases", out var tpuP) ? tpuP.GetDecimal() : (dEl.TryGetProperty("TotalPurchases", out var tpuP2) ? tpuP2.GetDecimal() : (dEl.TryGetProperty("purchases", out var pu3) ? pu3.GetDecimal() : 0m));
                                decimal dExpenses = dEl.TryGetProperty("totalExpenses", out var texP) ? texP.GetDecimal() : (dEl.TryGetProperty("TotalExpenses", out var texP2) ? texP2.GetDecimal() : (dEl.TryGetProperty("expenses", out var ex3) ? ex3.GetDecimal() : 0m));
                                int dInvoices = dEl.TryGetProperty("invoiceCount", out var icP) ? icP.GetInt32() : (dEl.TryGetProperty("InvoiceCount", out var icP2) ? icP2.GetInt32() : (dEl.TryGetProperty("salesCount", out var sc3) ? sc3.GetInt32() : 0));
                                decimal dNet = dEl.TryGetProperty("net", out var netP) ? netP.GetDecimal() : (dEl.TryGetProperty("Net", out var netP2) ? netP2.GetDecimal() : dPaid - dPurchases - dExpenses);
                                bool hasSales = dEl.TryGetProperty("hasSales", out var hsP) ? hsP.GetBoolean() : (dEl.TryGetProperty("HasSales", out var hsP2) ? hsP2.GetBoolean() : (dSales > 0 || dInvoices > 0 || dDebtCol > 0));
                                bool isToday = dEl.TryGetProperty("isToday", out var itP) ? itP.GetBoolean() : (dEl.TryGetProperty("IsToday", out var itP2) ? itP2.GetBoolean() : false);
                                bool isWeekend = dEl.TryGetProperty("isWeekend", out var iwP) ? iwP.GetBoolean() : (dEl.TryGetProperty("IsWeekend", out var iwP2) ? iwP2.GetBoolean() : (dayOfWeekIdx == 6));

                                parsedDays.Add(new
                                {
                                    Day = dayNum,
                                    DayNumber = dayNum,
                                    Date = dateStr,
                                    DayName = dayNameStr,
                                    DayNameAr = dayNameStr,
                                    DayOfWeekIndex = dayOfWeekIdx,
                                    Sales = dSales,
                                    TotalSales = dSales,
                                    NetSales = dNetSales,
                                    CashSales = dCash,
                                    CreditSales = dCredit,
                                    DebtCollections = dDebtCol,
                                    TotalPaid = dPaid,
                                    TotalReturns = dReturns,
                                    Purchases = dPurchases,
                                    TotalPurchases = dPurchases,
                                    Expenses = dExpenses,
                                    TotalExpenses = dExpenses,
                                    Net = dNet,
                                    SalesCount = dInvoices,
                                    InvoiceCount = dInvoices,
                                    HasSales = hasSales,
                                    IsToday = isToday,
                                    IsWeekend = isWeekend
                                });
                            }
                        }

                        if (parsedDays.Any())
                        {
                            return Ok(new
                            {
                                Year = targetYear,
                                Month = targetMonth,
                                MonthNameAr = monthNameAr,
                                DaysInMonth = daysInMonth,
                                FirstDayDayOfWeek = firstDayDayOfWeek,
                                TotalSales = totalMonthlySales,
                                TotalMonthlySales = totalMonthlySales,
                                NetSales = netMonthlySales,
                                NetMonthlySales = netMonthlySales,
                                TotalCashSales = totalMonthlyCashSales,
                                TotalMonthlyCashSales = totalMonthlyCashSales,
                                TotalCreditSales = totalMonthlyCreditSales,
                                TotalMonthlyCreditSales = totalMonthlyCreditSales,
                                TotalDebtCollections = totalMonthlyDebtCollections,
                                TotalMonthlyDebtCollections = totalMonthlyDebtCollections,
                                TotalCollected = totalMonthlyCollected,
                                TotalMonthlyCollected = totalMonthlyCollected,
                                TotalReturns = totalMonthlyReturns,
                                TotalMonthlyReturns = totalMonthlyReturns,
                                TotalPurchases = totalMonthlyPurchases,
                                TotalMonthlyPurchases = totalMonthlyPurchases,
                                TotalExpenses = totalMonthlyExpenses,
                                TotalMonthlyExpenses = totalMonthlyExpenses,
                                NetProfit = netProfit,
                                TotalInvoices = totalMonthlyInvoices,
                                TotalMonthlyInvoices = totalMonthlyInvoices,
                                DailyAverageSales = dailyAverageSales,
                                ActiveDaysCount = activeDaysCount,
                                HighestSalesDay = highestSalesDay,
                                HighestSalesAmount = highestSalesAmount,
                                LowestSalesDay = lowestSalesDay,
                                LowestSalesAmount = lowestSalesAmount,
                                Days = parsedDays,
                                DailyStats = parsedDays
                            });
                        }
                    }
                }
                catch { }
            }

            // 2. Fallback: Calculate directly from Cloud Database with absolute precision
            var sales = await _db.Sales
                .AsNoTracking()
                .Where(s => s.TenantId == tenantId && s.SaleDate >= startDate && s.SaleDate < endDate)
                .ToListAsync();

            var purchases = await _db.Purchases
                .AsNoTracking()
                .Where(p => p.TenantId == tenantId && p.PurchaseDate >= startDate && p.PurchaseDate < endDate)
                .ToListAsync();

            var expenses = await _db.Expenses
                .AsNoTracking()
                .Where(e => e.TenantId == tenantId && e.Date >= startDate && e.Date < endDate)
                .ToListAsync();

            var returns = await _db.Returns
                .AsNoTracking()
                .Where(r => r.TenantId == tenantId && r.Type == "Sale" && r.ReturnDate >= startDate && r.ReturnDate < endDate)
                .ToListAsync();

            var debtPayments = await _db.DebtPayments
                .AsNoTracking()
                .Where(d => d.TenantId == tenantId && d.CreatedAt >= startDate && d.CreatedAt < endDate)
                .ToListAsync();

            decimal calcGrossSales = 0;
            decimal calcCashSales = 0;
            decimal calcCreditSales = 0;
            decimal calcDebtCollections = 0;
            decimal calcReturns = 0;
            decimal calcPurchases = 0;
            decimal calcExpenses = 0;
            int calcInvoices = 0;

            int activeDays = 0;
            int highDay = 0;
            decimal highAmount = 0;
            int lowDay = 0;
            decimal lowAmount = decimal.MaxValue;

            var todayDate = DateTime.UtcNow.Date;
            var daysList = new List<object>();

            for (int d = 1; d <= daysInMonth; d++)
            {
                var curDate = new DateTime(targetYear, targetMonth, d);
                int dayOfWeekIdx = ((int)curDate.DayOfWeek + 1) % 7;
                string dayName = ArabicDayNames[dayOfWeekIdx];

                var dSalesList = sales.Where(s => s.SaleDate.Date == curDate.Date).ToList();
                decimal dSales = dSalesList.Sum(s => s.TotalAmount);
                int dInvoices = dSalesList.Count;

                // Cash sales: actual paid amount at time of sale
                decimal dCash = dSalesList.Sum(s => s.PaidAmount);

                // Credit sales: remaining balance for CREDIT sales (NEVER installments!)
                decimal dCredit = dSalesList
                    .Where(s => !s.IsInstallment && s.PaymentMethod != "Installment")
                    .Sum(s => Math.Max(0, s.TotalAmount - s.PaidAmount));

                decimal dDebtCol = debtPayments.Where(dp => dp.CreatedAt.Date == curDate.Date).Sum(dp => dp.Amount);
                decimal dPaid = dCash + dDebtCol;

                decimal dReturns = returns.Where(r => r.ReturnDate.Date == curDate.Date).Sum(r => r.TotalAmount);
                decimal dNetSales = Math.Max(0, dSales - dReturns);

                decimal dPurchases = purchases.Where(p => p.PurchaseDate.Date == curDate.Date).Sum(p => p.TotalAmount);
                decimal dExpenses = expenses.Where(e => e.Date.Date == curDate.Date).Sum(e => e.Amount);
                decimal dNet = dPaid - dPurchases - dExpenses;

                bool hasSales = dSales > 0 || dInvoices > 0 || dDebtCol > 0 || dReturns > 0;
                bool isToday = (curDate.Date == todayDate);
                bool isWeekend = (dayOfWeekIdx == 6); // الجمعة

                if (dNetSales > 0)
                {
                    activeDays++;
                    if (dNetSales > highAmount)
                    {
                        highAmount = dNetSales;
                        highDay = d;
                    }
                    if (dNetSales < lowAmount)
                    {
                        lowAmount = dNetSales;
                        lowDay = d;
                    }
                }

                calcGrossSales += dSales;
                calcCashSales += dCash;
                calcCreditSales += dCredit;
                calcDebtCollections += dDebtCol;
                calcReturns += dReturns;
                calcPurchases += dPurchases;
                calcExpenses += dExpenses;
                calcInvoices += dInvoices;

                daysList.Add(new
                {
                    Day = d,
                    DayNumber = d,
                    Date = curDate.ToString("yyyy-MM-dd"),
                    DayName = dayName,
                    DayNameAr = dayName,
                    DayOfWeekIndex = dayOfWeekIdx,
                    Sales = dSales,
                    TotalSales = dSales,
                    NetSales = dNetSales,
                    CashSales = dCash,
                    CreditSales = dCredit,
                    DebtCollections = dDebtCol,
                    TotalPaid = dPaid,
                    TotalReturns = dReturns,
                    Purchases = dPurchases,
                    TotalPurchases = dPurchases,
                    Expenses = dExpenses,
                    TotalExpenses = dExpenses,
                    Net = dNet,
                    SalesCount = dInvoices,
                    InvoiceCount = dInvoices,
                    HasSales = hasSales,
                    IsToday = isToday,
                    IsWeekend = isWeekend
                });
            }

            if (lowAmount == decimal.MaxValue)
            {
                lowAmount = 0;
                lowDay = 0;
            }

            decimal finalGrossSales = (snapshot != null && snapshot.MonthSales > 0) ? snapshot.MonthSales : calcGrossSales;
            decimal finalPurchases = (snapshot != null && snapshot.MonthPurchases > 0) ? snapshot.MonthPurchases : calcPurchases;
            decimal finalExpenses = (snapshot != null && snapshot.MonthExpenses > 0) ? snapshot.MonthExpenses : calcExpenses;
            decimal finalNetSales = Math.Max(0, finalGrossSales - calcReturns);
            decimal finalCollected = calcCashSales + calcDebtCollections;
            decimal finalProfit = (snapshot != null && snapshot.MonthProfit != 0) ? snapshot.MonthProfit : (finalCollected - finalPurchases - finalExpenses);
            decimal avgDailySales = daysInMonth > 0 ? Math.Round(finalNetSales / daysInMonth, 2) : 0;

            return Ok(new
            {
                Year = targetYear,
                Month = targetMonth,
                MonthNameAr = monthNameAr,
                DaysInMonth = daysInMonth,
                FirstDayDayOfWeek = firstDayDayOfWeek,
                TotalSales = finalGrossSales,
                TotalMonthlySales = finalGrossSales,
                NetSales = finalNetSales,
                NetMonthlySales = finalNetSales,
                TotalCashSales = calcCashSales,
                TotalMonthlyCashSales = calcCashSales,
                TotalCreditSales = calcCreditSales,
                TotalMonthlyCreditSales = calcCreditSales,
                TotalDebtCollections = calcDebtCollections,
                TotalMonthlyDebtCollections = calcDebtCollections,
                TotalCollected = finalCollected,
                TotalMonthlyCollected = finalCollected,
                TotalReturns = calcReturns,
                TotalMonthlyReturns = calcReturns,
                TotalPurchases = finalPurchases,
                TotalMonthlyPurchases = finalPurchases,
                TotalExpenses = finalExpenses,
                TotalMonthlyExpenses = finalExpenses,
                NetProfit = finalProfit,
                TotalInvoices = calcInvoices,
                TotalMonthlyInvoices = calcInvoices,
                DailyAverageSales = avgDailySales,
                ActiveDaysCount = activeDays,
                HighestSalesDay = highDay,
                HighestSalesAmount = highAmount,
                LowestSalesDay = lowDay,
                LowestSalesAmount = lowAmount,
                Days = daysList,
                DailyStats = daysList
            });
        }
    }
}
