namespace Inventory.Domain.Catalog.Products.Entities
{
    public enum ProductSerialStatus
    {
        InStock = 0,    // في المخزن / متاح للبيع
        Sold = 1,       // تم البيع لعميل
        Returned = 2,   // مرتجع من عميل
        Defective = 3   // تالف / عيب صناعة
    }
}
