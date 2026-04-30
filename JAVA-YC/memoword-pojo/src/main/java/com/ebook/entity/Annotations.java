package com.ebook.entity;

import com.baomidou.mybatisplus.annotation.IdType;
import com.baomidou.mybatisplus.annotation.TableField;
import com.baomidou.mybatisplus.annotation.TableId;
import com.baomidou.mybatisplus.annotation.TableName;
import com.baomidou.mybatisplus.extension.handlers.JacksonTypeHandler;
import lombok.Data;

import java.time.LocalDateTime;

@Data
@TableName(value = "Annotations", autoResultMap = true)
public class Annotations {
    @TableId(type = IdType.ASSIGN_UUID)
    private String id;
    private String userId;
    private String bookId;
    private String catalogId;

    @TableField(typeHandler = JacksonTypeHandler.class)
    private String locator; // SQL 中为 JSON 类型

    private String quoteText;
    private String noteContent;
    private String style;
    private String type;
    private String status;
    private LocalDateTime updatedAt;
    private LocalDateTime createTime;
    private LocalDateTime updateTime;
}