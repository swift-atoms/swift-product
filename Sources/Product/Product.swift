@_exported public import Comparison
@_exported public import Equation
@_exported public import Hash

@dynamicMemberLookup
@frozen
public struct Product<each Element> {

    // Swift 6.4 does not permit `~Copyable` or `~Escapable` suppression on an
    // `each` parameter. The element capabilities are therefore a compiler
    // concession of this variadic representation rather than an algebraic law.
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

extension Product: Sendable where repeat each Element: Sendable {}
