using System;
using System.Collections.Generic;
using System.Text;
using WordService.Domain.Entities;

namespace WordService.Domain;

public interface IWordSearchRepository
{
    Task<IReadOnlyList<Word>> SearchWordsAsync(string keyword, int limit, CancellationToken cancellationToken = default);
}