using WordService.Domain.Entities;

namespace WordService.Domain;

public interface IWordRepository
{
    Task<int?> GetMaxIdAsync(CancellationToken cancellationToken = default);

    Task<int> GetTotalCountAsync(CancellationToken cancellationToken = default);

    Task<List<Word>> GetWordsByIdsAsync(IEnumerable<int> ids, CancellationToken cancellationToken = default);
}
