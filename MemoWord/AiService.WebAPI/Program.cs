using AiService.Domain;
using AiService.Infrastructure;
using AiService.WebAPI.Settings;
using MemoWord.ServiceDefaults;
using Microsoft.EntityFrameworkCore;

var builder = WebApplication.CreateBuilder(args);

builder.AddServiceDefaults();

builder.Services.AddCors(options =>
{
    options.AddPolicy("AllowArkTS", policy =>
    {
        policy.AllowAnyOrigin()
            .AllowAnyHeader()
            .AllowAnyMethod();
    });
});

var memowordConnection = builder.Configuration.GetConnectionString("memoword");
if (string.IsNullOrWhiteSpace(memowordConnection))
{
    throw new InvalidOperationException("Connection string 'memoword' is required.");
}

var aiChatOptions = builder.Configuration.GetSection("AiChat").Get<AiChatApiOptions>() ?? new AiChatApiOptions();
var deepSeekConnection = builder.Configuration.GetConnectionString("deepseek");
var deepSeekOptions = DeepSeekConnectionParser.Parse(
    deepSeekConnection ?? string.Empty,
    aiChatOptions.Model,
    aiChatOptions.Temperature);

builder.Services.AddSingleton(aiChatOptions);
builder.Services.AddSingleton(deepSeekOptions);

builder.Services.AddDbContext<AiDbContext>(options =>
{
    options.UseMySql(
        memowordConnection,
        new MySqlServerVersion(new Version(8, 0, 36))
    );
});

builder.Services.AddHttpClient<IAiCompletionProvider, DeepSeekChatClient>(client =>
{
    client.BaseAddress = new Uri(deepSeekOptions.Endpoint.TrimEnd('/') + "/");
});
builder.Services.AddScoped<IAiChatRepository, AiChatRepository>();
builder.Services.AddScoped<AiChatDomainService>();

builder.Services.AddControllers();
builder.Services.AddOpenApi();
builder.AddDefaultOpenApi();

var app = builder.Build();

app.MapDefaultEndpoints();

app.UseCors("AllowArkTS");

app.UseAuthorization();

app.MapControllers();
app.UseDefaultOpenApi();

app.Run();
