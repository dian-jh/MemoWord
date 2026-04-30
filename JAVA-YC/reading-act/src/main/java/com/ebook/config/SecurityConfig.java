package com.ebook.config;
import com.ebook.interceptor.JwtAuthenticationFilter;
import org.springframework.context.annotation.Bean;
import org.springframework.context.annotation.Configuration;
import org.springframework.security.config.annotation.web.builders.HttpSecurity;
import org.springframework.security.config.annotation.web.configuration.EnableWebSecurity;
import org.springframework.security.web.SecurityFilterChain;
import org.springframework.security.web.authentication.UsernamePasswordAuthenticationFilter;

@Configuration
@EnableWebSecurity
public class SecurityConfig {

    @Bean
    public SecurityFilterChain securityFilterChain(HttpSecurity http) throws Exception {
        http
                .csrf(csrf -> csrf.disable())

                .authorizeHttpRequests(auth -> auth
                        // 放行登录、注册、退出
                                .requestMatchers("/api/v1/auth/registry").permitAll()
                                .requestMatchers("/api/v1/auth/login").permitAll()
                                .requestMatchers("/api/v1/auth/logout").permitAll()
//                                .requestMatchers("/api/v1/users/updatetargetwords/{num}").permitAll()
//                                .requestMatchers("/api/v1/users/me").permitAll()
// Swagger 全部放行
                                .requestMatchers("/swagger-resources/**").permitAll()
                                .requestMatchers("/webjars/**").permitAll()
                                .requestMatchers("/v2/api-docs").permitAll()
                                .requestMatchers("/v3/api-docs/**").permitAll()
                                .requestMatchers("/swagger-ui/**").permitAll()
                                .requestMatchers("/swagger-ui.html").permitAll()

                        // 其他所有接口必须登录
                        .anyRequest().authenticated()

                )

                // 👇 👇 👇 把 JWT 过滤器加在这里！
                .addFilterBefore(
                        new JwtAuthenticationFilter() ,
                        UsernamePasswordAuthenticationFilter.class
                );

        return http.build();
    }
}