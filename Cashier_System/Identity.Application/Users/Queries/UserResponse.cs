namespace Identity.Application.Users.Queries
{
    public sealed record UserResponse(
        string Id,
        string FullName,
        string UserName,
        string? Email,
        string? Phone,
        bool IsActive,
        DateTime CreatedAt,
        string Role);
}
