package com.ebook.entity;

import com.baomidou.mybatisplus.annotation.IdType;
import com.baomidou.mybatisplus.annotation.TableField;
import com.baomidou.mybatisplus.annotation.TableId;
import com.baomidou.mybatisplus.annotation.TableName;
import lombok.Data;

import java.time.LocalDateTime;

@Data
@TableName("User")
public class User {
    @TableId(type = IdType.ASSIGN_UUID)
    private String id; // CHAR(36)
    private String username;
    private String account;
    @TableField("PasswordHash")
    private String passwordHash;
    @TableField("AvatarUrl")
    private String avatarUrl;
    @TableField("CreateTime")
    private LocalDateTime createTime;
    @TableField("TargetWords")
    private  Integer targetWords;
}