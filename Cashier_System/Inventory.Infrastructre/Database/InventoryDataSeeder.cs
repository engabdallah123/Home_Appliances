using Inventory.Domain.Catalog.Units;
using Microsoft.EntityFrameworkCore;
using Microsoft.Extensions.DependencyInjection;

namespace Inventory.Infrastructre.Database;

public static class InventoryDataSeeder
{
    public static async Task SeedAsync(IServiceProvider serviceProvider)
    {
        using var scope = serviceProvider.CreateScope();
        var context = scope.ServiceProvider.GetRequiredService<InventoryDbContext>();

        await context.Database.MigrateAsync();

        await EnsureBrandColumnsAsync(context);

        await SeedUnitsAsync(context);
    }

    private static async Task EnsureBrandColumnsAsync(InventoryDbContext context)
    {
        try
        {
            await context.Database.ExecuteSqlRawAsync(@"
                IF NOT EXISTS (SELECT * FROM sys.columns WHERE object_id = OBJECT_ID('[Inventory].[Brands]') AND name = 'NameAr')
                    ALTER TABLE [Inventory].[Brands] ADD [NameAr] NVARCHAR(150) NULL;

                IF NOT EXISTS (SELECT * FROM sys.columns WHERE object_id = OBJECT_ID('[Inventory].[Brands]') AND name = 'NameEn')
                    ALTER TABLE [Inventory].[Brands] ADD [NameEn] NVARCHAR(150) NULL;

                IF NOT EXISTS (SELECT * FROM sys.columns WHERE object_id = OBJECT_ID('[Inventory].[Brands]') AND name = 'Description')
                    ALTER TABLE [Inventory].[Brands] ADD [Description] NVARCHAR(500) NULL;

                IF NOT EXISTS (SELECT * FROM sys.columns WHERE object_id = OBJECT_ID('[Inventory].[Brands]') AND name = 'OriginCountry')
                    ALTER TABLE [Inventory].[Brands] ADD [OriginCountry] NVARCHAR(100) NULL;

                IF NOT EXISTS (SELECT * FROM sys.columns WHERE object_id = OBJECT_ID('[Inventory].[Brands]') AND name = 'AgentContactNumber')
                    ALTER TABLE [Inventory].[Brands] ADD [AgentContactNumber] NVARCHAR(50) NULL;
            ");
        }
        catch (Exception ex)
        {
            Console.WriteLine($"[InventoryDataSeeder] EnsureBrandColumns warning: {ex.Message}");
        }
    }

    private static async Task SeedUnitsAsync(InventoryDbContext context)
    {
        var initialUnits = new (string NameAr, string NameEn, string Symbol)[]
        {
            ("قطعة", "Piece", "قطعة"),
            ("كرتونة", "Carton", "كرتونة"),
            ("طقم", "Set", "طقم"),
            ("دستة", "Dozen", "دستة"),
            ("علبة", "Box", "علبة"),
            ("طرد", "Package", "طرد"),
            ("متر", "Meter", "م"),
            ("رول", "Roll", "رول"),
            ("زوج", "Pair", "زوج")
        };

        var existingNames = await context.Units.Select(u => u.NameAr).ToListAsync();
        var unitsToInsert = new List<Unit>();
        foreach (var (nameAr, nameEn, symbol) in initialUnits)
        {
            if (existingNames.Any(e => string.Equals(e, nameAr, StringComparison.OrdinalIgnoreCase)))
                continue;

            var result = Unit.Create(nameAr, nameEn, symbol);
            if (result.IsSuccess && result.Value is not null)
            {
                unitsToInsert.Add(result.Value);
            }
        }

        if (unitsToInsert.Count > 0)
        {
            await context.Units.AddRangeAsync(unitsToInsert);
            await context.SaveChangesAsync();
        }
    }
}
