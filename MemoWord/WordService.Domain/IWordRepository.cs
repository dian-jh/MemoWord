using WordService.Domain.Entities;

namespace WordService.Domain;

public interface IWordRepository
{
    Task<int?> GetMaxIdAsync(CancellationToken cancellationToken = default);

    Task<int> GetTotalCountAsync(CancellationToken cancellationToken = default);

    Task<List<Word>> GetWordsByIdsAsync(IEnumerable<int> ids, CancellationToken cancellationToken = default);

    Task<List<Word>> SearchWordsByPrefixAsync(string prefix, int limit, CancellationToken cancellationToken = default);

    Task<Word?> GetWordByIdAsync(int id, CancellationToken cancellationToken = default);

    // 获取所有单词，用于同步到 ES
    Task<List<Word>> GetAllWordsForSyncAsync(CancellationToken cancellationToken = default);
}
