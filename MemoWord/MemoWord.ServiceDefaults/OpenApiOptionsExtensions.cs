using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.OpenApi;
using Microsoft.Extensions.Configuration;
using Microsoft.OpenApi;

namespace MemoWord.ServiceDefaults;

public static class OpenApiOptionsExtensions
{
    public static OpenApiOptions ApplyApiInfo(this OpenApiOptions options, string title, string description)
    {
        options.AddDocumentTransformer((document, context, cancellationToken) =>
        {
            // 直接将传入的标题和描述赋给文档
            document.Info.Title = title;
            document.Info.Description = description;

            // 由于没有动态版本，可以直接硬编码一个基础版本号，比如 "v1" 或 "1.0.0"
            document.Info.Version = "v1";

            return Task.CompletedTask;
        });

        return options;
    }

    public static OpenApiOptions ApplySecuritySchemeDefinitions(this OpenApiOptions options)
    {
        options.AddDocumentTransformer<SecuritySchemeDefinitionsTransformer>();
        return options;
    }

    public static OpenApiOptions ApplyAuthorizationChecks(this OpenApiOptions options, string[] scopes)
    {
        options.AddOperationTransformer((operation, context, cancellationToken) =>
        {
            var metadata = context.Description.ActionDescriptor.EndpointMetadata;
            //查找端点是否有IAuthorizeData特性：[Authorize]底层就是实现了IAuthorizeData
            if (!metadata.OfType<IAuthorizeData>().Any())
            {
                return Task.CompletedTask;
            }
            //补全401和403响应的API文档
            operation.Responses ??= new OpenApiResponses();
            operation.Responses.TryAdd("401", new OpenApiResponse { Description = "Unauthorized" });
            operation.Responses.TryAdd("403", new OpenApiResponse { Description = "Forbidden" });

            var oAuthScheme = new OpenApiSecuritySchemeReference("oauth2", null);

            operation.Security = new List<OpenApiSecurityRequirement>
            {
                new()
                {
                    [oAuthScheme] = scopes.ToList()
                }
            };

            return Task.CompletedTask;
        });
        return options;
    }
    //发现接口标记为过时后，在API文档中也标记为过时
    public static OpenApiOptions ApplyOperationDeprecatedStatus(this OpenApiOptions options)
    {
        options.AddOperationTransformer((operation, context, cancellationToken) =>
        {
            // 1. 获取当前 API 接口的所有元数据（也就是它上面打的所有特性 Attribute）
            var metadata = context.Description.ActionDescriptor.EndpointMetadata;

            // 2. 原生检查：查找是否存在 [Obsolete] 特性
            // OfType<ObsoleteAttribute>() 会筛选出过时特性，Any() 表示只要存在哪怕一个就返回 true
            var isObsolete = metadata.OfType<ObsoleteAttribute>().Any();

            // 3. 将结果赋值给 OpenAPI 规范模型
            operation.Deprecated |= isObsolete;

            return Task.CompletedTask;
        });
        return options;
    }

    private class SecuritySchemeDefinitionsTransformer(IConfiguration configuration) : IOpenApiDocumentTransformer
    {
        public Task TransformAsync(OpenApiDocument document, OpenApiDocumentTransformerContext context, CancellationToken cancellationToken)
        {
            //从配置中读取 Identity 配置节，如果不存在则直接返回
            var identitySection = configuration.GetSection("Identity");
            if (!identitySection.Exists())
            {
                return Task.CompletedTask;
            }

            var identityUrlExternal = identitySection.GetRequiredValue("Url");
            var scopes = identitySection.GetRequiredSection("Scopes").GetChildren().ToDictionary(p => p.Key, p => p.Value ?? string.Empty);
            var securityScheme = new OpenApiSecurityScheme
            {
                Type = SecuritySchemeType.OAuth2,
                Flows = new OpenApiOAuthFlows()
                {
                    // TODO: Change this to use Authorization Code flow with PKCE
                    Implicit = new OpenApiOAuthFlow()
                    {
                        AuthorizationUrl = new Uri($"{identityUrlExternal}/connect/authorize"),
                        TokenUrl = new Uri($"{identityUrlExternal}/connect/token"),
                        Scopes = scopes,
                    }
                }
            };
            document.Components ??= new();
            document.Components.SecuritySchemes ??= new Dictionary<string, IOpenApiSecurityScheme>();
            document.Components.SecuritySchemes.Add("oauth2", securityScheme);
            return Task.CompletedTask;
        }
    }
}