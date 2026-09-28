using FluentValidation;
using Microsoft.Extensions.DependencyInjection;

namespace Dashboard.Application
{
    public static class DependencyInjection
    {
        public static IServiceCollection AddDashboardApplication(this IServiceCollection services)
        {
            services.AddMediatR(configuration =>
            {
                configuration.RegisterServicesFromAssembly(typeof(DependencyInjection).Assembly);
            });

            return services;
        }
    }
}
