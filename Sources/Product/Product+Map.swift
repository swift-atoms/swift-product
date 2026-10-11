extension Product {

    @inlinable
    public consuming func map<each NewElement, E: Swift::Error>(
        _ transforms: repeat (each Element) throws(E) -> each NewElement
    ) throws(E) -> Product<repeat each NewElement> {
        Product<repeat each NewElement>(
            repeat try (each transforms)(each values)
        )
    }
}

extension Product {

    @inlinable
    public static func map<each NewElement, E: Swift::Error>(
        _ product: consuming Product,
        _ transforms: repeat (each Element) throws(E) -> each NewElement
    ) throws(E) -> Product<repeat each NewElement> {
        try product.map(repeat each transforms)
    }
}
