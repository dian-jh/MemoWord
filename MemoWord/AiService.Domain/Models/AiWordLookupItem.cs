namespace AiService.Domain.Models;

public sealed class AiWordLookupItem
{
    public int Id { get; init; }

    public string Word { get; init; } = string.Empty;
}
