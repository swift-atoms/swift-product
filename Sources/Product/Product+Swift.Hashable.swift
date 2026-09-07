extension Product: Swift.Hashable where repeat each Element: Swift.Hashable {

    @inlinable
    public func hash(into hasher: inout Hasher) {
        func combine<T: Swift.Hashable>(_ x: T, into hasher: inout Hasher) {
            hasher.combine(x)
        }
        repeat combine(each values, into: &hasher)
    }
}
