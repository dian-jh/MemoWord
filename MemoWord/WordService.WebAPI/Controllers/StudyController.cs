using Elastic.Clients.Elasticsearch;
using Microsoft.AspNetCore.Mvc;
using System.ComponentModel.DataAnnotations;
using System.Globalization;
using System.Security.Claims;
using WordService.Domain;
using WordService.Domain.Entities;
using WordService.Domain.Models;
using WordService.Infrastructure;

namespace WordService.WebAPI.Controllers;

[ApiController]
[Route("word/study")]
public class StudyController : ControllerBase
{
    private readonly StudyStatisticsDomainService _studyStatisticsDomainService;
    private readonly WordDomainService _wordDomainService;
    private readonly IWordRepository _wordRepository;
    private readonly ElasticsearchClient _elasticClient;

    public StudyController(
        StudyStatisticsDomainService studyStatisticsDomainService,
        WordDomainService wordDomainService,
        IWordRepository wordRepository,
        ElasticsearchClient elasticsearchClient
        )
    {
        _studyStatisticsDomainService = studyStatisticsDomainService;
        _wordDomainService = wordDomainService;
        _wordRepository = wordRepository;
        _elasticClient = elasticsearchClient;
    }

    [HttpGet("target/today")]
    public async Task<ActionResult<HttpResult<int>>> GetTodayTargetAsync(CancellationToken cancellationToken)
    {
        if (!TryGetUserId(out var userId))
        {
            return Unauthorized(HttpResult<int>.Fail("Unauthorized"));
        }

        var target = await _studyStatisticsDomainService.GetTodayTargetAsync(userId, cancellationToken);
        return Ok(HttpResult<int>.Success(target));
    }

    [HttpPost("target/today")]
    public async Task<ActionResult<HttpResult<bool>>> SetTodayTargetAsync([FromBody] SetTodayTargetRequest request, CancellationToken cancellationToken)
    {
        if (!TryGetUserId(out var userId))
        {
            return Unauthorized(HttpResult<bool>.Fail("Unauthorized"));
        }

        await _studyStatisticsDomainService.SetTodayTargetAsync(userId, request.TargetCount, cancellationToken);
        return Ok(HttpResult<bool>.Success(true));
    }

    [HttpGet("learned/today")]
    public async Task<ActionResult<HttpResult<int>>> GetTodayLearnedCountAsync(CancellationToken cancellationToken)
    {
        if (!TryGetUserId(out var userId))
        {
            return Unauthorized(HttpResult<int>.Fail("Unauthorized"));
        }

        var learnedCount = await _studyStatisticsDomainService.GetTodayLearnedCountAsync(userId, cancellationToken);
        return Ok(HttpResult<int>.Success(learnedCount));
    }

    [HttpPost("learned/today")]
    public async Task<ActionResult<HttpResult<bool>>> SetTodayLearnedCountAsync([FromBody] SetTodayLearnedCountRequest request, CancellationToken cancellationToken)
    {
        if (!TryGetUserId(out var userId))
        {
            return Unauthorized(HttpResult<bool>.Fail("Unauthorized"));
        }

        await _studyStatisticsDomainService.SetTodayLearnedCountAsync(userId, request.LearnedCount, cancellationToken);
        return Ok(HttpResult<bool>.Success(true));
    }

    [HttpGet("duration/today")]
    public async Task<ActionResult<HttpResult<int>>> GetTodayStudyDurationAsync(CancellationToken cancellationToken)
    {
        if (!TryGetUserId(out var userId))
        {
            return Unauthorized(HttpResult<int>.Fail("Unauthorized"));
        }

        var duration = await _studyStatisticsDomainService.GetTodayStudyDurationAsync(userId, cancellationToken);
        return Ok(HttpResult<int>.Success(duration));
    }

    [HttpPost("duration/today")]
    public async Task<ActionResult<HttpResult<bool>>> SetTodayStudyDurationAsync([FromBody] SetTodayStudyDurationRequest request, CancellationToken cancellationToken)
    {
        if (!TryGetUserId(out var userId))
        {
            return Unauthorized(HttpResult<bool>.Fail("Unauthorized"));
        }

        await _studyStatisticsDomainService.SetTodayStudyDurationAsync(userId, request.Duration, cancellationToken);
        return Ok(HttpResult<bool>.Success(true));
    }

    [HttpGet("learned/history")]
    public async Task<ActionResult<HttpResult<IReadOnlyList<DailyStudyRecordDto>>>> GetLearnedHistoryAsync(CancellationToken cancellationToken)
    {
        
        if (!TryGetUserId(out var userId))
        {
            return Unauthorized(HttpResult<IReadOnlyList<DailyStudyRecordDto>>.Fail("Unauthorized"));
        }

        var records = await _studyStatisticsDomainService.GetLearnedHistoryAsync(userId, cancellationToken);
        var history = records
            .Select(x => new DailyStudyRecordDto
            {
                Date = x.StatDate.ToString("yyyy-MM-dd", CultureInfo.InvariantCulture),
                LearnedCount = x.LearnedCount,
                TargetCount = x.TargetCount,
                StudyDuration = x.StudyDuration
            })
            .ToList();

        return Ok(HttpResult<IReadOnlyList<DailyStudyRecordDto>>.Success(history));
    }

    [HttpGet("today/words")]
    public async Task<ActionResult<HttpResult<List<WordWithFavoriteModel>>>> GetTodayWordQueueAsync(int count, CancellationToken ct)
    {
        if (!TryGetUserId(out var userId)) return Unauthorized();

        var results = await _wordDomainService.GetTodayWordsWithStatusAsync(userId, count, ct);
        return Ok(HttpResult<List<WordWithFavoriteModel>>.Success(results));
    }

    [HttpGet("search")]
    public async Task<ActionResult<HttpResult<IReadOnlyList<SearchWordResultDto>>>> SearchWordsAsync([FromQuery] string keyword, CancellationToken cancellationToken)
    {
        // 调用 DomainService 进行搜索，限制最大返回 10 条
        var words = await _wordDomainService.SearchWordsAsync(keyword, 10, cancellationToken);

        // 映射为轻量级 DTO 返回给前端
        var resultList = words.Select(w => new SearchWordResultDto
        {
            Id = w.Id,
            WordContent = w.WordContent,
            PhoneticUs = w.PhoneticUs,
            Translation = w.Translation
        }).ToList();

        return Ok(HttpResult<IReadOnlyList<SearchWordResultDto>>.Success(resultList));
    }

    [HttpGet("detail/{wordId}")]
    public async Task<ActionResult<HttpResult<WordWithFavoriteModel>>> GetWordDetailAsync(int wordId, CancellationToken ct)
    {
        if (!TryGetUserId(out var userId)) return Unauthorized();

        var result = await _wordDomainService.GetWordDetailWithFavoriteAsync(userId, wordId, ct);

        if (result == null) return NotFound(HttpResult<WordWithFavoriteModel>.Fail("单词不存在"));

        return Ok(HttpResult<WordWithFavoriteModel>.Success(result));
    }

    [HttpPost("admin/sync-to-es")]
    public async Task<IActionResult> SyncAllWordsToElasticsearch(CancellationToken cancellationToken)
    {
        var allWords = await _wordRepository.GetAllWordsForSyncAsync(cancellationToken);
        if (!allWords.Any()) return Ok("MySQL 中没有单词可以同步。");

        // 极度轻量的 DTO 映射
        var esDocuments = allWords.Select(w => new WordElasticDocument
        {
            WordId = w.Id,
            WordContent = w.WordContent,
            PhoneticUs = w.PhoneticUs,
            Translation = w.Translation
        }).ToList();

        int batchSize = 5000;
        int successCount = 0;

        for (int i = 0; i < esDocuments.Count; i += batchSize)
        {
            var batch = esDocuments.Skip(i).Take(batchSize).ToList();
            var response = await _elasticClient.IndexManyAsync(batch, "words", cancellationToken);

            if (response.IsValidResponse)
            {
                successCount += batch.Count;
            }
            else
            {
                Console.WriteLine($"[ES Sync 错误] {response.DebugInformation}");
                return StatusCode(500, "同步失败，请查看控制台日志。");
            }
        }

        return Ok(HttpResult<bool>.Success(true, $"极简模式同步完成！共 {successCount} 个单词。"));
    }

    private bool TryGetUserId(out Guid userId)
    {
        // 1. 尝试从真实的 JWT Token 中获取
        var rawUserId =
            User.FindFirstValue("userId")
            ?? User.FindFirstValue(ClaimTypes.NameIdentifier)
            ?? User.FindFirstValue("sub");

        // 2. 【核心 Mock 逻辑】：如果拿不到（说明没带 Token），且当前是开发环境，就给一个固定测试 ID
        if (string.IsNullOrEmpty(rawUserId) /* && 可以加上判断当前是否为 Development 环境的逻辑 */)
        {
            // 伪造一个固定的 Guid 作为当前测试用户
            rawUserId = "11111111-2222-3333-4444-555555555555";
            Console.WriteLine($"[Mock Auth] 使用了伪造的 UserId: {rawUserId}");
        }

        return Guid.TryParse(rawUserId, out userId);
    }

}

public sealed class SetTodayTargetRequest
{
    [Range(1, int.MaxValue)]
    public int TargetCount { get; init; }
}

public sealed class SetTodayLearnedCountRequest
{
    [Range(0, int.MaxValue)]
    public int LearnedCount { get; init; }
}

public sealed class SetTodayStudyDurationRequest
{
    [Range(0, int.MaxValue)]
    public int Duration { get; init; }
}

public sealed class DailyStudyRecordDto
{
    public string Date { get; init; } = string.Empty;

    public int LearnedCount { get; init; }

    public int TargetCount { get; init; }

    public int StudyDuration { get; init; }
}

public sealed class SearchWordResultDto
{
    public int Id { get; init; }
    public string WordContent { get; init; } = string.Empty;
    public string? PhoneticUs { get; init; }
    public string? Translation { get; init; }
}

public sealed class HttpResult<T>
{
    public int Code { get; init; }

    public string Message { get; init; } = string.Empty;

    public T Data { get; init; } = default!;

    public static HttpResult<T> Success(T data, string message = "success")
    {
        return new HttpResult<T>
        {
            Code = StatusCodes.Status200OK,
            Message = message,
            Data = data
        };
    }

    public static HttpResult<T> Fail(string message, int code = StatusCodes.Status401Unauthorized)
    {
        return new HttpResult<T>
        {
            Code = code,
            Message = message,
            Data = default!
        };
    }
}
