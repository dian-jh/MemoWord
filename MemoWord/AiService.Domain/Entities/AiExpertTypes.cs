namespace AiService.Domain.Entities;

public static class AiExpertTypes
{
    public const string Translator = "TRANSLATOR";
    public const string GrammarExpert = "GRAMMAR_EXPERT";
    public const string VocabCoach = "VOCAB_COACH";
    public const string WritingPolisher = "WRITING_POLISHER";

    public static bool IsSupported(string sessionKey)
    {
        return sessionKey == Translator
            || sessionKey == GrammarExpert
            || sessionKey == VocabCoach
            || sessionKey == WritingPolisher;
    }
}
