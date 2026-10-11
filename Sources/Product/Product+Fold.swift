extension Product {

    @inlinable
    public consuming func fold<R, E: Swift::Error>(
        _ body: (repeat each Element) throws(E) -> R
    ) throws(E) -> R {
        try body(repeat each values)
    }
}

extension Product {

    @inlinable
    public static func fold<R, E: Swift::Error>(
        _ product: consuming Product,
        _ body: (repeat each Element) throws(E) -> R
    ) throws(E) -> R {
        try product.fold(body)
    }
}
