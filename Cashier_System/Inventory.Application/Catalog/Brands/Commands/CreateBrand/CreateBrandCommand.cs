using POS.Shared.Application.Messaging;

namespace Inventory.Application.Catalog.Brands.Commands.CreateBrand
{
    public sealed record CreateBrandCommand(
        string? Name = null,
        string? NameAr = null,
        string? NameEn = null,
        string? Description = null,
        string? OriginCountry = null,
        string? AgentContactNumber = null) : ICommand<Guid>;
}
