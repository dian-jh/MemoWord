using Microsoft.AspNetCore.Mvc;
using System.Security.Claims;
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

    private bool TryGetUserId(out Guid userId)
    {
        var headerUserId = Request.Headers["X-User-Id"].ToString();

        // 2. 如果 Header 不存在，可以尝试从当前的 Claims 中获取（如果该服务也配置了身份验证中间件）
        if (string.IsNullOrEmpty(headerUserId))
        {
            headerUserId = User.FindFirstValue("userId")
                           ?? User.FindFirstValue(ClaimTypes.NameIdentifier);
        }

        // 3. 严谨校验：如果拿到的是空值，直接返回 false，不使用伪造 ID
        if (string.IsNullOrEmpty(headerUserId))
        {
            userId = Guid.Empty;
            return false;
        }

        // 4. 类型转换
        return Guid.TryParse(headerUserId, out userId);
    }
}