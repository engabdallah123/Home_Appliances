using Microsoft.EntityFrameworkCore;
using POS.CloudAPI.Entities;
using System.Security.Cryptography;
using System.Text;

namespace POS.CloudAPI.Database
{
    public class CloudDbContext : DbContext
    {
        public CloudDbContext(DbContextOptions<CloudDbContext> options) : base(options)
        {
        }

        public DbSet<Tenant> Tenants => Set<Tenant>();
        public DbSet<CloudUser> Users => Set<CloudUser>();
        public DbSet<CloudSupplier> Suppliers => Set<CloudSupplier>();
        public DbSet<CloudProduct> Products => Set<CloudProduct>();
        public DbSet<CloudCategory> Categories => Set<CloudCategory>();
        public DbSet<CloudBrand> Brands => Set<CloudBrand>();
        public DbSet<CloudPurchase> Purchases => Set<CloudPurchase>();
        public DbSet<CloudPurchaseItem> PurchaseItems => Set<CloudPurchaseItem>();
        public DbSet<CloudDebtItem> DebtItems => Set<CloudDebtItem>();
        public DbSet<CloudDebtPayment> DebtPayments => Set<CloudDebtPayment>();
        public DbSet<CloudExpense> Expenses => Set<CloudExpense>();
        public DbSet<CloudDashboardSnapshot> DashboardSnapshots => Set<CloudDashboardSnapshot>();
        public DbSet<CloudStoreSettings> StoreSettings => Set<CloudStoreSettings>();
        public DbSet<SyncRecord> SyncRecords => Set<SyncRecord>();
        public DbSet<CloudExpiryNotification> ExpiryNotifications => Set<CloudExpiryNotification>();
        public DbSet<CloudShiftSummary> ShiftSummaries => Set<CloudShiftSummary>();
        public DbSet<CloudReturn> Returns => Set<CloudReturn>();
        public DbSet<CloudSale> Sales => Set<CloudSale>();
        public DbSet<CloudSaleItem> SaleItems => Set<CloudSaleItem>();
        public DbSet<CloudOffer> Offers => Set<CloudOffer>();
        public DbSet<CloudOfferItem> OfferItems => Set<CloudOfferItem>();

        protected override void OnModelCreating(ModelBuilder modelBuilder)
        {
            base.OnModelCreating(modelBuilder);

            modelBuilder.Entity<Tenant>(b =>
            {
                b.HasIndex(t => t.Code).IsUnique();
            });

            modelBuilder.Entity<CloudUser>(b =>
            {
                b.HasIndex(u => new { u.TenantId, u.Username }).IsUnique();
            });

            modelBuilder.Entity<CloudSupplier>(b =>
            {
                b.HasIndex(s => new { s.TenantId, s.Name });
            });

            modelBuilder.Entity<CloudCategory>(b =>
            {
                b.HasIndex(c => new { c.TenantId, c.NameAr });
            });

            modelBuilder.Entity<CloudBrand>(b =>
            {
                b.HasIndex(c => new { c.TenantId, c.Name });
            });

            modelBuilder.Entity<CloudProduct>(b =>
            {
                b.HasIndex(p => new { p.TenantId, p.Barcode });
                b.HasIndex(p => new { p.TenantId, p.NameAr });
                b.HasIndex(p => new { p.TenantId, p.SyncStatus });
            });

            modelBuilder.Entity<CloudPurchase>(b =>
            {
                b.HasIndex(p => new { p.TenantId, p.InvoiceNumber });
                b.HasIndex(p => new { p.TenantId, p.SyncStatus });
                b.HasIndex(p => new { p.TenantId, p.CreatedAt });
                b.HasIndex(p => new { p.TenantId, p.SyncStatus, p.CreatedAt });
                b.HasMany(p => p.Items)
                 .WithOne()
                 .HasForeignKey(i => i.PurchaseId)
                 .OnDelete(DeleteBehavior.Cascade);
            });

            modelBuilder.Entity<CloudSale>(b =>
            {
                b.HasIndex(s => new { s.TenantId, s.InvoiceNumber });
                b.HasIndex(s => new { s.TenantId, s.SyncStatus });
                b.HasIndex(s => new { s.TenantId, s.CreatedAt });
                b.HasMany(s => s.Items)
                 .WithOne()
                 .HasForeignKey(i => i.SaleId)
                 .OnDelete(DeleteBehavior.Cascade);
            });

            modelBuilder.Entity<CloudOffer>(b =>
            {
                b.HasIndex(o => o.TenantId);
                b.HasMany(o => o.Items)
                 .WithOne()
                 .HasForeignKey(i => i.OfferId)
                 .OnDelete(DeleteBehavior.Cascade);
            });

            modelBuilder.Entity<CloudDebtItem>(b =>
            {
                b.HasIndex(d => new { d.TenantId, d.Type, d.ReferenceId });
            });

            modelBuilder.Entity<CloudDebtPayment>(b =>
            {
                b.HasIndex(p => new { p.TenantId, p.SyncStatus });
            });

            modelBuilder.Entity<CloudExpense>(b =>
            {
                b.HasIndex(e => new { e.TenantId, e.Date });
            });

            modelBuilder.Entity<CloudDashboardSnapshot>(b =>
            {
                b.HasIndex(s => s.TenantId);
            });

            modelBuilder.Entity<SyncRecord>(b =>
            {
                b.HasIndex(r => new { r.TenantId, r.EntityType, r.EntityId });
            });

            modelBuilder.Entity<CloudExpiryNotification>(b =>
            {
                b.HasIndex(n => new { n.TenantId, n.Status });
                b.HasIndex(n => new { n.TenantId, n.SyncStatus });
            });

            modelBuilder.Entity<CloudShiftSummary>(b =>
            {
                b.HasIndex(s => new { s.TenantId, s.ClosedAt });
                b.HasIndex(s => new { s.TenantId, s.ShiftId });
            });

            modelBuilder.Entity<CloudReturn>(b =>
            {
                b.HasIndex(r => new { r.TenantId, r.Type });
                b.HasIndex(r => new { r.TenantId, r.ReturnDate });
                b.HasIndex(r => new { r.TenantId, r.ReturnNumber });
            });
        }

        public async Task SeedInitialDataAsync()
        {
            if (!await Tenants.AnyAsync())
            {
                var defaultTenant = new Tenant
                {
                    Id = Guid.Parse("11111111-1111-1111-1111-111111111111"),
                    Name = "متجر الأجهزة المنزلية والكهربائية",
                    Code = "SHOP01",
                    SyncApiKey = "KEY-SHOP01-SECURE-SYNC-2026",
                    IsActive = true,
                    CreatedAt = DateTime.UtcNow
                };
                Tenants.Add(defaultTenant);

                // Default Owner User: admin / 123456
                var defaultUser = new CloudUser
                {
                    Id = Guid.Parse("22222222-2222-2222-2222-222222222222"),
                    TenantId = defaultTenant.Id,
                    Username = "admin",
                    PasswordHash = HashPassword("123456"),
                    FullName = "صاحب المتجر",
                    Role = "Owner",
                    Phone = "",
                    IsActive = true,
                    CreatedAt = DateTime.UtcNow
                };
                Users.Add(defaultUser);

                await SaveChangesAsync();
            }

            // Clean up any old sample mock data so client starts with a clean system
            var sampleBarcodes = new[] { "6221001001", "6221001002", "6221001003" };
            var sampleProducts = await Products.Where(p => sampleBarcodes.Contains(p.Barcode)).ToListAsync();
            if (sampleProducts.Any())
            {
                Products.RemoveRange(sampleProducts);
            }

            var sampleSupplierIds = new[]
            {
                Guid.Parse("33333333-3333-3333-3333-333333333331"),
                Guid.Parse("33333333-3333-3333-3333-333333333332"),
                Guid.Parse("33333333-3333-3333-3333-333333333333")
            };
            var sampleSuppliers = await Suppliers.Where(s => sampleSupplierIds.Contains(s.Id)).ToListAsync();
            if (sampleSuppliers.Any())
            {
                Suppliers.RemoveRange(sampleSuppliers);
            }

            await SaveChangesAsync();
        }

        public async Task EnsureSchemaUpToDateAsync()
        {
            try
            {
                var sql = @"
-- Products columns
IF NOT EXISTS (SELECT 1 FROM sys.columns WHERE object_id = OBJECT_ID('Products') AND name = 'CategoryId')
    ALTER TABLE [Products] ADD [CategoryId] UNIQUEIDENTIFIER NULL;

IF NOT EXISTS (SELECT 1 FROM sys.columns WHERE object_id = OBJECT_ID('Products') AND name = 'CategoryName')
    ALTER TABLE [Products] ADD [CategoryName] NVARCHAR(100) NULL;

IF NOT EXISTS (SELECT 1 FROM sys.columns WHERE object_id = OBJECT_ID('Products') AND name = 'IsWeighable')
    ALTER TABLE [Products] ADD [IsWeighable] BIT NOT NULL CONSTRAINT DF_Products_IsWeighable DEFAULT(0);

IF NOT EXISTS (SELECT 1 FROM sys.columns WHERE object_id = OBJECT_ID('Products') AND name = 'ShelfLifeDays')
    ALTER TABLE [Products] ADD [ShelfLifeDays] INT NOT NULL CONSTRAINT DF_Products_ShelfLifeDays DEFAULT(0);

IF NOT EXISTS (SELECT 1 FROM sys.columns WHERE object_id = OBJECT_ID('Products') AND name = 'ExpiryAlertDays')
    ALTER TABLE [Products] ADD [ExpiryAlertDays] INT NOT NULL CONSTRAINT DF_Products_ExpiryAlertDays DEFAULT(3);

IF NOT EXISTS (SELECT 1 FROM sys.columns WHERE object_id = OBJECT_ID('Products') AND name = 'ReorderLevel')
    ALTER TABLE [Products] ADD [ReorderLevel] DECIMAL(18,2) NOT NULL CONSTRAINT DF_Products_ReorderLevel DEFAULT(0);

IF NOT EXISTS (SELECT 1 FROM sys.columns WHERE object_id = OBJECT_ID('Products') AND name = 'SyncStatus')
    ALTER TABLE [Products] ADD [SyncStatus] INT NOT NULL CONSTRAINT DF_Products_SyncStatus DEFAULT(2);

-- Appliance Product columns
IF NOT EXISTS (SELECT 1 FROM sys.columns WHERE object_id = OBJECT_ID('Products') AND name = 'BrandId')
    ALTER TABLE [Products] ADD [BrandId] UNIQUEIDENTIFIER NULL;

IF NOT EXISTS (SELECT 1 FROM sys.columns WHERE object_id = OBJECT_ID('Products') AND name = 'BrandName')
    ALTER TABLE [Products] ADD [BrandName] NVARCHAR(150) NULL;

IF NOT EXISTS (SELECT 1 FROM sys.columns WHERE object_id = OBJECT_ID('Products') AND name = 'ModelNumber')
    ALTER TABLE [Products] ADD [ModelNumber] NVARCHAR(100) NULL;

IF NOT EXISTS (SELECT 1 FROM sys.columns WHERE object_id = OBJECT_ID('Products') AND name = 'Color')
    ALTER TABLE [Products] ADD [Color] NVARCHAR(50) NULL;

IF NOT EXISTS (SELECT 1 FROM sys.columns WHERE object_id = OBJECT_ID('Products') AND name = 'WarrantyPeriodMonths')
    ALTER TABLE [Products] ADD [WarrantyPeriodMonths] INT NOT NULL CONSTRAINT DF_Products_WarrantyPeriodMonths DEFAULT(12);

IF NOT EXISTS (SELECT 1 FROM sys.columns WHERE object_id = OBJECT_ID('Products') AND name = 'MaintenanceAgent')
    ALTER TABLE [Products] ADD [MaintenanceAgent] NVARCHAR(250) NULL;

IF NOT EXISTS (SELECT 1 FROM sys.columns WHERE object_id = OBJECT_ID('Products') AND name = 'HasSerialNumber')
    ALTER TABLE [Products] ADD [HasSerialNumber] BIT NOT NULL CONSTRAINT DF_Products_HasSerialNumber DEFAULT(0);

-- Brands table
IF NOT EXISTS (SELECT 1 FROM sys.tables WHERE name = 'Brands')
BEGIN
    CREATE TABLE [Brands] (
        [Id] UNIQUEIDENTIFIER NOT NULL PRIMARY KEY,
        [TenantId] UNIQUEIDENTIFIER NOT NULL,
        [Name] NVARCHAR(150) NOT NULL,
        [NameAr] NVARCHAR(150) NULL,
        [NameEn] NVARCHAR(150) NULL,
        [Description] NVARCHAR(500) NULL,
        [OriginCountry] NVARCHAR(100) NULL,
        [AgentContactNumber] NVARCHAR(50) NULL,
        [IsActive] BIT NOT NULL CONSTRAINT DF_Brands_IsActive DEFAULT 1,
        [SyncStatus] INT NOT NULL CONSTRAINT DF_Brands_SyncStatus DEFAULT 2,
        [CreatedAt] DATETIME2 NOT NULL CONSTRAINT DF_Brands_CreatedAt DEFAULT GETUTCDATE(),
        [UpdatedAt] DATETIME2 NULL
    );
    CREATE INDEX [IX_Brands_TenantId_Name] ON [Brands] ([TenantId], [Name]);
END

-- Sales and SaleItems tables
IF NOT EXISTS (SELECT 1 FROM sys.tables WHERE name = 'Sales')
BEGIN
    CREATE TABLE [Sales] (
        [Id] UNIQUEIDENTIFIER NOT NULL PRIMARY KEY,
        [TenantId] UNIQUEIDENTIFIER NOT NULL,
        [InvoiceNumber] NVARCHAR(100) NOT NULL,
        [CustomerId] UNIQUEIDENTIFIER NULL,
        [CustomerName] NVARCHAR(150) NULL,
        [CustomerPhone] NVARCHAR(50) NULL,
        [SaleDate] DATETIME2 NOT NULL CONSTRAINT DF_Sales_SaleDate DEFAULT GETUTCDATE(),
        [SubTotal] DECIMAL(18,2) NOT NULL CONSTRAINT DF_Sales_SubTotal DEFAULT 0,
        [DiscountAmount] DECIMAL(18,2) NOT NULL CONSTRAINT DF_Sales_DiscountAmount DEFAULT 0,
        [TaxAmount] DECIMAL(18,2) NOT NULL CONSTRAINT DF_Sales_TaxAmount DEFAULT 0,
        [TotalAmount] DECIMAL(18,2) NOT NULL CONSTRAINT DF_Sales_TotalAmount DEFAULT 0,
        [PaidAmount] DECIMAL(18,2) NOT NULL CONSTRAINT DF_Sales_PaidAmount DEFAULT 0,
        [RemainingAmount] DECIMAL(18,2) NOT NULL CONSTRAINT DF_Sales_RemainingAmount DEFAULT 0,
        [PaymentMethod] NVARCHAR(50) NOT NULL CONSTRAINT DF_Sales_PaymentMethod DEFAULT 'Cash',
        [Notes] NVARCHAR(500) NULL,
        [CreatedByUserId] UNIQUEIDENTIFIER NOT NULL CONSTRAINT DF_Sales_CreatedByUserId DEFAULT '00000000-0000-0000-0000-000000000000',
        [CreatedByName] NVARCHAR(100) NULL,
        [IsDelivery] BIT NOT NULL CONSTRAINT DF_Sales_IsDelivery DEFAULT 0,
        [RecipientName] NVARCHAR(150) NULL,
        [RecipientPhone] NVARCHAR(50) NULL,
        [DeliveryAddress] NVARCHAR(250) NULL,
        [DeliveryFloor] NVARCHAR(50) NULL,
        [DeliveryFee] DECIMAL(18,2) NOT NULL CONSTRAINT DF_Sales_DeliveryFee DEFAULT 0,
        [IsInstallment] BIT NOT NULL CONSTRAINT DF_Sales_IsInstallment DEFAULT 0,
        [GuarantorName] NVARCHAR(150) NULL,
        [GuarantorPhone] NVARCHAR(50) NULL,
        [InterestPercentage] DECIMAL(18,2) NOT NULL CONSTRAINT DF_Sales_InterestPercentage DEFAULT 0,
        [NumberOfMonths] INT NOT NULL CONSTRAINT DF_Sales_NumberOfMonths DEFAULT 12,
        [IsReserved] BIT NOT NULL CONSTRAINT DF_Sales_IsReserved DEFAULT 0,
        [TargetDeliveryDate] DATETIME2 NULL,
        [SyncStatus] INT NOT NULL CONSTRAINT DF_Sales_SyncStatus DEFAULT 1,
        [SyncAttempts] INT NOT NULL CONSTRAINT DF_Sales_SyncAttempts DEFAULT 0,
        [SyncError] NVARCHAR(1000) NULL,
        [SyncedAt] DATETIME2 NULL,
        [CreatedAt] DATETIME2 NOT NULL CONSTRAINT DF_Sales_CreatedAt DEFAULT GETUTCDATE()
    );
    CREATE INDEX [IX_Sales_TenantId_InvoiceNumber] ON [Sales] ([TenantId], [InvoiceNumber]);
    CREATE INDEX [IX_Sales_TenantId_SyncStatus] ON [Sales] ([TenantId], [SyncStatus]);
END

IF NOT EXISTS (SELECT 1 FROM sys.tables WHERE name = 'SaleItems')
BEGIN
    CREATE TABLE [SaleItems] (
        [Id] UNIQUEIDENTIFIER NOT NULL PRIMARY KEY,
        [SaleId] UNIQUEIDENTIFIER NOT NULL FOREIGN KEY REFERENCES [Sales]([Id]) ON DELETE CASCADE,
        [ProductId] UNIQUEIDENTIFIER NOT NULL,
        [ProductName] NVARCHAR(200) NOT NULL,
        [Barcode] NVARCHAR(100) NULL,
        [ModelNumber] NVARCHAR(100) NULL,
        [BrandName] NVARCHAR(100) NULL,
        [SerialNumber] NVARCHAR(100) NULL,
        [WarrantyPeriodMonths] INT NOT NULL CONSTRAINT DF_SaleItems_WarrantyPeriodMonths DEFAULT 12,
        [Quantity] DECIMAL(18,2) NOT NULL CONSTRAINT DF_SaleItems_Quantity DEFAULT 1,
        [UnitPrice] DECIMAL(18,2) NOT NULL CONSTRAINT DF_SaleItems_UnitPrice DEFAULT 0,
        [Discount] DECIMAL(18,2) NOT NULL CONSTRAINT DF_SaleItems_Discount DEFAULT 0,
        [Tax] DECIMAL(18,2) NOT NULL CONSTRAINT DF_SaleItems_Tax DEFAULT 0,
        [Total] DECIMAL(18,2) NOT NULL CONSTRAINT DF_SaleItems_Total DEFAULT 0
    );
END

-- Suppliers columns
IF NOT EXISTS (SELECT 1 FROM sys.columns WHERE object_id = OBJECT_ID('Suppliers') AND name = 'UpdatedAt')
    ALTER TABLE [Suppliers] ADD [UpdatedAt] DATETIME2 NULL;

-- Purchases columns
IF NOT EXISTS (SELECT 1 FROM sys.columns WHERE object_id = OBJECT_ID('Purchases') AND name = 'InternalNumber')
    ALTER TABLE [Purchases] ADD [InternalNumber] NVARCHAR(100) NULL;

-- Categories table
IF NOT EXISTS (SELECT 1 FROM sys.tables WHERE name = 'Categories')
BEGIN
    CREATE TABLE [Categories] (
        [Id] UNIQUEIDENTIFIER NOT NULL PRIMARY KEY,
        [TenantId] UNIQUEIDENTIFIER NOT NULL,
        [NameAr] NVARCHAR(150) NOT NULL,
        [NameEn] NVARCHAR(150) NULL,
        [IsActive] BIT NOT NULL CONSTRAINT DF_Categories_IsActive DEFAULT 1,
        [SyncStatus] INT NOT NULL CONSTRAINT DF_Categories_SyncStatus DEFAULT 2,
        [CreatedAt] DATETIME2 NOT NULL CONSTRAINT DF_Categories_CreatedAt DEFAULT GETUTCDATE(),
        [UpdatedAt] DATETIME2 NULL
    );
    CREATE INDEX [IX_Categories_TenantId_NameAr] ON [Categories] ([TenantId], [NameAr]);
END
IF NOT EXISTS (SELECT 1 FROM sys.columns WHERE object_id = OBJECT_ID('Categories') AND name = 'UpdatedAt')
    ALTER TABLE [Categories] ADD [UpdatedAt] DATETIME2 NULL;

-- DashboardSnapshots table
IF NOT EXISTS (SELECT 1 FROM sys.tables WHERE name = 'DashboardSnapshots')
BEGIN
    CREATE TABLE [DashboardSnapshots] (
        [Id] UNIQUEIDENTIFIER NOT NULL PRIMARY KEY,
        [TenantId] UNIQUEIDENTIFIER NOT NULL,
        [TodaySales] DECIMAL(18,2) NOT NULL CONSTRAINT DF_Dashboard_TodaySales DEFAULT 0,
        [TodayProfit] DECIMAL(18,2) NOT NULL CONSTRAINT DF_Dashboard_TodayProfit DEFAULT 0,
        [TodayPurchases] DECIMAL(18,2) NOT NULL CONSTRAINT DF_Dashboard_TodayPurchases DEFAULT 0,
        [TodayExpenses] DECIMAL(18,2) NOT NULL CONSTRAINT DF_Dashboard_TodayExpenses DEFAULT 0,
        [MonthSales] DECIMAL(18,2) NOT NULL CONSTRAINT DF_Dashboard_MonthSales DEFAULT 0,
        [MonthProfit] DECIMAL(18,2) NOT NULL CONSTRAINT DF_Dashboard_MonthProfit DEFAULT 0,
        [MonthPurchases] DECIMAL(18,2) NOT NULL CONSTRAINT DF_Dashboard_MonthPurchases DEFAULT 0,
        [MonthExpenses] DECIMAL(18,2) NOT NULL CONSTRAINT DF_Dashboard_MonthExpenses DEFAULT 0,
        [CustomerDebtsTotal] DECIMAL(18,2) NOT NULL CONSTRAINT DF_Dashboard_CustomerDebtsTotal DEFAULT 0,
        [SupplierDebtsTotal] DECIMAL(18,2) NOT NULL CONSTRAINT DF_Dashboard_SupplierDebtsTotal DEFAULT 0,
        [LowStockCount] INT NOT NULL CONSTRAINT DF_Dashboard_LowStockCount DEFAULT 0,
        [ExpiryAlertsCount] INT NOT NULL CONSTRAINT DF_Dashboard_ExpiryAlertsCount DEFAULT 0,
        [MonthlySalesJson] NVARCHAR(MAX) NULL,
        [UpdatedAt] DATETIME2 NOT NULL CONSTRAINT DF_Dashboard_UpdatedAt DEFAULT GETUTCDATE()
    );
    CREATE INDEX [IX_DashboardSnapshots_TenantId] ON [DashboardSnapshots] ([TenantId]);
END

-- DebtItems table
IF NOT EXISTS (SELECT 1 FROM sys.tables WHERE name = 'DebtItems')
BEGIN
    CREATE TABLE [DebtItems] (
        [Id] UNIQUEIDENTIFIER NOT NULL PRIMARY KEY,
        [TenantId] UNIQUEIDENTIFIER NOT NULL,
        [Type] NVARCHAR(20) NOT NULL,
        [ReferenceId] UNIQUEIDENTIFIER NOT NULL,
        [InvoiceNumber] NVARCHAR(100) NOT NULL,
        [EntityName] NVARCHAR(150) NOT NULL,
        [Phone] NVARCHAR(50) NULL,
        [TotalAmount] DECIMAL(18,2) NOT NULL CONSTRAINT DF_DebtItems_TotalAmount DEFAULT 0,
        [PaidAmount] DECIMAL(18,2) NOT NULL CONSTRAINT DF_DebtItems_PaidAmount DEFAULT 0,
        [RemainingAmount] DECIMAL(18,2) NOT NULL CONSTRAINT DF_DebtItems_RemainingAmount DEFAULT 0,
        [Date] DATETIME2 NOT NULL CONSTRAINT DF_DebtItems_Date DEFAULT GETUTCDATE(),
        [UpdatedAt] DATETIME2 NOT NULL CONSTRAINT DF_DebtItems_UpdatedAt DEFAULT GETUTCDATE()
    );
    CREATE INDEX [IX_DebtItems_TenantId_Type_ReferenceId] ON [DebtItems] ([TenantId], [Type], [ReferenceId]);
END

-- DebtPayments table
IF NOT EXISTS (SELECT 1 FROM sys.tables WHERE name = 'DebtPayments')
BEGIN
    CREATE TABLE [DebtPayments] (
        [Id] UNIQUEIDENTIFIER NOT NULL PRIMARY KEY,
        [TenantId] UNIQUEIDENTIFIER NOT NULL,
        [DebtType] NVARCHAR(20) NOT NULL,
        [ReferenceId] UNIQUEIDENTIFIER NOT NULL,
        [Amount] DECIMAL(18,2) NOT NULL CONSTRAINT DF_DebtPayments_Amount DEFAULT 0,
        [Notes] NVARCHAR(500) NULL,
        [SyncStatus] INT NOT NULL CONSTRAINT DF_DebtPayments_SyncStatus DEFAULT 1,
        [CreatedAt] DATETIME2 NOT NULL CONSTRAINT DF_DebtPayments_CreatedAt DEFAULT GETUTCDATE()
    );
    CREATE INDEX [IX_DebtPayments_TenantId_SyncStatus] ON [DebtPayments] ([TenantId], [SyncStatus]);
END

-- Expenses table
IF NOT EXISTS (SELECT 1 FROM sys.tables WHERE name = 'Expenses')
BEGIN
    CREATE TABLE [Expenses] (
        [Id] UNIQUEIDENTIFIER NOT NULL PRIMARY KEY,
        [TenantId] UNIQUEIDENTIFIER NOT NULL,
        [Title] NVARCHAR(200) NOT NULL,
        [Amount] DECIMAL(18,2) NOT NULL CONSTRAINT DF_Expenses_Amount DEFAULT 0,
        [Category] NVARCHAR(100) NULL,
        [Date] DATETIME2 NOT NULL CONSTRAINT DF_Expenses_Date DEFAULT GETUTCDATE(),
        [Notes] NVARCHAR(500) NULL,
        [SyncStatus] INT NOT NULL CONSTRAINT DF_Expenses_SyncStatus DEFAULT 2,
        [CreatedAt] DATETIME2 NOT NULL CONSTRAINT DF_Expenses_CreatedAt DEFAULT GETUTCDATE()
    );
    CREATE INDEX [IX_Expenses_TenantId_Date] ON [Expenses] ([TenantId], [Date]);
END

-- Suppliers table enhancements
IF COL_LENGTH('Suppliers', 'Email') IS NULL
    ALTER TABLE [Suppliers] ADD [Email] NVARCHAR(100) NULL;

IF COL_LENGTH('Suppliers', 'ContactPerson') IS NULL
    ALTER TABLE [Suppliers] ADD [ContactPerson] NVARCHAR(100) NULL;

IF COL_LENGTH('Suppliers', 'SyncStatus') IS NULL
    ALTER TABLE [Suppliers] ADD [SyncStatus] INT NOT NULL CONSTRAINT DF_Suppliers_SyncStatus DEFAULT 2;

-- StoreSettings table
IF NOT EXISTS (SELECT 1 FROM sys.tables WHERE name = 'StoreSettings')
BEGIN
    CREATE TABLE [StoreSettings] (
        [Id] UNIQUEIDENTIFIER NOT NULL PRIMARY KEY,
        [TenantId] UNIQUEIDENTIFIER NOT NULL,
        [StoreName] NVARCHAR(200) NOT NULL CONSTRAINT DF_StoreSettings_StoreName DEFAULT N'المتجر الرئيسي',
        [Address] NVARCHAR(500) NULL,
        [Phone] NVARCHAR(50) NULL,
        [TaxRate] DECIMAL(18,2) NOT NULL CONSTRAINT DF_StoreSettings_TaxRate DEFAULT 0,
        [IsTaxIncluded] BIT NOT NULL CONSTRAINT DF_StoreSettings_IsTaxIncluded DEFAULT 0,
        [Currency] NVARCHAR(20) NOT NULL CONSTRAINT DF_StoreSettings_Currency DEFAULT N'ج.م',
        [InvoiceFooterMessage] NVARCHAR(500) NULL,
        [AllowNegativeStock] BIT NOT NULL CONSTRAINT DF_StoreSettings_AllowNegativeStock DEFAULT 0,
        [LogoUrl] NVARCHAR(MAX) NULL,
        [UpdatedAt] DATETIME2 NOT NULL CONSTRAINT DF_StoreSettings_UpdatedAt DEFAULT GETUTCDATE()
    );
    CREATE UNIQUE INDEX [IX_StoreSettings_TenantId] ON [StoreSettings] ([TenantId]);
END

-- DashboardSnapshots columns for waste loss
IF NOT EXISTS (SELECT 1 FROM sys.columns WHERE object_id = OBJECT_ID('DashboardSnapshots') AND name = 'TodayWasteLoss')
    ALTER TABLE [DashboardSnapshots] ADD [TodayWasteLoss] DECIMAL(18,2) NOT NULL CONSTRAINT DF_Dashboard_TodayWasteLoss DEFAULT 0;

IF NOT EXISTS (SELECT 1 FROM sys.columns WHERE object_id = OBJECT_ID('DashboardSnapshots') AND name = 'MonthWasteLoss')
    ALTER TABLE [DashboardSnapshots] ADD [MonthWasteLoss] DECIMAL(18,2) NOT NULL CONSTRAINT DF_Dashboard_MonthWasteLoss DEFAULT 0;

IF NOT EXISTS (SELECT 1 FROM sys.columns WHERE object_id = OBJECT_ID('DashboardSnapshots') AND name = 'TotalWasteLoss')
    ALTER TABLE [DashboardSnapshots] ADD [TotalWasteLoss] DECIMAL(18,2) NOT NULL CONSTRAINT DF_Dashboard_TotalWasteLoss DEFAULT 0;

-- ExpiryNotifications table
IF NOT EXISTS (SELECT 1 FROM sys.tables WHERE name = 'ExpiryNotifications')
BEGIN
    CREATE TABLE [ExpiryNotifications] (
        [Id] UNIQUEIDENTIFIER NOT NULL PRIMARY KEY,
        [TenantId] UNIQUEIDENTIFIER NOT NULL,
        [ProductId] UNIQUEIDENTIFIER NOT NULL,
        [ProductName] NVARCHAR(200) NOT NULL,
        [Barcode] NVARCHAR(100) NULL,
        [BatchId] UNIQUEIDENTIFIER NULL,
        [BatchNumber] NVARCHAR(100) NULL,
        [RemainingQuantity] DECIMAL(18,2) NOT NULL CONSTRAINT DF_ExpiryNotifications_RemainingQuantity DEFAULT 0,
        [Unit] NVARCHAR(50) NOT NULL CONSTRAINT DF_ExpiryNotifications_Unit DEFAULT N'قطعة',
        [UnitCost] DECIMAL(18,2) NOT NULL CONSTRAINT DF_ExpiryNotifications_UnitCost DEFAULT 0,
        [ExpiryDate] DATETIME2 NULL,
        [DaysRemaining] INT NOT NULL CONSTRAINT DF_ExpiryNotifications_DaysRemaining DEFAULT 0,
        [IsExpired] BIT NOT NULL CONSTRAINT DF_ExpiryNotifications_IsExpired DEFAULT 0,
        [Message] NVARCHAR(500) NOT NULL,
        [Status] NVARCHAR(50) NOT NULL CONSTRAINT DF_ExpiryNotifications_Status DEFAULT N'Active',
        [ActionType] NVARCHAR(50) NULL,
        [ActionQuantity] DECIMAL(18,2) NOT NULL CONSTRAINT DF_ExpiryNotifications_ActionQuantity DEFAULT 0,
        [ActionReason] NVARCHAR(200) NULL,
        [NewExpiryDate] DATETIME2 NULL,
        [NewBatchNumber] NVARCHAR(100) NULL,
        [ActionNotes] NVARCHAR(500) NULL,
        [SyncStatus] INT NOT NULL CONSTRAINT DF_ExpiryNotifications_SyncStatus DEFAULT 2,
        [CreatedAt] DATETIME2 NOT NULL CONSTRAINT DF_ExpiryNotifications_CreatedAt DEFAULT GETUTCDATE(),
        [ActionTakenAt] DATETIME2 NULL
    );
    CREATE INDEX [IX_ExpiryNotifications_TenantId_Status] ON [ExpiryNotifications] ([TenantId], [Status]);
    CREATE INDEX [IX_ExpiryNotifications_TenantId_SyncStatus] ON [ExpiryNotifications] ([TenantId], [SyncStatus]);
END

-- ShiftSummaries table
IF NOT EXISTS (SELECT 1 FROM sys.tables WHERE name = 'ShiftSummaries')
BEGIN
    CREATE TABLE [ShiftSummaries] (
        [Id] UNIQUEIDENTIFIER NOT NULL PRIMARY KEY,
        [TenantId] UNIQUEIDENTIFIER NOT NULL,
        [ShiftId] UNIQUEIDENTIFIER NOT NULL,
        [CashierName] NVARCHAR(150) NOT NULL,
        [OpenedAt] DATETIME2 NOT NULL,
        [ClosedAt] DATETIME2 NOT NULL,
        [OpeningCash] DECIMAL(18,2) NOT NULL CONSTRAINT DF_ShiftSummaries_OpeningCash DEFAULT 0,
        [ActualClosingCash] DECIMAL(18,2) NOT NULL CONSTRAINT DF_ShiftSummaries_ActualClosingCash DEFAULT 0,
        [SystemCash] DECIMAL(18,2) NOT NULL CONSTRAINT DF_ShiftSummaries_SystemCash DEFAULT 0,
        [CashDifference] DECIMAL(18,2) NOT NULL CONSTRAINT DF_ShiftSummaries_CashDifference DEFAULT 0,
        [TotalSales] DECIMAL(18,2) NOT NULL CONSTRAINT DF_ShiftSummaries_TotalSales DEFAULT 0,
        [TotalCash] DECIMAL(18,2) NOT NULL CONSTRAINT DF_ShiftSummaries_TotalCash DEFAULT 0,
        [TotalCard] DECIMAL(18,2) NOT NULL CONSTRAINT DF_ShiftSummaries_TotalCard DEFAULT 0,
        [TotalWallet] DECIMAL(18,2) NOT NULL CONSTRAINT DF_ShiftSummaries_TotalWallet DEFAULT 0,
        [TotalCredit] DECIMAL(18,2) NOT NULL CONSTRAINT DF_ShiftSummaries_TotalCredit DEFAULT 0,
        [TotalInvoices] INT NOT NULL CONSTRAINT DF_ShiftSummaries_TotalInvoices DEFAULT 0,
        [TotalReturns] INT NOT NULL CONSTRAINT DF_ShiftSummaries_TotalReturns DEFAULT 0,
        [ClosingNotes] NVARCHAR(500) NULL,
        [IsReadByOwner] BIT NOT NULL CONSTRAINT DF_ShiftSummaries_IsReadByOwner DEFAULT 0,
        [CreatedAt] DATETIME2 NOT NULL CONSTRAINT DF_ShiftSummaries_CreatedAt DEFAULT GETUTCDATE()
    );
    CREATE INDEX [IX_ShiftSummaries_TenantId_ClosedAt] ON [ShiftSummaries] ([TenantId], [ClosedAt]);
    CREATE INDEX [IX_ShiftSummaries_TenantId_ShiftId] ON [ShiftSummaries] ([TenantId], [ShiftId]);
END

-- SyncRecords table
IF NOT EXISTS (SELECT 1 FROM sys.tables WHERE name = 'SyncRecords')
BEGIN
    CREATE TABLE [SyncRecords] (
        [Id] UNIQUEIDENTIFIER NOT NULL PRIMARY KEY,
        [TenantId] UNIQUEIDENTIFIER NOT NULL,
        [EntityType] NVARCHAR(50) NOT NULL,
        [EntityId] UNIQUEIDENTIFIER NOT NULL,
        [Direction] NVARCHAR(50) NOT NULL,
        [Status] NVARCHAR(50) NOT NULL,
        [Timestamp] DATETIME2 NOT NULL CONSTRAINT DF_SyncRecords_Timestamp DEFAULT GETUTCDATE(),
        [Details] NVARCHAR(1000) NULL
    );
    CREATE INDEX [IX_SyncRecords_TenantId_EntityType_EntityId] ON [SyncRecords] ([TenantId], [EntityType], [EntityId]);
END

-- Returns table
IF NOT EXISTS (SELECT 1 FROM sys.tables WHERE name = 'Returns')
BEGIN
    CREATE TABLE [Returns] (
        [Id] UNIQUEIDENTIFIER NOT NULL PRIMARY KEY,
        [TenantId] UNIQUEIDENTIFIER NOT NULL,
        [ReturnNumber] NVARCHAR(100) NOT NULL,
        [Type] NVARCHAR(50) NOT NULL,
        [OriginalInvoiceNumber] NVARCHAR(100) NULL,
        [PartyName] NVARCHAR(200) NULL,
        [PartyPhone] NVARCHAR(50) NULL,
        [ReturnDate] DATETIME2 NOT NULL CONSTRAINT DF_Returns_ReturnDate DEFAULT GETUTCDATE(),
        [TotalAmount] DECIMAL(18,2) NOT NULL CONSTRAINT DF_Returns_TotalAmount DEFAULT 0,
        [RefundMethod] NVARCHAR(50) NOT NULL CONSTRAINT DF_Returns_RefundMethod DEFAULT N'نقداً',
        [Reason] NVARCHAR(250) NULL,
        [Notes] NVARCHAR(500) NULL,
        [ItemsJson] NVARCHAR(MAX) NULL,
        [ItemsCount] INT NOT NULL CONSTRAINT DF_Returns_ItemsCount DEFAULT 1,
        [CreatedAt] DATETIME2 NOT NULL CONSTRAINT DF_Returns_CreatedAt DEFAULT GETUTCDATE()
    );
    CREATE INDEX [IX_Returns_TenantId_Type] ON [Returns] ([TenantId], [Type]);
    CREATE INDEX [IX_Returns_TenantId_ReturnDate] ON [Returns] ([TenantId], [ReturnDate]);
    CREATE INDEX [IX_Returns_TenantId_ReturnNumber] ON [Returns] ([TenantId], [ReturnNumber]);
END

-- Offers table
IF NOT EXISTS (SELECT 1 FROM sys.tables WHERE name = 'Offers')
BEGIN
    CREATE TABLE [Offers] (
        [Id] UNIQUEIDENTIFIER NOT NULL PRIMARY KEY,
        [TenantId] UNIQUEIDENTIFIER NOT NULL,
        [Title] NVARCHAR(200) NOT NULL,
        [Description] NVARCHAR(500) NULL,
        [Type] INT NOT NULL CONSTRAINT DF_Offers_Type DEFAULT 3,
        [OfferType] NVARCHAR(50) NOT NULL CONSTRAINT DF_Offers_OfferType DEFAULT 'BundlePackage',
        [DiscountPercentage] DECIMAL(18,2) NULL,
        [FixedDiscountAmount] DECIMAL(18,2) NULL,
        [BundlePrice] DECIMAL(18,2) NULL,
        [StartDate] DATETIME2 NOT NULL CONSTRAINT DF_Offers_StartDate DEFAULT GETUTCDATE(),
        [EndDate] DATETIME2 NOT NULL CONSTRAINT DF_Offers_EndDate DEFAULT GETUTCDATE(),
        [IsActive] BIT NOT NULL CONSTRAINT DF_Offers_IsActive DEFAULT 1,
        [TargetProductId] UNIQUEIDENTIFIER NULL,
        [TargetProductName] NVARCHAR(200) NULL,
        [TargetCategoryId] UNIQUEIDENTIFIER NULL,
        [TargetCategoryName] NVARCHAR(150) NULL,
        [TargetBrandId] UNIQUEIDENTIFIER NULL,
        [TargetBrandName] NVARCHAR(150) NULL,
        [SyncStatus] INT NOT NULL CONSTRAINT DF_Offers_SyncStatus DEFAULT 2,
        [CreatedAt] DATETIME2 NOT NULL CONSTRAINT DF_Offers_CreatedAt DEFAULT GETUTCDATE(),
        [UpdatedAt] DATETIME2 NULL
    );
    CREATE INDEX [IX_Offers_TenantId] ON [Offers] ([TenantId]);
END

-- OfferItems table
IF NOT EXISTS (SELECT 1 FROM sys.tables WHERE name = 'OfferItems')
BEGIN
    CREATE TABLE [OfferItems] (
        [Id] UNIQUEIDENTIFIER NOT NULL PRIMARY KEY,
        [OfferId] UNIQUEIDENTIFIER NOT NULL FOREIGN KEY REFERENCES [Offers]([Id]) ON DELETE CASCADE,
        [ProductId] UNIQUEIDENTIFIER NOT NULL,
        [ProductName] NVARCHAR(200) NOT NULL,
        [ProductBarcode] NVARCHAR(100) NULL,
        [Quantity] DECIMAL(18,2) NOT NULL CONSTRAINT DF_OfferItems_Quantity DEFAULT 1,
        [OriginalUnitPrice] DECIMAL(18,2) NOT NULL CONSTRAINT DF_OfferItems_OriginalUnitPrice DEFAULT 0
    );
END

-- Ensure ReservationStatus column in Sales
IF NOT EXISTS (SELECT 1 FROM sys.columns WHERE object_id = OBJECT_ID('Sales') AND name = 'ReservationStatus')
BEGIN
    ALTER TABLE [Sales] ADD [ReservationStatus] INT NOT NULL CONSTRAINT DF_Sales_ReservationStatus DEFAULT 0;
END

-- Ensure columns in DashboardSnapshots for separated debts
IF NOT EXISTS (SELECT 1 FROM sys.columns WHERE object_id = OBJECT_ID('DashboardSnapshots') AND name = 'CustomerCreditDebtsTotal')
BEGIN
    ALTER TABLE [DashboardSnapshots] ADD [CustomerCreditDebtsTotal] DECIMAL(18,2) NOT NULL CONSTRAINT DF_DashboardSnapshots_CustomerCreditDebtsTotal DEFAULT 0;
    ALTER TABLE [DashboardSnapshots] ADD [InstallmentDebtsTotal] DECIMAL(18,2) NOT NULL CONSTRAINT DF_DashboardSnapshots_InstallmentDebtsTotal DEFAULT 0;
    ALTER TABLE [DashboardSnapshots] ADD [CustomerCreditDebtsCount] INT NOT NULL CONSTRAINT DF_DashboardSnapshots_CustomerCreditDebtsCount DEFAULT 0;
    ALTER TABLE [DashboardSnapshots] ADD [InstallmentContractsCount] INT NOT NULL CONSTRAINT DF_DashboardSnapshots_InstallmentContractsCount DEFAULT 0;
END
";
                await Database.ExecuteSqlRawAsync(sql);
            }
            catch (Exception ex)
            {
                Console.WriteLine($"[Schema Upgrade Notice] {ex.Message}");
            }
        }

        public static string HashPassword(string password)
        {
            using var sha256 = SHA256.Create();
            var bytes = sha256.ComputeHash(Encoding.UTF8.GetBytes(password));
            return Convert.ToBase64String(bytes);
        }

        public static bool VerifyPassword(string password, string storedHash)
        {
            return HashPassword(password) == storedHash;
        }
    }
}
