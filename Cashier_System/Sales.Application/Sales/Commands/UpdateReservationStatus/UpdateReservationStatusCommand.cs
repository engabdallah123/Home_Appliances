using POS.Shared.Application.Messaging;
using Sales.Domain.Sales.Entities;

namespace Sales.Application.Sales.Commands.UpdateReservationStatus;

public sealed record UpdateReservationStatusCommand(Guid SaleId, ReservationStatus Status) : ICommand;
