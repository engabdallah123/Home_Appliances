namespace POS.Desktop.Services.Sync
{
    public interface ICloudSyncService : IDisposable
    {
        event Action? OnSyncStateChanged;
        event Action? OnDataImported;

        bool IsSyncing { get; }
        bool IsOffline { get; }
        DateTime? LastSyncTime { get; }
        string? LastSyncStatus { get; }
        bool IsCloudReachable { get; }
        bool? LastSyncSucceeded { get; }

        string CurrentSyncStage { get; }
        int CurrentProgressPercent { get; }
        IReadOnlyList<SyncStageItem> Stages { get; }
        IReadOnlyList<PendingSyncItemView> PendingQueue { get; }

        Task<bool> CheckCloudOnlineAsync();
        Task<SyncStatusResult> SyncNowAsync(bool forceCatalogPush = false);
        Task<bool> PushClosedShiftToCloudAsync(PushClosedShiftRequest shiftReq);
        void RecordLocalChange();
        void NotifyLocalChange() => RecordLocalChange();
        void StartPeriodicSync(TimeSpan? interval = null);
        void StopPeriodicSync();

        void CancelSync();
        void SkipCurrentStage();
        Task<List<PendingSyncItemView>> FetchPendingQueueAsync();
        Task<bool> DismissPendingItemAsync(string entityType, Guid id);
        Task<bool> SyncSinglePendingItemAsync(string entityType, Guid id);

        // Targeted / Incremental delta sync methods
        Task<bool> SyncOffersOnlyAsync();
        Task<bool> SyncBrandsAndCategoriesOnlyAsync();
        Task<bool> SyncDebtsAndInstallmentsOnlyAsync();
        Task<bool> SyncReservationsAndSalesOnlyAsync();
        Task<bool> SyncPurchasesOnlyAsync();
    }
}
