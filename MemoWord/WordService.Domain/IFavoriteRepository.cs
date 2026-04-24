using System;
using System.Collections.Generic;
using System.Text;
using WordService.Domain.Entities;
using WordService.Domain.Models;

namespace WordService.Domain;

public interface IFavoriteRepository
{
    // 基础操作
    Task AddAsync(UserFavorite favorite, CancellationToken ct = default);
    Task RemoveAsync(Guid userId, int wordId, CancellationToken ct = default);
    Task<bool> IsFavoriteAsync(Guid userId, int wordId, CancellationToken ct = default);

    // 获取实体列表（用于内部逻辑）
    Task<List<UserFavorite>> GetFavoritesByUserIdAsync(Guid userId, CancellationToken ct = default);

    // 👇 关键：获取用于前端展示的投影模型列表（包含单词详情、例句等）
    Task<List<FavoriteWordModel>> GetUserFavoriteModelsAsync(Guid userId, CancellationToken ct = default);

    Task<HashSet<int>> GetFavoriteIdsFromListAsync(Guid userId, List<int> wordIds, CancellationToken ct);
}
