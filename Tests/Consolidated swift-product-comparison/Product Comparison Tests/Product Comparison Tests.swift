import Product
import Comparison
import Testing

@Suite
struct `Products expose comparison conformance through the legacy integration module` {

    @Test
    func `Products conform to Comparison when every element does`() {
        func less<T: Comparison.`Protocol`>(_ a: borrowing T, _ b: borrowing T) -> Bool { a < b }
        let a = Product(1, 2, 0)
        let b = Product(1, 3, 0)
        #expect(less(a, b))
        #expect(!less(b, a))
    }
}
