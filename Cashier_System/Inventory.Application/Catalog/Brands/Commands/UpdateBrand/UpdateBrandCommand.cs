using POS.Shared.Application.Messaging;

namespace Inventory.Application.Catalog.Brands.Commands.UpdateBrand
{
    public sealed record UpdateBrandCommand(
        Guid Id,
        string? Name = null,
        string? NameAr = null,
        string? NameEn = null,
        string? Description = null,
        string? OriginCountry = null,
        string? AgentContactNumber = null,
        bool? IsActive = null) : ICommand;
}
