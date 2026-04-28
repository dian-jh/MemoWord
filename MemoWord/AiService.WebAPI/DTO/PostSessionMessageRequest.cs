using System.ComponentModel.DataAnnotations;

namespace AiService.WebAPI.DTO;

public sealed class PostSessionMessageRequest
{
    [Required]
    [StringLength(4000, MinimumLength = 1)]
    public string Content { get; init; } = string.Empty;
}
