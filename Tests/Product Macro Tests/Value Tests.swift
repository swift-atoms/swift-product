import Foundation
import Product_Macro
import Testing

@Value
private struct Pair<First, Second> {
    let first: First
    let second: Second

    init(first: First, second: Second) {
        self.first = first
        self.second = second
    }
}

@Value
private struct Unit {}

private struct Opaque {}

private func requireHashable<Value: Hashable>(_: Value) {}
private func requireComparable<Value: Comparable>(_: Value) {}
private func requireCodable<Value: Codable>(_: Value) {}
private func requireSendable<Value: Sendable>(_: Value) {}

@Suite
private struct `Value Tests` {
    @Test
    func `conformances are conditional on the parameters`() {
        let pair = Pair(first: 1, second: "b")
        requireHashable(pair)
        requireComparable(pair)
        requireCodable(pair)
        requireSendable(pair)
        _ = Pair(first: Opaque(), second: 1)
        requireHashable(Unit())
        requireComparable(Unit())
        requireCodable(Unit())
    }

    @Test
    func `equality and hashing are fieldwise`() {
        #expect(Pair(first: 1, second: "b") == Pair(first: 1, second: "b"))
        #expect(Pair(first: 1, second: "b") != Pair(first: 2, second: "b"))
        #expect(Pair(first: 1, second: "b").hashValue == Pair(first: 1, second: "b").hashValue)
        #expect(Unit() == Unit())
    }

    @Test
    func `comparison is lexicographic over the fields`() {
        #expect(Pair(first: 1, second: "z") < Pair(first: 2, second: "a"))
        #expect(Pair(first: 1, second: "a") < Pair(first: 1, second: "b"))
        #expect(!(Pair(first: 1, second: "a") < Pair(first: 1, second: "a")))
        #expect(!(Unit() < Unit()))
    }

    @Test
    func `coding round-trips through keyed containers`() throws {
        let pair = Pair(first: 1, second: "b")
        let data = try JSONEncoder().encode(pair)
        let object = try #require(JSONSerialization.jsonObject(with: data) as? [String: Any])
        #expect(object["first"] as? Int == 1)
        #expect(object["second"] as? String == "b")
        #expect(try JSONDecoder().decode(Pair<Int, String>.self, from: data) == pair)
        #expect(try JSONDecoder().decode(Unit.self, from: JSONEncoder().encode(Unit())) == Unit())
    }
}
