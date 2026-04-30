using System;
using System.Collections.Generic;
using System.Text;
using WordService.Domain.Entities;

namespace WordService.Domain.Models;

public class WordWithFavoriteModel
{
    // 包含 Word 的所有字段（这里为了简便直接组合 Word 对象，或者平铺字段）
    public Word Word { get; set; } = null!;

    // 是否已收藏
    public bool IsFavorite { get; set; }
}
