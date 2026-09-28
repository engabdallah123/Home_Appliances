using System.Collections.Concurrent;
using Microsoft.Extensions.Caching.Memory;
using POS.Shared.Application.IService;

namespace POS.Shared.Infrastructure.Services
{
    public class MemoryCacheService : ICacheService
    {
        private readonly IMemoryCache _memoryCache;
        private readonly ConcurrentDictionary<string, byte> _keys = new();

        public MemoryCacheService(IMemoryCache memoryCache)
        {
            _memoryCache = memoryCache;
        }

        public Task<T?> GetAsync<T>(string key, CancellationToken ct = default)
        {
            if (_memoryCache.TryGetValue(key, out T? value))
            {
                return Task.FromResult(value);
            }

            return Task.FromResult(default(T));
        }

        public Task SetAsync<T>(
            string key,
            T value,
            TimeSpan? absoluteExpiration = null,
            TimeSpan? slidingExpiration = null,
            CancellationToken ct = default)
        {
            var options = new MemoryCacheEntryOptions();

            if (absoluteExpiration.HasValue)
                options.SetAbsoluteExpiration(absoluteExpiration.Value);
            else
                options.SetAbsoluteExpiration(TimeSpan.FromMinutes(5));

            if (slidingExpiration.HasValue)
                options.SetSlidingExpiration(slidingExpiration.Value);

            options.RegisterPostEvictionCallback((k, v, r, s) =>
            {
                _keys.TryRemove(k.ToString()!, out _);
            });

            _memoryCache.Set(key, value, options);
            _keys.TryAdd(key, 0);

            return Task.CompletedTask;
        }

        public async Task<T> GetOrCreateAsync<T>(
            string key,
            Func<Task<T>> factory,
            TimeSpan? absoluteExpiration = null,
            TimeSpan? slidingExpiration = null,
            CancellationToken ct = default)
        {
            if (_memoryCache.TryGetValue(key, out T? cachedValue) && cachedValue is not null)
            {
                return cachedValue;
            }

            var result = await factory();

            await SetAsync(key, result, absoluteExpiration, slidingExpiration, ct);

            return result;
        }

        public Task RemoveAsync(string key, CancellationToken ct = default)
        {
            _memoryCache.Remove(key);
            _keys.TryRemove(key, out _);
            return Task.CompletedTask;
        }

        public Task RemoveByPrefixAsync(string prefix, CancellationToken ct = default)
        {
            var keysToRemove = _keys.Keys.Where(k => k.StartsWith(prefix, StringComparison.OrdinalIgnoreCase)).ToList();

            foreach (var key in keysToRemove)
            {
                _memoryCache.Remove(key);
                _keys.TryRemove(key, out _);
            }

            return Task.CompletedTask;
        }
    }
}
