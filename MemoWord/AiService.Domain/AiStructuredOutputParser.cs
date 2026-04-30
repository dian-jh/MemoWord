using System.Text.Json;
using AiService.Domain.Models;

namespace AiService.Domain;

public static class AiStructuredOutputParser
{
    private static readonly JsonSerializerOptions SerializerOptions = new(JsonSerializerDefaults.Web)
    {
        PropertyNameCaseInsensitive = true
    };

    public static AiStructuredOutput Parse(string rawContent)
    {
        if (string.IsNullOrWhiteSpace(rawContent))
        {
            throw new InvalidOperationException("AI response is empty.");
        }

        var cleaned = Cleanup(rawContent);
        AiStructuredOutputDto? dto;

        try
        {
            dto = JsonSerializer.Deserialize<AiStructuredOutputDto>(cleaned, SerializerOptions);
        }
        catch (JsonException ex)
        {
            throw new InvalidOperationException($"AI response is not valid JSON: {ex.Message}");
        }

        if (dto is null)
        {
            throw new InvalidOperationException("AI response JSON is empty.");
        }

        var translation = (dto.Translation ?? string.Empty).Trim();
        var analysis = (dto.Analysis ?? string.Empty).Trim();
        var coreWords = (dto.CoreWords ?? [])
            .Where(x => !string.IsNullOrWhiteSpace(x))
            .Select(x => x.Trim())
            .Distinct(StringComparer.OrdinalIgnoreCase)
            .Take(8)
            .ToList();

        if (translation.Length == 0 || analysis.Length == 0)
        {
            throw new InvalidOperationException("AI response JSON misses required fields: translation/analysis.");
        }

        return new AiStructuredOutput
        {
            Translation = translation,
            Analysis = analysis,
            CoreWords = coreWords
        };
    }

    private static string Cleanup(string content)
    {
        var cleaned = content.Trim();
        if (!cleaned.StartsWith("```", StringComparison.Ordinal))
        {
            return cleaned;
        }

        var lines = cleaned.Split('\n')
            .Select(x => x.TrimEnd('\r'))
            .ToList();

        if (lines.Count >= 2 && lines[0].StartsWith("```", StringComparison.Ordinal) && lines[^1].StartsWith("```", StringComparison.Ordinal))
        {
            lines.RemoveAt(0);
            lines.RemoveAt(lines.Count - 1);
            return string.Join('\n', lines).Trim();
        }

        return cleaned;
    }

    private sealed class AiStructuredOutputDto
    {
        public string? Translation { get; set; }

        public string? Analysis { get; set; }

        public List<string>? CoreWords { get; set; }
    }
}
