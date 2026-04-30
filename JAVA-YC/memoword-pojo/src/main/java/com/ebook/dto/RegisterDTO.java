package com.ebook.dto;

import lombok.Data;

// POST /api/v1/auth/register
@Data
public class RegisterDTO {
    private String account;
    private String username;
    private String password;
}