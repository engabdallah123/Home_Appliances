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

            var customerDebtsSum = await _db.DebtItems
                .AsNoTracking()
                .Where(d => d.TenantId == tenantId && d.Type == "Customer" && d.RemainingAmount > 0)
                .SumAsync(d => d.RemainingAmount);

            var supplierDebtsSum = await _db.DebtItems
                .AsNoTracking()
                .Where(d => d.TenantId == tenantId && d.Type == "Supplier" && d.RemainingAmount > 0)
                .SumAsync(d => d.RemainingAmount);

            var todayExpensesSum = await _db.Expenses
                .AsNoTracking()
                .Where(e => e.TenantId == tenantId && e.Date >= today)
                .SumAsync(e => e.Amount);

            var monthExpensesSum = await _db.Expenses
                .AsNoTracking()
                .Where(e => e.TenantId == tenantId && e.Date >= startOfMonth)
                .SumAsync(e => e.Amount);

            var response = new DashboardStatsDto(
                TodaySalesAmount: snapshot?.TodaySales ?? 0,
                TodayProfitAmount: snapshot?.TodayProfit ?? 0,
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
                CustomerCreditDebtsTotal: snapshot?.CustomerCreditDebtsTotal ?? 0,
                InstallmentDebtsTotal: snapshot?.InstallmentDebtsTotal ?? 0,
                CustomerCreditDebtsCount: snapshot?.CustomerCreditDebtsCount ?? 0,
                InstallmentContractsCount: snapshot?.InstallmentContractsCount ?? 0
            );

            return Ok(response);
        }

        [HttpGet("monthly-report")]
        public async Task<IActionResult> GetMonthlyReport([FromQuery] int? year, [FromQuery] int? month)
        {
            var tenantId = GetTenantId();
            if (tenantId == Guid.Empty) return Unauthorized();

            var targetYear = year ?? DateTime.UtcNow.Year;
            var targetMonth = month ?? DateTime.UtcNow.Month;

            var startDate = new DateTime(targetYear, targetMonth, 1);
            var endDate = startDate.AddMonths(1);

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

            var daysInMonth = DateTime.DaysInMonth(targetYear, targetMonth);
            var dailyBreakdown = new List<object>();

            decimal totalSales = 0;
            decimal totalPurchases = 0;
            decimal totalExpenses = 0;

            // Check if current month snapshot from Desktop is available
            CloudDashboardSnapshot? snapshot = null;
            if (targetYear == DateTime.UtcNow.Year && targetMonth == DateTime.UtcNow.Month)
            {
                snapshot = await _db.DashboardSnapshots
                    .AsNoTracking()
                    .Where(s => s.TenantId == tenantId)
                    .OrderByDescending(s => s.UpdatedAt)
                    .FirstOrDefaultAsync();
            }

            bool usedSnapshotCalendar = false;
            if (snapshot != null && !string.IsNullOrWhiteSpace(snapshot.MonthlySalesJson))
            {
                try
                {
                    using var doc = System.Text.Json.JsonDocument.Parse(snapshot.MonthlySalesJson);
                    if (doc.RootElement.ValueKind == System.Text.Json.JsonValueKind.Array)
                    {
                        foreach (var dayEl in doc.RootElement.EnumerateArray())
                        {
                            int dayNum = dayEl.TryGetProperty("day", out var dP) ? dP.GetInt32() : (dayEl.TryGetProperty("Day", out var dp2) ? dp2.GetInt32() : 0);
                            string dateStr = dayEl.TryGetProperty("date", out var dtP) ? dtP.GetString() ?? "" : (dayEl.TryGetProperty("Date", out var dtP2) ? dtP2.GetString() ?? "" : "");
                            string dayNameStr = dayEl.TryGetProperty("dayName", out var dnP) ? dnP.GetString() ?? "" : (dayEl.TryGetProperty("DayName", out var dnP2) ? dnP2.GetString() ?? "" : "");
                            decimal dSales = dayEl.TryGetProperty("sales", out var sP) ? sP.GetDecimal() : (dayEl.TryGetProperty("Sales", out var sP2) ? sP2.GetDecimal() : 0m);
                            int dSalesCount = dayEl.TryGetProperty("salesCount", out var scP) ? scP.GetInt32() : (dayEl.TryGetProperty("SalesCount", out var scP2) ? scP2.GetInt32() : 0);
                            decimal dPurchases = dayEl.TryGetProperty("purchases", out var puP) ? puP.GetDecimal() : (dayEl.TryGetProperty("Purchases", out var puP2) ? puP2.GetDecimal() : 0m);
                            decimal dExpenses = dayEl.TryGetProperty("expenses", out var exP) ? exP.GetDecimal() : (dayEl.TryGetProperty("Expenses", out var exP2) ? exP2.GetDecimal() : 0m);
                            decimal dNet = dayEl.TryGetProperty("net", out var nP) ? nP.GetDecimal() : (dayEl.TryGetProperty("Net", out var nP2) ? nP2.GetDecimal() : dSales - dPurchases - dExpenses);

                            dailyBreakdown.Add(new
                            {
                                Day = dayNum,
                                Date = dateStr,
                                DayName = dayNameStr,
                                Sales = dSales,
                                SalesCount = dSalesCount,
                                Purchases = dPurchases,
                                Expenses = dExpenses,
                                Net = dNet
                            });
                        }
                        usedSnapshotCalendar = dailyBreakdown.Any();
                    }
                }
                catch { }
            }

            if (!usedSnapshotCalendar)
            {
                dailyBreakdown.Clear();
                for (int d = 1; d <= daysInMonth; d++)
                {
                    var curDate = new DateTime(targetYear, targetMonth, d);
                    var daySales = sales.Where(s => s.SaleDate.Date == curDate.Date).Sum(s => s.TotalAmount);
                    var daySalesCount = sales.Count(s => s.SaleDate.Date == curDate.Date);
                    var dayPurchases = purchases.Where(p => p.PurchaseDate.Date == curDate.Date).Sum(p => p.TotalAmount);
                    var dayExpenses = expenses.Where(e => e.Date.Date == curDate.Date).Sum(e => e.Amount);
                    var dayNet = daySales - dayPurchases - dayExpenses;

                    totalSales += daySales;
                    totalPurchases += dayPurchases;
                    totalExpenses += dayExpenses;

                    dailyBreakdown.Add(new
                    {
                        Day = d,
                        Date = curDate.ToString("yyyy-MM-dd"),
                        DayName = curDate.ToString("dddd", new System.Globalization.CultureInfo("ar-EG")),
                        Sales = daySales,
                        SalesCount = daySalesCount,
                        Purchases = dayPurchases,
                        Expenses = dayExpenses,
                        Net = dayNet
                    });
                }
            }

            decimal finalSales = (snapshot != null && snapshot.MonthSales > 0) ? snapshot.MonthSales : (totalSales > 0 ? totalSales : sales.Sum(s => s.TotalAmount));
            decimal finalPurchases = (snapshot != null && snapshot.MonthPurchases > 0) ? snapshot.MonthPurchases : (totalPurchases > 0 ? totalPurchases : purchases.Sum(p => p.TotalAmount));
            decimal finalExpenses = (snapshot != null && snapshot.MonthExpenses > 0) ? snapshot.MonthExpenses : (totalExpenses > 0 ? totalExpenses : expenses.Sum(e => e.Amount));
            decimal finalProfit = (snapshot != null && snapshot.MonthProfit != 0) ? snapshot.MonthProfit : (finalSales - finalPurchases - finalExpenses);

            return Ok(new
            {
                Year = targetYear,
                Month = targetMonth,
                TotalSales = finalSales,
                TotalPurchases = finalPurchases,
                TotalExpenses = finalExpenses,
                NetProfit = finalProfit,
                DailyStats = dailyBreakdown
            });
        }
    }
}
