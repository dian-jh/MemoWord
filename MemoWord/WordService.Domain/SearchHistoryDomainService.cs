using WordService.Domain.Models;

namespace WordService.Domain;

public class SearchHistoryDomainService
{
    private readonly ISearchHistoryRepository _searchHistoryRepository;

    public SearchHistoryDomainService(ISearchHistoryRepository searchHistoryRepository)
    {
        _searchHistoryRepository = searchHistoryRepository;
    }

    public async Task AddHistoryAsync(Guid userId, int wordId, CancellationToken cancellationToken = default)
    {
        if (wordId <= 0)
        {
            throw new ArgumentOutOfRangeException(nameof(wordId), "wordId must be greater than 0.");
        }

        await _searchHistoryRepository.AddOrRefreshAsync(userId, wordId, cancellationToken);
    }

    public Task<List<SearchHistoryWordModel>> GetHistoryAsync(Guid userId, int take = 10, CancellationToken cancellationToken = default)
    {
        if (take <= 0)
        {
            return Task.FromResult(new List<SearchHistoryWordModel>());
        }

        return _searchHistoryRepository.GetRecentHistoryAsync(userId, take, cancellationToken);
    }

    public Task ClearHistoryAsync(Guid userId, CancellationToken cancellationToken = default)
    {
        return _searchHistoryRepository.ClearAsync(userId, cancellationToken);
    }
}
