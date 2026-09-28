namespace Purchases.Domain.Purchases.Entities
{
    public enum PurchaseStatus
    {
        Draft = 1,
        Received = 2,
        Cancelled = 3
    }

    public enum PaymentMethod
    {
        Cash = 1,
        Card = 2,
        MobileWallet = 3,
        Credit = 4
    }
}
