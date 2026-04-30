package com.ebook.interceptor;
import com.ebook.context.BaseContext;
import com.ebook.utils.JwtUtil;
import io.jsonwebtoken.Claims;
import jakarta.servlet.FilterChain;
import jakarta.servlet.ServletException;
import jakarta.servlet.http.HttpServletRequest;
import jakarta.servlet.http.HttpServletResponse;
import org.springframework.security.authentication.UsernamePasswordAuthenticationToken;
import org.springframework.security.core.context.SecurityContextHolder;
import org.springframework.web.filter.OncePerRequestFilter;

import java.io.IOException;

public class JwtAuthenticationFilter extends OncePerRequestFilter {

    @Override
    protected void doFilterInternal(HttpServletRequest request,
                                    HttpServletResponse response,
                                    FilterChain filterChain) throws ServletException, IOException {

        // 1. 从请求头获取 token
        String token = request.getHeader("token");

        // 2. 无token 直接放行
        if (token == null || token.isEmpty()) {
            filterChain.doFilter(request, response);
            return;
        }

        Claims claims;
        try {
            claims = JwtUtil.parseJWT("666", token);
        } catch (Exception e) {
            response.setStatus(HttpServletResponse.SC_UNAUTHORIZED);
            return;
        }

        // ==========================
        String userId = claims.get("userId").toString();
        BaseContext.setCurrentId(userId);


        // =============================================
        // 【关键 3】给 Spring Security 做认证（可选）
        // =============================================
        UsernamePasswordAuthenticationToken authentication =
                new UsernamePasswordAuthenticationToken(userId, null, null);
        SecurityContextHolder.getContext().setAuthentication(authentication);

        // 放行
        filterChain.doFilter(request, response);
    }
}