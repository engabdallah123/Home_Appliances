namespace Returns.Domain.Returns.Entities
{
    public enum RefundMethod
    {
        Cash = 1,
        Card = 2,
        StoreCredit = 3,
        Exchange = 4
    }

    public enum ReturnStatus
    {
        Completed = 1,
        Cancelled = 2
    }
}
