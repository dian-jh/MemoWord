using Microsoft.EntityFrameworkCore;
using Microsoft.EntityFrameworkCore.Metadata.Builders;
using WordService.Domain.Entities;

namespace WordService.Infrastructure.Configs;

public class WordConfiguration : IEntityTypeConfiguration<Word>
{
    public void Configure(EntityTypeBuilder<Word> builder)
    {
        // 映射到表
        builder.ToTable("english_chinese_words");

        // 主键配置：由于 ID 由外部（CSV）提供，关闭自增
        builder.HasKey(w => w.Id);
        builder.Property(w => w.Id)
               .HasColumnName("word_id")
               .ValueGeneratedNever();

        // 字段映射
        builder.Property(w => w.WordContent)
               .HasColumnName("word_content")
               .HasMaxLength(100)
               .IsRequired();

        builder.Property(w => w.PhoneticEn)
               .HasColumnName("phonetic_en")
               .HasMaxLength(100);

        builder.Property(w => w.PhoneticUs)
               .HasColumnName("phonetic_us")
               .HasMaxLength(100);

        builder.Property(w => w.Definition)
               .HasColumnName("definition")
               .HasColumnType("text");

        builder.Property(w => w.Translation)
               .HasColumnName("translation")
               .HasColumnType("text");

        builder.Property(w => w.WordTags)
               .HasColumnName("word_tags")
               .HasMaxLength(255);

        builder.Property(w => w.WordExchanges)
               .HasColumnName("word_exchanges")
               .HasMaxLength(255);

        builder.Property(w => w.BncLevel).HasColumnName("bnc_level");
        builder.Property(w => w.FrqLevel).HasColumnName("frq_level");
        builder.Property(w => w.CollinsLevel).HasColumnName("collins_level");
        builder.Property(w => w.OxfordLevel).HasColumnName("oxford_level");

        builder.Property(w => w.ExampleSentences)
               .HasColumnName("example_sentences")
               .HasColumnType("longtext");

        // 索引配置
        builder.HasIndex(w => w.WordContent)
               .HasDatabaseName("idx_word_content");
    }
}