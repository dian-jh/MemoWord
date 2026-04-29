using AiService.Infrastructure.Entities;
using Microsoft.EntityFrameworkCore;
using Microsoft.EntityFrameworkCore.Metadata.Builders;

namespace AiService.Infrastructure.Configs;

public class WordLookupConfiguration : IEntityTypeConfiguration<WordLookupEntity>
{
    public void Configure(EntityTypeBuilder<WordLookupEntity> builder)
    {
        builder.ToTable("english_chinese_words");

        builder.HasKey(x => x.Id);

        builder.Property(x => x.Id)
            .HasColumnName("word_id")
            .ValueGeneratedNever();

        builder.Property(x => x.WordContent)
            .HasColumnName("word_content")
            .HasMaxLength(100)
            .IsRequired();
    }
}
