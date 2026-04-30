using Elastic.Clients.Elasticsearch;
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

var esConnectionString = builder.Configuration.GetConnectionString("elasticsearch");

if (string.IsNullOrEmpty(esConnectionString))
{
    // 如果找不到，给一个默认值防止启动崩溃（仅限开发环境）
    esConnectionString = "http://localhost:9200";
}

// 2. 使用读取到的地址创建设置
var esSettings = new ElasticsearchClientSettings(new Uri(esConnectionString))
    .DefaultIndex("words")
    .EnableDebugMode();

// 3. 注册单例
builder.Services.AddSingleton<ElasticsearchClient>(new ElasticsearchClient(esSettings));

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
builder.Services.AddScoped<IWordSearchRepository, ElasticWordSearchRepository>();
builder.Services.AddScoped<IFavoriteRepository, FavoriteRepository>();
builder.Services.AddScoped<ISearchHistoryRepository, SearchHistoryRepository>();
builder.Services.AddScoped<WordDomainService>();
builder.Services.AddScoped<StudyStatisticsDomainService>();
builder.Services.AddScoped<FavoriteDomainService>();
builder.Services.AddScoped<SearchHistoryDomainService>();
// Learn more about configuring OpenAPI at https://aka.ms/aspnet/openapi
builder.Services.AddOpenApi();

builder.AddDefaultOpenApi();

var app = builder.Build();
//强制监听所有网卡上的 5195 端口
//app.Urls.Add("http://0.0.0.0:5195");

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
