package com.ebook.entity;

import com.baomidou.mybatisplus.annotation.IdType;
import com.baomidou.mybatisplus.annotation.TableId;
import com.baomidou.mybatisplus.annotation.TableName;
import lombok.Data;

import java.time.LocalDate;
import java.time.LocalDateTime;

@Data
@TableName("UserReadingStats")
public class UserReadingStats {
    @TableId(type = IdType.ASSIGN_UUID)
    private String id;
    private String userId;
    private Integer currentStreakCount;
    private Integer longestStreakCount;
    private LocalDate lastAchieveDate; // DATE 类型
    private LocalDateTime updateTime;
}