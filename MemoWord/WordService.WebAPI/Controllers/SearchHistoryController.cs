using Microsoft.AspNetCore.Mvc;
using System.Security.Claims;
using WordService.Domain;
using WordService.WebAPI.DTO;

namespace WordService.WebAPI.Controllers;

[ApiController]
[Route("word/study")]
public class SearchHistoryController : ControllerBase
{
    private readonly SearchHistoryDomainService _searchHistoryDomainService;

    public SearchHistoryController(SearchHistoryDomainService searchHistoryDomainService)
    {
        _searchHistoryDomainService = searchHistoryDomainService;
    }

    /// <summary>
    /// Add search history item. Keep only the latest record for the same word.
    /// </summary>
    [HttpPost("history")]
    public async Task<ActionResult<HttpResult<bool>>> AddHistoryAsync([FromBody] AddHistoryRequest request, CancellationToken cancellationToken)
    {
        if (!TryGetUserId(out var userId))
        {
            return Unauthorized(HttpResult<bool>.Fail("Unauthorized"));
        }

        await _searchHistoryDomainService.AddHistoryAsync(userId, request.WordId, cancellationToken);
        return Ok(HttpResult<bool>.Success(true));
    }

    /// <summary>
    /// Get latest 10 search history items for current user.
    /// </summary>
    [HttpGet("history")]
    public async Task<ActionResult<HttpResult<List<SearchHistoryDto>>>> GetHistoryAsync(CancellationToken cancellationToken)
    {
        if (!TryGetUserId(out var userId))
        {
            return Unauthorized(HttpResult<List<SearchHistoryDto>>.Fail("Unauthorized"));
        }

        var list = await _searchHistoryDomainService.GetHistoryAsync(userId, 10, cancellationToken);
        var dtoList = list.Select(x => new SearchHistoryDto
        {
            Id = x.Id,
            WordContent = x.WordContent,
            PhoneticUs = x.PhoneticUs,
            Translation = x.Translation,
            CreateTime = x.CreateTime
        }).ToList();

        return Ok(HttpResult<List<SearchHistoryDto>>.Success(dtoList));
    }

    /// <summary>
    /// Clear all search history of current user.
    /// </summary>
    [HttpDelete("history")]
    public async Task<ActionResult<HttpResult<bool>>> ClearHistoryAsync(CancellationToken cancellationToken)
    {
        if (!TryGetUserId(out var userId))
        {
            return Unauthorized(HttpResult<bool>.Fail("Unauthorized"));
        }

        await _searchHistoryDomainService.ClearHistoryAsync(userId, cancellationToken);
        return Ok(HttpResult<bool>.Success(true));
    }

    private bool TryGetUserId(out Guid userId)
    {
        var headerUserId = Request.Headers["X-User-Id"].ToString();

        if (string.IsNullOrEmpty(headerUserId))
        {
            headerUserId = User.FindFirstValue("userId")
                           ?? User.FindFirstValue(ClaimTypes.NameIdentifier);
        }

        if (string.IsNullOrEmpty(headerUserId))
        {
            userId = Guid.Empty;
            return false;
        }

        return Guid.TryParse(headerUserId, out userId);
    }


    public class AddHistoryRequest
    {
        public int WordId { get; set; }
    }
}
