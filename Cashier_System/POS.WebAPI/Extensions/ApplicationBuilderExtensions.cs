using Microsoft.Extensions.FileProviders;
using POS.WebAPI.Middlewares;

namespace POS.WebAPI.Extensions
{
    public static class ApplicationBuilderExtensions
    {
        /// <summary>
        /// Configures the HTTP request pipeline and system middlewares.
        /// </summary>
        public static WebApplication UseAppPipeline(this WebApplication app)
        {
            // 1. Swagger OpenAPI UI
            app.UseSwagger();
            app.UseSwaggerUI(c =>
            {
                c.SwaggerEndpoint("/swagger/v1/swagger.json", "POS Cashier System API v1");
                c.RoutePrefix = "swagger";
            });

            // 2. Static files serving (default web root)
            app.UseStaticFiles();

            // 3. Serve uploaded files from writable ProgramData location
            ConfigureUploadsDirectory(app);

            // 4. CORS Policy
            app.UseCors("AllowAll");

            // 5. Global Exception Handling
            app.UseCustomExceptionHandler();

            // 6. Security (Authentication & Authorization)
            app.UseAuthentication();
            app.UseAuthorization();

            // 7. Route Endpoints & Health Checks
            app.MapControllers();
            app.MapHealthChecks("/health");

            return app;
        }

        private static void ConfigureUploadsDirectory(WebApplication app)
        {
            try
            {
                var commonAppData = Environment.GetFolderPath(Environment.SpecialFolder.CommonApplicationData);
                if (!string.IsNullOrWhiteSpace(commonAppData))
                {
                    var uploadsDir = Path.Combine(commonAppData, "POS Cashier System", "uploads");
                    if (!Directory.Exists(uploadsDir))
                    {
                        Directory.CreateDirectory(uploadsDir);
                    }

                    app.UseStaticFiles(new StaticFileOptions
                    {
                        FileProvider = new PhysicalFileProvider(uploadsDir),
                        RequestPath = "/uploads"
                    });
                }
            }
            catch (Exception ex)
            {
                Console.WriteLine($"[StaticFiles Notice] Uploads directory mapping: {ex.Message}");
            }
        }
    }
}
