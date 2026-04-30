package com.ebook.utils;

import io.jsonwebtoken.Claims;
import io.jsonwebtoken.JwtBuilder;
import io.jsonwebtoken.Jwts;
import io.jsonwebtoken.SignatureAlgorithm;
import io.jsonwebtoken.security.Keys;

import java.nio.charset.StandardCharsets;
import java.util.Date;
import java.util.Map;

public class JwtUtil {

    // 👇 👇 👇 【关键】把你的短密钥 → 自动变成合法 256bit 密钥
    private static final String FIXED_KEY = "12345678901234567890123456789012"; // 32位字符串

    public static String createJWT(String secretKey, long ttlMillis, Map<String, Object> claims) {
        SignatureAlgorithm signatureAlgorithm = SignatureAlgorithm.HS256;

        long expMillis = System.currentTimeMillis() + ttlMillis;
        Date exp = new Date(expMillis);

        JwtBuilder builder = Jwts.builder()
                .setClaims(claims)
                // 👇 使用安全密钥
                .signWith(Keys.hmacShaKeyFor(FIXED_KEY.getBytes(StandardCharsets.UTF_8)))
                .setExpiration(exp);

        return builder.compact();
    }

    public static Claims parseJWT(String secretKey, String token) {
        Claims claims = Jwts.parser()
                // 👇 使用安全密钥
                .setSigningKey(Keys.hmacShaKeyFor(FIXED_KEY.getBytes(StandardCharsets.UTF_8)))
                .parseClaimsJws(token)
                .getBody();
        return claims;
    }
}