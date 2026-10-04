using POS.Desktop.Services.Api;
using POS.Desktop.Services.Auth;
using System.IO;
using System.Net.Http;
using System.Net.Http.Json;
using System.Net.NetworkInformation;
using System.Text.Json;

namespace POS.Desktop.Services.Sync
{
    public class CloudSyncService : ICloudSyncService
    {
        private readonly HttpClient _cloudHttp;
        private readonly PosApiClient _posApi;
        private readonly CustomAuthStateProvider _authState;
        private Timer? _syncTimer;
        private bool _isSyncing;
        private bool _isOffline;
        private bool _hasLocalChanges = true;
        private readonly string _syncApiKey = "KEY-SHOP01-SECURE-SYNC-2026";
        private readonly string _shopCode = "SHOP01";
        private DateTime _lastCatalogPush = DateTime.MinValue;
        private DateTime _lastDashboardPush = DateTime.MinValue;
        private readonly HashSet<string> _knownInvoiceNumbers = new(StringComparer.OrdinalIgnoreCase);
        private readonly HashSet<string> _knownSaleInvoiceNumbers = new(StringComparer.OrdinalIgnoreCase);

        public event Action? OnSyncStateChanged;

        public bool IsSyncing => _isSyncing;
        public bool IsOffline => _isOffline;
        public DateTime? LastSyncTime { get; private set; }
        public string? LastSyncStatus { get; private set; }
        public bool IsCloudReachable { get; private set; }
        public bool? LastSyncSucceeded { get; private set; }

        public void RecordLocalChange()
        {
            _hasLocalChanges = true;
        }

        public CloudSyncService(
            HttpClient httpClient,
            PosApiClient posApi,
            CustomAuthStateProvider authState)
        {
            _posApi = posApi;
            _authState = authState;

            var cloudUrl = ResolveCloudBaseUrl();
            if (!cloudUrl.EndsWith('/')) cloudUrl += "/";

            // Configure Cloud API Client
            _cloudHttp = new HttpClient
            {
                BaseAddress = new Uri(cloudUrl),
                Timeout = TimeSpan.FromSeconds(25)
            };
            _cloudHttp.DefaultRequestHeaders.Add("X-Sync-ApiKey", _syncApiKey);
            _cloudHttp.DefaultRequestHeaders.Add("X-Shop-Code", _shopCode);

            // Fast periodic sync every 20 seconds (first run after 3 seconds)
            StartPeriodicSync(TimeSpan.FromSeconds(20));
        }

        public static string ResolveCloudBaseUrl()
        {
            try
            {
                var envUrl = Environment.GetEnvironmentVariable("POS_CLOUD_URL");
                if (!string.IsNullOrWhiteSpace(envUrl)) return envUrl;

                var localFolder = Path.Combine(Environment.GetFolderPath(Environment.SpecialFolder.LocalApplicationData), "POS_HomeAppliances");
                var configPath = Path.Combine(localFolder, "cloudsync_config.json");
                if (File.Exists(configPath))
                {
                    var json = File.ReadAllText(configPath);
                    using var doc = JsonDocument.Parse(json);
                    if (doc.RootElement.TryGetProperty("url", out var urlProp) && !string.IsNullOrWhiteSpace(urlProp.GetString()))
                    {
                        return urlProp.GetString()!;
                    }
                }
            }
            catch { }
            return "https://homecashier.tryasp.net/";
        }

        public static void SaveCloudBaseUrl(string url)
        {
            try
            {
                var localFolder = Path.Combine(Environment.GetFolderPath(Environment.SpecialFolder.LocalApplicationData), "POS_HomeAppliances");
                Directory.CreateDirectory(localFolder);
                var configPath = Path.Combine(localFolder, "cloudsync_config.json");
                var json = JsonSerializer.Serialize(new { url = url.Trim() });
                File.WriteAllText(configPath, json);
            }
            catch { }
        }

        public void StartPeriodicSync(TimeSpan? interval = null)
        {
            StopPeriodicSync();
            var timerInterval = interval ?? TimeSpan.FromSeconds(20);
            _syncTimer = new Timer(async _ =>
            {
                try
                {
                    await BackgroundPeriodicCheckAsync();
                }
                catch
                {
                    // Silently catch background periodic errors so desktop UI is never affected
                }
            }, null, TimeSpan.FromSeconds(3), timerInterval);
        }

        public void StopPeriodicSync()
        {
            _syncTimer?.Dispose();
            _syncTimer = null;
        }

        private async Task BackgroundPeriodicCheckAsync()
        {
            if (_isSyncing) return;

            // 1. Check network connectivity
            if (!NetworkInterface.GetIsNetworkAvailable())
            {
                if (!_isOffline)
                {
                    _isOffline = true;
                    IsCloudReachable = false;
                    NotifyStateChanged();
                }
                return;
            }

            // 2. If we have local changes on Desktop, run full sync
            if (_hasLocalChanges)
            {
                await SyncNowAsync();
                return;
            }

            // 3. Otherwise, check Cloud for pending remote changes (lightweight status check)
            try
            {
                var status = await _cloudHttp.GetFromJsonAsync<CloudSyncStatusDto>("api/sync/status");
                if (status != null && status.HasPending)
                {
                    // Cloud has incoming data from Mobile! Run full sync
                    await SyncNowAsync();
                }
                else
                {
                    // Neither Desktop nor Mobile has changes. Keep calm & connected!
                    if (_isOffline || !IsCloudReachable)
                    {
                        _isOffline = false;
                        IsCloudReachable = true;
                        NotifyStateChanged();
                    }
                }
            }
            catch
            {
                if (!_isOffline && !IsCloudReachable)
                {
                    _isOffline = true;
                    NotifyStateChanged();
                }
            }
        }

        public async Task<bool> CheckCloudOnlineAsync()
        {
            try
            {
                if (!NetworkInterface.GetIsNetworkAvailable())
                {
                    _isOffline = true;
                    IsCloudReachable = false;
                    NotifyStateChanged();
                    return false;
                }

                var response = await _cloudHttp.GetAsync("api/sync/health");
                IsCloudReachable = response.IsSuccessStatusCode;
                _isOffline = !IsCloudReachable;
            }
            catch
            {
                IsCloudReachable = false;
                _isOffline = true;
            }
            NotifyStateChanged();
            return IsCloudReachable;
        }

        public async Task<SyncStatusResult> SyncNowAsync()
        {
            return await SyncNowAsync(forceCatalogPush: false);
        }

        public async Task<SyncStatusResult> SyncNowAsync(bool forceCatalogPush = false)
        {
            if (!NetworkInterface.GetIsNetworkAvailable())
            {
                _isOffline = true;
                IsCloudReachable = false;
                NotifyStateChanged();
                return new SyncStatusResult
                {
                    Success = false,
                    Message = "الجهاز غير متصل بالإنترنت."
                };
            }

            if (_isSyncing)
            {
                return new SyncStatusResult
                {
                    Success = false,
                    Message = "عملية المزامنة قيد التشغيل بالفعل..."
                };
            }

            _isSyncing = true;
            NotifyStateChanged();

            var result = new SyncStatusResult();

            try
            {
                // 1. Health check
                var isOnline = await CheckCloudOnlineAsync();
                if (!isOnline)
                {
                    result.Success = false;
                    LastSyncSucceeded = false;
                    result.Error = "تعذر الاتصال بالخادم السحابي (السيرفر غير متصل أو لا يوجد إنترنت).";
                    LastSyncStatus = "السيرفر السحابي غير متصل";
                    return result;
                }

                // 1.5 PRIORITY #0: Pull Pending Categories from Cloud (So products find them)
                await PullPendingCategoriesFromCloudAsync();

                // 2. PRIORITY #1: Pull Pending Suppliers from Cloud (So purchases find them)
                await PullPendingSuppliersFromCloudAsync();

                // 3. PRIORITY #2: Pull Pending Purchases from Cloud (Fast & Critical)
                int purchasesCount = await PullPendingPurchasesFromCloudAsync();
                result.SyncedPurchasesCount = purchasesCount;

                // 3.5 PRIORITY #2b: Pull Pending Mobile POS Sales from Cloud
                int salesCount = await PullPendingSalesFromCloudAsync();
                result.SyncedSalesCount = salesCount;

                // 4. PRIORITY #3: Pull Pending Products from Mobile
                await PullPendingProductsFromCloudAsync();

                // 5. PRIORITY #4: Pull Pending Debt Payments from Mobile
                int debtsCount = await PullPendingDebtPaymentsFromCloudAsync();
                result.SyncedDebtsCount = debtsCount;

                // 6. PRIORITY #5: Pull Pending Expenses from Mobile
                int expensesCount = await PullPendingExpensesFromCloudAsync();

                // 7. Push Local Expenses to Cloud
                await PushLocalExpensesToCloudAsync();

                // 8. Handle Expiry Notifications: Push active alerts to Cloud and pull mobile actions
                await PushActiveExpiryNotificationsAsync();
                await PullPendingNotificationActionsFromCloudAsync();

                // 9. Push Store Settings & Shop Name to Cloud (Every sync)
                await PushStoreSettingsToCloudAsync();

                // 10. Push Suppliers & Debts to Cloud
                await PushSuppliersToCloudAsync();

                // 11. Push Sales & Purchase Returns to Cloud
                await PushReturnsToCloudAsync();

                // 11.5 Push Local Sales, Reservations & Installments to Cloud
                await PushSalesToCloudAsync();

                // 11.6 Push Active Offers & Bride Packages to Cloud
                await PushOffersToCloudAsync();

                // 12. Push Dashboard snapshot & Debts (Every 60s or if items imported)
                if (purchasesCount > 0 || salesCount > 0 || debtsCount > 0 || expensesCount > 0 || (DateTime.UtcNow - _lastDashboardPush) > TimeSpan.FromSeconds(60))
                {
                    await PushDebtsAndDashboardAsync();
                    _lastDashboardPush = DateTime.UtcNow;
                }

                // 13. Push Full Catalog every 30 seconds or if forced (for low stock alerts)
                int catalogCount = 0;
                if (forceCatalogPush || (DateTime.UtcNow - _lastCatalogPush) > TimeSpan.FromSeconds(30))
                {
                    catalogCount = await PushLocalCatalogToCloudAsync();
                    result.SyncedCatalogCount = catalogCount;
                    _lastCatalogPush = DateTime.UtcNow;
                }

                result.Success = true;
                LastSyncSucceeded = true;
                _isOffline = false;
                _hasLocalChanges = false;
                LastSyncTime = DateTime.Now;
                LastSyncStatus = (purchasesCount > 0 || salesCount > 0)
                    ? $"اكتملت المزامنة بنجاح (تم استيراد {purchasesCount} مشتريات و {salesCount} مبيعات موبايل)"
                    : "المزامنة نشطة ومحدثة بنجاح";
                result.Message = $"تمت المزامنة بنجاح! ({purchasesCount} مشتريات، {salesCount} مبيعات، {debtsCount} سدادات ديون)";
            }
            catch (Exception ex)
            {
                result.Success = false;
                LastSyncSucceeded = false;
                result.Error = ex.Message;
                LastSyncStatus = $"فشلت المزامنة: {ex.Message}";
            }
            finally
            {
                _isSyncing = false;
                NotifyStateChanged();
            }

            return result;
        }

        private async Task<int> PullPendingPurchasesFromCloudAsync()
        {
            int importedCount = 0;

            try
            {
                var pendingPurchases = await _cloudHttp.GetFromJsonAsync<List<CloudPurchaseSyncDto>>("api/sync/purchases/pending");
                if (pendingPurchases == null || !pendingPurchases.Any())
                    return 0;

                // Initialize invoice cache if needed
                if (!_knownInvoiceNumbers.Any())
                {
                    var existingLocalPurchases = await _posApi.GetPurchasesListAsync();
                    foreach (var p in existingLocalPurchases ?? Enumerable.Empty<PurchaseDto>())
                    {
                        if (!string.IsNullOrWhiteSpace(p.InvoiceNumber))
                            _knownInvoiceNumbers.Add(p.InvoiceNumber.Trim());
                    }
                }

                var adminUserId = _authState.UserId != Guid.Empty ? _authState.UserId : Guid.Parse("2bc4e49b-fe29-4c7b-9eed-649de1c32cef");

                var localProducts = await _posApi.GetProductsAsync();
                var localById = localProducts?.ToDictionary(p => p.Id) ?? new();
                var localByBarcode = localProducts?
                    .Where(p => !string.IsNullOrWhiteSpace(p.Barcode))
                    .GroupBy(p => p.Barcode.Trim().ToLower())
                    .ToDictionary(g => g.Key, g => g.First()) ?? new();

                var affectedProductIds = new HashSet<Guid>();
                var affectedSupplierIds = new HashSet<Guid>();

                foreach (var cloudPurchase in pendingPurchases)
                {
                    // 1. Idempotency Check: if already imported locally, acknowledge and skip
                    if (_knownInvoiceNumbers.Contains(cloudPurchase.InvoiceNumber.Trim()))
                    {
                        await AcknowledgePurchaseAsync(cloudPurchase.Id, "Already Exists Locally");
                        continue;
                    }

                    // 2. Map Cloud Purchase to local CreatePurchaseRequest (resolving ProductId by Id or Barcode fallback)
                    var localItems = cloudPurchase.Items.Select(i =>
                    {
                        Guid resolvedProductId = i.ProductId;
                        if (!localById.ContainsKey(resolvedProductId))
                        {
                            if (!string.IsNullOrWhiteSpace(i.Barcode) && localByBarcode.TryGetValue(i.Barcode.Trim().ToLower(), out var pMatch))
                            {
                                resolvedProductId = pMatch.Id;
                            }
                        }

                        return new CreatePurchaseItemRequest(
                            ProductId: resolvedProductId,
                            Quantity: i.Quantity,
                            UnitCost: i.UnitCost,
                            Discount: i.Discount,
                            Tax: i.Tax,
                            ExpiryDate: i.ExpiryDate,
                            BatchNumber: i.BatchNumber,
                            Unit: i.Unit
                        );
                    }).ToList();

                    var localReq = new CreatePurchaseRequest(
                        InvoiceNumber: cloudPurchase.InvoiceNumber,
                        SupplierId: cloudPurchase.SupplierId,
                        CreatedByUserId: adminUserId,
                        Items: localItems,
                        InternalNumber: cloudPurchase.InternalNumber,
                        DiscountAmount: cloudPurchase.DiscountAmount,
                        TaxAmount: cloudPurchase.TaxAmount,
                        PaidAmount: cloudPurchase.PaidAmount,
                        PaymentMethod: cloudPurchase.PaymentMethod,
                        Notes: $"[وارد من تطبيق الموبايل] {cloudPurchase.Notes}".Trim(),
                        PurchaseDate: cloudPurchase.PurchaseDate
                    );

                    // 3. Execute local purchase creation (applies local stock increase, batch creation, etc.)
                    var (success, error) = await _posApi.CreatePurchaseAsync(localReq);

                    if (success)
                    {
                        // 4. Acknowledge sync to Cloud API
                        await AcknowledgePurchaseAsync(cloudPurchase.Id, "Imported into Local POS");
                        _knownInvoiceNumbers.Add(cloudPurchase.InvoiceNumber.Trim());
                        importedCount++;

                        foreach (var item in localItems)
                        {
                            affectedProductIds.Add(item.ProductId);
                        }
                        if (cloudPurchase.SupplierId != Guid.Empty)
                        {
                            affectedSupplierIds.Add(cloudPurchase.SupplierId);
                        }
                    }
                    else
                    {
                        // 5. Report failure to Cloud API with reason
                        await FailPurchaseAsync(cloudPurchase.Id, error ?? "Unknown local creation error");
                    }
                }

                // Immediately push updated stock and supplier balance back to Cloud so Mobile sees the new values!
                if (importedCount > 0)
                {
                    await PushFastStockAndSuppliersAsync(affectedProductIds, affectedSupplierIds);
                }
            }
            catch (Exception ex)
            {
                LastSyncStatus = $"خطأ أثناء سحب الفواتير: {ex.Message}";
            }

            return importedCount;
        }

        private async Task PushFastStockAndSuppliersAsync(IEnumerable<Guid> productIds, IEnumerable<Guid> supplierIds)
        {
            try
            {
                // 1. Push updated stock for affected products
                if (productIds.Any())
                {
                    var allProducts = await _posApi.GetProductsAsync();
                    var pDict = allProducts.ToDictionary(p => p.Id);

                    var stockUpdates = productIds
                        .Where(id => pDict.ContainsKey(id))
                        .Select(id => new StockUpdateItem(id, pDict[id].QuantityInStock))
                        .ToList();

                    if (stockUpdates.Any())
                    {
                        await _cloudHttp.PostAsJsonAsync("api/sync/stock/push", new PushStockRequest(stockUpdates));
                    }
                }

                // 2. Push updated supplier balances
                if (supplierIds.Any())
                {
                    var debts = await _posApi.GetSupplierDebtsAsync();
                    var debtGroups = debts.GroupBy(d => d.SupplierId).ToDictionary(g => g.Key, g => g.Sum(d => d.RemainingAmount));

                    var supUpdates = supplierIds.Select(id => new SupplierBalanceUpdateItem(
                        id,
                        debtGroups.TryGetValue(id, out var bal) ? bal : 0
                    )).ToList();

                    if (supUpdates.Any())
                    {
                        await _cloudHttp.PostAsJsonAsync("api/sync/suppliers/balances", new PushSupplierBalancesRequest(supUpdates));
                    }
                }
            }
            catch
            {
                // Non-critical fast push error
            }
        }

        private async Task PullPendingProductsFromCloudAsync()
        {
            try
            {
                var pendingProducts = await _cloudHttp.GetFromJsonAsync<List<PendingCloudProductDto>>("api/sync/products/pending");
                if (pendingProducts == null || !pendingProducts.Any()) return;

                var categories = await _posApi.GetCategoriesAsync();
                var units = await _posApi.GetUnitsAsync();
                var defaultCatId = categories?.FirstOrDefault()?.Id ?? Guid.Empty;
                if (defaultCatId == Guid.Empty)
                {
                    defaultCatId = await _posApi.CreateCategoryAsync(new CreateCategoryRequest("أجهزة كهربائية عامة")) ?? Guid.Empty;
                }
                var defaultUnitId = units?.FirstOrDefault()?.Id ?? Guid.Empty;

                var localProducts = await _posApi.GetProductsAsync();
                var localById = localProducts?.ToDictionary(p => p.Id) ?? new();
                var localByBarcode = localProducts?
                    .Where(p => !string.IsNullOrWhiteSpace(p.Barcode))
                    .GroupBy(p => p.Barcode.Trim().ToLower())
                    .ToDictionary(g => g.Key, g => g.First()) ?? new();

                foreach (var prod in pendingProducts)
                {
                    var barcodeClean = prod.Barcode.Trim().ToLower();
                    if (localById.ContainsKey(prod.Id) || localByBarcode.ContainsKey(barcodeClean))
                    {
                        await _cloudHttp.PostAsync($"api/sync/products/{prod.Id}/acknowledge", null);
                        continue;
                    }

                    var formModel = new CreateProductFormModel
                    {
                        Id = prod.Id,
                        Barcode = prod.Barcode,
                        NameAr = prod.NameAr,
                        NameEn = prod.NameEn ?? string.Empty,
                        BaseUnit = prod.BaseUnit,
                        ParentUnit = prod.ParentUnit,
                        ConversionFactor = prod.ConversionFactor,
                        PurchasePrice = prod.PurchasePrice,
                        SellingPrice = prod.SellingPrice,
                        WholesalePrice = prod.WholesalePrice,
                        ShelfLifeDays = prod.ShelfLifeDays,
                        ExpiryAlertDays = prod.ExpiryAlertDays,
                        ReorderLevel = prod.ReorderLevel,
                        IsWeighable = prod.IsWeighable,
                        TrackExpiry = prod.TrackExpiry,
                        CategoryId = (prod.CategoryId.HasValue && prod.CategoryId.Value != Guid.Empty) ? prod.CategoryId.Value : defaultCatId,
                        UnitId = defaultUnitId,
                        InitialStock = prod.StockQuantity,
                        BrandId = prod.BrandId,
                        ModelNumber = prod.ModelNumber,
                        Color = prod.Color,
                        WarrantyPeriodMonths = prod.WarrantyPeriodMonths > 0 ? prod.WarrantyPeriodMonths : 12,
                        MaintenanceAgent = prod.MaintenanceAgent,
                        HasSerialNumber = prod.HasSerialNumber
                    };

                    var (productId, error) = await _posApi.CreateProductAsync(formModel);
                    if (productId.HasValue || (error != null && error.Contains("الباركود مسجل مسبقاً")))
                    {
                        await _cloudHttp.PostAsync($"api/sync/products/{prod.Id}/acknowledge", null);
                    }
                }
            }
            catch { }
        }

        private async Task<int> PullPendingDebtPaymentsFromCloudAsync()
        {
            int count = 0;
            try
            {
                var pendingPayments = await _cloudHttp.GetFromJsonAsync<List<PendingDebtPaymentDto>>("api/sync/debts/pending");
                if (pendingPayments == null || !pendingPayments.Any()) return 0;

                foreach (var payment in pendingPayments)
                {
                    bool success = false;
                    string? err = null;
                    if (string.Equals(payment.DebtType, "Customer", StringComparison.OrdinalIgnoreCase))
                    {
                        var (res, errorMsg) = await _posApi.PayCustomerDebtAsync(payment.ReferenceId, payment.Amount);
                        success = res;
                        err = errorMsg;
                    }
                    else
                    {
                        var (res, errorMsg) = await _posApi.PaySupplierDebtAsync(payment.ReferenceId, payment.Amount);
                        success = res;
                        err = errorMsg;
                    }

                    if (success)
                    {
                        await _cloudHttp.PostAsync($"api/sync/debts/{payment.Id}/acknowledge", null);
                        count++;
                    }
                    else
                    {
                        Console.WriteLine($"[CloudSync] Failed to apply {payment.DebtType} debt payment {payment.ReferenceId}: {err}");
                        // Acknowledge permanent failures to prevent infinite retry loops
                        // that cause stale debt snapshots to overwrite mobile payments.
                        // Permanent errors: already paid, not found, invalid amount, or any
                        // application-level error (not a transient network error).
                        bool isPermanentError = err != null && (
                            err.Contains("مسددة بالكامل") ||
                            err.Contains("AlreadyFullyPaid") ||
                            err.Contains("NotFound") ||
                            err.Contains("InvalidPaymentAmount") ||
                            err.Contains("أكبر من") ||
                            err.Contains("يجب أن يكون"));

                        if (isPermanentError)
                        {
                            await _cloudHttp.PostAsync($"api/sync/debts/{payment.Id}/acknowledge", null);
                            count++;
                        }
                    }
                }

                if (count > 0)
                {
                    // Fire state changed event so any open UI (like Debts.razor) refreshes instantly!
                    NotifyStateChanged();
                }
            }
            catch (Exception ex)
            {
                Console.WriteLine($"[CloudSync] Exception in PullPendingDebtPaymentsFromCloudAsync: {ex.Message}");
            }
            return count;
        }

        private async Task PushDebtsAndDashboardAsync()
        {
            try
            {
                // 1. Debts Push
                var customerDebts = await _posApi.GetCustomerDebtsAsync();
                var supplierDebts = await _posApi.GetSupplierDebtsAsync();

                var syncDebts = new List<DebtItemSyncDto>();

                if (customerDebts != null)
                {
                    syncDebts.AddRange(customerDebts.Select(c => new DebtItemSyncDto(
                        Id: Guid.NewGuid(),
                        Type: "Customer",
                        ReferenceId: c.SaleId,
                        InvoiceNumber: c.InvoiceNumber,
                        EntityName: c.CustomerName ?? "عميل",
                        Phone: c.CustomerPhone,
                        TotalAmount: c.TotalAmount,
                        PaidAmount: c.PaidAmount,
                        RemainingAmount: c.RemainingAmount,
                        Date: c.SaleDate
                    )));
                }

                if (supplierDebts != null)
                {
                    syncDebts.AddRange(supplierDebts.Select(s => new DebtItemSyncDto(
                        Id: Guid.NewGuid(),
                        Type: "Supplier",
                        ReferenceId: s.PurchaseId,
                        InvoiceNumber: s.InvoiceNumber,
                        EntityName: s.SupplierName ?? "مورد",
                        Phone: s.SupplierPhone,
                        TotalAmount: s.TotalAmount,
                        PaidAmount: s.PaidAmount,
                        RemainingAmount: s.RemainingAmount,
                        Date: s.PurchaseDate
                    )));
                }

                await _cloudHttp.PostAsJsonAsync("api/sync/debts/push", new PushDebtsRequest(syncDebts));

                // 2. Dashboard Snapshot Push
                var dashData = await _posApi.GetDashboardAsync();
                var calendar = await _posApi.GetMonthlySalesCalendarAsync(DateTime.UtcNow.Year, DateTime.UtcNow.Month);

                if (dashData != null)
                {
                    var req = new PushDashboardSnapshotRequest(
                        TodaySales: dashData.TodayMetrics?.TotalSales ?? 0,
                        TodayProfit: dashData.TodayMetrics?.NetProfit ?? 0,
                        TodayPurchases: dashData.TodayMetrics?.TotalPurchases ?? 0,
                        TodayExpenses: dashData.TodayMetrics?.TotalExpenses ?? 0,
                        MonthSales: dashData.MonthMetrics?.TotalSales ?? 0,
                        MonthProfit: dashData.MonthMetrics?.NetProfit ?? 0,
                        MonthPurchases: dashData.MonthMetrics?.TotalPurchases ?? 0,
                        MonthExpenses: dashData.MonthMetrics?.TotalExpenses ?? 0,
                        CustomerDebtsTotal: dashData.TotalCustomerDebts,
                        SupplierDebtsTotal: supplierDebts?.Sum(s => s.RemainingAmount) ?? 0,
                        LowStockCount: dashData.LowStockProductsCount,
                        ExpiryAlertsCount: dashData.ActiveExpiryNotificationsCount,
                        MonthlySalesJson: calendar != null ? JsonSerializer.Serialize(calendar.Days) : null,
                        TodayWasteLoss: dashData.WasteLosses?.TodayLoss ?? 0,
                        MonthWasteLoss: dashData.WasteLosses?.MonthLoss ?? 0,
                        TotalWasteLoss: dashData.WasteLosses?.TotalLoss ?? 0
                    );

                    await _cloudHttp.PostAsJsonAsync("api/sync/dashboard/push", req);
                }
            }
            catch { }
        }

        private async Task<int> PullPendingSuppliersFromCloudAsync()
        {
            int importedCount = 0;
            try
            {
                var pendingSuppliers = await _cloudHttp.GetFromJsonAsync<List<PendingCloudSupplierDto>>("api/sync/suppliers/pending");
                if (pendingSuppliers == null || !pendingSuppliers.Any())
                    return 0;

                var localSuppliers = await _posApi.GetSuppliersAsync();
                var localByName = localSuppliers?.ToDictionary(s => s.Name.Trim().ToLower(), s => s) ?? new();
                var localById = localSuppliers?.ToDictionary(s => s.Id, s => s) ?? new();

                foreach (var sup in pendingSuppliers)
                {
                    if (localById.ContainsKey(sup.Id) || localByName.ContainsKey(sup.Name.Trim().ToLower()))
                    {
                        await AcknowledgeSupplierAsync(sup.Id);
                        continue;
                    }

                    var req = new CreateSupplierRequest(
                        Name: sup.Name.Trim(),
                        Phone: !string.IsNullOrWhiteSpace(sup.Phone) ? sup.Phone.Trim() : "01000000000",
                        Email: sup.Email?.Trim(),
                        Address: sup.Address?.Trim(),
                        ContactPerson: sup.ContactPerson?.Trim(),
                        Id: sup.Id
                    );

                    var (success, error) = await _posApi.CreateSupplierAsync(req);
                    if (success || (error != null && error.Contains("مسبقاً")))
                    {
                        await AcknowledgeSupplierAsync(sup.Id);
                        importedCount++;
                    }
                }
            }
            catch { }
            return importedCount;
        }

        private async Task AcknowledgeSupplierAsync(Guid supplierId)
        {
            try
            {
                await _cloudHttp.PostAsync($"api/sync/suppliers/{supplierId}/acknowledge", null);
            }
            catch { }
        }

        private async Task<int> PullPendingCategoriesFromCloudAsync()
        {
            int importedCount = 0;
            try
            {
                var pendingCategories = await _cloudHttp.GetFromJsonAsync<List<PendingCloudCategoryDto>>("api/sync/categories/pending");
                if (pendingCategories == null || !pendingCategories.Any())
                    return 0;

                var localCategories = await _posApi.GetCategoriesAsync();
                var localByName = localCategories?.ToDictionary(c => c.NameAr.Trim().ToLower(), c => c) ?? new();
                var localById = localCategories?.ToDictionary(c => c.Id, c => c) ?? new();

                foreach (var cat in pendingCategories)
                {
                    if (localById.ContainsKey(cat.Id) || localByName.ContainsKey(cat.NameAr.Trim().ToLower()))
                    {
                        await AcknowledgeCategoryAsync(cat.Id);
                        continue;
                    }

                    var req = new CreateCategoryRequest(
                        NameAr: cat.NameAr.Trim(),
                        NameEn: !string.IsNullOrWhiteSpace(cat.NameEn) ? cat.NameEn.Trim() : cat.NameAr.Trim(),
                        ParentCategoryId: null,
                        Id: cat.Id
                    );

                    var catId = await _posApi.CreateCategoryAsync(req);
                    if (catId.HasValue && catId.Value != Guid.Empty)
                    {
                        await AcknowledgeCategoryAsync(cat.Id);
                        importedCount++;
                    }
                    else
                    {
                        // Check if it already exists by name before acknowledging
                        var refreshedCats = await _posApi.GetCategoriesAsync();
                        if (refreshedCats != null && refreshedCats.Any(c => c.NameAr.Trim().Equals(cat.NameAr.Trim(), StringComparison.OrdinalIgnoreCase)))
                        {
                            await AcknowledgeCategoryAsync(cat.Id);
                        }
                    }
                }

                if (importedCount > 0)
                {
                    NotifyStateChanged();
                }
            }
            catch { }
            return importedCount;
        }

        private async Task AcknowledgeCategoryAsync(Guid categoryId)
        {
            try
            {
                await _cloudHttp.PostAsync($"api/sync/categories/{categoryId}/acknowledge", null);
            }
            catch { }
        }

        private async Task PushStoreSettingsToCloudAsync()
        {
            try
            {
                var settings = await _posApi.GetSettingsAsync();
                if (settings == null || string.IsNullOrWhiteSpace(settings.StoreName)) return;

                var req = new PushStoreSettingsRequest(
                    StoreName: settings.StoreName,
                    Address: settings.Address,
                    Phone: settings.Phone,
                    TaxRate: settings.TaxRate,
                    IsTaxIncluded: settings.IsTaxIncluded,
                    Currency: string.IsNullOrWhiteSpace(settings.Currency) ? "ج.م" : settings.Currency,
                    InvoiceFooterMessage: settings.InvoiceFooterMessage,
                    AllowNegativeStock: settings.AllowNegativeStock,
                    LogoUrl: settings.LogoUrl
                );

                await _cloudHttp.PostAsJsonAsync("api/sync/store-settings/push", req);
            }
            catch { }
        }

        private async Task<int> PushLocalCatalogToCloudAsync()
        {
            try
            {
                var localSuppliers = await _posApi.GetSuppliersAsync();
                var localProducts = await _posApi.GetProductsAsync();
                var localCategories = await _posApi.GetCategoriesAsync();
                var supplierDebts = await _posApi.GetSupplierDebtsAsync();

                var debtMap = supplierDebts?
                    .GroupBy(d => d.SupplierId)
                    .ToDictionary(g => g.Key, g => g.Sum(d => d.RemainingAmount)) ?? new();

                var supList = localSuppliers?.Select(s => new CatalogSupplierSyncItem(
                    s.Id,
                    s.Name,
                    s.Phone,
                    s.Address,
                    debtMap.TryGetValue(s.Id, out var bal) ? bal : 0,
                    s.Email,
                    s.ContactPerson
                )).ToList() ?? new();

                var catList = localCategories?.Select(c => new CatalogCategorySyncItem(
                    c.Id,
                    c.NameAr,
                    c.NameEn
                )).ToList() ?? new();

                var prodList = localProducts?.Select(p => new CatalogProductSyncItem(
                    p.Id,
                    p.Barcode,
                    p.NameAr,
                    p.NameEn,
                    p.BaseUnit,
                    p.ParentUnit,
                    p.ConversionFactor,
                    p.PurchasePrice,
                    p.SellingPrice,
                    p.WholesalePrice,
                    p.QuantityInStock,
                    p.CategoryId,
                    p.CategoryName,
                    p.IsWeighable,
                    p.ShelfLifeDays,
                    p.ExpiryAlertDays,
                    p.ReorderLevel,
                    p.TrackExpiry
                )).ToList() ?? new();

                if (supList.Any() || prodList.Any() || catList.Any())
                {
                    var req = new PushCloudCatalogRequest(supList, prodList, catList);
                    var res = await _cloudHttp.PostAsJsonAsync("api/sync/catalog/push", req);
                    if (res.IsSuccessStatusCode)
                    {
                        return supList.Count + prodList.Count + catList.Count;
                    }
                }
            }
            catch { }
            return 0;
        }

        private async Task AcknowledgePurchaseAsync(Guid purchaseId, string localRef)
        {
            try
            {
                await _cloudHttp.PostAsJsonAsync($"api/sync/purchases/{purchaseId}/acknowledge",
                    new AcknowledgeCloudSyncRequest(purchaseId, localRef));
            }
            catch { }
        }

        private async Task FailPurchaseAsync(Guid purchaseId, string errorMessage)
        {
            try
            {
                await _cloudHttp.PostAsJsonAsync($"api/sync/purchases/{purchaseId}/fail",
                    new FailCloudSyncRequest(purchaseId, errorMessage));
            }
            catch { }
        }

        private async Task<int> PullPendingSalesFromCloudAsync()
        {
            int importedCount = 0;
            try
            {
                var pendingSales = await _cloudHttp.GetFromJsonAsync<List<CloudSaleSyncDto>>("api/sync/sales/pending");
                if (pendingSales == null || !pendingSales.Any())
                    return 0;

                var adminUserId = _authState.UserId != Guid.Empty ? _authState.UserId : Guid.Parse("2bc4e49b-fe29-4c7b-9eed-649de1c32cef");

                var localProducts = await _posApi.GetProductsAsync();
                var localById = localProducts?.ToDictionary(p => p.Id) ?? new();
                var localByBarcode = localProducts?
                    .Where(p => !string.IsNullOrWhiteSpace(p.Barcode))
                    .GroupBy(p => p.Barcode.Trim().ToLower())
                    .ToDictionary(g => g.Key, g => g.First()) ?? new();

                var affectedProductIds = new HashSet<Guid>();

                foreach (var cloudSale in pendingSales)
                {
                    if (!string.IsNullOrWhiteSpace(cloudSale.InvoiceNumber) && _knownSaleInvoiceNumbers.Contains(cloudSale.InvoiceNumber.Trim()))
                    {
                        await AcknowledgeSaleAsync(cloudSale.Id, "Already Exists Locally");
                        continue;
                    }

                    var localItems = cloudSale.Items.Select(i =>
                    {
                        Guid resolvedProductId = i.ProductId;
                        if (!localById.ContainsKey(resolvedProductId))
                        {
                            if (!string.IsNullOrWhiteSpace(i.Barcode) && localByBarcode.TryGetValue(i.Barcode.Trim().ToLower(), out var pMatch))
                            {
                                resolvedProductId = pMatch.Id;
                            }
                        }

                        return new CreateSaleItemRequest(
                            ProductId: resolvedProductId,
                            Quantity: i.Quantity,
                            UnitPrice: i.UnitPrice,
                            Discount: i.Discount,
                            Tax: i.Tax,
                            SerialNumber: i.SerialNumber
                        );
                    }).ToList();

                    var localCmd = new CreateSaleCommand(
                        CashierId: adminUserId,
                        ShiftId: Guid.Empty, // Auto-resolved by backend to active shift or system shift!
                        Items: localItems,
                        CustomerId: cloudSale.CustomerId,
                        DiscountAmount: cloudSale.DiscountAmount,
                        TaxAmount: cloudSale.TaxAmount,
                        PaidAmount: cloudSale.PaidAmount,
                        PaymentMethod: string.IsNullOrWhiteSpace(cloudSale.PaymentMethod) ? "Cash" : cloudSale.PaymentMethod,
                        Notes: string.IsNullOrWhiteSpace(cloudSale.Notes)
                            ? $"[مبيعات من تطبيق الموبايل] فاتورة {cloudSale.InvoiceNumber}"
                            : $"[مبيعات من تطبيق الموبايل] {cloudSale.Notes} ({cloudSale.InvoiceNumber})",
                        IsDelivery: cloudSale.IsDelivery,
                        RecipientName: cloudSale.RecipientName,
                        RecipientPhone: cloudSale.RecipientPhone,
                        DeliveryAddress: cloudSale.DeliveryAddress,
                        DeliveryFloor: cloudSale.DeliveryFloor,
                        DeliveryFee: cloudSale.DeliveryFee,
                        IsReserved: cloudSale.IsReserved,
                        TargetDeliveryDate: cloudSale.TargetDeliveryDate,
                        IsInstallment: cloudSale.IsInstallment,
                        GuarantorName: cloudSale.GuarantorName,
                        GuarantorPhone: cloudSale.GuarantorPhone,
                        InterestPercentage: cloudSale.InterestPercentage,
                        NumberOfMonths: cloudSale.NumberOfMonths
                    );

                    var (result, error) = await _posApi.CreateSaleAsync(localCmd);

                    if (result != null && result.SaleId != Guid.Empty)
                    {
                        await AcknowledgeSaleAsync(cloudSale.Id, result.SaleId.ToString());
                        if (!string.IsNullOrWhiteSpace(cloudSale.InvoiceNumber))
                        {
                            _knownSaleInvoiceNumbers.Add(cloudSale.InvoiceNumber.Trim());
                        }
                        importedCount++;

                        foreach (var item in localItems)
                        {
                            affectedProductIds.Add(item.ProductId);
                        }
                    }
                    else
                    {
                        await FailSaleAsync(cloudSale.Id, error ?? "Unknown error creating sale locally");
                    }
                }

                if (importedCount > 0)
                {
                    await PushFastStockAndSuppliersAsync(affectedProductIds, Enumerable.Empty<Guid>());
                    NotifyStateChanged();
                }
            }
            catch (Exception ex)
            {
                LastSyncStatus = $"خطأ أثناء سحب مبيعات الموبايل: {ex.Message}";
            }

            return importedCount;
        }

        private async Task AcknowledgeSaleAsync(Guid saleId, string? reference = null)
        {
            try
            {
                await _cloudHttp.PostAsJsonAsync($"api/sync/sales/{saleId}/acknowledge",
                    new AcknowledgeCloudSyncRequest(saleId, reference));
            }
            catch { }
        }

        private async Task FailSaleAsync(Guid saleId, string errorMessage)
        {
            try
            {
                await _cloudHttp.PostAsJsonAsync($"api/sync/sales/{saleId}/fail",
                    new FailCloudSyncRequest(saleId, errorMessage));
            }
            catch { }
        }

        private async Task<int> PullPendingExpensesFromCloudAsync()
        {
            int imported = 0;
            try
            {
                var pendingExpenses = await _cloudHttp.GetFromJsonAsync<List<CloudExpenseSyncDto>>("api/sync/expenses/pending");
                if (pendingExpenses == null || !pendingExpenses.Any())
                    return 0;

                var adminUserId = _authState.UserId != Guid.Empty ? _authState.UserId : Guid.Parse("2bc4e49b-fe29-4c7b-9eed-649de1c32cef");

                foreach (var exp in pendingExpenses)
                {
                    var req = new CreateExpenseRequest(
                        Title: exp.Category,
                        Amount: exp.Amount,
                        CreatedByUserId: adminUserId,
                        Description: exp.Description,
                        ExpenseDate: exp.Date,
                        Notes: $"[وارد من الموبايل] {exp.Notes}".Trim()
                    );

                    var (success, error) = await _posApi.CreateExpenseAsync(req);
                    if (success)
                    {
                        await _cloudHttp.PostAsync($"api/sync/expenses/{exp.Id}/acknowledge", null);
                        imported++;
                    }
                }
            }
            catch { }
            return imported;
        }

        private async Task PushLocalExpensesToCloudAsync()
        {
            try
            {
                var localExpenses = await _posApi.GetExpensesListAsync(DateTime.UtcNow.AddDays(-30), DateTime.UtcNow.AddDays(1));
                if (localExpenses == null || !localExpenses.Any()) return;

                var items = localExpenses.Select(e => new CloudExpenseSyncDto(
                    e.Id,
                    e.Amount,
                    e.Title ?? e.Category ?? "مصروفات عامة",
                    e.Description,
                    e.ExpenseDate,
                    e.Notes
                )).ToList();

                await _cloudHttp.PostAsJsonAsync("api/sync/expenses/push", new PushExpensesRequest(items));
            }
            catch { }
        }

        private async Task PushSuppliersToCloudAsync()
        {
            try
            {
                var localSuppliers = await _posApi.GetSuppliersAsync();
                var supplierDebts = await _posApi.GetSupplierDebtsAsync();
                var debtMap = supplierDebts?
                    .GroupBy(d => d.SupplierId)
                    .ToDictionary(g => g.Key, g => g.Sum(d => d.RemainingAmount)) ?? new();

                var supList = localSuppliers?.Select(s => new CatalogSupplierSyncItem(
                    s.Id,
                    s.Name,
                    s.Phone,
                    s.Address,
                    debtMap.TryGetValue(s.Id, out var bal) ? bal : 0,
                    s.Email,
                    s.ContactPerson
                )).ToList() ?? new();

                if (supList.Any())
                {
                    var req = new PushCloudCatalogRequest(supList, new(), new());
                    await _cloudHttp.PostAsJsonAsync("api/sync/catalog/push", req);
                }
            }
            catch { }
        }

        private async Task PushReturnsToCloudAsync()
        {
            try
            {
                var salesReturns = await _posApi.GetSalesReturnsAsync(cashierId: null, shiftId: null, page: 1, pageSize: 100);
                var purchaseReturns = await _posApi.GetPurchaseReturnsAsync(supplierId: null, page: 1, pageSize: 100);

                var itemsToPush = new List<PushReturnSyncItem>();

                if (salesReturns != null && salesReturns.Any())
                {
                    foreach (var sr in salesReturns)
                    {
                        try
                        {
                            SalesReturnDetailDto? detail = null;
                            try { detail = await _posApi.GetSalesReturnByIdAsync(sr.Id); } catch { }

                            var returnItems = detail?.Items?.Select(i => new ReturnItemSyncDto(
                                i.Id,
                                i.ProductId,
                                i.ProductName ?? "صنف مرتجع",
                                i.Barcode,
                                i.Quantity,
                                i.UnitPrice,
                                i.Tax,
                                i.Total,
                                i.Reason
                            )).ToList() ?? new List<ReturnItemSyncDto>();

                            itemsToPush.Add(new PushReturnSyncItem(
                                sr.Id,
                                sr.ReturnNumber,
                                "Sale",
                                detail?.OriginalInvoiceNumber,
                                sr.CustomerName,
                                null,
                                sr.ReturnDate,
                                sr.TotalAmount,
                                sr.RefundMethod ?? "Cash",
                                sr.Reason,
                                sr.Notes,
                                JsonSerializer.Serialize(returnItems),
                                returnItems.Count
                            ));
                        }
                        catch { }
                    }
                }

                if (purchaseReturns != null && purchaseReturns.Any())
                {
                    foreach (var pr in purchaseReturns)
                    {
                        try
                        {
                            PurchaseReturnDetailDto? detail = null;
                            try { detail = await _posApi.GetPurchaseReturnByIdAsync(pr.Id); } catch { }

                            var returnItems = detail?.Items?.Select(i => new ReturnItemSyncDto(
                                i.Id,
                                i.ProductId,
                                i.ProductName ?? "صنف مرتجع",
                                i.Barcode,
                                i.Quantity,
                                i.UnitCost,
                                i.Tax,
                                i.Total,
                                null
                            )).ToList() ?? new List<ReturnItemSyncDto>();

                            itemsToPush.Add(new PushReturnSyncItem(
                                pr.Id,
                                pr.ReturnNumber,
                                "Purchase",
                                detail?.OriginalInvoiceNumber,
                                pr.SupplierName,
                                null,
                                pr.ReturnDate,
                                pr.TotalAmount,
                                "Cash",
                                pr.Reason,
                                pr.Notes,
                                JsonSerializer.Serialize(returnItems),
                                returnItems.Count
                            ));
                        }
                        catch { }
                    }
                }

                if (itemsToPush.Any())
                {
                    await _cloudHttp.PostAsJsonAsync("api/sync/returns/push", new PushReturnsRequest(itemsToPush));
                }
            }
            catch { }
        }

        private async Task PushSalesToCloudAsync()
        {
            try
            {
                var localSales = await _posApi.GetSalesListAsync(DateTime.UtcNow.AddDays(-60), DateTime.UtcNow.AddDays(1));
                if (localSales == null || !localSales.Any()) return;

                var customerDebts = await _posApi.GetCustomerDebtsAsync();
                var remainingMap = customerDebts?.ToDictionary(d => d.SaleId, d => d.RemainingAmount) ?? new();

                var installmentContracts = await _posApi.GetInstallmentContractsAsync();
                var contractMap = installmentContracts?.ToDictionary(c => c.SaleId, c => c) ?? new();

                var salesToPush = localSales.Select(s =>
                {
                    decimal remaining = remainingMap.TryGetValue(s.Id, out var rem) ? rem : Math.Max(0, s.TotalAmount - s.PaidAmount);
                    bool isInst = s.IsInstallment || s.PaymentMethod == "Installment" || s.PaymentMethod == "تقسيط" || contractMap.ContainsKey(s.Id);

                    InstallmentContractDto? contract = null;
                    if (s.InstallmentContractId.HasValue) contractMap.TryGetValue(s.InstallmentContractId.Value, out contract);
                    if (contract == null) contractMap.TryGetValue(s.Id, out contract);

                    return new CloudSaleSyncDto(
                        Id: s.Id,
                        InvoiceNumber: s.InvoiceNumber,
                        CustomerId: s.CustomerId,
                        CustomerName: s.CustomerName,
                        CustomerPhone: s.RecipientPhone,
                        SaleDate: s.SaleDate,
                        SubTotal: s.SubTotal,
                        DiscountAmount: s.DiscountAmount,
                        TaxAmount: s.TaxAmount,
                        TotalAmount: s.TotalAmount,
                        PaidAmount: s.PaidAmount,
                        RemainingAmount: remaining,
                        PaymentMethod: s.PaymentMethod ?? "Cash",
                        Notes: s.Notes,
                        IsDelivery: s.IsDelivery,
                        RecipientName: s.RecipientName,
                        RecipientPhone: s.RecipientPhone,
                        DeliveryAddress: s.DeliveryAddress,
                        DeliveryFloor: s.DeliveryFloor,
                        DeliveryFee: s.DeliveryFee,
                        IsInstallment: isInst,
                        GuarantorName: contract?.GuarantorName,
                        GuarantorPhone: contract?.GuarantorPhone,
                        InterestPercentage: contract?.InterestPercentage ?? 0,
                        NumberOfMonths: contract?.NumberOfMonths ?? 12,
                        IsReserved: s.IsReserved,
                        TargetDeliveryDate: s.TargetDeliveryDate,
                        Items: (s.Items ?? new List<SaleItemDto>()).Select(i => new CloudSaleItemSyncDto(
                            Id: i.Id != Guid.Empty ? i.Id : Guid.NewGuid(),
                            ProductId: i.ProductId,
                            ProductName: i.ProductName ?? "منتج",
                            Barcode: i.Barcode,
                            ModelNumber: null,
                            BrandName: null,
                            SerialNumber: i.SerialNumber,
                            WarrantyPeriodMonths: 12,
                            Quantity: i.Quantity,
                            UnitPrice: i.UnitPrice,
                            Discount: i.Discount,
                            Tax: i.Tax,
                            Total: i.Total
                        )).ToList()
                    );
                }).ToList();

                if (salesToPush.Any())
                {
                    await _cloudHttp.PostAsJsonAsync("api/sync/sales/push", new PushSalesRequest(salesToPush));
                }
            }
            catch { }
        }

        private async Task PushOffersToCloudAsync()
        {
            try
            {
                var localOffers = await _posApi.GetOffersAsync();
                if (localOffers == null || !localOffers.Any()) return;

                var offersToPush = localOffers.Select(o => new PushOfferDto(
                    Id: o.Id,
                    Title: o.Title,
                    Description: o.Description,
                    Type: o.Type,
                    OfferType: o.OfferType,
                    DiscountPercentage: o.DiscountPercentage,
                    FixedDiscountAmount: o.FixedDiscountAmount,
                    BundlePrice: o.BundlePrice,
                    StartDate: o.StartDate,
                    EndDate: o.EndDate,
                    IsActive: o.IsActive,
                    TargetProductId: o.TargetProductId,
                    TargetProductName: o.TargetProductName,
                    TargetCategoryId: o.TargetCategoryId,
                    TargetCategoryName: o.TargetCategoryName,
                    TargetBrandId: o.TargetBrandId,
                    TargetBrandName: o.TargetBrandName,
                    Items: o.Items?.Select(i => new PushOfferItemDto(
                        Id: i.Id,
                        ProductId: i.ProductId,
                        ProductName: i.ProductName,
                        ProductBarcode: i.ProductBarcode,
                        Quantity: i.Quantity,
                        OriginalUnitPrice: i.OriginalUnitPrice
                    )).ToList()
                )).ToList();

                if (offersToPush.Any())
                {
                    await _cloudHttp.PostAsJsonAsync("api/sync/offers/push", new PushOffersRequest(offersToPush));
                }
            }
            catch { }
        }

        private async Task PushActiveExpiryNotificationsAsync()
        {
            try
            {
                var notifs = await _posApi.GetExpiryNotificationsAsync(includeSnoozed: true);
                if (notifs == null || !notifs.Any()) return;

                var syncItems = notifs.Select(n => new CloudExpiryNotificationItemDto(
                    n.Id,
                    n.ProductId,
                    n.ProductName,
                    n.ProductBarcode,
                    n.BatchId,
                    n.BatchNumber,
                    n.RemainingQuantity,
                    n.BaseUnit,
                    n.UnitCost,
                    n.ExpiryDate,
                    n.DaysRemaining,
                    n.IsExpired,
                    n.Message,
                    n.Status
                )).ToList();

                await _cloudHttp.PostAsJsonAsync("api/sync/notifications/push", new PushExpiryNotificationsRequest(syncItems));
            }
            catch { }
        }

        private async Task PullPendingNotificationActionsFromCloudAsync()
        {
            try
            {
                var actions = await _cloudHttp.GetFromJsonAsync<List<PendingNotificationActionDto>>("api/sync/notifications/pending-actions");
                if (actions == null || !actions.Any()) return;

                foreach (var act in actions)
                {
                    bool executed = false;
                    if (act.ActionType == "OK")
                    {
                        var (res, _) = await _posApi.ResolveNotificationAsync(act.NotificationId);
                        executed = res;
                    }
                    else if (act.ActionType == "Waste" && act.BatchId.HasValue)
                    {
                        var wasteReq = new RecordWasteRequest(
                            ProductId: act.ProductId,
                            InventoryBatchId: act.BatchId.Value,
                            Quantity: act.Quantity > 0 ? act.Quantity : 1,
                            Unit: "قطعة",
                            Reason: act.Reason ?? "تسجيل هالك من تطبيق الموبايل",
                            Notes: act.Notes,
                            Source: "MobileApp",
                            RelatedNotificationId: act.NotificationId
                        );
                        var (res, _, _) = await _posApi.RecordWasteAsync(wasteReq);
                        if (res)
                        {
                            await _posApi.ResolveNotificationAsync(act.NotificationId);
                            executed = true;
                        }
                    }
                    else if (act.ActionType == "SupplierReplacement" && act.BatchId.HasValue && act.NewExpiryDate.HasValue)
                    {
                        var (res, _) = await _posApi.ReplaceBatchWithSupplierAsync(
                            act.BatchId.Value,
                            act.NewExpiryDate.Value,
                            act.NewBatchNumber,
                            act.Notes,
                            act.NotificationId
                        );
                        if (res)
                        {
                            await _posApi.ResolveNotificationAsync(act.NotificationId);
                            executed = true;
                        }
                    }

                    if (executed)
                    {
                        await _cloudHttp.PostAsync($"api/sync/notifications/actions/{act.NotificationId}/acknowledge", null);
                    }
                }
            }
            catch { }
        }

        public async Task<bool> PushClosedShiftToCloudAsync(PushClosedShiftRequest shiftReq)
        {
            try
            {
                var res = await _cloudHttp.PostAsJsonAsync("api/sync/shifts/closed-push", shiftReq);
                if (res.IsSuccessStatusCode)
                {
                    _ = Task.Run(async () =>
                    {
                        await Task.Delay(500);
                        await SyncNowAsync(forceCatalogPush: true);
                    });
                }
                return res.IsSuccessStatusCode;
            }
            catch
            {
                return false;
            }
        }

        private void NotifyStateChanged() => OnSyncStateChanged?.Invoke();

        public void Dispose()
        {
            StopPeriodicSync();
            _cloudHttp.Dispose();
        }
    }
}
