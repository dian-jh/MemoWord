package com.ebook.entity;

import com.baomidou.mybatisplus.annotation.TableName;
import lombok.Data;

import java.time.LocalDateTime;

// BookCollectionMapping.java
@Data
@TableName("BookCollectionMapping")
public class BookCollectionMapping {
    private String collectionId; // 联合主键
    private String bookId;       // 联合主键
    private String userId;
    private LocalDateTime addTime;
}