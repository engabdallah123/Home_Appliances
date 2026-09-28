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

        await SeedUnitsAsync(context);
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
