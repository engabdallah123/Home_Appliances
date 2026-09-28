using System.Linq.Expressions;

namespace POS.Shared.Domain
{
    public static class OrderBy
    {
        public const string Ascending = "ASC";
        public const string Descending = "DESC";
    }

    public interface IBaseRepository<T> where T : class
    {
        T GetById(Guid id);
        Task<T> GetByIdAsync(Guid id);

        IEnumerable<T> GetAll();
        IEnumerable<T> GetAll(string[] includes = null); // my code

        Task<IEnumerable<T>> GetAllAsync();
        Task<IEnumerable<T>> GetAllAsync(string[] includes = null); // mycode

        // 🟢 الدالة الجديدة (Where)
        // بترجع IQueryable عشان تسمح بتركيب شروط إضافية قبل التنفيذ في الداتابيز
        IQueryable<T> Where(Expression<Func<T, bool>> criteria);

        T Find(Expression<Func<T, bool>> criteria, string[] includes = null);
        Task<T> FindAsync(Expression<Func<T, bool>> criteria, string[] includes = null);

        IEnumerable<T> FindAll(Expression<Func<T, bool>> criteria, string[] includes = null);
        IEnumerable<T> FindAll(Expression<Func<T, bool>> criteria, int take, int skip);
        IEnumerable<T> FindAll(Expression<Func<T, bool>> criteria, int? take, int? skip,
            Expression<Func<T, object>> orderBy = null, string orderByDirection = OrderBy.Ascending);

        Task<IEnumerable<T>> FindAllAsync(Expression<Func<T, bool>> criteria, string[] includes = null);
        Task<IEnumerable<T>> FindAllAsync(Expression<Func<T, bool>> criteria, int skip, int take);
        Task<IEnumerable<T>> FindAllAsync(Expression<Func<T, bool>> criteria, int? skip, int? take,
            Expression<Func<T, object>> orderBy = null, string orderByDirection = OrderBy.Ascending);

        IEnumerable<T> Paginate(int take, int skip);
        Task<IEnumerable<T>> PaginateAsync(int take, int skip);

        T Add(T entity);
        Task<T> AddAsync(T entity);

        IEnumerable<T> AddRange(IEnumerable<T> entities);
        Task<IEnumerable<T>> AddRangeAsync(IEnumerable<T> entities);

        T Update(T entity);

        void Delete(T entity);
        void DeleteRange(IEnumerable<T> entities);

        void Attach(T entity);
        void AttachRange(IEnumerable<T> entities);

        int Count();
        int Count(Expression<Func<T, bool>> criteria);
        Task<int> CountAsync();
        Task<int> CountAsync(Expression<Func<T, bool>> criteria);

        bool Any();
        bool Any(Expression<Func<T, bool>> criteria);
        Task<bool> AnyAsync();
        Task<bool> AnyAsync(Expression<Func<T, bool>> criteria);

        //// Transaction Management

        //// Begin a new transaction
        //Task BeginTransactionAsync();
        //// Commit the current transaction
        //Task CommitTransactionAsync();
        //// Rollback the current transaction
        //Task RollbackTransactionAsync();
    }
}