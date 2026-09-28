using POS.Shared.Application.Messaging;
using POS.Shared.Domain;
using Sales.Domain;

namespace Sales.Application.Promotions.Commands.DeleteOffer
{
    internal sealed class DeleteOfferCommandHandler : ICommandHandler<DeleteOfferCommand>
    {
        private readonly ISalesUnitOfWork _salesUnitOfWork;

        public DeleteOfferCommandHandler(ISalesUnitOfWork salesUnitOfWork)
        {
            _salesUnitOfWork = salesUnitOfWork;
        }

        public async Task<Result> Handle(DeleteOfferCommand request, CancellationToken cancellationToken)
        {
            var offer = await _salesUnitOfWork.OfferRepository.GetByIdAsync(request.Id);
            if (offer is null)
                return Result.Failure(new Error("Offer.NotFound", "العرض المطلوب غير موجود."));

            _salesUnitOfWork.OfferRepository.Delete(offer);
            await _salesUnitOfWork.SaveChangesAsync(cancellationToken);

            return Result.Success();
        }
    }
}
