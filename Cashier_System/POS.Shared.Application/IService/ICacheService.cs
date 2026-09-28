namespace POS.Shared.Application.IService
{
    public interface ICacheService
    {
        Task<T?> GetAsync<T>(string key, CancellationToken ct = default);

        Task SetAsync<T>(
            string key,
            T value,
            TimeSpan? absoluteExpiration = null,
            TimeSpan? slidingExpiration = null,
            CancellationToken ct = default);

        Task<T> GetOrCreateAsync<T>(
            string key,
            Func<Task<T>> factory,
            TimeSpan? absoluteExpiration = null,
            TimeSpan? slidingExpiration = null,
            CancellationToken ct = default);

        Task RemoveAsync(string key, CancellationToken ct = default);

        Task RemoveByPrefixAsync(string prefix, CancellationToken ct = default);
    }
}
