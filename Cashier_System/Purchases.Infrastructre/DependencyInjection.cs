using Microsoft.EntityFrameworkCore;
using Microsoft.Extensions.Configuration;
using Microsoft.Extensions.DependencyInjection;
using Purchases.Domain;
using Purchases.Infrastructre.Database;

namespace Purchases.Infrastructre
{
    public static class DependencyInjection
    {
        public static IServiceCollection AddPurchasesInfrastructure(
            this IServiceCollection services, IConfiguration configuration)
        {
            var connectionString = configuration.GetConnectionString("DefaultConnection")
                ?? throw new ArgumentNullException(nameof(configuration));

            services.AddDbContext<PurchasesDbContext>(options =>
            {
                options.UseSqlServer(connectionString);
                options.ConfigureWarnings(w => w.Ignore(Microsoft.EntityFrameworkCore.Diagnostics.RelationalEventId.PendingModelChangesWarning));
            });

            services.AddScoped<IPurchasesUnitOfWork, PurchasesUnitOfWork>();

            return services;
        }
    }
}
