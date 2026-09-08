import Product
import Equation
import Testing

@Suite
struct `Products expose equation conformance through the legacy integration module` {

    @Test
    func `Products conform to Equation when every element does`() {
        func eq<T: Equation.`Protocol`>(_ a: borrowing T, _ b: borrowing T) -> Bool { a == b }
        let a = Product(1, "x")
        let b = Product(1, "x")
        let c = Product(1, "y")
        #expect(eq(a, b))
        #expect(!eq(a, c))
    }
}
