using Inventory.Domain;
using Inventory.Domain.Catalog.Brands;
using POS.Shared.Application.Messaging;
using POS.Shared.Domain;

namespace Inventory.Application.Catalog.Brands.Commands.CreateBrand
{
    internal sealed class CreateBrandCommandHandler : ICommandHandler<CreateBrandCommand, Guid>
    {
        private readonly IInventoryUnitOfWork _unitOfWork;

        public CreateBrandCommandHandler(IInventoryUnitOfWork unitOfWork)
        {
            _unitOfWork = unitOfWork;
        }

        public async Task<Result<Guid>> Handle(CreateBrandCommand request, CancellationToken cancellationToken)
        {
            string effectiveName = !string.IsNullOrWhiteSpace(request.Name)
                ? request.Name.Trim()
                : (!string.IsNullOrWhiteSpace(request.NameAr) && !string.IsNullOrWhiteSpace(request.NameEn))
                    ? $"{request.NameAr.Trim()} ({request.NameEn.Trim()})"
                    : !string.IsNullOrWhiteSpace(request.NameAr)
                        ? request.NameAr.Trim()
                        : request.NameEn?.Trim() ?? "";

            if (string.IsNullOrWhiteSpace(effectiveName))
                return Result<Guid>.Failure(BrandErrors.NameRequired);

            var brandResult = Brand.Create(
                effectiveName,
                request.NameAr,
                request.NameEn,
                request.Description,
                request.OriginCountry,
                request.AgentContactNumber);

            if (brandResult.IsFailure)
                return Result<Guid>.Failure(brandResult.Error);

            var brand = brandResult.Value!;
            await _unitOfWork.BrandRepository.AddAsync(brand);
            await _unitOfWork.SaveChangesAsync(cancellationToken);

            return Result<Guid>.Success(brand.Id);
        }
    }
}
