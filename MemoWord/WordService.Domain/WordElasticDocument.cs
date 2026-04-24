using System;
using System.Collections.Generic;
using System.Text;

namespace WordService.Domain;

public class WordElasticDocument
{
    public int WordId { get; set; }
    public string WordContent { get; set; } = string.Empty;
    public string? PhoneticUs { get; set; }
    public string? Translation { get; set; }
}
