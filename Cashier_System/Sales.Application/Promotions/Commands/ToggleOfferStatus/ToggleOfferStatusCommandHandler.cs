using POS.Shared.Application.Messaging;
using POS.Shared.Domain;
using Sales.Domain;

namespace Sales.Application.Promotions.Commands.ToggleOfferStatus
{
    internal sealed class ToggleOfferStatusCommandHandler : ICommandHandler<ToggleOfferStatusCommand>
    {
        private readonly ISalesUnitOfWork _salesUnitOfWork;

        public ToggleOfferStatusCommandHandler(ISalesUnitOfWork salesUnitOfWork)
        {
            _salesUnitOfWork = salesUnitOfWork;
        }

        public async Task<Result> Handle(ToggleOfferStatusCommand request, CancellationToken cancellationToken)
        {
            var offer = await _salesUnitOfWork.OfferRepository.GetByIdAsync(request.Id);
            if (offer is null)
                return Result.Failure(new Error("Offer.NotFound", "العرض المطلوب غير موجود."));

            if (offer.IsActive)
                offer.Deactivate();
            else
                offer.Activate();

            _salesUnitOfWork.OfferRepository.Update(offer);
            await _salesUnitOfWork.SaveChangesAsync(cancellationToken);

            return Result.Success();
        }
    }
}
