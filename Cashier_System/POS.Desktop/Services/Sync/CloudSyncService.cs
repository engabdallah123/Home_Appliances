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

        private CancellationTokenSource? _syncCts;
        private volatile bool _skipCurrentStage = false;
        private readonly List<SyncStageItem> _stages = new();
        public IReadOnlyList<SyncStageItem> Stages => _stages;
        private readonly List<PendingSyncItemView> _pendingQueue = new();
        public IReadOnlyList<PendingSyncItemView> PendingQueue => _pendingQueue;

        public string CurrentSyncStage { get; private set; } = "جاهز للمزامنة";
        public int CurrentProgressPercent { get; private set; } = 0;

        public event Action? OnSyncStateChanged;
        public event Action? OnDataImported;

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

        public void CancelSync()
        {
            if (_isSyncing && _syncCts != null)
            {
                try
                {
                    _syncCts.Cancel();
                }
                catch { }
                CurrentSyncStage = "تم إيقاف المزامنة بواسطة المستخدم";
                LastSyncStatus = "تم إيقاف المزامنة يدوياً بواسطة المستخدم";
                NotifyStateChanged();
            }
        }

        public void SkipCurrentStage()
        {
            _skipCurrentStage = true;
            NotifyStateChanged();
        }

        private void InitializeStages()
        {
            _stages.Clear();
            _stages.Add(new SyncStageItem { Id = "health", NameAr = "فحص الاتصال والشبكة", DescriptionAr = "التحقق من اتصال الإنترنت واستجابة السيرفر السحابي", Icon = "fa-solid fa-wifi" });
            _stages.Add(new SyncStageItem { Id = "pull_categories_brands", NameAr = "سحب الأقسام والماركات", DescriptionAr = "تنزيل الأقسام والماركات المسجلة سحابياً", Icon = "fa-solid fa-tags" });
            _stages.Add(new SyncStageItem { Id = "pull_suppliers", NameAr = "سحب بيانات الموردين", DescriptionAr = "تنزيل حسابات الموردين المضافة حديثاً من الموبايل", Icon = "fa-solid fa-truck" });
            _stages.Add(new SyncStageItem { Id = "pull_purchases", NameAr = "سحب فواتير المشتريات من الموبايل", DescriptionAr = "استيراد فواتير البضاعة المسجلة من تطبيق الموبايل", Icon = "fa-solid fa-cart-shopping" });
            _stages.Add(new SyncStageItem { Id = "pull_products", NameAr = "سحب المنتجات والأسعار من الموبايل", DescriptionAr = "تحديث أسعار وباركودات الأجهزة المضافة من الصالة", Icon = "fa-solid fa-box" });
            _stages.Add(new SyncStageItem { Id = "pull_sales", NameAr = "سحب مبيعات الصالة من الموبايل", DescriptionAr = "استيراد فواتير بيع أجهزة المعرض المسجلة من الموبايل", Icon = "fa-solid fa-receipt" });
            _stages.Add(new SyncStageItem { Id = "pull_debts", NameAr = "سحب تحصيلات الديون من الموبايل", DescriptionAr = "استيراد سندات سداد ديون العملاء المحصلة عبر الموبايل", Icon = "fa-solid fa-hand-holding-dollar" });
            _stages.Add(new SyncStageItem { Id = "pull_expenses", NameAr = "سحب المصروفات من الموبايل", DescriptionAr = "استيراد مصاريف التشغيل المسجلة من تطبيق الموبايل", Icon = "fa-solid fa-file-invoice-dollar" });
            _stages.Add(new SyncStageItem { Id = "push_expenses", NameAr = "رفع المصروفات المحلية", DescriptionAr = "مزامنة مصاريف كاشير المحل إلى السحابة", Icon = "fa-solid fa-outbox" });
            _stages.Add(new SyncStageItem { Id = "push_settings", NameAr = "تحديث إعدادات ومعلومات المحل", DescriptionAr = "مزامنة اسم المعرض وبيانات الفاتورة", Icon = "fa-solid fa-store" });
            _stages.Add(new SyncStageItem { Id = "push_suppliers_brands", NameAr = "رفع الموردين والماركات والديون", DescriptionAr = "مزامنة أرصدة الموردين وحسابات الذمم المدينة", Icon = "fa-solid fa-award" });
            _stages.Add(new SyncStageItem { Id = "push_returns", NameAr = "رفع المرتجعات", DescriptionAr = "مزامنة مرتجعات المبيعات والمشتريات المحلية", Icon = "fa-solid fa-rotate-left" });
            _stages.Add(new SyncStageItem { Id = "push_sales", NameAr = "رفع المبيعات والأقساط والحجوزات", DescriptionAr = "مزامنة فواتير بيع الكاشير وعقود التقسيط وحجوزات العرائس", Icon = "fa-solid fa-vault" });
            _stages.Add(new SyncStageItem { Id = "push_offers", NameAr = "رفع العروض وبكجات التخفيض", DescriptionAr = "مزامنة بكجات الأجهزة وعروض الخصم إلى الموبايل", Icon = "fa-solid fa-gift" });
            _stages.Add(new SyncStageItem { Id = "push_dashboard", NameAr = "تحديث الداشبورد والتقويم المالي", DescriptionAr = "مزامنة أرقام ومبيعات الشهر والتقويم المالي للسحابة", Icon = "fa-solid fa-chart-line" });
            _stages.Add(new SyncStageItem { Id = "push_catalog", NameAr = "مزامنة كتالوج المنتجات والمخزون", DescriptionAr = "تحديث كامل للأجهزة والأسعار والكميات المتاحة", Icon = "fa-solid fa-boxes-stacked" });
        }

        private void UpdateProgressPercentage()
        {
            if (!_stages.Any())
            {
                CurrentProgressPercent = 0;
                return;
            }
            int done = _stages.Count(s => s.Status == SyncStageStatus.Completed || s.Status == SyncStageStatus.Skipped || s.Status == SyncStageStatus.Failed);
            CurrentProgressPercent = (int)Math.Round((double)done / _stages.Count * 100);
        }

        private async Task RunStageAsync(string stageId, Func<CancellationToken, Task<string?>> action)
        {
            if (_syncCts?.IsCancellationRequested == true)
            {
                var s = _stages.FirstOrDefault(x => x.Id == stageId);
                if (s != null) { s.Status = SyncStageStatus.Skipped; s.Details = "تم الإلغاء"; }
                return;
            }

            var stage = _stages.FirstOrDefault(s => s.Id == stageId);
            if (stage != null)
            {
                stage.Status = SyncStageStatus.InProgress;
                stage.StartedAt = DateTime.Now;
                CurrentSyncStage = stage.NameAr;
                NotifyStateChanged();
            }

            try
            {
                if (_syncCts != null)
                {
                    var detail = await action(_syncCts.Token);
                    if (stage != null)
                    {
                        stage.Status = _skipCurrentStage ? SyncStageStatus.Skipped : SyncStageStatus.Completed;
                        stage.Details = detail ?? "اكتملت الخطوة بنجاح";
                        stage.FinishedAt = DateTime.Now;
                    }
                }
            }
            catch (OperationCanceledException)
            {
                if (stage != null)
                {
                    stage.Status = SyncStageStatus.Skipped;
                    stage.Details = "تم إلغاء الخطوة بواسطة المستخدم";
                    stage.FinishedAt = DateTime.Now;
                }
                throw;
            }
            catch (Exception ex)
            {
                if (stage != null)
                {
                    stage.Status = SyncStageStatus.Failed;
                    stage.Details = ex.Message;
                    stage.FinishedAt = DateTime.Now;
                }
            }
            finally
            {
                _skipCurrentStage = false;
                UpdateProgressPercentage();
                NotifyStateChanged();
            }
        }

        public async Task<SyncStatusResult> SyncNowAsync(bool forceCatalogPush = false)
        {
            if (!NetworkInterface.GetIsNetworkAvailable())
            {
                _isOffline = true;
                IsCloudReachable = false;
                CurrentSyncStage = "الجهاز غير متصل بالإنترنت";
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
            _syncCts = new CancellationTokenSource();
            _skipCurrentStage = false;
            InitializeStages();
            CurrentSyncStage = "بدء المزامنة...";
            UpdateProgressPercentage();
            NotifyStateChanged();

            var result = new SyncStatusResult();

            try
            {
                // 1. Health check
                await RunStageAsync("health", async (ct) =>
                {
                    var isOnline = await CheckCloudOnlineAsync();
                    if (!isOnline)
                    {
                        throw new InvalidOperationException("تعذر الاتصال بالخادم السحابي (السيرفر غير متصل أو لا يوجد إنترنت).");
                    }
                    return "تم الاتصال بنجاح بالسيرفر السحابي";
                });

                if (_syncCts.IsCancellationRequested) throw new OperationCanceledException();

                // 2. Categories & Brands
                int catsCount = 0;
                int brandsCount = 0;
                await RunStageAsync("pull_categories_brands", async (ct) =>
                {
                    catsCount = await PullPendingCategoriesFromCloudAsync();
                    brandsCount = await PullPendingBrandsFromCloudAsync();
                    return $"تم استيراد {catsCount} أقسام و {brandsCount} ماركات";
                });

                if (_syncCts.IsCancellationRequested) throw new OperationCanceledException();

                // 3. Suppliers
                await RunStageAsync("pull_suppliers", async (ct) =>
                {
                    await PullPendingSuppliersFromCloudAsync();
                    return "تم فحص وسحب الموردين الجدد";
                });

                if (_syncCts.IsCancellationRequested) throw new OperationCanceledException();

                // 4. Purchases
                int purchasesCount = 0;
                await RunStageAsync("pull_purchases", async (ct) =>
                {
                    purchasesCount = await PullPendingPurchasesFromCloudAsync();
                    result.SyncedPurchasesCount = purchasesCount;
                    return purchasesCount > 0 ? $"تم استيراد {purchasesCount} فاتورة مشتريات من الموبايل" : "لا توجد مشتريات جديدة معلقة";
                });

                if (_syncCts.IsCancellationRequested) throw new OperationCanceledException();

                // 5. Products
                await RunStageAsync("pull_products", async (ct) =>
                {
                    await PullPendingProductsFromCloudAsync();
                    return "تم فحص وسحب المنتجات المحدثة من الموبايل";
                });

                if (_syncCts.IsCancellationRequested) throw new OperationCanceledException();

                // 6. Mobile POS Sales
                int salesCount = 0;
                await RunStageAsync("pull_sales", async (ct) =>
                {
                    salesCount = await PullPendingSalesFromCloudAsync();
                    result.SyncedSalesCount = salesCount;
                    return salesCount > 0 ? $"تم استيراد {salesCount} فواتير بيع من تطبيق الموبايل" : "لا توجد مبيعات صالة جديدة";
                });

                if (_syncCts.IsCancellationRequested) throw new OperationCanceledException();

                // 7. Debts
                int debtsCount = 0;
                await RunStageAsync("pull_debts", async (ct) =>
                {
                    debtsCount = await PullPendingDebtPaymentsFromCloudAsync();
                    result.SyncedDebtsCount = debtsCount;
                    return debtsCount > 0 ? $"تم استيراد {debtsCount} سندات سداد ديون" : "لا توجد سندات سداد معلقة";
                });

                if (_syncCts.IsCancellationRequested) throw new OperationCanceledException();

                // 8. Expenses
                int expensesCount = 0;
                await RunStageAsync("pull_expenses", async (ct) =>
                {
                    expensesCount = await PullPendingExpensesFromCloudAsync();
                    return expensesCount > 0 ? $"تم استيراد {expensesCount} مصروفات مسجلة بالموبايل" : "لا توجد مصروفات جديدة";
                });

                if (_syncCts.IsCancellationRequested) throw new OperationCanceledException();

                // 9. Push Local Expenses
                await RunStageAsync("push_expenses", async (ct) =>
                {
                    await PushLocalExpensesToCloudAsync();
                    return "تم رفع المصروفات المحلية بنجاح";
                });

                if (_syncCts.IsCancellationRequested) throw new OperationCanceledException();

                // 10. Push Settings
                await RunStageAsync("push_settings", async (ct) =>
                {
                    await PushStoreSettingsToCloudAsync();
                    return "تم تحديث بيانات المحل بالسحابة";
                });

                if (_syncCts.IsCancellationRequested) throw new OperationCanceledException();

                // 11. Push Suppliers, Brands, Debts
                await RunStageAsync("push_suppliers_brands", async (ct) =>
                {
                    await PushSuppliersToCloudAsync();
                    await PushBrandsToCloudAsync();
                    return "تمت مزامنة الموردين والماركات والديون";
                });

                if (_syncCts.IsCancellationRequested) throw new OperationCanceledException();

                // 12. Push Returns
                await RunStageAsync("push_returns", async (ct) =>
                {
                    await PushReturnsToCloudAsync();
                    return "تمت مزامنة مرتجعات المبيعات والمشتريات";
                });

                if (_syncCts.IsCancellationRequested) throw new OperationCanceledException();

                // 13. Push Sales, Reservations & Installments
                await RunStageAsync("push_sales", async (ct) =>
                {
                    await PushSalesToCloudAsync();
                    return "تمت مزامنة المبيعات المحلية والأقساط والحجوزات";
                });

                if (_syncCts.IsCancellationRequested) throw new OperationCanceledException();

                // 14. Push Offers
                await RunStageAsync("push_offers", async (ct) =>
                {
                    await PushOffersToCloudAsync();
                    return "تمت مزامنة العروض وبكجات العرائس";
                });

                if (_syncCts.IsCancellationRequested) throw new OperationCanceledException();

                // 15. Push Dashboard Snapshot
                await RunStageAsync("push_dashboard", async (ct) =>
                {
                    if (purchasesCount > 0 || salesCount > 0 || debtsCount > 0 || expensesCount > 0 || (DateTime.UtcNow - _lastDashboardPush) > TimeSpan.FromSeconds(60))
                    {
                        await PushDebtsAndDashboardAsync();
                        _lastDashboardPush = DateTime.UtcNow;
                        return "تم تحديث أرقام الداشبورد والتقويم المالي بالسحابة";
                    }
                    return "الداشبورد السحابي محدث ومطابق";
                });

                if (_syncCts.IsCancellationRequested) throw new OperationCanceledException();

                // 16. Push Catalog
                int catalogCount = 0;
                await RunStageAsync("push_catalog", async (ct) =>
                {
                    if (forceCatalogPush || (DateTime.UtcNow - _lastCatalogPush) > TimeSpan.FromMinutes(15))
                    {
                        catalogCount = await PushLocalCatalogToCloudAsync();
                        result.SyncedCatalogCount = catalogCount;
                        _lastCatalogPush = DateTime.UtcNow;
                        return $"تم تحديث كتالوج المنتجات ({catalogCount} صنف)";
                    }
                    return "الكتالوج السحابي محدث";
                });

                // Notify pages ONLY when new data was actually pulled/imported from remote
                if (purchasesCount > 0 || salesCount > 0 || debtsCount > 0 || expensesCount > 0 || brandsCount > 0 || catsCount > 0)
                {
                    NotifyDataImported();
                }

                result.Success = true;
                LastSyncSucceeded = true;
                _isOffline = false;
                _hasLocalChanges = false;
                LastSyncTime = DateTime.Now;
                CurrentSyncStage = "اكتملت المزامنة بنجاح";
                CurrentProgressPercent = 100;
                LastSyncStatus = (purchasesCount > 0 || salesCount > 0 || brandsCount > 0)
                    ? $"اكتملت المزامنة بنجاح (تم استيراد {purchasesCount} مشتريات و {salesCount} مبيعات و {brandsCount} ماركات)"
                    : "المزامنة نشطة ومحدثة بنجاح";
                result.Message = $"تمت المزامنة بنجاح! ({purchasesCount} مشتريات، {salesCount} مبيعات، {debtsCount} سدادات ديون، {brandsCount} ماركات)";
            }
            catch (OperationCanceledException)
            {
                result.Success = false;
                LastSyncSucceeded = false;
                result.Error = "تم إلغاء المزامنة بواسطة المستخدم.";
                CurrentSyncStage = "تم إيقاف المزامنة";
                LastSyncStatus = "تم إيقاف المزامنة يدوياً بواسطة المستخدم";
                result.Message = "تم إيقاف المزامنة.";
            }
            catch (Exception ex)
            {
                result.Success = false;
                LastSyncSucceeded = false;
                result.Error = ex.Message;
                CurrentSyncStage = $"خطأ: {ex.Message}";
                LastSyncStatus = $"فشلت المزامنة: {ex.Message}";
            }
            finally
            {
                _isSyncing = false;
                NotifyStateChanged();
                // Refresh pending queue after sync finishes
                _ = Task.Run(async () => { try { await FetchPendingQueueAsync(); } catch { } });
            }

            return result;
        }

        public async Task<List<PendingSyncItemView>> FetchPendingQueueAsync()
        {
            var list = new List<PendingSyncItemView>();
            try
            {
                var pendingPurchases = await _cloudHttp.GetFromJsonAsync<List<CloudPurchaseSyncDto>>("api/sync/purchases/pending");
                if (pendingPurchases != null)
                {
                    foreach (var p in pendingPurchases)
                    {
                        list.Add(new PendingSyncItemView
                        {
                            Id = p.Id,
                            EntityType = "Purchase",
                            Title = $"فاتورة مشتريات #{p.InvoiceNumber}",
                            Subtitle = $"المورد: {p.SupplierName ?? "غير محدد"} | التاريخ: {p.PurchaseDate:yyyy-MM-dd}",
                            Details = $"{p.Items.Count} أصناف | الإجمالي: {p.TotalAmount:N2} ج.م",
                            Amount = p.TotalAmount,
                            Date = p.PurchaseDate,
                            Source = "تطبيق الموبايل",
                            Status = "بانتظار السحب للديسكتوب"
                        });
                    }
                }
            }
            catch { }

            try
            {
                var pendingSales = await _cloudHttp.GetFromJsonAsync<List<CloudSaleSyncDto>>("api/sync/sales/pending");
                if (pendingSales != null)
                {
                    foreach (var s in pendingSales)
                    {
                        list.Add(new PendingSyncItemView
                        {
                            Id = s.Id,
                            EntityType = "Sale",
                            Title = $"فاتورة بيع صالة #{s.InvoiceNumber}",
                            Subtitle = $"العميل: {s.CustomerName ?? "عميل نقدي"} | {s.PaymentMethod}",
                            Details = $"{s.Items.Count} أجهزة | الإجمالي: {s.TotalAmount:N2} ج.م",
                            Amount = s.TotalAmount,
                            Date = s.SaleDate,
                            Source = "موبايل الصالة (POS)",
                            Status = "بانتظار السحب للديسكتوب"
                        });
                    }
                }
            }
            catch { }

            try
            {
                var pendingDebts = await _cloudHttp.GetFromJsonAsync<List<PendingDebtPaymentDto>>("api/sync/debts/pending");
                if (pendingDebts != null)
                {
                    foreach (var d in pendingDebts)
                    {
                        list.Add(new PendingSyncItemView
                        {
                            Id = d.Id,
                            EntityType = "DebtPayment",
                            Title = $"سند تحصيل دين ({d.DebtType})",
                            Subtitle = $"ملاحظات: {d.Notes ?? "تحصيل من الموبايل"}",
                            Details = $"المبلغ المحصل: {d.Amount:N2} ج.م",
                            Amount = d.Amount,
                            Date = d.CreatedAt,
                            Source = "تطبيق الموبايل",
                            Status = "بانتظار السحب للديسكتوب"
                        });
                    }
                }
            }
            catch { }

            try
            {
                var pendingExpenses = await _cloudHttp.GetFromJsonAsync<List<CloudExpenseSyncDto>>("api/sync/expenses/pending");
                if (pendingExpenses != null)
                {
                    foreach (var e in pendingExpenses)
                    {
                        list.Add(new PendingSyncItemView
                        {
                            Id = e.Id,
                            EntityType = "Expense",
                            Title = $"مصروف: {e.Category}",
                            Subtitle = e.Description ?? "مصروف مسجل من الموبايل",
                            Details = $"المبلغ: {e.Amount:N2} ج.م",
                            Amount = e.Amount,
                            Date = e.Date,
                            Source = "تطبيق الموبايل",
                            Status = "بانتظار السحب للديسكتوب"
                        });
                    }
                }
            }
            catch { }

            try
            {
                var pendingProds = await _cloudHttp.GetFromJsonAsync<List<PendingCloudProductDto>>("api/sync/products/pending");
                if (pendingProds != null)
                {
                    foreach (var pr in pendingProds)
                    {
                        list.Add(new PendingSyncItemView
                        {
                            Id = pr.Id,
                            EntityType = "Product",
                            Title = $"منتج جديد: {pr.NameAr}",
                            Subtitle = $"باركود: {pr.Barcode} | القسم: {pr.CategoryName ?? "عام"}",
                            Details = $"سعر البيع: {pr.SellingPrice:N2} ج.م | الشراء: {pr.PurchasePrice:N2} ج.م",
                            Amount = pr.SellingPrice,
                            Date = DateTime.Now,
                            Source = "تطبيق الموبايل",
                            Status = "بانتظار السحب للديسكتوب"
                        });
                    }
                }
            }
            catch { }

            _pendingQueue.Clear();
            _pendingQueue.AddRange(list);
            NotifyStateChanged();
            return list;
        }

        public async Task<bool> DismissPendingItemAsync(string entityType, Guid id)
        {
            try
            {
                var response = await _cloudHttp.PostAsync($"api/sync/items/{entityType}/{id}/dismiss", null);
                if (response.IsSuccessStatusCode)
                {
                    _pendingQueue.RemoveAll(x => x.Id == id && string.Equals(x.EntityType, entityType, StringComparison.OrdinalIgnoreCase));
                    NotifyStateChanged();
                    return true;
                }
            }
            catch (Exception ex)
            {
                Console.WriteLine($"Error dismissing pending item: {ex.Message}");
            }
            return false;
        }

        public async Task<bool> SyncSinglePendingItemAsync(string entityType, Guid id)
        {
            await SyncNowAsync();
            await FetchPendingQueueAsync();
            return true;
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

                var categories = await _posApi.GetCategoriesAsync() ?? new();
                var units = await _posApi.GetUnitsAsync() ?? new();
                var brands = await _posApi.GetBrandsAsync() ?? new();

                // 1. Ensure Default Category exists locally
                var defaultCatId = categories.FirstOrDefault()?.Id ?? Guid.Empty;
                if (defaultCatId == Guid.Empty)
                {
                    defaultCatId = await _posApi.CreateCategoryAsync(new CreateCategoryRequest("أجهزة كهربائية عامة")) ?? Guid.Empty;
                    categories = await _posApi.GetCategoriesAsync() ?? new();
                }

                // 2. Ensure Default Unit exists locally (Never Guid.Empty!)
                if (!units.Any())
                {
                    await _posApi.CreateUnitAsync(new CreateUnitRequest("قطعة", "Piece", "قطعة"));
                    units = await _posApi.GetUnitsAsync() ?? new();
                }
                var defaultUnitId = units.FirstOrDefault()?.Id ?? Guid.Empty;

                var localProducts = await _posApi.GetProductsAsync() ?? new();
                var localById = localProducts.ToDictionary(p => p.Id);
                var localByBarcode = localProducts
                    .Where(p => !string.IsNullOrWhiteSpace(p.Barcode))
                    .GroupBy(p => p.Barcode.Trim().ToLower())
                    .ToDictionary(g => g.Key, g => g.First());

                int importedProductsCount = 0;

                foreach (var prod in pendingProducts)
                {
                    var barcodeClean = prod.Barcode?.Trim().ToLower() ?? string.Empty;

                    // If already exists locally by Id or Barcode, acknowledge immediately and skip
                    if (localById.ContainsKey(prod.Id) || (!string.IsNullOrEmpty(barcodeClean) && localByBarcode.ContainsKey(barcodeClean)))
                    {
                        await _cloudHttp.PostAsync($"api/sync/products/{prod.Id}/acknowledge", null);
                        continue;
                    }

                    // A. Resolve Unit ID
                    Guid resolvedUnitId = defaultUnitId;
                    if (!string.IsNullOrWhiteSpace(prod.BaseUnit))
                    {
                        var matchingUnit = units.FirstOrDefault(u =>
                            u.NameAr.Equals(prod.BaseUnit.Trim(), StringComparison.OrdinalIgnoreCase) ||
                            u.Symbol.Equals(prod.BaseUnit.Trim(), StringComparison.OrdinalIgnoreCase) ||
                            u.NameEn.Equals(prod.BaseUnit.Trim(), StringComparison.OrdinalIgnoreCase));
                        if (matchingUnit != null)
                        {
                            resolvedUnitId = matchingUnit.Id;
                        }
                    }

                    // B. Resolve Category ID
                    Guid resolvedCatId = defaultCatId;
                    if (prod.CategoryId.HasValue && categories.Any(c => c.Id == prod.CategoryId.Value))
                    {
                        resolvedCatId = prod.CategoryId.Value;
                    }
                    else if (!string.IsNullOrWhiteSpace(prod.CategoryName))
                    {
                        var matchingCat = categories.FirstOrDefault(c =>
                            c.NameAr.Trim().Equals(prod.CategoryName.Trim(), StringComparison.OrdinalIgnoreCase) ||
                            (!string.IsNullOrWhiteSpace(c.NameEn) && c.NameEn.Trim().Equals(prod.CategoryName.Trim(), StringComparison.OrdinalIgnoreCase)));
                        if (matchingCat != null)
                        {
                            resolvedCatId = matchingCat.Id;
                        }
                        else
                        {
                            // Try creating the category locally
                            var newCatId = await _posApi.CreateCategoryAsync(new CreateCategoryRequest(prod.CategoryName.Trim(), prod.CategoryName.Trim()));
                            if (newCatId.HasValue && newCatId.Value != Guid.Empty)
                            {
                                resolvedCatId = newCatId.Value;
                                categories = await _posApi.GetCategoriesAsync() ?? categories;
                            }
                        }
                    }

                    // C. Resolve Brand ID
                    Guid? resolvedBrandId = null;
                    if (prod.BrandId.HasValue && brands.Any(b => b.Id == prod.BrandId.Value))
                    {
                        resolvedBrandId = prod.BrandId.Value;
                    }
                    else if (!string.IsNullOrWhiteSpace(prod.BrandName))
                    {
                        var matchingBrand = brands.FirstOrDefault(b =>
                            (!string.IsNullOrWhiteSpace(b.Name) && b.Name.Trim().Equals(prod.BrandName.Trim(), StringComparison.OrdinalIgnoreCase)) ||
                            (!string.IsNullOrWhiteSpace(b.NameAr) && b.NameAr.Trim().Equals(prod.BrandName.Trim(), StringComparison.OrdinalIgnoreCase)));
                        if (matchingBrand != null)
                        {
                            resolvedBrandId = matchingBrand.Id;
                        }
                        else
                        {
                            // Try creating the brand locally
                            var (newBrandId, _) = await _posApi.CreateBrandAsync(new CreateBrandRequest(
                                NameAr: prod.BrandName.Trim(),
                                NameEn: prod.BrandName.Trim(),
                                Description: "مستورد من تطبيق الموبايل",
                                Name: prod.BrandName.Trim()));
                            if (newBrandId.HasValue && newBrandId.Value != Guid.Empty)
                            {
                                resolvedBrandId = newBrandId.Value;
                                brands = await _posApi.GetBrandsAsync() ?? brands;
                            }
                        }
                    }

                    var formModel = new CreateProductFormModel
                    {
                        Id = prod.Id,
                        Barcode = prod.Barcode ?? string.Empty,
                        NameAr = prod.NameAr,
                        NameEn = prod.NameEn ?? string.Empty,
                        BaseUnit = prod.BaseUnit ?? "قطعة",
                        ParentUnit = prod.ParentUnit ?? "قطعة",
                        ConversionFactor = prod.ConversionFactor > 0 ? prod.ConversionFactor : 1,
                        PurchasePrice = prod.PurchasePrice,
                        SellingPrice = prod.SellingPrice,
                        WholesalePrice = prod.WholesalePrice,
                        ShelfLifeDays = prod.ShelfLifeDays,
                        ExpiryAlertDays = prod.ExpiryAlertDays > 0 ? prod.ExpiryAlertDays : 3,
                        ReorderLevel = prod.ReorderLevel,
                        IsWeighable = prod.IsWeighable,
                        TrackExpiry = prod.TrackExpiry,
                        CategoryId = resolvedCatId,
                        UnitId = resolvedUnitId,
                        InitialStock = prod.StockQuantity,
                        BrandId = resolvedBrandId,
                        ModelNumber = prod.ModelNumber,
                        Color = prod.Color,
                        WarrantyPeriodMonths = prod.WarrantyPeriodMonths > 0 ? prod.WarrantyPeriodMonths : 12,
                        MaintenanceAgent = prod.MaintenanceAgent,
                        HasSerialNumber = prod.HasSerialNumber
                    };

                    Console.WriteLine($"[CloudSync] Pulling mobile product '{prod.NameAr}' ({prod.Barcode}) -> CatId: {resolvedCatId}, UnitId: {resolvedUnitId}, BrandId: {resolvedBrandId}, InitialStock: {prod.StockQuantity}");
                    var (productId, error) = await _posApi.CreateProductAsync(formModel);
                    if (productId.HasValue || (error != null && (error.Contains("الباركود مسجل مسبقاً") || error.Contains("Duplicate") || error.Contains("AlreadyExists"))))
                    {
                        await _cloudHttp.PostAsync($"api/sync/products/{prod.Id}/acknowledge", null);
                        Console.WriteLine($"[CloudSync] Product '{prod.NameAr}' ({prod.Barcode}) synced successfully and acknowledged with Cloud.");
                        importedProductsCount++;
                    }
                    else
                    {
                        Console.WriteLine($"[CloudSync] Failed to create mobile product '{prod.NameAr}' locally: {error}");
                    }
                }

                if (importedProductsCount > 0)
                {
                    RecordLocalChange();
                    NotifyStateChanged();
                }
            }
            catch (Exception ex)
            {
                Console.WriteLine($"[CloudSync] Exception in PullPendingProductsFromCloudAsync: {ex.Message}");
            }
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
                        if (!res)
                        {
                            try
                            {
                                var contracts = await _posApi.GetInstallmentContractsAsync();
                                var contract = contracts?.FirstOrDefault(c => c.Id == payment.ReferenceId || c.SaleId == payment.ReferenceId);
                                if (contract != null)
                                {
                                    var fullContract = await _posApi.GetInstallmentContractByIdAsync(contract.Id);
                                    var pendingSchedule = fullContract?.Schedules?
                                        .Where(s => s.RemainingAmount > 0)
                                        .OrderBy(s => s.DueDate)
                                        .FirstOrDefault();

                                    if (pendingSchedule != null)
                                    {
                                        var payReq = new PayInstallmentRequest(
                                            ContractId: contract.Id,
                                            ScheduleId: pendingSchedule.Id,
                                            Amount: Math.Min(payment.Amount, pendingSchedule.RemainingAmount),
                                            PaymentMethod: "Cash",
                                            Notes: $"[سداد من الموبايل] {payment.Notes}".Trim()
                                        );
                                        var (instRes, instErr) = await _posApi.PayInstallmentScheduleAsync(payReq);
                                        if (instRes)
                                        {
                                            res = true;
                                            errorMsg = null;
                                        }
                                        else
                                        {
                                            errorMsg = instErr;
                                        }
                                    }
                                }
                            }
                            catch { }
                        }
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
                        MonthlySalesJson: calendar != null ? JsonSerializer.Serialize(calendar) : null,
                        TodayWasteLoss: dashData.WasteLosses?.TodayLoss ?? 0,
                        MonthWasteLoss: dashData.WasteLosses?.MonthLoss ?? 0,
                        TotalWasteLoss: dashData.WasteLosses?.TotalLoss ?? 0,
                        CustomerCreditDebtsTotal: dashData.TotalCustomerCreditDebts,
                        InstallmentDebtsTotal: dashData.TotalInstallmentDebts,
                        CustomerCreditDebtsCount: dashData.CustomerCreditDebtsCount,
                        InstallmentContractsCount: dashData.InstallmentContractsCount
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

        private async Task<int> PullPendingBrandsFromCloudAsync()
        {
            int importedCount = 0;
            try
            {
                var pendingBrands = await _cloudHttp.GetFromJsonAsync<List<PendingCloudBrandDto>>("api/sync/brands/pending");
                if (pendingBrands == null || !pendingBrands.Any())
                    return 0;

                var localBrands = await _posApi.GetBrandsAsync();
                var localByName = localBrands?
                    .Where(b => !string.IsNullOrWhiteSpace(b.NameAr) || !string.IsNullOrWhiteSpace(b.Name))
                    .ToDictionary(b => (!string.IsNullOrWhiteSpace(b.NameAr) ? b.NameAr : b.Name!).Trim().ToLower(), b => b) ?? new();
                var localById = localBrands?.ToDictionary(b => b.Id, b => b) ?? new();

                foreach (var brand in pendingBrands)
                {
                    var brandName = !string.IsNullOrWhiteSpace(brand.NameAr)
                        ? brand.NameAr.Trim()
                        : !string.IsNullOrWhiteSpace(brand.Name)
                            ? brand.Name.Trim()
                            : brand.NameEn?.Trim() ?? "ماركة";

                    if (localById.ContainsKey(brand.Id) || localByName.ContainsKey(brandName.ToLower()))
                    {
                        await AcknowledgeBrandAsync(brand.Id);
                        continue;
                    }

                    var req = new CreateBrandRequest(
                        NameAr: brandName,
                        NameEn: !string.IsNullOrWhiteSpace(brand.NameEn) ? brand.NameEn.Trim() : brandName,
                        Description: brand.Description,
                        OriginCountry: brand.OriginCountry,
                        AgentContactNumber: brand.AgentContactNumber,
                        Name: brandName
                    );

                    var (brandId, error) = await _posApi.CreateBrandAsync(req);
                    if ((brandId.HasValue && brandId.Value != Guid.Empty) || (error != null && error.Contains("مسبقاً")))
                    {
                        await AcknowledgeBrandAsync(brand.Id);
                        importedCount++;
                    }
                    else
                    {
                        var refreshedBrands = await _posApi.GetBrandsAsync();
                        if (refreshedBrands != null && refreshedBrands.Any(b =>
                            (!string.IsNullOrWhiteSpace(b.NameAr) && b.NameAr.Trim().Equals(brandName, StringComparison.OrdinalIgnoreCase)) ||
                            (!string.IsNullOrWhiteSpace(b.Name) && b.Name.Trim().Equals(brandName, StringComparison.OrdinalIgnoreCase))))
                        {
                            await AcknowledgeBrandAsync(brand.Id);
                        }
                    }
                }
            }
            catch (Exception ex)
            {
                Console.WriteLine($"[CloudSync] Error in PullPendingBrandsFromCloudAsync: {ex.Message}");
            }
            return importedCount;
        }

        private async Task AcknowledgeBrandAsync(Guid brandId)
        {
            try
            {
                await _cloudHttp.PostAsync($"api/sync/brands/{brandId}/acknowledge", null);
            }
            catch { }
        }

        private async Task PushBrandsToCloudAsync()
        {
            try
            {
                var localBrands = await _posApi.GetBrandsAsync();
                if (localBrands == null || !localBrands.Any()) return;

                var brandsToPush = localBrands.Select(b => new PushBrandDto(
                    Id: b.Id,
                    Name: !string.IsNullOrWhiteSpace(b.Name) ? b.Name : b.NameAr,
                    NameAr: b.NameAr,
                    NameEn: b.NameEn,
                    Description: b.Description,
                    OriginCountry: b.OriginCountry,
                    AgentContactNumber: b.AgentContactNumber,
                    IsActive: b.IsActive
                )).ToList();

                await _cloudHttp.PostAsJsonAsync("api/sync/brands/push", new PushBrandsRequest(brandsToPush));
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
                var localBrands = await _posApi.GetBrandsAsync();
                var supplierDebts = await _posApi.GetSupplierDebtsAsync();

                var brandMap = localBrands?.ToDictionary(b => b.Id, b => b.Name) ?? new();

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
                    p.TrackExpiry,
                    p.BrandId,
                    p.BrandId.HasValue && brandMap.TryGetValue(p.BrandId.Value, out var bn) ? bn : null,
                    p.ModelNumber,
                    p.Color,
                    p.WarrantyPeriodMonths > 0 ? p.WarrantyPeriodMonths : 12,
                    p.MaintenanceAgent,
                    p.HasSerialNumber
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

                // Preload known local sales invoices if cache is empty
                if (!_knownSaleInvoiceNumbers.Any())
                {
                    try
                    {
                        var existingLocal = await _posApi.GetSalesListAsync(DateTime.UtcNow.AddDays(-180), DateTime.UtcNow.AddDays(1));
                        foreach (var s in existingLocal ?? Enumerable.Empty<SaleDto>())
                        {
                            if (!string.IsNullOrWhiteSpace(s.InvoiceNumber))
                                _knownSaleInvoiceNumbers.Add(s.InvoiceNumber.Trim());
                        }
                    }
                    catch { }
                }

                var adminUserId = _authState.UserId != Guid.Empty ? _authState.UserId : Guid.Parse("2bc4e49b-fe29-4c7b-9eed-649de1c32cef");

                var localProducts = await _posApi.GetProductsAsync();
                var localById = localProducts?.ToDictionary(p => p.Id) ?? new();
                var localByBarcode = localProducts?
                    .Where(p => !string.IsNullOrWhiteSpace(p.Barcode))
                    .GroupBy(p => p.Barcode.Trim().ToLower())
                    .ToDictionary(g => g.Key, g => g.First()) ?? new();
                var localByName = localProducts?
                    .Where(p => !string.IsNullOrWhiteSpace(p.NameAr))
                    .GroupBy(p => p.NameAr.Trim().ToLower())
                    .ToDictionary(g => g.Key, g => g.First()) ?? new();

                var affectedProductIds = new HashSet<Guid>();

                foreach (var cloudSale in pendingSales)
                {
                    bool isKnown = !string.IsNullOrWhiteSpace(cloudSale.InvoiceNumber) && _knownSaleInvoiceNumbers.Contains(cloudSale.InvoiceNumber.Trim());
                    SaleDto? matchedSale = null;

                    if (isKnown || !string.IsNullOrWhiteSpace(cloudSale.InvoiceNumber))
                    {
                        try
                        {
                            var existingSales = await _posApi.GetSalesListAsync(DateTime.UtcNow.AddDays(-180), DateTime.UtcNow.AddDays(1));
                            matchedSale = existingSales?.FirstOrDefault(s =>
                                s.Id == cloudSale.Id ||
                                (!string.IsNullOrWhiteSpace(s.InvoiceNumber) && !string.IsNullOrWhiteSpace(cloudSale.InvoiceNumber) &&
                                 s.InvoiceNumber.Trim().Equals(cloudSale.InvoiceNumber.Trim(), StringComparison.OrdinalIgnoreCase)));
                        }
                        catch { }
                    }

                    if (matchedSale != null)
                    {
                        if (cloudSale.ReservationStatus > 0 && matchedSale.ReservationStatus != cloudSale.ReservationStatus)
                        {
                            try
                            {
                                await _posApi.UpdateReservationStatusAsync(matchedSale.Id, cloudSale.ReservationStatus);
                                importedCount++;
                            }
                            catch { }
                        }
                        await AcknowledgeSaleAsync(cloudSale.Id, matchedSale.Id.ToString());
                        if (!string.IsNullOrWhiteSpace(cloudSale.InvoiceNumber))
                        {
                            _knownSaleInvoiceNumbers.Add(cloudSale.InvoiceNumber.Trim());
                        }
                        continue;
                    }

                    // Auto-resolve or create Customer locally if name/phone provided
                    Guid? resolvedCustomerId = cloudSale.CustomerId;
                    var targetCustName = !string.IsNullOrWhiteSpace(cloudSale.CustomerName)
                        ? cloudSale.CustomerName.Trim()
                        : cloudSale.RecipientName?.Trim();
                    var targetCustPhone = !string.IsNullOrWhiteSpace(cloudSale.CustomerPhone)
                        ? cloudSale.CustomerPhone.Trim()
                        : cloudSale.RecipientPhone?.Trim();

                    if (!string.IsNullOrWhiteSpace(targetCustName))
                    {
                        try
                        {
                            var existingCustomers = await _posApi.GetCustomersAsync();
                            var matchedCust = existingCustomers?.FirstOrDefault(c =>
                                (!string.IsNullOrWhiteSpace(targetCustPhone) && !string.IsNullOrWhiteSpace(c.Phone) && c.Phone.Trim() == targetCustPhone) ||
                                c.Name.Trim().Equals(targetCustName, StringComparison.OrdinalIgnoreCase));

                            if (matchedCust != null)
                            {
                                resolvedCustomerId = matchedCust.Id;
                            }
                            else
                            {
                                var (newCustId, _) = await _posApi.CreateCustomerAsync(
                                    name: targetCustName,
                                    phone: !string.IsNullOrWhiteSpace(targetCustPhone) ? targetCustPhone : "01000000000",
                                    address: cloudSale.DeliveryAddress);
                                if (newCustId.HasValue && newCustId.Value != Guid.Empty)
                                {
                                    resolvedCustomerId = newCustId.Value;
                                }
                            }
                        }
                        catch { }
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
                            else if (!string.IsNullOrWhiteSpace(i.ProductName) && localByName.TryGetValue(i.ProductName.Trim().ToLower(), out var pMatchName))
                            {
                                resolvedProductId = pMatchName.Id;
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

                    bool isInstSale = cloudSale.IsInstallment || cloudSale.PaymentMethod == "Installment";

                    var localCmd = new CreateSaleCommand(
                        CashierId: adminUserId,
                        ShiftId: Guid.Empty, // Auto-resolved by backend to active shift or system shift!
                        Items: localItems,
                        CustomerId: resolvedCustomerId,
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
                        IsInstallment: isInstSale,
                        GuarantorName: cloudSale.GuarantorName,
                        GuarantorPhone: cloudSale.GuarantorPhone,
                        InterestPercentage: cloudSale.InterestPercentage,
                        NumberOfMonths: cloudSale.NumberOfMonths > 0 ? cloudSale.NumberOfMonths : 12,
                        CustomInvoiceNumber: cloudSale.InvoiceNumber,
                        BypassStockCheck: true
                    );

                    var (result, error) = await _posApi.CreateSaleAsync(localCmd);

                    if (result != null && result.SaleId != Guid.Empty)
                    {
                        if (cloudSale.ReservationStatus > 0)
                        {
                            try
                            {
                                await _posApi.UpdateReservationStatusAsync(result.SaleId, cloudSale.ReservationStatus);
                            }
                            catch { }
                        }

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
                    else if (error != null && (error.Contains("مسجل مسبقاً") || error.Contains("Duplicate") || error.Contains("already exists") || error.Contains("موجودة")))
                    {
                        await AcknowledgeSaleAsync(cloudSale.Id, "Duplicate Detected Locally");
                        if (!string.IsNullOrWhiteSpace(cloudSale.InvoiceNumber))
                        {
                            _knownSaleInvoiceNumbers.Add(cloudSale.InvoiceNumber.Trim());
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
                var remainingMap = customerDebts?
                    .Where(d => d.SaleId != Guid.Empty)
                    .GroupBy(d => d.SaleId)
                    .ToDictionary(g => g.Key, g => g.First().RemainingAmount) ?? new();

                var installmentContracts = await _posApi.GetInstallmentContractsAsync();
                var contractBySaleIdMap = installmentContracts?
                    .Where(c => c.SaleId != Guid.Empty)
                    .GroupBy(c => c.SaleId)
                    .ToDictionary(g => g.Key, g => g.First()) ?? new();

                var contractByIdMap = installmentContracts?
                    .Where(c => c.Id != Guid.Empty)
                    .GroupBy(c => c.Id)
                    .ToDictionary(g => g.Key, g => g.First()) ?? new();

                var salesToPush = localSales.Select(s =>
                {
                    bool isInst = s.IsInstallment || s.PaymentMethod == "Installment" || s.PaymentMethod == "تقسيط" || contractBySaleIdMap.ContainsKey(s.Id);

                    InstallmentContractDto? contract = null;
                    if (s.InstallmentContractId.HasValue && contractByIdMap.TryGetValue(s.InstallmentContractId.Value, out var c1)) contract = c1;
                    if (contract == null && contractBySaleIdMap.TryGetValue(s.Id, out var c2)) contract = c2;

                    decimal total = s.TotalAmount;
                    decimal remaining = remainingMap.TryGetValue(s.Id, out var rem) ? rem : Math.Max(0, s.TotalAmount - s.PaidAmount);

                    if (isInst && contract != null)
                    {
                        total = contract.TotalWithInterest > 0 ? contract.TotalWithInterest : s.TotalAmount;
                        remaining = contract.RemainingAmount;
                    }

                    int resStatus = s.ReservationStatus;
                    if (s.IsReserved && resStatus == 0)
                    {
                        resStatus = 1; // Default to Reserved (1)
                    }
                    bool isRes = (s.IsReserved || resStatus == 1 || resStatus == 2) && resStatus != 3 && resStatus != 0;

                    return new CloudSaleSyncDto(
                        Id: s.Id,
                        InvoiceNumber: s.InvoiceNumber,
                        CustomerId: s.CustomerId,
                        CustomerName: s.CustomerName,
                        CustomerPhone: !string.IsNullOrWhiteSpace(s.RecipientPhone) ? s.RecipientPhone : (customerDebts?.FirstOrDefault(d => d.CustomerId == s.CustomerId)?.CustomerPhone ?? null),
                        SaleDate: s.SaleDate,
                        SubTotal: s.SubTotal,
                        DiscountAmount: s.DiscountAmount,
                        TaxAmount: s.TaxAmount,
                        TotalAmount: total,
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
                        IsReserved: isRes,
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
                        )).ToList(),
                        ReservationStatus: resStatus
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
                if (localOffers == null) return;

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

                await _cloudHttp.PostAsJsonAsync("api/sync/offers/push", new PushOffersRequest(offersToPush));
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
        private void NotifyDataImported() => OnDataImported?.Invoke();

        public void Dispose()
        {
            StopPeriodicSync();
            _cloudHttp.Dispose();
        }
    }
}
