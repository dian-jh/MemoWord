using Microsoft.AspNetCore.OpenApi;
using Microsoft.OpenApi;

namespace MemoWord.ServiceDefaults;

public sealed class BearerSecuritySchemeTransformer : IOpenApiDocumentTransformer
{
    public Task TransformAsync(OpenApiDocument document, OpenApiDocumentTransformerContext context, CancellationToken cancellationToken)
    {
        document.Components ??= new OpenApiComponents();
        document.Components.SecuritySchemes ??= new Dictionary<string, IOpenApiSecurityScheme>();

        var bearerScheme = new OpenApiSecurityScheme
        {
            Type = SecuritySchemeType.Http,
            Scheme = "bearer",
            BearerFormat = "JWT",
            Description = "直接输入 JWT Token（带或不带 Bearer 前缀均可）"
        };

        document.Components.SecuritySchemes["Bearer"] = bearerScheme;

        return Task.CompletedTask;
    }
}