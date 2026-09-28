using Microsoft.Data.SqlClient;
using POS.Shared.Application.Database;
using System.Data;

namespace POS.Shared.Infrastructure.Database
{
    internal sealed class SqlConnectionFactory : ISqlConnectionFactory
    {
        private readonly string _connectionFactory;

        public SqlConnectionFactory(string connectionFactory)
        {
            _connectionFactory = connectionFactory;
        }

        public IDbConnection CreateConnection()
        {
            //var connection = new NpgsqlConnection(_connectionFactory);
            var connection = new SqlConnection(_connectionFactory);
            connection.Open();

            return connection;
        }
    }
}
