using System.Net.Http.Json;
using System.Text.Json;
using Microsoft.Extensions.AI;

namespace AiService.Infrastructure;

public sealed class DeepSeekChatClient : IChatClient
{
    private static readonly JsonSerializerOptions SerializerOptions = new(JsonSerializerDefaults.Web);

    private readonly HttpClient _httpClient;
    private readonly ChatClientMetadata _metadata = new("deepseek");

    public DeepSeekChatClient(HttpClient httpClient)
    {
        _httpClient = httpClient;
    }

    public ChatClientMetadata Metadata => _metadata;

    public object? GetService(Type serviceType, object? serviceKey = null)
    {
        return serviceType == typeof(IChatClient) ? this : null;
    }

    public async Task<ChatResponse> GetResponseAsync(
        IEnumerable<ChatMessage> messages,
        ChatOptions? options = null,
        CancellationToken cancellationToken = default)
    {
        var messageList = messages.ToList();
        if (messageList.Count == 0)
        {
            throw new ArgumentException("messages cannot be empty.", nameof(messages));
        }

        var model = string.IsNullOrWhiteSpace(options?.ModelId) ? "deepseek-chat" : options!.ModelId!;
        var temperature = (float)(options?.Temperature ?? 0.7);

        var request = new DeepSeekChatRequest
        {
            Model = model,
            Temperature = temperature,
            Stream = false,
            Messages = messageList.Select(ToDeepSeekMessage).ToList()
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

        return new ChatResponse(new ChatMessage(ChatRole.Assistant, content.Trim()));
    }

    public async IAsyncEnumerable<ChatResponseUpdate> GetStreamingResponseAsync(
        IEnumerable<ChatMessage> messages,
        ChatOptions? options = null,
        [System.Runtime.CompilerServices.EnumeratorCancellation] CancellationToken cancellationToken = default)
    {
        var response = await GetResponseAsync(messages, options, cancellationToken);
        foreach (var update in response.ToChatResponseUpdates())
        {
            yield return update;
        }
    }

    public void Dispose()
    {
    }

    private static DeepSeekRequestMessage ToDeepSeekMessage(ChatMessage message)
    {
        var role = message.Role == ChatRole.System
            ? "system"
            : message.Role == ChatRole.Assistant
                ? "assistant"
                : "user";

        return new DeepSeekRequestMessage
        {
            Role = role,
            Content = message.Text
        };
    }

    private sealed class DeepSeekChatRequest
    {
        public string Model { get; set; } = "deepseek-chat";

        public float Temperature { get; set; } = 0.7f;

        public bool Stream { get; set; }

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
