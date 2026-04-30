using System;
using System.Collections.Generic;
using System.Text;
using WordService.Domain.Entities;
using WordService.Domain.Models;

namespace WordService.Domain;

public class FavoriteDomainService
{
    private readonly IFavoriteRepository _favoriteRepository;

    public FavoriteDomainService(IFavoriteRepository favoriteRepository)
    {
        _favoriteRepository = favoriteRepository;
    }

    /// <summary>
    /// 获取用户的“全量”收藏单词本
    /// </summary>
    public async Task<List<FavoriteWordModel>> GetUserWordBookAsync(Guid userId, CancellationToken ct = default)
    {
        // 直接调用仓储层的高性能 JOIN 查询，一次性拿回所有字段
        return await _favoriteRepository.GetUserFavoriteModelsAsync(userId, ct);
    }

    /// <summary>
    /// 切换收藏状态（收藏/取消收藏）
    /// </summary>
    /// <returns>返回 true 表示已收藏，false 表示已取消收藏</returns>
    public async Task<bool> ToggleFavoriteAsync(Guid userId, int wordId, CancellationToken ct = default)
    {
        var isFavorite = await _favoriteRepository.IsFavoriteAsync(userId, wordId, ct);

        if (isFavorite)
        {
            await _favoriteRepository.RemoveAsync(userId, wordId, ct);
            return false;
        }
        else
        {
            // 创建新的领域实体
            var favorite = new UserFavorite(userId, wordId);
            await _favoriteRepository.AddAsync(favorite, ct);
            return true;
        }
    }
}