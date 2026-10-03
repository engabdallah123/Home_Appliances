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
                TotalWasteLossAmount: snapshot?.TotalWasteLoss ?? 0
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

            return Ok(new
            {
                Year = targetYear,
                Month = targetMonth,
                TotalSales = totalSales,
                TotalPurchases = totalPurchases,
                TotalExpenses = totalExpenses,
                NetProfit = totalSales - totalPurchases - totalExpenses,
                DailyStats = dailyBreakdown
            });
        }
    }
}
