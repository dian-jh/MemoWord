package com.ebook.config;

import com.ebook.interceptor.JwtTokenAdminInterceptor;
import io.swagger.v3.oas.models.OpenAPI;
import io.swagger.v3.oas.models.info.Info;
import lombok.extern.slf4j.Slf4j;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.context.annotation.Bean;
import org.springframework.context.annotation.Configuration;
import org.springframework.web.servlet.config.annotation.InterceptorRegistry;
import org.springframework.web.servlet.config.annotation.ResourceHandlerRegistry;
import org.springframework.web.servlet.config.annotation.WebMvcConfigurer;

@Configuration
@Slf4j
public class WebConfiguration implements WebMvcConfigurer {

//    @Autowired
//    private JwtTokenAdminInterceptor jwtTokenAdminInterceptor;

    @Override
    public void addInterceptors(InterceptorRegistry registry) {
        log.info("开始注册自定义拦截器...");

//        registry.addInterceptor(jwtTokenAdminInterceptor)
//                .addPathPatterns("/api/v1/**")  // 修复：前面加 /
//                .excludePathPatterns("/api/v1/auth/registry", "/api/v1/auth/login","/api/v1/auth/logout"); // 修复：前面加 /
/**
 * Swagger文档配置（直接写在当前Web配置类里，不再新建单独配置类）
 */
    }

    @Override
    public void addResourceHandlers(ResourceHandlerRegistry registry) {
        // 头像/文件上传映射
        registry.addResourceHandler("/uploads/**")
                .addResourceLocations("file:D:/Vocabulary/uploads/");
    }

    @Bean
        public OpenAPI openAPI() {
            return new OpenAPI()
                    .info(new Info()
                            .description("Ebook电子书后台管理系统API接口")
                            .version("1.0.0")
                    );
        }




    // ======================
    // 【关键】把整个 addResourceHandlers 方法删掉！
    // Spring Boot 会自动配置，你手动写就会冲突
    // ======================

}