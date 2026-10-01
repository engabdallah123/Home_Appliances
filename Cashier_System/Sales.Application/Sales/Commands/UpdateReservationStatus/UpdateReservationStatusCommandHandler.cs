using POS.Shared.Application.IService;
using POS.Shared.Application.Messaging;
using POS.Shared.Domain;
using Sales.Domain;
using Sales.Domain.Sales;
using Sales.Domain.Sales.Entities;

namespace Sales.Application.Sales.Commands.UpdateReservationStatus;

internal sealed class UpdateReservationStatusCommandHandler : ICommandHandler<UpdateReservationStatusCommand>
{
    private readonly ISalesUnitOfWork _salesUnitOfWork;
    private readonly ICacheService _cacheService;

    public UpdateReservationStatusCommandHandler(
        ISalesUnitOfWork salesUnitOfWork,
        ICacheService cacheService)
    {
        _salesUnitOfWork = salesUnitOfWork;
        _cacheService = cacheService;
    }

    public async Task<Result> Handle(UpdateReservationStatusCommand request, CancellationToken cancellationToken)
    {
        var sale = await _salesUnitOfWork.SaleRepository.GetByIdAsync(request.SaleId);
        if (sale is null)
            return Result.Failure(SaleErrors.NotFound(request.SaleId));

        sale.UpdateReservationStatus(request.Status);
        _salesUnitOfWork.SaleRepository.Update(sale);
        await _salesUnitOfWork.SaveChangesAsync(cancellationToken);

        await _cacheService.RemoveByPrefixAsync("dashboard_", cancellationToken);

        return Result.Success();
    }
}
