namespace WordService.WebAPI.DTO;

public sealed class SearchHistoryDto
{
    public int Id { get; init; }

    public string WordContent { get; init; } = string.Empty;

    public string? PhoneticUs { get; init; }

    public string? Translation { get; init; }

    public DateTime CreateTime { get; init; }
}
