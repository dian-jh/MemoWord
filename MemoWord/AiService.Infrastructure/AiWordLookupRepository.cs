using AiService.Domain;
using AiService.Domain.Models;
using Microsoft.EntityFrameworkCore;

namespace AiService.Infrastructure;

public class AiWordLookupRepository : IAiWordLookupRepository
{
    private readonly AiDbContext _dbContext;

    public AiWordLookupRepository(AiDbContext dbContext)
    {
        _dbContext = dbContext;
    }

    public async Task<IReadOnlyDictionary<string, AiWordLookupItem>> GetByWordsAsync(
        IReadOnlyCollection<string> words,
        CancellationToken cancellationToken = default)
    {
        if (words.Count == 0)
        {
            return new Dictionary<string, AiWordLookupItem>(StringComparer.OrdinalIgnoreCase);
        }

        var normalizedWords = words
            .Where(x => !string.IsNullOrWhiteSpace(x))
            .Select(x => x.Trim().ToLowerInvariant())
            .Distinct()
            .ToList();

        if (normalizedWords.Count == 0)
        {
            return new Dictionary<string, AiWordLookupItem>(StringComparer.OrdinalIgnoreCase);
        }

        var matched = await _dbContext.Words
            .AsNoTracking()
            .Where(x => normalizedWords.Contains(x.WordContent.ToLower()))
            .Select(x => new { x.Id, x.WordContent })
            .ToListAsync(cancellationToken);

        var byLowerWord = matched
            .GroupBy(x => x.WordContent.ToLowerInvariant())
            .ToDictionary(
                g => g.Key,
                g => new AiWordLookupItem
                {
                    Id = g.First().Id,
                    Word = g.First().WordContent
                });

        var result = new Dictionary<string, AiWordLookupItem>(StringComparer.OrdinalIgnoreCase);
        foreach (var originalWord in words)
        {
            var key = originalWord.Trim().ToLowerInvariant();
            if (byLowerWord.TryGetValue(key, out var item))
            {
                result[originalWord] = item;
            }
        }

        return result;
    }
}
