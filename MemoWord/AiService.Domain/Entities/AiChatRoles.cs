namespace AiService.Domain.Entities;

public static class AiChatRoles
{
    public const string System = "system";
    public const string User = "user";
    public const string Assistant = "assistant";

    public static bool IsValid(string role)
    {
        return role == System || role == User || role == Assistant;
    }
}
