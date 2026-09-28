using POS.Shared.Domain;

namespace Inventory.Domain.Batches.ProductBatches
{
    public static class ProductBatchErrors
    {
        public static Error NotFound(Guid id) =>
            new("ProductBatch.NotFound", $"الباتش بالرقم '{id}' غير موجود.");

        public static readonly Error BatchNumberRequired =
            new("ProductBatch.BatchNumberRequired", "رقم الباتش مطلوب.");

        public static readonly Error QuantityCannotBeNegative =
            new("ProductBatch.QuantityCannotBeNegative", "الكمية لا يمكن أن تكون سالبة.");

        public static readonly Error QuantityMustBePositive =
            new("ProductBatch.QuantityMustBePositive", "الكمية يجب أن تكون أكبر من صفر.");

        public static readonly Error InsufficientBatchQuantity =
            new("ProductBatch.InsufficientQuantity", "كمية الباتش غير كافية.");

        public static readonly Error DuplicateBatchNumber =
            Error.Conflict("ProductBatch.DuplicateBatchNumber", "يوجد بالفعل باتش بنفس الرقم لهذا المنتج.");
    }
}
