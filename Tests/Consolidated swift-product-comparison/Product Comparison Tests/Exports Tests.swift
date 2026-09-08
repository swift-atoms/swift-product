import Comparison
import Product
import Testing

@Suite
struct `Legacy product comparison imports expose the product and comparison APIs` {
    @Test
    func `Products retain comparison conformance through the legacy import`() {
        func less<Value: Comparison::Comparison.`Protocol`>(_ first: Value, _ second: Value) -> Bool {
            first < second
        }

        #expect(less(Product(1, "a"), Product(1, "b")))
        #expect(!less(Product(2, "a"), Product(1, "b")))
    }
}
