using Microsoft.EntityFrameworkCore;
using Microsoft.EntityFrameworkCore.Metadata.Builders;
using System;
using System.Collections.Generic;
using System.Text;
using WordService.Domain.Entities;

namespace WordService.Infrastructure.Configs;

public class UserFavoriteConfiguration : IEntityTypeConfiguration<UserFavorite>
{
    public void Configure(EntityTypeBuilder<UserFavorite> builder)
    {
        builder.ToTable("userfavorite");

        builder.HasKey(e => e.Id);

        builder.Property(e => e.Id)
            .HasColumnType("char(36)")
            .IsRequired();

        builder.Property(e => e.UserId)
            .HasColumnType("char(36)")
            .IsRequired();

        builder.Property(e => e.WordId)
            .HasColumnName("WordId")
            .IsRequired();

        builder.Property(e => e.CreateTime)
            .HasDefaultValueSql("CURRENT_TIMESTAMP")
            .IsRequired();

        // 联合唯一索引
        builder.HasIndex(e => new { e.UserId, e.WordId })
            .IsUnique()
            .HasDatabaseName("UK_User_Word");

        // 普通索引用于加速查询
        builder.HasIndex(e => e.UserId)
            .HasDatabaseName("idx_user_id");
    }
}
