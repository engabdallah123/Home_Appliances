using System.Data;

namespace POS.Shared.Application.Database
{
    public interface ISqlConnectionFactory
    {
        IDbConnection CreateConnection();
    }
}
