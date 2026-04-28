using System.Security.Claims;
using AiService.Domain;
using AiService.Domain.Entities;
using AiService.WebAPI.Common;
using AiService.WebAPI.DTO;
using AiService.WebAPI.Settings;
using Microsoft.AspNetCore.Mvc;

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
            var result = await _aiChatDomainService.SendMessageAsync(
                userId,
                sessionId,
                request.Content,
                _options.HistoryWindow,
                _options.SystemPrompt,
                cancellationToken);

            var response = new SendSessionMessageResponse
            {
                SessionId = result.SessionId,
                UserMessage = Map(result.UserMessage),
                AssistantMessage = Map(result.AssistantMessage)
            };

            return Ok(HttpResult<SendSessionMessageResponse>.Success(response));
        }
        catch (ArgumentException ex)
        {
            return BadRequest(HttpResult<SendSessionMessageResponse>.Fail(ex.Message, StatusCodes.Status400BadRequest));
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
}
