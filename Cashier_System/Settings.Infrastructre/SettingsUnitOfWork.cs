using POS.Shared.Domain;
using POS.Shared.Infrastructure.Database;
using Settings.Domain;
using Settings.Domain.StoreSettings.Entities;
using Settings.Infrastructre.Database;

namespace Settings.Infrastructre
{
    public class SettingsUnitOfWork : ISettingsUnitOfWork
    {
        private readonly SettingsDbContext _dbContext;

        public IBaseRepository<StoreSetting> StoreSettingRepository { get; private set; }

        public SettingsUnitOfWork(SettingsDbContext dbContext)
        {
            _dbContext = dbContext;
            StoreSettingRepository = new BaseRepository<StoreSetting>(_dbContext);
        }

        public async Task<int> SaveChangesAsync(CancellationToken cancellationToken = default)
        {
            return await _dbContext.SaveChangesAsync(cancellationToken);
        }
    }
}
