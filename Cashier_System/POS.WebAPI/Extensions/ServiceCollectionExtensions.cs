using Audit.Application;
using Audit.Infrastructre;
using Dashboard.Application;
using Expenses.Application;
using Expenses.Infrastructre;
using Identity.Application;
using Identity.Infrastructre;
using Inventory.Application;
using Inventory.Infrastructre;
using Inventory.Infrastructre.Database;
using Microsoft.AspNetCore.Http.Features;
using Microsoft.AspNetCore.Server.Kestrel.Core;
using POS.Shared.Application;
using POS.Shared.Infrastructure;
using POS.WebAPI.Services;
using Purchases.Application;
using Purchases.Infrastructre;
using Returns.Application;
using Returns.Infrastructre;
using Sales.Application;
using Sales.Infrastructre;
using Settings.Application;
using Settings.Infrastructre;
using Shifts.Application;
using Shifts.Infrastructre;

namespace POS.WebAPI.Extensions
{
    public static class ServiceCollectionExtensions
    {
        /// <summary>
        /// Registers Application and Infrastructure services for all system domain modules.
        /// </summary>
        public static IServiceCollection AddAppModules(this IServiceCollection services, IConfiguration configuration)
        {
            // 1. Shared Services
            services.AddSharedApplication();
            services.AddSharedInfrastructure(configuration);

            // 2. Identity & Shifts
            services.AddIdentityApplication();
            services.AddIdentityInfrastructure(configuration);
            services.AddShiftsApplication();
            services.AddShiftsInfrastructure(configuration);

            // 3. Core Store Operations (Inventory, Purchases, Sales, Returns, Expenses)
            services.AddInventoryApplication();
            services.AddInventoryInfrastructure(configuration);

            services.AddPurchasesApplication();
            services.AddPurchasesInfrastructure(configuration);

            services.AddSalesApplication();
            services.AddSalesInfrastructure(configuration);

            services.AddReturnsApplication();
            services.AddReturnsInfrastructure(configuration);

            services.AddExpensesApplication();
            services.AddExpensesInfrastructure(configuration);

            // 4. Analytics, Settings & Audit
            services.AddDashboardApplication();

            services.AddSettingsApplication();
            services.AddSettingsInfrastructure(configuration);

            services.AddAuditApplication();
            services.AddAuditInfrastructure(configuration);

            return services;
        }

        /// <summary>
        /// Registers background hosted services, health checks, backup engines, and file upload limits.
        /// </summary>
        public static IServiceCollection AddAppInfrastructure(
            this IServiceCollection services,
            IConfiguration configuration,
            ConfigureWebHostBuilder webHost)
        {
            // Health Checks (checks SQL connectivity via DbContext)
            services.AddHealthChecks()
                .AddDbContextCheck<InventoryDbContext>("Database", tags: new[] { "db", "ready" });

            // Backup Service & 12-Hour Automatic Database Backup Service
            services.AddScoped<IBackupService, BackupService>();
            services.AddHostedService<AutoBackupBackgroundService>();

            // Cloud Synchronization Engine (Syncs Suppliers, Purchases, Stock, Settings, Dashboard with Cloud API)
            services.AddHostedService<CloudSyncBackgroundService>();

            services.AddHttpContextAccessor();
            services.AddControllers();

            // Support large file uploads and long-running bulk imports
            services.Configure<FormOptions>(options =>
            {
                options.MultipartBodyLengthLimit = 524_288_000; // 500 MB
                options.ValueLengthLimit = int.MaxValue;
                options.MultipartHeadersLengthLimit = int.MaxValue;
            });

            webHost.ConfigureKestrel(serverOptions =>
            {
                serverOptions.Limits.MaxRequestBodySize = 524_288_000; // 500 MB
                serverOptions.Limits.KeepAliveTimeout = TimeSpan.FromMinutes(20);
                serverOptions.Limits.RequestHeadersTimeout = TimeSpan.FromMinutes(20);
            });

            return services;
        }

        /// <summary>
        /// Configures Swagger OpenAPI docs and CORS policies.
        /// </summary>
        public static IServiceCollection AddAppDocumentationAndCors(this IServiceCollection services)
        {
            services.AddEndpointsApiExplorer();
            services.AddSwaggerGen();

            services.AddCors(options =>
            {
                options.AddPolicy("AllowAll", builder =>
                {
                    builder.AllowAnyOrigin()
                           .AllowAnyMethod()
                           .AllowAnyHeader();
                });
            });

            return services;
        }
    }
}
