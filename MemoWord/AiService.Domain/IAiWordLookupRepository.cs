using AiService.Domain.Models;

namespace AiService.Domain;

public interface IAiWordLookupRepository
{
    Task<IReadOnlyDictionary<string, AiWordLookupItem>> GetByWordsAsync(
        IReadOnlyCollection<string> words,
        CancellationToken cancellationToken = default);
}
