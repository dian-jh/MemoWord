using WordService.Domain.Models;

namespace WordService.Domain;

public interface ISearchHistoryRepository
{
    Task AddOrRefreshAsync(Guid userId, int wordId, CancellationToken cancellationToken = default);

    Task<List<SearchHistoryWordModel>> GetRecentHistoryAsync(Guid userId, int take, CancellationToken cancellationToken = default);

    Task ClearAsync(Guid userId, CancellationToken cancellationToken = default);
}
