using Microsoft.EntityFrameworkCore;
using Microsoft.Extensions.Configuration;
using Microsoft.Extensions.DependencyInjection;
using Returns.Domain;
using Returns.Infrastructre.Database;

namespace Returns.Infrastructre
{
    public static class DependencyInjection
    {
        public static IServiceCollection AddReturnsInfrastructure(
            this IServiceCollection services, IConfiguration configuration)
        {
            var connectionString = configuration.GetConnectionString("DefaultConnection")
                ?? throw new ArgumentNullException(nameof(configuration));

            services.AddDbContext<ReturnsDbContext>(options =>
                options.UseSqlServer(connectionString));

            services.AddScoped<IReturnsUnitOfWork, ReturnsUnitOfWork>();

            return services;
        }
    }
}
