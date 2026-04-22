using WordService.Domain.Entities;

namespace WordService.Domain;

public class WordDomainService
{
    private readonly IWordRepository _wordRepository;

    public WordDomainService(IWordRepository wordRepository)
    {
        _wordRepository = wordRepository;
    }

    public async Task<IReadOnlyList<Word>> GetRandomWordsAsync(int count, CancellationToken cancellationToken = default)
    {
        if (count <= 0)
        {
            throw new ArgumentOutOfRangeException(nameof(count), "count must be greater than 0.");
        }

        var totalCount = await _wordRepository.GetTotalCountAsync(cancellationToken);
        if (totalCount <= 0)
        {
            return [];
        }

        var targetCount = Math.Min(count, totalCount);
        var maxId = await _wordRepository.GetMaxIdAsync(cancellationToken);
        if (maxId is null or <= 0)
        {
            return [];
        }

        var wordById = new Dictionary<int, Word>(targetCount);
        var pickedIds = new HashSet<int>();
        var random = Random.Shared;
        var density = Math.Clamp(totalCount / (double)maxId.Value, 0.01d, 1d);

        while (wordById.Count < targetCount && pickedIds.Count < maxId.Value)
        {
            var need = targetCount - wordById.Count;
            var remainingIdSlots = maxId.Value - pickedIds.Count;
            var estimateForNeed = (int)Math.Ceiling(need / density);
            var batchSize = Math.Min(remainingIdSlots, Math.Max(need * 2, estimateForNeed));

            var batchIds = CreateDistinctRandomIds(maxId.Value, batchSize, pickedIds, random);
            if (batchIds.Count == 0)
            {
                break;
            }

            foreach (var id in batchIds)
            {
                pickedIds.Add(id);
            }

            var words = await _wordRepository.GetWordsByIdsAsync(batchIds, cancellationToken);
            foreach (var word in words)
            {
                wordById.TryAdd(word.Id, word);
            }
        }

        var result = wordById.Values.ToList();
        Shuffle(result, random);
        return result.Take(targetCount).ToList();
    }

    private static List<int> CreateDistinctRandomIds(int maxId, int count, HashSet<int> excludedIds, Random random)
    {
        var ids = new HashSet<int>();
        var maxTryCount = count * 10;
        var tryCount = 0;

        while (ids.Count < count && tryCount < maxTryCount && excludedIds.Count + ids.Count < maxId)
        {
            tryCount++;
            var candidate = random.Next(1, maxId + 1);
            if (excludedIds.Contains(candidate))
            {
                continue;
            }

            ids.Add(candidate);
        }

        if (ids.Count < count)
        {
            var start = random.Next(1, maxId + 1);
            for (var i = 0; i < maxId && ids.Count < count; i++)
            {
                var candidate = ((start + i - 1) % maxId) + 1;
                if (excludedIds.Contains(candidate) || ids.Contains(candidate))
                {
                    continue;
                }

                ids.Add(candidate);
            }
        }

        return ids.ToList();
    }

    private static void Shuffle<T>(IList<T> list, Random random)
    {
        for (var i = list.Count - 1; i > 0; i--)
        {
            var j = random.Next(i + 1);
            (list[i], list[j]) = (list[j], list[i]);
        }
    }
}
