using Microsoft.EntityFrameworkCore;
using WordService.Domain;
using WordService.Domain.Entities;

namespace WordService.Infrastructure;

public class WordRepository : IWordRepository
{
    private readonly WordDbContext _dbContext;

    public WordRepository(WordDbContext dbContext)
    {
        _dbContext = dbContext;
    }

    public Task<int?> GetMaxIdAsync(CancellationToken cancellationToken = default)
    {
        return _dbContext.Words.MaxAsync(x => (int?)x.Id, cancellationToken);
    }

    public Task<int> GetTotalCountAsync(CancellationToken cancellationToken = default)
    {
        return _dbContext.Words.CountAsync(cancellationToken);
    }

    public Task<List<Word>> GetWordsByIdsAsync(IEnumerable<int> ids, CancellationToken cancellationToken = default)
    {
        var idList = ids.Distinct().ToList();
        return _dbContext.Words
            .Where(x => idList.Contains(x.Id))
            .ToListAsync(cancellationToken);
    }
}
