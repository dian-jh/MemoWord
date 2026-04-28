namespace AiService.Domain.Models;

public sealed class AiStructuredOutput
{
    public string Translation { get; init; } = string.Empty;

    public string Analysis { get; init; } = string.Empty;

    public List<string> CoreWords { get; init; } = [];
}
