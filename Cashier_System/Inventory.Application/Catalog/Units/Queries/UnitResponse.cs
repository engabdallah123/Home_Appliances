namespace Inventory.Application.Catalog.Units.Queries
{
    public sealed record UnitResponse(
        Guid Id,
        string NameAr,
        string NameEn,
        string Symbol);
}
