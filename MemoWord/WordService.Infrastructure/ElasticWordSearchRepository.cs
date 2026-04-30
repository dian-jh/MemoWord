using Elastic.Clients.Elasticsearch;
using WordService.Domain;
using WordService.Domain.Entities;

namespace WordService.Infrastructure;

public class ElasticWordSearchRepository : IWordSearchRepository
{
    private readonly ElasticsearchClient _elasticClient;

    public ElasticWordSearchRepository(ElasticsearchClient elasticClient)
    {
        _elasticClient = elasticClient;
    }

    public async Task<IReadOnlyList<Word>> SearchWordsAsync(string keyword, int limit, CancellationToken cancellationToken = default)
    {
        var searchResponse = await _elasticClient.SearchAsync<WordElasticDocument>(s => s
            .Index("words")
            .Size(limit)
            .Query(q => q
                .Match(m => m
                    .Field(f => f.WordContent) // 对应 "wordContent"
                    .Query(keyword)            // 对应 "query": "in"
                    .Fuzziness(new Fuzziness("AUTO")) // 对应 "fuzziness": "AUTO"
                    .PrefixLength(2)           // 对应 "prefix_length": 2
                )
            )
            , cancellationToken
        );

        // 【重要排错利器】：如果以后再遇到查不出来，立刻看控制台的这行红字！
        if (!searchResponse.IsValidResponse)
        {
            Console.WriteLine($"\n========== ES 查询大翻车 ==========\n");
            Console.WriteLine(searchResponse.DebugInformation);
            Console.WriteLine($"\n===================================\n");
            return Array.Empty<Word>();
        }

        return searchResponse.Documents.Select(doc =>
        {
            return new Word(doc.WordId, doc.WordContent, doc.PhoneticUs, doc.Translation);
        }).ToList();
    }
}
