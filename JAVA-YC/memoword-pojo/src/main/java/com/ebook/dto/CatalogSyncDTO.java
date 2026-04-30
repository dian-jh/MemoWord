package com.ebook.dto;

import lombok.Data;
import java.util.List;

// PUT /api/v1/library/books/{bookId}/catalogs
@Data
public class CatalogSyncDTO {
    private Boolean replaceAll;
    private List<CatalogItemDTO> items;
}