import Hash
import Product
import Testing

@Suite
struct `Legacy product hash imports expose the product and hash APIs` {
    @Test
    func `Products retain domain typed hash values through the legacy import`() {
        func hash<Value: Hash::Hash.`Protocol`>(_ value: borrowing Value) -> Hash::Hash.Value {
            value.hashValue
        }

        let first: Hash::Hash.Value = hash(Product(1, "value", true))
        let second: Hash::Hash.Value = hash(Product(1, "value", true))
        #expect(first == second)
    }
}
