namespace Sales.Application.Customers.Queries
{
    public sealed record CustomerResponse(
        Guid Id,
        string Name,
        string Phone,
        string? Email,
        string? Address,
        int LoyaltyPoints,
        decimal Balance,
        bool IsActive,
        DateTime CreatedAt);
}
