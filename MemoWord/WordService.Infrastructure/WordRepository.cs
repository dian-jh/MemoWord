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

    public async Task<Word?> GetWordByIdAsync(int id, CancellationToken cancellationToken = default)
    {
        return await _dbContext.Words
            .AsNoTracking()
            .FirstOrDefaultAsync(w => w.Id == id, cancellationToken);
    }

    public Task<List<Word>> GetWordsByIdsAsync(IEnumerable<int> ids, CancellationToken cancellationToken = default)
    {
        var idList = ids.Distinct().ToList();
        return _dbContext.Words
            .Where(x => idList.Contains(x.Id))
            .ToListAsync(cancellationToken);
    }

    public async Task<List<Word>> SearchWordsByPrefixAsync(string prefix, int limit, CancellationToken cancellationToken = default)
    {
        // 核心：使用 .StartsWith()，这会在数据库层面翻译为 LIKE 'abc%'，从而利用索引加速查询
        return await _dbContext.Words
            .AsNoTracking() // 搜索不需要实体跟踪，极大提升性能
            .Where(w => w.WordContent.StartsWith(prefix))
            .OrderBy(w => w.WordContent) // 按字母顺序排序
            .Take(limit) // 必须限制条数，防止撑爆内存
            .ToListAsync(cancellationToken);
    }

    public async Task<List<Word>> GetAllWordsForSyncAsync(CancellationToken cancellationToken = default)
    {
        return await _dbContext.Words
            .AsNoTracking() // 仅仅是读取出来同步，绝不需要跟踪，这样查得飞快！
            .ToListAsync(cancellationToken);
    }
}
