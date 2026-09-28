using POS.Shared.Application.Messaging;

namespace Inventory.Application.Catalog.Units.Queries.GetUnits
{
    public sealed record GetUnitsQuery(bool? OnlyActive = true) : IQuery<IReadOnlyList<UnitResponse>>;
}
