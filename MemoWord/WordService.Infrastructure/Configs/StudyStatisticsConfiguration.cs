using Microsoft.EntityFrameworkCore;
using Microsoft.EntityFrameworkCore.Metadata.Builders;
using System;
using System.Collections.Generic;
using System.Text;
using WordService.Domain.Entities;

namespace WordService.Infrastructure.Configs;

public class StudyStatisticsConfiguration : IEntityTypeConfiguration<StudyStatistics>
{
    public void Configure(EntityTypeBuilder<StudyStatistics> builder)
    {
        // 映射表名
        builder.ToTable("StudyStatistics");

        // 主键配置
        builder.HasKey(s => s.Id);
        builder.Property(s => s.Id)
               .HasColumnName("Id")
               .HasColumnType("char(36)")
               .ValueGeneratedNever();

        // 字段映射
        builder.Property(s => s.UserId)
               .HasColumnName("UserId")
               .HasColumnType("char(36)")
               .IsRequired();

        builder.Property(s => s.StatDate)
               .HasColumnName("StatDate")
               .HasColumnType("date")
               .IsRequired();

        builder.Property(s => s.LearnedCount)
               .HasColumnName("LearnedCount")
               .HasDefaultValue(0);

        builder.Property(s => s.TargetCount)
               .HasColumnName("TargetCount")
               .HasDefaultValue(100);

        builder.Property(s => s.StudyDuration)
               .HasColumnName("StudyDuration")
               .HasDefaultValue(0);

        // 时间戳配置
        builder.Property(s => s.CreateTime)
               .HasColumnName("CreateTime")
               .HasDefaultValueSql("CURRENT_TIMESTAMP")
               .ValueGeneratedOnAdd();

        builder.Property(s => s.UpdateTime)
               .HasColumnName("UpdateTime")
               .HasDefaultValueSql("CURRENT_TIMESTAMP")
               .ValueGeneratedOnAddOrUpdate();

        // 唯一索引配置 (对应你 SQL 中的 UNIQUE KEY)
        builder.HasIndex(s => new { s.UserId, s.StatDate })
               .IsUnique()
               .HasDatabaseName("UK_User_Date");
    }
}