using POS.Shared.Domain.Abstractions;
using System;
using System.Collections.Generic;
using System.Text;

namespace POS.Shared.Domain.Events.Inventory
{
    public sealed record ProductStockChangedIntegrationEvent(
      Guid ProductId,
      string Sku,
      int NewQuantity,
      bool IsLowStock) : IDomainEvent;
}
