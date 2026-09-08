import Equation
import Product
import Testing

@Suite
struct `Legacy product equation imports expose the product and equation APIs` {
    @Test
    func `Products retain equation conformance through the legacy import`() {
        func equal<Value: Equation::Equation.`Protocol`>(_ first: Value, _ second: Value) -> Bool {
            first == second
        }

        #expect(equal(Product(1, "value"), Product(1, "value")))
        #expect(!equal(Product(1, "value"), Product(1, "different")))
    }
}
