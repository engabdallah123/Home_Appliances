using Expenses.Domain;
using Expenses.Infrastructre.Database;
using Microsoft.EntityFrameworkCore;
using Microsoft.Extensions.Configuration;
using Microsoft.Extensions.DependencyInjection;

namespace Expenses.Infrastructre
{
    public static class DependencyInjection
    {
        public static IServiceCollection AddExpensesInfrastructure(
            this IServiceCollection services, IConfiguration configuration)
        {
            var connectionString = configuration.GetConnectionString("DefaultConnection")
                ?? throw new ArgumentNullException(nameof(configuration));

            services.AddDbContext<ExpensesDbContext>(options =>
                options.UseSqlServer(connectionString));

            services.AddScoped<IExpensesUnitOfWork, ExpensesUnitOfWork>();

            return services;
        }
    }
}
