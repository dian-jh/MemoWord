using MemoWord.ServiceDefaults;
using Microsoft.EntityFrameworkCore;
using WordService.Domain;
using WordService.Infrastructure;

var builder = WebApplication.CreateBuilder(args);

builder.AddServiceDefaults();

builder.Services.AddCors(options =>
{
    options.AddPolicy("AllowArkTS", policy =>
    {
        policy.AllowAnyOrigin() // 生产环境建议指定具体 IP
              .AllowAnyHeader()
              .AllowAnyMethod();
    });
});

// Add services to the container.

builder.Services.AddDbContext<WordDbContext>(options =>
{
    options.UseMySql(
        builder.Configuration.GetConnectionString("memoword"),
        new MySqlServerVersion(new Version(8, 0, 36))
    );
});

builder.Services.AddControllers();
builder.Services.AddScoped<IWordRepository, WordRepository>();
builder.Services.AddScoped<IStudyStatisticsRepository, StudyStatisticsRepository>();
builder.Services.AddScoped<WordDomainService>();
builder.Services.AddScoped<StudyStatisticsDomainService>();
// Learn more about configuring OpenAPI at https://aka.ms/aspnet/openapi
builder.Services.AddOpenApi();

builder.AddDefaultOpenApi();

var app = builder.Build();

app.MapDefaultEndpoints();

app.UseCors("AllowArkTS");

// Configure the HTTP request pipeline.
//if (app.Environment.IsDevelopment())
//{
//    app.MapOpenApi();
//}

//app.UseHttpsRedirection();

app.UseAuthorization();

app.MapControllers();
app.UseDefaultOpenApi();

app.Run();
