namespace Purchases.Application.Suppliers.Queries
{
    public sealed record SupplierResponse(
        Guid Id,
        string Name,
        string Phone,
        string? Email,
        string? Address,
        string? ContactPerson,
        bool IsActive);
}
