using FluentValidation;
using Microsoft.Extensions.DependencyInjection;

namespace Settings.Application
{
    public static class DependencyInjection
    {
        public static IServiceCollection AddSettingsApplication(this IServiceCollection services)
        {
            services.AddMediatR(configuration =>
            {
                configuration.RegisterServicesFromAssembly(typeof(DependencyInjection).Assembly);
            });

            services.AddValidatorsFromAssembly(
                typeof(DependencyInjection).Assembly,
                includeInternalTypes: true);

            return services;
        }
    }
}
