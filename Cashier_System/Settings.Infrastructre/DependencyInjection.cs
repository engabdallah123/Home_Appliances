using Microsoft.EntityFrameworkCore;
using Microsoft.Extensions.Configuration;
using Microsoft.Extensions.DependencyInjection;
using Settings.Domain;
using Settings.Infrastructre.Database;

namespace Settings.Infrastructre
{
    public static class DependencyInjection
    {
        public static IServiceCollection AddSettingsInfrastructure(
            this IServiceCollection services, IConfiguration configuration)
        {
            var connectionString = configuration.GetConnectionString("DefaultConnection")
                ?? throw new ArgumentNullException(nameof(configuration));

            services.AddDbContext<SettingsDbContext>(options =>
                options.UseSqlServer(connectionString));

            services.AddScoped<ISettingsUnitOfWork, SettingsUnitOfWork>();

            return services;
        }
    }
}
