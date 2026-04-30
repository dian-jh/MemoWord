package com.ebook.dto;

import lombok.Data;

import java.util.List;

// PATCH /api/v1/collections/order
@Data
public class CollectionOrderDTO {
    private List<OrderItem> orders;

    @Data
    public static class OrderItem {
        private String collectionId;
        private Integer sortOrder;
    }
}