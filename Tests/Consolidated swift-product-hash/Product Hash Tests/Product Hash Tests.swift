import Hash
import Product
import Testing

@Suite
struct `Products expose hash conformance through the legacy integration module` {

    @Test
    func `Product supplies Hash's domain-typed value`() {
        let first = Product(1, "x", true)
        let second = Product(1, "x", true)

        let firstHash: Hash.Value = hash(first)
        let secondHash: Hash.Value = hash(second)
        #expect(firstHash == secondHash)
    }

    @Test
    func `Product retains atom-owned native Hashable behavior`() {
        let first = Product(1, "x", true)
        let equal = Product(1, "x", true)
        let different = Product(2, "x", true)

        #expect(Set([first, equal, different]).count == 2)
    }
}

private func hash<T: Hash.`Protocol`>(_ value: borrowing T) -> Hash.Value {
    value.hashValue
}
