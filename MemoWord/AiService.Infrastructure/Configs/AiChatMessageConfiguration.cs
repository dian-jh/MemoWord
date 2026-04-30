using AiService.Domain.Entities;
using Microsoft.EntityFrameworkCore;
using Microsoft.EntityFrameworkCore.Metadata.Builders;

namespace AiService.Infrastructure.Configs;

public class AiChatMessageConfiguration : IEntityTypeConfiguration<AiChatMessage>
{
    public void Configure(EntityTypeBuilder<AiChatMessage> builder)
    {
        builder.ToTable("ai_chat_messages");

        builder.HasKey(x => x.Id);

        builder.Property(x => x.Id)
            .HasColumnName("id")
            .HasColumnType("char(36)")
            .ValueGeneratedNever()
            .IsRequired();

        builder.Property(x => x.SessionId)
            .HasColumnName("session_id")
            .HasColumnType("char(36)")
            .IsRequired();

        builder.Property(x => x.UserId)
            .HasColumnName("user_id")
            .HasColumnType("char(36)")
            .IsRequired();

        builder.Property(x => x.Role)
            .HasColumnName("role")
            .HasMaxLength(20)
            .IsRequired();

        builder.Property(x => x.Content)
            .HasColumnName("content")
            .HasColumnType("longtext")
            .IsRequired();

        builder.Property(x => x.CreateTime)
            .HasColumnName("create_time")
            .HasColumnType("datetime(6)")
            .HasDefaultValueSql("CURRENT_TIMESTAMP(6)")
            .IsRequired();

        builder.HasIndex(x => new { x.SessionId, x.CreateTime })
            .HasDatabaseName("idx_ai_chat_message_session_time");

        builder.HasIndex(x => new { x.UserId, x.SessionId, x.CreateTime })
            .HasDatabaseName("idx_ai_chat_message_user_session_time");

        builder.HasOne<AiChatSession>()
            .WithMany()
            .HasForeignKey(x => x.SessionId)
            .OnDelete(DeleteBehavior.Cascade);
    }
}
