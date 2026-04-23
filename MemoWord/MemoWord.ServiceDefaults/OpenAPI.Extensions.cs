using Microsoft.AspNetCore.Builder;
using Microsoft.AspNetCore.Http;
using Microsoft.AspNetCore.Routing;
using Microsoft.Extensions.Configuration;
using Microsoft.Extensions.DependencyInjection;
using Microsoft.Extensions.Hosting;
using Scalar;
using Scalar.AspNetCore;

namespace MemoWord.ServiceDefaults;

public static partial class Extensions
{
    public static IApplicationBuilder UseDefaultOpenApi(this WebApplication app)
    {
        var configuration = app.Configuration;
        var openApiSection = configuration.GetSection("OpenApi");

        if (!openApiSection.Exists())
        {
            return app;
        }

        app.MapOpenApi();

        if (app.Environment.IsDevelopment())
        {
            app.MapScalarApiReference(options =>
            {
                // Disable default fonts to avoid download unnecessary fonts
                options.DefaultFonts = false;
                options.AddPreferredSecuritySchemes("Bearer");
                options.AddPreferredSecuritySchemes("oauth2");
            });
            //ExcludeFromDescription把这个接口从API文档中排除掉，因为它只是一个重定向，不需要在文档中展示
            app.MapGet("/", () => Results.Redirect("/scalar/v1")).ExcludeFromDescription();
        }

        return app;
    }

    public static IHostApplicationBuilder AddDefaultOpenApi(
        this IHostApplicationBuilder builder)
    {
        //从appsettings.json读取配置
        var openApi = builder.Configuration.GetSection("OpenApi");
        var identitySection = builder.Configuration.GetSection("Identity");
        //若存在identity配置，则读取其中的Scopes配置，并转换为字典；否则创建一个空字典
        //UI界面需要知道有哪些scope可用，以便在授权时展示给用户选择
        var scopes = identitySection.Exists()
            ? identitySection.GetRequiredSection("Scopes").GetChildren().ToDictionary(p => p.Key, p => p.Value)
            : new Dictionary<string, string?>();


        if (!openApi.Exists())
        {
            return builder;
        }

        builder.Services.AddOpenApi("v1", options =>
        {
            options.ApplyApiInfo(
                openApi.GetRequiredValue("Document:Title"),
                openApi.GetRequiredValue("Document:Description")
            );

            options.ApplyAuthorizationChecks([.. scopes.Keys]);
            options.ApplySecuritySchemeDefinitions();
            options.ApplyOperationDeprecatedStatus();

            options.AddDocumentTransformer<BearerSecuritySchemeTransformer>();

            // 【注意】下面这行必须删除或注释掉！
            // 因为 ApplyApiVersionDescription 是依赖于 IApiVersioningBuilder 的扩展方法。
            // 既然我们移除了 API 版本控制组件，这个方法将无法获取到多版本描述，会导致编译或运行报错。
            // options.ApplyApiVersionDescription(); 
        });

        return builder;
    }
}