@_exported public import Comparison
@_exported public import Equation
@_exported public import Hash

@dynamicMemberLookup
@frozen
public struct Product<each Element> {




    public var values: (repeat each Element)

    @inlinable
    public init(_ values: repeat each Element) {
        self.values = (repeat each values)
    }
}

extension Product {

    @inlinable
    public subscript<T>(dynamicMember keyPath: KeyPath<(repeat each Element), T>) -> T {
        values[keyPath: keyPath]
    }

    @inlinable
    public subscript<T>(
        dynamicMember keyPath: WritableKeyPath<(repeat each Element), T>
    ) -> T {
        get { values[keyPath: keyPath] }
        set { values[keyPath: keyPath] = newValue }
    }
}

extension Product: Swift.Sendable where repeat each Element: Swift.Sendable {}
