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
            var offerResult = Offer.Create(
                request.Title,
                request.Description,
                request.Type,
                request.DiscountPercentage,
                request.FixedDiscountAmount,
                request.BundlePrice,
                request.StartDate,
                request.EndDate,
                request.TargetProductId,
                request.TargetCategoryId,
                request.TargetBrandId);

            if (offerResult.IsFailure)
                return Result<Guid>.Failure(offerResult.Error);

            var offer = offerResult.Value!;

            if (request.Type == OfferType.BundlePackage && request.Items != null && request.Items.Any())
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
