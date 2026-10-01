using POS.Shared.Application.Messaging;
using POS.Shared.Domain;
using Sales.Domain;
using Sales.Domain.Promotions.Entities;

namespace Sales.Application.Promotions.Commands.CreateOffer
{
    internal sealed class CreateOfferCommandHandler : ICommandHandler<CreateOfferCommand, Guid>
    {
        private readonly ISalesUnitOfWork _salesUnitOfWork;

        public CreateOfferCommandHandler(ISalesUnitOfWork salesUnitOfWork)
        {
            _salesUnitOfWork = salesUnitOfWork;
        }

        public async Task<Result<Guid>> Handle(CreateOfferCommand request, CancellationToken cancellationToken)
        {
            var title = request.ResolvedTitle;
            var type = request.ResolvedType;

            var offerResult = Offer.Create(
                title,
                request.Description,
                type,
                request.ResolvedDiscountPercentage,
                request.ResolvedFixedDiscountAmount,
                request.ResolvedBundlePrice,
                request.StartDate,
                request.EndDate,
                request.TargetProductId,
                request.TargetCategoryId,
                request.TargetBrandId);

            if (offerResult.IsFailure)
                return Result<Guid>.Failure(offerResult.Error);

            var offer = offerResult.Value!;

            if (type == OfferType.BundlePackage && request.Items != null && request.Items.Any())
            {
                foreach (var itemReq in request.Items)
                {
                    var addItemResult = offer.AddItem(itemReq.ProductId, itemReq.Quantity);
                    if (addItemResult.IsFailure)
                        return Result<Guid>.Failure(addItemResult.Error);
                }
            }

            await _salesUnitOfWork.OfferRepository.AddAsync(offer);
            await _salesUnitOfWork.SaveChangesAsync(cancellationToken);

            return Result<Guid>.Success(offer.Id);
        }
    }
}
