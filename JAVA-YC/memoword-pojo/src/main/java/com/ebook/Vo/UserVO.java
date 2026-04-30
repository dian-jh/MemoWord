package com.ebook.Vo;

import lombok.Data;

import java.time.LocalDateTime;

// 用户基础信息 (VO)
@Data
public class UserVO {
    private String id;
    private String username;
    private String account;
    private String avatarUrl;
    private LocalDateTime createTime; // ISO 8601
    private  Integer targetWords;
}