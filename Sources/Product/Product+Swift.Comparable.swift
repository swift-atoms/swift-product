extension Product: Swift.Comparable where repeat each Element: Swift.Comparable {

    @inlinable
    public static func < (lhs: borrowing Self, rhs: borrowing Self) -> Bool {
        func order<T: Swift.Comparable>(_ a: borrowing T, _ b: borrowing T) -> Int {
            if a < b { return -1 }
            if b < a { return 1 }
            return 0
        }
        for o in repeat order(each lhs.values, each rhs.values) {
            if o < 0 { return true }
            if o > 0 { return false }
        }
        return false
    }
}
