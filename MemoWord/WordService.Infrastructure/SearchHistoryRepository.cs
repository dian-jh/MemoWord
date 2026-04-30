using Microsoft.EntityFrameworkCore;
using WordService.Domain;
using WordService.Domain.Entities;
using WordService.Domain.Models;

namespace WordService.Infrastructure;

public class SearchHistoryRepository : ISearchHistoryRepository
{
    private readonly WordDbContext _dbContext;

    public SearchHistoryRepository(WordDbContext dbContext)
    {
        _dbContext = dbContext;
    }

    public async Task AddOrRefreshAsync(Guid userId, int wordId, CancellationToken cancellationToken = default)
    {
        var existingRecords = await _dbContext.SearchHistories
            .Where(x => x.UserId == userId && x.WordId == wordId)
            .ToListAsync(cancellationToken);

        if (existingRecords.Count > 0)
        {
            _dbContext.SearchHistories.RemoveRange(existingRecords);
        }

        await _dbContext.SearchHistories.AddAsync(new SearchHistory(userId, wordId), cancellationToken);
        await _dbContext.SaveChangesAsync(cancellationToken);
    }

    public Task<List<SearchHistoryWordModel>> GetRecentHistoryAsync(Guid userId, int take, CancellationToken cancellationToken = default)
    {
        var query = from history in _dbContext.SearchHistories.AsNoTracking()
                    where history.UserId == userId
                    join word in _dbContext.Words.AsNoTracking()
                        on history.WordId equals word.Id
                    orderby history.CreateTime descending
                    select new SearchHistoryWordModel
                    {
                        Id = word.Id,
                        WordContent = word.WordContent,
                        PhoneticUs = word.PhoneticUs,
                        Translation = word.Translation,
                        CreateTime = history.CreateTime
                    };

        return query.Take(take).ToListAsync(cancellationToken);
    }

    public async Task ClearAsync(Guid userId, CancellationToken cancellationToken = default)
    {
        var records = _dbContext.SearchHistories.Where(x => x.UserId == userId);
        _dbContext.SearchHistories.RemoveRange(records);
        await _dbContext.SaveChangesAsync(cancellationToken);
    }
}
