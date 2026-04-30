package com.ebook.entity;

import com.baomidou.mybatisplus.annotation.TableName;
import com.baomidou.mybatisplus.annotation.Version;
import lombok.Data;

import java.math.BigDecimal;
import java.time.LocalDateTime;

@Data
@TableName("ReadingProgress")
public class ReadingProgress {
    private String userId; // 联合主键
    private String bookId; // 联合主键
    private String locatorType;
    private String locatorValue;
    private String catalogId;
    private BigDecimal progressRatio; // DECIMAL(5,4)
    @Version
    private Integer version;
    private LocalDateTime updateTime;
}