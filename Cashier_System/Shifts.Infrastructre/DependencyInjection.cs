using Microsoft.EntityFrameworkCore;
using Microsoft.Extensions.Configuration;
using Microsoft.Extensions.DependencyInjection;
using Shifts.Domain;
using Shifts.Infrastructre.Database;

namespace Shifts.Infrastructre
{
    public static class DependencyInjection
    {
        public static IServiceCollection AddShiftsInfrastructure(
            this IServiceCollection services, IConfiguration configuration)
        {
            var connectionString = configuration.GetConnectionString("DefaultConnection")
                ?? throw new ArgumentNullException(nameof(configuration));

            services.AddDbContext<ShiftsDbContext>(options =>
                options.UseSqlServer(connectionString));

            services.AddScoped<IShiftsUnitOfWork, ShiftsUnitOfWork>();

            return services;
        }
    }
}
