package com.ebook.entity;

import com.baomidou.mybatisplus.annotation.IdType;
import com.baomidou.mybatisplus.annotation.TableId;
import com.baomidou.mybatisplus.annotation.TableName;
import lombok.Data;

import java.time.LocalDateTime;

// UserCollections.java
@Data
@TableName("UserCollections")
public class UserCollections {
    @TableId(type = IdType.ASSIGN_UUID)
    private String id;
    private String userId;
    private String name;
    private Integer sortOrder;
    private LocalDateTime createTime;
}

// BookCollectionMapping.java
