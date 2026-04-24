namespace WordService.WebAPI.DTO;

public sealed class FavoriteWordDto
{
    // --- 标识与基础信息 ---
    public int WordId { get; init; }
    public string WordContent { get; init; } = string.Empty;
    public string? PhoneticUs { get; init; }
    public string? Translation { get; init; }

    // --- 你新增要求的深度字段 ---
    public string? WordExchanges { get; init; }    // 词性变化 (forms)
    public string? ExampleSentences { get; init; } // 例句 (JSON 或 Text)

    // --- 业务信息 ---
    public DateTime CreateTime { get; init; }
}