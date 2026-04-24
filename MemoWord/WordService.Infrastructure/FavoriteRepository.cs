using Microsoft.EntityFrameworkCore;
using System;
using System.Collections.Generic;
using System.Text;
using WordService.Domain;
using WordService.Domain.Entities;
using WordService.Domain.Models;

namespace WordService.Infrastructure;

public class FavoriteRepository : IFavoriteRepository
{
    private readonly WordDbContext _dbContext;

    public FavoriteRepository(WordDbContext dbContext)
    {
        _dbContext = dbContext;
    }

    public async Task AddAsync(UserFavorite favorite, CancellationToken ct = default)
    {
        await _dbContext.UserFavorites.AddAsync(favorite, ct);
        await _dbContext.SaveChangesAsync(ct);
    }

    public async Task RemoveAsync(Guid userId, int wordId, CancellationToken ct = default)
    {
        var entity = await _dbContext.UserFavorites
            .FirstOrDefaultAsync(f => f.UserId == userId && f.WordId == wordId, ct);

        if (entity != null)
        {
            _dbContext.UserFavorites.Remove(entity);
            await _dbContext.SaveChangesAsync(ct);
        }
    }

    public async Task<bool> IsFavoriteAsync(Guid userId, int wordId, CancellationToken ct = default)
    {
        return await _dbContext.UserFavorites
            .AnyAsync(f => f.UserId == userId && f.WordId == wordId, ct);
    }

    public async Task<List<UserFavorite>> GetFavoritesByUserIdAsync(Guid userId, CancellationToken ct = default)
    {
        return await _dbContext.UserFavorites
            .Where(f => f.UserId == userId)
            .ToListAsync(ct);
    }

    // 👇 核心实现：JOIN 查询，一次性带回单词详情和例句
    public async Task<List<FavoriteWordModel>> GetUserFavoriteModelsAsync(Guid userId, CancellationToken ct = default)
    {
        var query = from fav in _dbContext.UserFavorites
                    where fav.UserId == userId
                    join word in _dbContext.Words on fav.WordId equals word.Id
                    select new FavoriteWordModel
                    {
                        WordId = word.Id,
                        WordContent = word.WordContent,
                        PhoneticUs = word.PhoneticUs,
                        Translation = word.Translation,
                        WordExchanges = word.WordExchanges,     // 映射词性变化
                        ExampleSentences = word.ExampleSentences, // 映射例句
                        CreateTime = fav.CreateTime
                    };

        return await query.ToListAsync(ct);
    }


    public async Task<HashSet<int>> GetFavoriteIdsFromListAsync(Guid userId, List<int> wordIds, CancellationToken ct)
    {
        var ids = await _dbContext.UserFavorites
            .Where(f => f.UserId == userId && wordIds.Contains(f.WordId))
            .Select(f => f.WordId)
            .ToListAsync(ct);

        return new HashSet<int>(ids); // 使用 HashSet 保证后续 Contains 操作是 O(1) 复杂度
    }
}
