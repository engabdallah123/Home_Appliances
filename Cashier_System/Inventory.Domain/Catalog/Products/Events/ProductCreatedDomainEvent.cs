using POS.Shared.Domain.Abstractions;
using System;
using System.Collections.Generic;
using System.Text;

namespace Inventory.Domain.Catalog.Products.Events
{
    public sealed record ProductCreatedDomainEvent(Guid ProductId, string Sku) : IDomainEvent;
}
