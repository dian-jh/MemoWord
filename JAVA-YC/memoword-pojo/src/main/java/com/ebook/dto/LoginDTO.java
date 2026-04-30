package com.ebook.dto;

import lombok.Data;

// POST /api/v1/auth/login
@Data
public class LoginDTO {
    private String account;
    private String password;
}