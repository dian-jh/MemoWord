using Microsoft.AspNetCore.Mvc;
using WordService.Domain;
using WordService.Domain.Models;
using WordService.WebAPI.DTO;

namespace WordService.WebAPI.Controllers;

[ApiController]
[Route("word/favorite")]
public class FavoriteController : ControllerBase
{
    private readonly FavoriteDomainService _favoriteService;

    public FavoriteController(FavoriteDomainService favoriteService)
    {
        _favoriteService = favoriteService;
    }

    /// <summary>
    /// 收藏或取消收藏单词
    /// </summary>
    [HttpPost("toggle/{wordId}")]
    public async Task<ActionResult<HttpResult<bool>>> ToggleAsync(int wordId, CancellationToken ct)
    {
        // 1. 权限校验
        if (!TryGetUserId(out var userId)) return Unauthorized();

        // 2. 调用服务层执行切换逻辑
        var isFavorite = await _favoriteService.ToggleFavoriteAsync(userId, wordId, ct);

        // 3. 返回最新状态
        return Ok(HttpResult<bool>.Success(isFavorite, isFavorite ? "收藏成功" : "已取消收藏"));
    }

    /// <summary>
    /// 获取用户收藏的所有单词（包含例句、变换等全量信息）
    /// </summary>
    [HttpGet("list")]
    public async Task<ActionResult<HttpResult<List<FavoriteWordModel>>>> GetListAsync(CancellationToken ct)
    {
        // 1. 权限校验
        if (!TryGetUserId(out var userId)) return Unauthorized();

        // 2. 直接获取高性能 JOIN 查询后的结果
        var list = await _favoriteService.GetUserWordBookAsync(userId, ct);

        // 3. 返回给前端，前端将负责后续的排序
        return Ok(HttpResult<List<FavoriteWordModel>>.Success(list));
    }

    // --- 内部辅助方法 ---
    private bool TryGetUserId(out Guid userId)
    {
        // 这里是你之前实现的解析 Token 获取 UserId 的逻辑
        // 建议从 HttpContext.Items 或 Claims 中读取
        var userIdStr = User.FindFirst("UserId")?.Value;
        return Guid.TryParse(userIdStr, out userId);
    }
}