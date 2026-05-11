namespace AiService.Infrastructure;

public static class DeepSeekConnectionParser
{
    public static DeepSeekOptions Parse(string deepSeekConnectionString)
    {
        if (string.IsNullOrWhiteSpace(deepSeekConnectionString))
        {
            throw new InvalidOperationException("Connection string 'deepseek' is required.");
        }

        string? endpoint = null;
        string? apiKey = null;

        var parts = deepSeekConnectionString.Split(';', StringSplitOptions.RemoveEmptyEntries | StringSplitOptions.TrimEntries);
        foreach (var part in parts)
        {
            var pair = part.Split('=', 2, StringSplitOptions.TrimEntries);
            if (pair.Length != 2)
            {
                continue;
            }

            if (pair[0].Equals("Endpoint", StringComparison.OrdinalIgnoreCase))
            {
                endpoint = pair[1];
                continue;
            }

            if (pair[0].Equals("Key", StringComparison.OrdinalIgnoreCase))
            {
                apiKey = pair[1];
            }
        }

        if (string.IsNullOrWhiteSpace(endpoint))
        {
            throw new InvalidOperationException("DeepSeek endpoint is missing in connection string.");
        }

        if (string.IsNullOrWhiteSpace(apiKey))
        {
            throw new InvalidOperationException("DeepSeek api key is missing in connection string.");
        }

        return new DeepSeekOptions
        {
            Endpoint = endpoint.Trim(),
            ApiKey = apiKey.Trim()
        };
    }
}
