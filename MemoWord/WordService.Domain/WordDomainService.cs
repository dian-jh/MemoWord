using WordService.Domain.Entities;
using WordService.Domain.Models;

namespace WordService.Domain;

public class WordDomainService
{
    private readonly IWordRepository _wordRepository;
    private readonly IWordSearchRepository _wordSearchRepository;
    private readonly IFavoriteRepository _favoriteRepository;

    public WordDomainService(IWordRepository wordRepository,
        IWordSearchRepository wordSearchRepository,
        IFavoriteRepository favoriteRepository)
    {
        _wordRepository = wordRepository;
        _wordSearchRepository = wordSearchRepository;
        _favoriteRepository = favoriteRepository;
    }

    /// <summary>
    /// 【列表搜索】：走 Elasticsearch (仅包含基础 4 个字段)
    /// </summary>
    public async Task<IReadOnlyList<Word>> SearchWordsAsync(string keyword, int limit = 15, CancellationToken cancellationToken = default)
    {
        if (string.IsNullOrWhiteSpace(keyword)) return Array.Empty<Word>();

        var cleanKeyword = keyword.Trim().ToLowerInvariant();
        return await _wordSearchRepository.SearchWordsAsync(cleanKeyword, limit, cancellationToken);
    }

    /// <summary>
    /// 【单词详情】：走 MySQL，根据 ID 查询包含例句在内的完整 13 个字段
    /// </summary>
    public async Task<Word?> GetWordDetailAsync(int wordId, CancellationToken cancellationToken = default)
    {
        if (wordId <= 0) return null;

        // 直接调用 MySQL 仓储，获取完全体数据
        return await _wordRepository.GetWordByIdAsync(wordId, cancellationToken);
    }

    public async Task<WordWithFavoriteModel?> GetWordDetailWithFavoriteAsync(Guid userId, int wordId, CancellationToken ct)
    {
        // 1. 获取单词信息
        var word = await _wordRepository.GetWordByIdAsync(wordId, ct);
        if (word == null) return null;

        // 2. 检查收藏状态
        var isFavorite = await _favoriteRepository.IsFavoriteAsync(userId, wordId, ct);

        return new WordWithFavoriteModel { Word = word, IsFavorite = isFavorite };
    }

    public async Task<List<WordWithFavoriteModel>> GetTodayWordsWithStatusAsync(Guid userId, int count, CancellationToken ct)
    {
        // 1. 获取随机单词列表（复用你现有的逻辑）
        var words = await GetRandomWordsAsync(count, ct);
        if (!words.Any()) return [];

        // 2. 获取这些单词中，当前用户已收藏的 ID 集合
        var wordIds = words.Select(w => w.Id).ToList();

        var favoriteIds = await _favoriteRepository.GetFavoriteIdsFromListAsync(userId, wordIds, ct);

        // 3. 组装结果
        return words.Select(w => new WordWithFavoriteModel
        {
            Word = w,
            IsFavorite = favoriteIds.Contains(w.Id)
        }).ToList();
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
