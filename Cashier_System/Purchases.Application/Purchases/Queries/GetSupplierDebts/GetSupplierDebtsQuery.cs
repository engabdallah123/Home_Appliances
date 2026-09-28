using POS.Shared.Application.Messaging;

namespace Purchases.Application.Purchases.Queries.GetSupplierDebts
{
    public sealed record GetSupplierDebtsQuery(
        string? SearchTerm = null,
        Guid? SupplierId = null) : IQuery<IReadOnlyList<SupplierDebtResponse>>;
}
