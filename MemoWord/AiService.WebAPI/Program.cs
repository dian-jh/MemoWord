using AiService.Domain;
using AiService.Infrastructure;
using AiService.WebAPI.Settings;
using MemoWord.ServiceDefaults;

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

var aiChatOptions = builder.Configuration.GetSection("AiChat").Get<AiChatApiOptions>() ?? new AiChatApiOptions();

builder.Services.AddSingleton(aiChatOptions);
builder.Services.AddAiInfrastructure(builder.Configuration);

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
