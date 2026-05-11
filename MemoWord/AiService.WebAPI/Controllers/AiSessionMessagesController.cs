using AiService.Domain;
using AiService.Domain.Entities;
using AiService.WebAPI.Common;
using AiService.WebAPI.DTO;
using AiService.WebAPI.Settings;
using Microsoft.AspNetCore.Mvc;
using Microsoft.EntityFrameworkCore;
using System.Security.Claims;

namespace AiService.WebAPI.Controllers;

[ApiController]
[Route("ai/sessions/{sessionId}/messages")]
public class AiSessionMessagesController : ControllerBase
{
    private readonly AiChatDomainService _aiChatDomainService;
    private readonly AiChatApiOptions _options;

    public AiSessionMessagesController(
        AiChatDomainService aiChatDomainService,
        AiChatApiOptions options)
    {
        _aiChatDomainService = aiChatDomainService;
        _options = options;
    }

    [HttpPost]
    public async Task<ActionResult<HttpResult<SendSessionMessageResponse>>> SendMessageAsync(
        string sessionId,
        [FromBody] PostSessionMessageRequest request,
        CancellationToken cancellationToken)
    {
        if (!TryGetUserId(out var userId))
        {
            return Unauthorized(HttpResult<SendSessionMessageResponse>.Fail("Unauthorized", StatusCodes.Status401Unauthorized));
        }

        try
        {
            var resolvedSessionKey = ResolveSessionKey(sessionId, request.SessionKey);
            var result = await _aiChatDomainService.SendMessageAsync(
                userId,
                resolvedSessionKey,
                request.Content,
                _options.HistoryWindow,
                cancellationToken);

            var response = new SendSessionMessageResponse
            {
                SessionId = result.SessionId,
                Translation = result.Translation,
                Analysis = result.Analysis,
                CoreWords = result.CoreWords
                    .Select(x => new CoreWordItemDto
                    {
                        Word = x.Word,
                        Id = x.Id
                    })
                    .ToList()
            };

            return Ok(HttpResult<SendSessionMessageResponse>.Success(response));
        }
        catch (ArgumentException ex)
        {
            return BadRequest(HttpResult<SendSessionMessageResponse>.Fail(ex.Message, StatusCodes.Status400BadRequest));
        }
        catch (InvalidOperationException ex)
        {
            return StatusCode(StatusCodes.Status502BadGateway, HttpResult<SendSessionMessageResponse>.Fail(ex.Message, StatusCodes.Status502BadGateway));
        }
    }

    [HttpGet]
    public async Task<ActionResult<HttpResult<List<AiChatMessageDto>>>> GetMessagesAsync(
        string sessionId,
        [FromQuery] int take = 100,
        CancellationToken cancellationToken = default)
    {
        if (!TryGetUserId(out var userId))
        {
            return Unauthorized(HttpResult<List<AiChatMessageDto>>.Fail("Unauthorized", StatusCodes.Status401Unauthorized));
        }

        try
        {
            var list = await _aiChatDomainService.GetMessagesAsync(userId, sessionId, take, cancellationToken);
            var dtoList = list.Select(Map).ToList();
            return Ok(HttpResult<List<AiChatMessageDto>>.Success(dtoList));
        }
        catch (ArgumentException ex)
        {
            return BadRequest(HttpResult<List<AiChatMessageDto>>.Fail(ex.Message, StatusCodes.Status400BadRequest));
        }
    }

    private static AiChatMessageDto Map(AiChatMessage message)
    {
        return new AiChatMessageDto
        {
            Id = message.Id,
            Role = message.Role,
            Content = message.Content,
            CreateTime = message.CreateTime
        };
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

    private static string ResolveSessionKey(string routeSessionKey, string? bodySessionKey)
    {
        var routeKey = routeSessionKey?.Trim();
        var bodyKey = bodySessionKey?.Trim();

        if (string.IsNullOrWhiteSpace(bodyKey))
        {
            return routeKey ?? string.Empty;
        }

        if (string.IsNullOrWhiteSpace(routeKey))
        {
            return bodyKey;
        }

        if (!routeKey.Equals(bodyKey, StringComparison.OrdinalIgnoreCase))
        {
            throw new ArgumentException("Route sessionId and body sessionKey do not match.");
        }

        return bodyKey;
    }
}
