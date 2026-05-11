using Microsoft.AspNetCore.Authentication.JwtBearer;
using Microsoft.AspNetCore.DataProtection;
using Microsoft.IdentityModel.Tokens;
using System.Text;
using Yarp.ReverseProxy.Transforms;

var builder = WebApplication.CreateBuilder(args);

builder.AddServiceDefaults();
builder.Services.AddServiceDiscovery();
builder.Services.AddDataProtection().UseEphemeralDataProtectionProvider();

builder.Services.AddCors(options =>
{
    options.AddPolicy("AllowArkTS", policy =>
    {
        policy.AllowAnyOrigin()
              .AllowAnyHeader()
              .AllowAnyMethod();
    });
});

// --- 1. 配置身份验证服务 ---
var secretKey = "12345678901234567890123456789012";
builder.Services.AddAuthentication(JwtBearerDefaults.AuthenticationScheme)
   .AddJwtBearer(options =>
   {
       // ✅ 核心修改：拦截消息接收事件
       options.Events = new JwtBearerEvents
       {
           OnMessageReceived = context =>
           {
               // 从名为 "token" 的 Header 中获取值
               var customToken = context.Request.Headers["token"].FirstOrDefault();
               if (!string.IsNullOrEmpty(customToken))
               {
                   // 将其赋值给 context.Token，网关后续会自动对其进行签名校验
                   // 如果你前端传的是纯 token (不带 Bearer )，直接赋值即可
                   context.Token = customToken;
               }
               return Task.CompletedTask;
           }
       };

       options.TokenValidationParameters = new TokenValidationParameters
       {
           ValidateIssuerSigningKey = true,
           IssuerSigningKey = new SymmetricSecurityKey(Encoding.UTF8.GetBytes(secretKey)),
           ValidateIssuer = false,
           ValidateAudience = false,
           ValidateLifetime = true,
           ClockSkew = TimeSpan.Zero // 建议加上，防止服务器时间差导致校验失败
       };
   });

builder.Services.AddAuthorization();


builder.Services.AddReverseProxy()
    .LoadFromConfig(builder.Configuration.GetSection("ReverseProxy"))
    .AddServiceDiscoveryDestinationResolver()
    .AddTransforms(builderContext =>
    {
        builderContext.AddRequestTransform(async transformContext =>
        {
            var user = transformContext.HttpContext.User;

            // 只有当用户已通过 JWT 验证时，才尝试提取 ID
            if (user.Identity?.IsAuthenticated == true)
            {
                // 【关键修正】：队友 Java 常量定义为 "userId" (首字母小写)
                // 同时保留标准 NameIdentifier 作为备选
                var userId = user.FindFirst("userId")?.Value
                             ?? user.FindFirst(System.Security.Claims.ClaimTypes.NameIdentifier)?.Value;

                if (!string.IsNullOrEmpty(userId))
                {
                    // 【安全修正】：使用 Remove 确保没有伪造的 Header，再添加
                    transformContext.ProxyRequest.Headers.Remove("X-User-Id");
                    transformContext.ProxyRequest.Headers.Add("X-User-Id", userId);
                }
            }
        });
    });


var app = builder.Build();

app.MapDefaultEndpoints();

app.UseRouting();

app.UseCors("AllowArkTS");



app.UseAuthentication(); 
app.UseAuthorization(); 

app.MapReverseProxy();
//app.MapControllers();

app.Run();
