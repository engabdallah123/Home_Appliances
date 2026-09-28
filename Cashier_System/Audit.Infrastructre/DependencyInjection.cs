using Audit.Domain;
using Audit.Infrastructre.Database;
using Microsoft.EntityFrameworkCore;
using Microsoft.Extensions.Configuration;
using Microsoft.Extensions.DependencyInjection;

namespace Audit.Infrastructre
{
    public static class DependencyInjection
    {
        public static IServiceCollection AddAuditInfrastructure(
            this IServiceCollection services, IConfiguration configuration)
        {
            var connectionString = configuration.GetConnectionString("DefaultConnection")
                ?? throw new ArgumentNullException(nameof(configuration));

            services.AddDbContext<AuditDbContext>(options =>
                options.UseSqlServer(connectionString));

            services.AddScoped<IAuditUnitOfWork, AuditUnitOfWork>();

            return services;
        }
    }
}
