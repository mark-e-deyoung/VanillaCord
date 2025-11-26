package io.netty.util;

public final class AttributeKey<T> {
    private AttributeKey() {}

    public static <T> AttributeKey<T> valueOf(String name) {
        return new AttributeKey<>();
    }
}
