using Audit.Infrastructre.Database;
using Expenses.Infrastructre.Database;
using Identity.Infrastructre.Database;
using Inventory.Infrastructre.Database;
using Microsoft.Data.SqlClient;
using Microsoft.EntityFrameworkCore;
using Purchases.Infrastructre.Database;
using Returns.Infrastructre.Database;
using Sales.Infrastructre.Database;
using Settings.Infrastructre.Database;
using Shifts.Infrastructre.Database;

namespace POS.WebAPI.Extensions
{
    public static class DatabaseExtensions
    {
        /// <summary>
        /// Dynamically resolves the best working SQL Server connection string (checking configured server, localhost, SQLEXPRESS, etc.).
        /// </summary>
        public static string ResolveWorkingConnectionString(IConfiguration configuration)
        {
            var configured = configuration.GetConnectionString("DefaultConnection");

            if (!string.IsNullOrWhiteSpace(configured) && CanConnectToSql(configured))
            {
                return configured;
            }

            var fallbackServers = new[] { ".", "localhost", "127.0.0.1", ".\\SQLEXPRESS", "(localdb)\\MSSQLLocalDB" };
            var connBuilder = new SqlConnectionStringBuilder(configured ?? "Database=POS_HomeAppliances;Integrated Security=True;Encrypt=False;TrustServerCertificate=True;MultipleActiveResultSets=True;");

            foreach (var server in fallbackServers)
            {
                connBuilder.DataSource = server;
                connBuilder.ConnectTimeout = 2;
                if (CanConnectToSql(connBuilder.ConnectionString))
                {
                    connBuilder.ConnectTimeout = 30;
                    return connBuilder.ConnectionString;
                }
            }

            return configured ?? "Server=.; Database=POS_HomeAppliances; Integrated Security=True; Encrypt=False; TrustServerCertificate=True; MultipleActiveResultSets=True;";
        }

        public static bool CanConnectToSql(string connectionString)
        {
            try
            {
                var testBuilder = new SqlConnectionStringBuilder(connectionString)
                {
                    InitialCatalog = "master",
                    ConnectTimeout = 2
                };
                using var conn = new SqlConnection(testBuilder.ConnectionString);
                conn.Open();
                return true;
            }
            catch
            {
                return false;
            }
        }

        /// <summary>
        /// Applies EF Core migrations for all 9 modules and applies home appliance store schema extensions.
        /// </summary>
        public static async Task ApplyDatabaseMigrationsAsync(this IServiceProvider services)
        {
            using var scope = services.CreateScope();
            var sp = scope.ServiceProvider;

            var dbContexts = new DbContext[]
            {
                sp.GetRequiredService<IdentityModuleDbContext>(),
                sp.GetRequiredService<ShiftsDbContext>(),
                sp.GetRequiredService<InventoryDbContext>(),
                sp.GetRequiredService<PurchasesDbContext>(),
                sp.GetRequiredService<SalesDbContext>(),
                sp.GetRequiredService<ReturnsDbContext>(),
                sp.GetRequiredService<ExpensesDbContext>(),
                sp.GetRequiredService<SettingsDbContext>(),
                sp.GetRequiredService<AuditDbContext>()
            };

            foreach (var context in dbContexts)
            {
                try
                {
                    await context.Database.MigrateAsync();
                }
                catch (Exception ex)
                {
                    Console.WriteLine($"[Migration Notice] {context.GetType().Name}: {ex.Message}");
                }
            }

            // Self-healing & Schema Extension operations
            await RepairSalesTotalsAsync(sp);
            await EnsureSalePaymentsTableAsync(sp);
            await ApplyApplianceInventoryExtensionsAsync(sp);
            await ApplyApplianceSalesExtensionsAsync(sp);
        }

        /// <summary>
        /// Seeds initial data (Default Admin Users, Roles, Store Settings, Appliance Units).
        /// </summary>
        public static async Task SeedInitialDataAsync(this IServiceProvider services)
        {
            try
            {
                await IdentityDataSeeder.SeedAsync(services);
                await SettingsDataSeeder.SeedAsync(services);
                await AuditDataSeeder.SeedAsync(services);
                await InventoryDataSeeder.SeedAsync(services);
            }
            catch (Exception ex)
            {
                Console.WriteLine($"[Seed Warning] Database seeding delayed: {ex.Message}");
            }
        }

        #region Self-Healing & Appliance Store Schema Setup

        private static async Task RepairSalesTotalsAsync(IServiceProvider sp)
        {
            try
            {
                var salesContext = sp.GetRequiredService<SalesDbContext>();
                const string repairSalesSql = """
                    UPDATE s
                    SET s.SubTotal = ISNULL(items.TotalItemSum, 0),
                        s.TotalAmount = CASE WHEN (ISNULL(items.TotalItemSum, 0) - s.DiscountAmount + s.TaxAmount) < 0 THEN 0 ELSE (ISNULL(items.TotalItemSum, 0) - s.DiscountAmount + s.TaxAmount) END,
                        s.ChangeAmount = CASE WHEN s.PaidAmount > (ISNULL(items.TotalItemSum, 0) - s.DiscountAmount + s.TaxAmount) 
                                              THEN s.PaidAmount - (ISNULL(items.TotalItemSum, 0) - s.DiscountAmount + s.TaxAmount) 
                                              ELSE 0 END
                    FROM [Sales].[Sales] s
                    CROSS APPLY (
                        SELECT SUM(i.Quantity * i.UnitPrice) AS TotalItemSum
                        FROM [Sales].[SaleItems] i
                        WHERE i.SaleId = s.Id
                    ) items
                    WHERE s.TotalAmount = 0 AND items.TotalItemSum > 0;
                    """;
                await salesContext.Database.ExecuteSqlRawAsync(repairSalesSql);
            }
            catch (Exception ex)
            {
                Console.WriteLine($"[Data Repair Notice] Sales repair check: {ex.Message}");
            }
        }

        private static async Task EnsureSalePaymentsTableAsync(IServiceProvider sp)
        {
            try
            {
                var salesContext = sp.GetRequiredService<SalesDbContext>();
                const string ensurePaymentsTableSql = """
                    IF NOT EXISTS (SELECT * FROM sys.tables t JOIN sys.schemas s ON t.schema_id = s.schema_id WHERE t.name = 'SalePayments' AND s.name = 'Sales')
                    BEGIN
                        CREATE TABLE [Sales].[SalePayments] (
                            [Id] uniqueidentifier NOT NULL PRIMARY KEY,
                            [SaleId] uniqueidentifier NOT NULL,
                            [Amount] decimal(18,2) NOT NULL,
                            [PaymentDate] datetime2 NOT NULL,
                            [PaymentMethod] nvarchar(50) NOT NULL,
                            [CashierId] uniqueidentifier NOT NULL,
                            [ShiftId] uniqueidentifier NULL,
                            [Notes] nvarchar(500) NULL,
                            CONSTRAINT [FK_SalePayments_Sales_SaleId] FOREIGN KEY ([SaleId]) REFERENCES [Sales].[Sales] ([Id]) ON DELETE CASCADE
                        );
                        CREATE INDEX [IX_SalePayments_SaleId] ON [Sales].[SalePayments] ([SaleId]);
                        CREATE INDEX [IX_SalePayments_PaymentDate] ON [Sales].[SalePayments] ([PaymentDate]);
                    END

                    -- Backfill initial payments for historical sales that don't have SalePayments yet
                    INSERT INTO [Sales].[SalePayments] (Id, SaleId, Amount, PaymentDate, PaymentMethod, CashierId, ShiftId, Notes)
                    SELECT 
                        NEWID(), s.Id, s.PaidAmount, s.SaleDate, s.PaymentMethod, s.CashierId, s.ShiftId, N'دفعة أولية عند البيع'
                    FROM [Sales].[Sales] s
                    WHERE s.PaidAmount > 0 
                      AND NOT EXISTS (SELECT 1 FROM [Sales].[SalePayments] p WHERE p.SaleId = s.Id);
                    """;
                await salesContext.Database.ExecuteSqlRawAsync(ensurePaymentsTableSql);
            }
            catch (Exception ex)
            {
                Console.WriteLine($"[Data Repair Notice] SalePayments table setup: {ex.Message}");
            }
        }

        private static async Task ApplyApplianceInventoryExtensionsAsync(IServiceProvider sp)
        {
            try
            {
                var inventoryContext = sp.GetRequiredService<InventoryDbContext>();
                const string applianceInventorySql = """
                    -- 1. Ensure Brands table exists
                    IF NOT EXISTS (SELECT * FROM sys.tables t JOIN sys.schemas s ON t.schema_id = s.schema_id WHERE t.name = 'Brands' AND s.name = 'Inventory')
                    BEGIN
                        CREATE TABLE [Inventory].[Brands] (
                            [Id] uniqueidentifier NOT NULL PRIMARY KEY,
                            [Name] nvarchar(150) NOT NULL,
                            [IsActive] bit NOT NULL DEFAULT 1,
                            [CreatedAt] datetime2 NOT NULL DEFAULT GETUTCDATE()
                        );
                        CREATE UNIQUE INDEX [IX_Brands_Name] ON [Inventory].[Brands] ([Name]);
                    END

                    -- 2. Add Appliance columns to Products table
                    IF NOT EXISTS (SELECT 1 FROM sys.columns WHERE object_id = OBJECT_ID('[Inventory].[Products]') AND name = 'BrandId')
                        ALTER TABLE [Inventory].[Products] ADD [BrandId] uniqueidentifier NULL;

                    IF NOT EXISTS (SELECT 1 FROM sys.columns WHERE object_id = OBJECT_ID('[Inventory].[Products]') AND name = 'ModelNumber')
                        ALTER TABLE [Inventory].[Products] ADD [ModelNumber] nvarchar(100) NULL;

                    IF NOT EXISTS (SELECT 1 FROM sys.columns WHERE object_id = OBJECT_ID('[Inventory].[Products]') AND name = 'Color')
                        ALTER TABLE [Inventory].[Products] ADD [Color] nvarchar(50) NULL;

                    IF NOT EXISTS (SELECT 1 FROM sys.columns WHERE object_id = OBJECT_ID('[Inventory].[Products]') AND name = 'WarrantyPeriodMonths')
                        ALTER TABLE [Inventory].[Products] ADD [WarrantyPeriodMonths] int NOT NULL DEFAULT 12;

                    IF NOT EXISTS (SELECT 1 FROM sys.columns WHERE object_id = OBJECT_ID('[Inventory].[Products]') AND name = 'MaintenanceAgent')
                        ALTER TABLE [Inventory].[Products] ADD [MaintenanceAgent] nvarchar(250) NULL;

                    IF NOT EXISTS (SELECT 1 FROM sys.columns WHERE object_id = OBJECT_ID('[Inventory].[Products]') AND name = 'HasSerialNumber')
                        ALTER TABLE [Inventory].[Products] ADD [HasSerialNumber] bit NOT NULL DEFAULT 0;

                    -- 3. Ensure ProductSerials table exists
                    IF NOT EXISTS (SELECT * FROM sys.tables t JOIN sys.schemas s ON t.schema_id = s.schema_id WHERE t.name = 'ProductSerials' AND s.name = 'Inventory')
                    BEGIN
                        CREATE TABLE [Inventory].[ProductSerials] (
                            [Id] uniqueidentifier NOT NULL PRIMARY KEY,
                            [ProductId] uniqueidentifier NOT NULL,
                            [SerialNumber] nvarchar(100) NOT NULL,
                            [Status] int NOT NULL DEFAULT 0,
                            [PurchaseId] uniqueidentifier NULL,
                            [SaleId] uniqueidentifier NULL,
                            [SoldAt] datetime2 NULL,
                            [WarrantyExpiryDate] datetime2 NULL,
                            [Notes] nvarchar(500) NULL,
                            [CreatedAt] datetime2 NOT NULL DEFAULT GETUTCDATE(),
                            [UpdatedAt] datetime2 NULL,
                            CONSTRAINT [FK_ProductSerials_Products] FOREIGN KEY ([ProductId]) REFERENCES [Inventory].[Products] ([Id]) ON DELETE CASCADE
                        );
                        CREATE UNIQUE INDEX [IX_ProductSerials_Product_SN] ON [Inventory].[ProductSerials] ([ProductId], [SerialNumber]);
                        CREATE INDEX [IX_ProductSerials_SerialNumber] ON [Inventory].[ProductSerials] ([SerialNumber]);
                        CREATE INDEX [IX_ProductSerials_Status] ON [Inventory].[ProductSerials] ([Status]);
                    END
                    """;
                await inventoryContext.Database.ExecuteSqlRawAsync(applianceInventorySql);
            }
            catch (Exception ex)
            {
                Console.WriteLine($"[Data Repair Notice] Appliance inventory extensions setup: {ex.Message}");
            }
        }

        private static async Task ApplyApplianceSalesExtensionsAsync(IServiceProvider sp)
        {
            try
            {
                var salesContext = sp.GetRequiredService<SalesDbContext>();
                const string applianceSalesSql = """
                    -- 4. Add Appliance & Delivery & Installment columns to Sales & SaleItems
                    IF NOT EXISTS (SELECT 1 FROM sys.columns WHERE object_id = OBJECT_ID('[Sales].[Sales]') AND name = 'IsDelivery')
                        ALTER TABLE [Sales].[Sales] ADD [IsDelivery] bit NOT NULL DEFAULT 0;

                    IF NOT EXISTS (SELECT 1 FROM sys.columns WHERE object_id = OBJECT_ID('[Sales].[Sales]') AND name = 'DeliveryFee')
                        ALTER TABLE [Sales].[Sales] ADD [DeliveryFee] decimal(18,2) NOT NULL DEFAULT 0;

                    IF NOT EXISTS (SELECT 1 FROM sys.columns WHERE object_id = OBJECT_ID('[Sales].[Sales]') AND name = 'RecipientName')
                        ALTER TABLE [Sales].[Sales] ADD [RecipientName] nvarchar(200) NULL;

                    IF NOT EXISTS (SELECT 1 FROM sys.columns WHERE object_id = OBJECT_ID('[Sales].[Sales]') AND name = 'RecipientPhone')
                        ALTER TABLE [Sales].[Sales] ADD [RecipientPhone] nvarchar(50) NULL;

                    IF NOT EXISTS (SELECT 1 FROM sys.columns WHERE object_id = OBJECT_ID('[Sales].[Sales]') AND name = 'DeliveryAddress')
                        ALTER TABLE [Sales].[Sales] ADD [DeliveryAddress] nvarchar(500) NULL;

                    IF NOT EXISTS (SELECT 1 FROM sys.columns WHERE object_id = OBJECT_ID('[Sales].[Sales]') AND name = 'DeliveryFloor')
                        ALTER TABLE [Sales].[Sales] ADD [DeliveryFloor] nvarchar(100) NULL;

                    IF NOT EXISTS (SELECT 1 FROM sys.columns WHERE object_id = OBJECT_ID('[Sales].[Sales]') AND name = 'DriverName')
                        ALTER TABLE [Sales].[Sales] ADD [DriverName] nvarchar(100) NULL;

                    IF NOT EXISTS (SELECT 1 FROM sys.columns WHERE object_id = OBJECT_ID('[Sales].[Sales]') AND name = 'DeliveryStatus')
                        ALTER TABLE [Sales].[Sales] ADD [DeliveryStatus] int NOT NULL DEFAULT 0;

                    IF NOT EXISTS (SELECT 1 FROM sys.columns WHERE object_id = OBJECT_ID('[Sales].[Sales]') AND name = 'IsReserved')
                        ALTER TABLE [Sales].[Sales] ADD [IsReserved] bit NOT NULL DEFAULT 0;

                    IF NOT EXISTS (SELECT 1 FROM sys.columns WHERE object_id = OBJECT_ID('[Sales].[Sales]') AND name = 'TargetDeliveryDate')
                        ALTER TABLE [Sales].[Sales] ADD [TargetDeliveryDate] datetime2 NULL;

                    IF NOT EXISTS (SELECT 1 FROM sys.columns WHERE object_id = OBJECT_ID('[Sales].[Sales]') AND name = 'ReservationStatus')
                        ALTER TABLE [Sales].[Sales] ADD [ReservationStatus] int NOT NULL DEFAULT 0;

                    IF NOT EXISTS (SELECT 1 FROM sys.columns WHERE object_id = OBJECT_ID('[Sales].[Sales]') AND name = 'IsInstallment')
                        ALTER TABLE [Sales].[Sales] ADD [IsInstallment] bit NOT NULL DEFAULT 0;

                    IF NOT EXISTS (SELECT 1 FROM sys.columns WHERE object_id = OBJECT_ID('[Sales].[Sales]') AND name = 'InstallmentContractId')
                        ALTER TABLE [Sales].[Sales] ADD [InstallmentContractId] uniqueidentifier NULL;

                    IF NOT EXISTS (SELECT 1 FROM sys.columns WHERE object_id = OBJECT_ID('[Sales].[SaleItems]') AND name = 'SerialNumber')
                        ALTER TABLE [Sales].[SaleItems] ADD [SerialNumber] nvarchar(100) NULL;

                    -- 5. Ensure InstallmentContracts & InstallmentSchedules tables exist
                    IF NOT EXISTS (SELECT * FROM sys.tables t JOIN sys.schemas s ON t.schema_id = s.schema_id WHERE t.name = 'InstallmentContracts' AND s.name = 'Sales')
                    BEGIN
                        CREATE TABLE [Sales].[InstallmentContracts] (
                            [Id] uniqueidentifier NOT NULL PRIMARY KEY,
                            [ContractNumber] nvarchar(50) NOT NULL,
                            [SaleId] uniqueidentifier NOT NULL,
                            [CustomerId] uniqueidentifier NOT NULL,
                            [GuarantorName] nvarchar(200) NOT NULL,
                            [GuarantorPhone] nvarchar(50) NOT NULL,
                            [GuarantorNationalId] nvarchar(50) NULL,
                            [GuarantorAddress] nvarchar(500) NULL,
                            [GuarantorNotes] nvarchar(500) NULL,
                            [TotalCashAmount] decimal(18,2) NOT NULL,
                            [DownPayment] decimal(18,2) NOT NULL,
                            [InterestPercentage] decimal(5,2) NOT NULL,
                            [InterestAmount] decimal(18,2) NOT NULL,
                            [TotalInstallmentAmount] decimal(18,2) NOT NULL,
                            [MonthlyInstallmentAmount] decimal(18,2) NOT NULL,
                            [NumberOfMonths] int NOT NULL,
                            [StartDate] datetime2 NOT NULL,
                            [Status] int NOT NULL DEFAULT 1,
                            [Notes] nvarchar(1000) NULL,
                            [CreatedAt] datetime2 NOT NULL DEFAULT GETUTCDATE(),
                            [UpdatedAt] datetime2 NULL
                        );
                        CREATE UNIQUE INDEX [IX_InstallmentContracts_Number] ON [Sales].[InstallmentContracts] ([ContractNumber]);
                        CREATE INDEX [IX_InstallmentContracts_CustomerId] ON [Sales].[InstallmentContracts] ([CustomerId]);
                        CREATE INDEX [IX_InstallmentContracts_SaleId] ON [Sales].[InstallmentContracts] ([SaleId]);
                    END

                    IF NOT EXISTS (SELECT * FROM sys.tables t JOIN sys.schemas s ON t.schema_id = s.schema_id WHERE t.name = 'InstallmentSchedules' AND s.name = 'Sales')
                    BEGIN
                        CREATE TABLE [Sales].[InstallmentSchedules] (
                            [Id] uniqueidentifier NOT NULL PRIMARY KEY,
                            [ContractId] uniqueidentifier NOT NULL,
                            [InstallmentNumber] int NOT NULL,
                            [DueDate] datetime2 NOT NULL,
                            [Amount] decimal(18,2) NOT NULL,
                            [PaidAmount] decimal(18,2) NOT NULL DEFAULT 0,
                            [PaidDate] datetime2 NULL,
                            [Status] int NOT NULL DEFAULT 0,
                            [PaymentMethod] nvarchar(50) NULL,
                            [Notes] nvarchar(500) NULL,
                            CONSTRAINT [FK_InstallmentSchedules_Contract] FOREIGN KEY ([ContractId]) REFERENCES [Sales].[InstallmentContracts] ([Id]) ON DELETE CASCADE
                        );
                        CREATE INDEX [IX_InstallmentSchedules_ContractId] ON [Sales].[InstallmentSchedules] ([ContractId]);
                        CREATE INDEX [IX_InstallmentSchedules_DueDate] ON [Sales].[InstallmentSchedules] ([DueDate]);
                    END

                    -- 6. Ensure Offers & OfferItems tables exist
                    IF NOT EXISTS (SELECT * FROM sys.tables t JOIN sys.schemas s ON t.schema_id = s.schema_id WHERE t.name = 'Offers' AND s.name = 'Sales')
                    BEGIN
                        CREATE TABLE [Sales].[Offers] (
                            [Id] uniqueidentifier NOT NULL PRIMARY KEY,
                            [Title] nvarchar(200) NOT NULL,
                            [Description] nvarchar(1000) NULL,
                            [Type] int NOT NULL,
                            [DiscountPercentage] decimal(5,2) NULL,
                            [FixedDiscountAmount] decimal(18,2) NULL,
                            [BundlePrice] decimal(18,2) NULL,
                            [StartDate] datetime2 NOT NULL,
                            [EndDate] datetime2 NOT NULL,
                            [IsActive] bit NOT NULL DEFAULT 1,
                            [TargetProductId] uniqueidentifier NULL,
                            [TargetCategoryId] uniqueidentifier NULL,
                            [TargetBrandId] uniqueidentifier NULL,
                            [CreatedAt] datetime2 NOT NULL DEFAULT GETUTCDATE(),
                            [UpdatedAt] datetime2 NULL
                        );
                        CREATE INDEX [IX_Offers_IsActive] ON [Sales].[Offers] ([IsActive]);
                        CREATE INDEX [IX_Offers_Type] ON [Sales].[Offers] ([Type]);
                    END

                    IF NOT EXISTS (SELECT * FROM sys.tables t JOIN sys.schemas s ON t.schema_id = s.schema_id WHERE t.name = 'OfferItems' AND s.name = 'Sales')
                    BEGIN
                        CREATE TABLE [Sales].[OfferItems] (
                            [Id] uniqueidentifier NOT NULL PRIMARY KEY,
                            [OfferId] uniqueidentifier NOT NULL,
                            [ProductId] uniqueidentifier NOT NULL,
                            [Quantity] decimal(18,3) NOT NULL DEFAULT 1,
                            CONSTRAINT [FK_OfferItems_Offer] FOREIGN KEY ([OfferId]) REFERENCES [Sales].[Offers] ([Id]) ON DELETE CASCADE
                        );
                        CREATE INDEX [IX_OfferItems_OfferId] ON [Sales].[OfferItems] ([OfferId]);
                    END
                    """;
                await salesContext.Database.ExecuteSqlRawAsync(applianceSalesSql);
            }
            catch (Exception ex)
            {
                Console.WriteLine($"[Data Repair Notice] Appliance sales extensions setup: {ex.Message}");
            }
        }

        #endregion
    }
}
