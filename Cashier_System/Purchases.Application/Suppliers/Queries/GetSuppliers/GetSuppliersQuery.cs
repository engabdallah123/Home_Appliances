using POS.Shared.Application.Messaging;

namespace Purchases.Application.Suppliers.Queries.GetSuppliers
{
    public sealed record GetSuppliersQuery() : IQuery<IReadOnlyList<SupplierResponse>>;
}
