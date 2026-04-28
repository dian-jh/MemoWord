namespace AiService.WebAPI.DTO;

public sealed class SendSessionMessageResponse
{
    public string SessionId { get; init; } = string.Empty;

    public string Translation { get; init; } = string.Empty;

    public string Analysis { get; init; } = string.Empty;

    public List<CoreWordItemDto> CoreWords { get; init; } = [];
}
