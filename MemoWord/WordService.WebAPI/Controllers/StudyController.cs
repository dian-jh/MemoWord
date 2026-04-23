using System.Security.Claims;
using System.ComponentModel.DataAnnotations;
using System.Globalization;
using Microsoft.AspNetCore.Mvc;
using WordService.Domain;
using WordService.Domain.Entities;

namespace WordService.WebAPI.Controllers;

[ApiController]
[Route("word/study")]
public class StudyController : ControllerBase
{
    private readonly StudyStatisticsDomainService _studyStatisticsDomainService;
    private readonly WordDomainService _wordDomainService;

    public StudyController(
        StudyStatisticsDomainService studyStatisticsDomainService,
        WordDomainService wordDomainService)
    {
        _studyStatisticsDomainService = studyStatisticsDomainService;
        _wordDomainService = wordDomainService;
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
    public async Task<ActionResult<HttpResult<IReadOnlyList<Word>>>> GetTodayWordQueueAsync([FromQuery][Range(1, int.MaxValue)] int count, CancellationToken cancellationToken)
    {
        var words = await _wordDomainService.GetRandomWordsAsync(count, cancellationToken);
        return Ok(HttpResult<IReadOnlyList<Word>>.Success(words));
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
