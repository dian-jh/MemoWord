using System.Net.Http.Headers;
using System.Net.Http.Json;
using System.Text.Json;
using AiService.Domain;
using AiService.Domain.Models;

namespace AiService.Infrastructure;

public class DeepSeekChatClient : IAiCompletionProvider
{
    private static readonly JsonSerializerOptions SerializerOptions = new(JsonSerializerDefaults.Web);

    private readonly HttpClient _httpClient;
    private readonly DeepSeekOptions _options;

    public DeepSeekChatClient(HttpClient httpClient, DeepSeekOptions options)
    {
        _httpClient = httpClient;
        _options = options;
        _httpClient.DefaultRequestHeaders.Authorization = new AuthenticationHeaderValue("Bearer", _options.ApiKey);
    }

    public async Task<string> GetCompletionAsync(IReadOnlyList<AiChatPromptMessage> messages, CancellationToken cancellationToken = default)
    {
        if (messages.Count == 0)
        {
            throw new ArgumentException("messages cannot be empty.", nameof(messages));
        }

        var request = new DeepSeekChatRequest
        {
            Model = _options.Model,
            Temperature = _options.Temperature,
            Messages = messages.Select(x => new DeepSeekRequestMessage
            {
                Role = x.Role,
                Content = x.Content
            }).ToList()
        };

        using var httpRequest = new HttpRequestMessage(HttpMethod.Post, "chat/completions")
        {
            Content = JsonContent.Create(request, options: SerializerOptions)
        };

        using var response = await _httpClient.SendAsync(httpRequest, cancellationToken);
        var responseBody = await response.Content.ReadAsStringAsync(cancellationToken);
        if (!response.IsSuccessStatusCode)
        {
            throw new InvalidOperationException($"DeepSeek request failed ({(int)response.StatusCode}): {responseBody}");
        }

        var completion = JsonSerializer.Deserialize<DeepSeekChatResponse>(responseBody, SerializerOptions);
        var content = completion?.Choices?.FirstOrDefault()?.Message?.Content;
        if (string.IsNullOrWhiteSpace(content))
        {
            throw new InvalidOperationException("DeepSeek response has no assistant content.");
        }

        return content.Trim();
    }

    private sealed class DeepSeekChatRequest
    {
        public string Model { get; set; } = "deepseek-chat";

        public double Temperature { get; set; } = 0.7;

        public List<DeepSeekRequestMessage> Messages { get; set; } = [];
    }

    private sealed class DeepSeekRequestMessage
    {
        public string Role { get; set; } = string.Empty;

        public string Content { get; set; } = string.Empty;
    }

    private sealed class DeepSeekChatResponse
    {
        public List<DeepSeekChoice>? Choices { get; set; }
    }

    private sealed class DeepSeekChoice
    {
        public DeepSeekResponseMessage? Message { get; set; }
    }

    private sealed class DeepSeekResponseMessage
    {
        public string? Content { get; set; }
    }
}
