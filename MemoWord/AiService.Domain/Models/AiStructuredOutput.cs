namespace AiService.Domain.Models;

public sealed class AiStructuredOutput
{
    public const string JsonSchemaName = "memo_word_ai_structured_output";

    public string Translation { get; init; } = string.Empty;

    public string Analysis { get; init; } = string.Empty;

    public List<string> CoreWords { get; init; } = [];
}
