using POS.Shared.Domain;
using POS.Shared.Domain.Abstractions;
using Settings.Domain.StoreSettings.Entities;

namespace Settings.Domain
{
    public interface ISettingsUnitOfWork : IUnitOfWork
    {
        IBaseRepository<StoreSetting> StoreSettingRepository { get; }
    }
}
