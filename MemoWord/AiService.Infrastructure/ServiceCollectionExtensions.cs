using System.Net.Http.Headers;
using AiService.Domain;
using AiService.Domain.Models;
using Microsoft.EntityFrameworkCore;
using Microsoft.Extensions.AI;
using Microsoft.Extensions.Caching.Distributed;
using Microsoft.Extensions.Configuration;
using Microsoft.Extensions.DependencyInjection;
using Microsoft.Extensions.Http.Resilience;

namespace AiService.Infrastructure;

public static class ServiceCollectionExtensions
{
    public static IServiceCollection AddAiInfrastructure(this IServiceCollection services, IConfiguration configuration)
    {
        var memowordConnection = configuration.GetConnectionString("memoword");
        if (string.IsNullOrWhiteSpace(memowordConnection))
        {
            throw new InvalidOperationException("Connection string 'memoword' is required.");
        }

        var deepSeekConnection = configuration.GetConnectionString("deepseek");
        var deepSeekOptions = DeepSeekConnectionParser.Parse(deepSeekConnection ?? string.Empty);
        var aiOptions = configuration.GetSection("AiChat").Get<AiInfrastructureOptions>() ?? new AiInfrastructureOptions();

        services.AddSingleton(deepSeekOptions);
        services.AddSingleton(aiOptions);

        services.AddDbContext<AiDbContext>(options =>
        {
            options.UseMySql(
                memowordConnection,
                new MySqlServerVersion(new Version(8, 0, 36)));
        });

        services.AddHttpClient(nameof(DeepSeekChatClient), client =>
            {
                client.BaseAddress = new Uri(deepSeekOptions.Endpoint.TrimEnd('/') + "/");
                client.DefaultRequestHeaders.Authorization = new AuthenticationHeaderValue("Bearer", deepSeekOptions.ApiKey);
            })
            .AddStandardResilienceHandler();

        services.AddDistributedMemoryCache();

        var chatBuilder = services.AddChatClient(sp =>
            {
                var factory = sp.GetRequiredService<IHttpClientFactory>();
                return new DeepSeekChatClient(factory.CreateClient(nameof(DeepSeekChatClient)));
            })
            .UseLogging()
            .ConfigureOptions(options =>
            {
                options.ModelId = aiOptions.Model;
                options.Temperature ??= aiOptions.Temperature;
                options.ResponseFormat ??= ChatResponseFormat.ForJsonSchema<AiStructuredOutput>();
            });

        if (aiOptions.EnableDistributedCache)
        {
            chatBuilder.UseDistributedCache();
        }

        services.AddScoped<IAiChatRepository, AiChatRepository>();
        services.AddScoped<IAiWordLookupRepository, AiWordLookupRepository>();
        services.AddScoped<AiChatDomainService>();

        return services;
    }
}
