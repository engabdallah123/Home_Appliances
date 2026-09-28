using Microsoft.Data.SqlClient;
using POS.WebAPI.Extensions;
using QuestPDF.Infrastructure;

namespace POS.WebAPI
{
    public class Program
    {
        public static async Task Main(string[] args)
        {
            // Set QuestPDF License to Community
            QuestPDF.Settings.License = LicenseType.Community;

            var builder = WebApplication.CreateBuilder(args);

            // Configure URLs explicitly for production service & desktop app
            builder.WebHost.UseUrls("http://*:5000");

            // Configure as Windows Service
            builder.Host.UseWindowsService(options =>
            {
                options.ServiceName = "POSWebAPI";
            });

            // Dynamically resolve working SQL Server instance (SQLEXPRESS / MSSQLSERVER / LocalDB)
            var resolvedConnectionString = DatabaseExtensions.ResolveWorkingConnectionString(builder.Configuration);
            builder.Configuration["ConnectionStrings:DefaultConnection"] = resolvedConnectionString;
            Console.WriteLine($"[Database] Using connection string with DataSource: {new SqlConnectionStringBuilder(resolvedConnectionString).DataSource}");

            // 1. Register Domain Modules (Inventory, Sales, Purchases, Settings, etc.)
            builder.Services.AddAppModules(builder.Configuration);

            // 2. Register Infrastructure & Hosted Services (Backups, CloudSync, HealthChecks, Kestrel limits)
            builder.Services.AddAppInfrastructure(builder.Configuration, builder.WebHost);

            // 3. Register Swagger Documentation & CORS
            builder.Services.AddAppDocumentationAndCors();

            var app = builder.Build();

            // 4. Auto-Apply Database Migrations and Appliance Store Schema Extensions
            await app.Services.ApplyDatabaseMigrationsAsync();

            // 5. Seed Initial System Data (Units, Categories, Brands, Settings, Roles, Users)
            await app.Services.SeedInitialDataAsync();

            // 6. Configure HTTP Pipeline & Middlewares (Swagger, StaticFiles, Auth, ExceptionHandler, Endpoints)
            app.UseAppPipeline();

            app.Run();
        }
    }
}
