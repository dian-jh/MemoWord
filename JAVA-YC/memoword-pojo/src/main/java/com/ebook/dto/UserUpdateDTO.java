package com.ebook.dto;

import lombok.Data;

// PUT /api/v1/users/me
@Data
public class UserUpdateDTO {
    private String username;
    private String avatarUrl;
}