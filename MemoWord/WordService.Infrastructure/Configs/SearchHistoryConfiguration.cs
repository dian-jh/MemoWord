using Microsoft.EntityFrameworkCore;
using Microsoft.EntityFrameworkCore.Metadata.Builders;
using WordService.Domain.Entities;

namespace WordService.Infrastructure.Configs;

public class SearchHistoryConfiguration : IEntityTypeConfiguration<SearchHistory>
{
    public void Configure(EntityTypeBuilder<SearchHistory> builder)
    {
        builder.ToTable("searchhistory");

        builder.HasKey(x => x.Id);

        builder.Property(x => x.Id)
            .HasColumnType("char(36)")
            .ValueGeneratedNever()
            .IsRequired();

        builder.Property(x => x.UserId)
            .HasColumnType("char(36)")
            .IsRequired();

        builder.Property(x => x.WordId)
            .HasColumnName("WordId")
            .IsRequired();

        builder.Property(x => x.CreateTime)
            .HasColumnName("CreateTime")
            .HasDefaultValueSql("CURRENT_TIMESTAMP")
            .IsRequired();

        builder.HasIndex(x => new { x.UserId, x.CreateTime })
            .HasDatabaseName("idx_search_user_time");
    }
}
