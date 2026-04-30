package com.ebook.Vo;

import lombok.Builder;
import lombok.Data;

// 登录成功返回 (VO)
@Data
@Builder
public class LoginVO {
    private String accessToken;
    private String refreshToken;
    private Integer expiresInSec;
    private UserVO user;
}