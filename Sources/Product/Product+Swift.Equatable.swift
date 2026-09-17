extension Product: Swift.Equatable where repeat each Element: Swift.Equatable {

    @inlinable
    public static func == (lhs: borrowing Self, rhs: borrowing Self) -> Bool {
        func eq<T: Swift.Equatable>(_ a: borrowing T, _ b: borrowing T) -> Bool {
            a == b
        }
        for r in repeat eq(each lhs.values, each rhs.values) {
            if !r { return false }
        }
        return true
    }
}
