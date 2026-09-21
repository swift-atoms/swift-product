import Product_Macro
import Testing

private struct Pair<First, Second> {
    let first: First
    let second: Second

    init(first: First, second: Second) {
        self.first = first
        self.second = second
    }
}

private struct Unit {}

private enum Choice<Left, Right> {
    case left(Left)
    case right(Right)
    case neither
}

private enum Token<Payload: ~Copyable>: ~Copyable {
    case token(Payload)
}

private struct Opaque {}
private struct Linear: ~Copyable {}

private func requireHashable<Value: Hashable>(_: Value) {}
private func requireSendable<Value: Sendable & ~Copyable>(_: borrowing Value) {}
private func requireCopyable<Value: Copyable>(_: Value) {}
private func requireNoncopyable<Value: ~Copyable>(_: consuming Value) {}

@Suite
private struct `Structural Tests` {
    @Test
    func `a product has a capability exactly when every parameter has it`() {
        let pair = Pair(first: 1, second: "b")
        requireHashable(pair)
        requireSendable(pair)
        _ = Pair(first: Opaque(), second: 1)
        requireHashable(Unit())
        #expect(Pair(first: 1, second: "b") == Pair(first: 1, second: "b"))
        #expect(Pair(first: 1, second: "b") != Pair(first: 2, second: "b"))
        #expect(Pair(first: 1, second: "b").hashValue == Pair(first: 1, second: "b").hashValue)
        #expect(Unit() == Unit())
    }

    @Test
    func `a coproduct has a capability exactly when every summand has it`() {
        requireHashable(Choice<Int, String>.left(1))
        requireSendable(Choice<Int, String>.neither)
        _ = Choice<Opaque, Int>.right(1)
        #expect(Choice<Int, String>.left(1) == .left(1))
        #expect(Choice<Int, String>.left(1) != .right("1"))
        #expect(Choice<Int, String>.neither == .neither)
        #expect(Choice<Int, String>.left(1).hashValue == Choice<Int, String>.left(1).hashValue)
    }

    @Test
    func `a suppressed Copyable returns exactly when every summand has it`() {
        requireCopyable(Token<Int>.token(1))
        requireHashable(Token<Int>.token(1))
        requireNoncopyable(Token<Linear>.token(Linear()))
    }
}

private enum LabeledPayload {
    case pair(left: Int, right: String)
    case empty
}
@Test func structuralCapabilitiesHandleEveryAssociatedValue() {
    #expect(LabeledPayload.pair(left: 1, right: "a") == .pair(left: 1, right: "a"))
    #expect(LabeledPayload.pair(left: 1, right: "a") != .pair(left: 1, right: "b"))
    #expect(Set([LabeledPayload.pair(left: 1, right: "a"), .pair(left: 1, right: "a")]).count == 1)
}

private struct Phantom<Value: ~Copyable> { let tag: Int }
@Test func phantomParametersDoNotImposeCapabilities() {
    let value = Phantom<Linear>(tag: 1)
    requireHashable(value)
    requireSendable(value)
    requireCopyable(value)
    #expect(value == Phantom<Linear>(tag: 1))
    #expect(value.hashValue == Phantom<Linear>(tag: 1).hashValue)
}

extension Pair: Equatable where First: Equatable, Second: Equatable {}
extension Pair: Hashable where First: Hashable, Second: Hashable {}
extension Pair: Sendable where First: Sendable, Second: Sendable {}
extension Unit: Equatable, Hashable, Sendable {}
extension Choice: Equatable where Left: Equatable, Right: Equatable {}
extension Choice: Hashable where Left: Hashable, Right: Hashable {}
extension Choice: Sendable where Left: Sendable, Right: Sendable {}
extension Token: Copyable where Payload: Copyable {}
extension Token: Sendable where Payload: Sendable & ~Copyable {}
extension Token: Equatable where Payload: Equatable {
    static func == (lhs: Self, rhs: Self) -> Bool {
        switch (lhs, rhs) { case let (.token(lhs), .token(rhs)): lhs == rhs }
    }
}
extension Token: Hashable where Payload: Hashable {
    func hash(into hasher: inout Hasher) {
        switch self { case let .token(value): hasher.combine(value) }
    }
}
extension LabeledPayload: Equatable, Hashable {}
extension Phantom: Equatable, Hashable, Sendable where Value: ~Copyable {}

@_Structural
private enum Compared<Value: ~Copyable>: ~Copyable {
    case pair(Value, Value)
}

private final class Comparisons {
    var visited: [Int] = []
}

private struct RecordedEquality: Equatable {
    let coordinate: Int
    let value: Bool
    let comparisons: Comparisons

    static func == (lhs: Self, rhs: Self) -> Bool {
        lhs.comparisons.visited.append(lhs.coordinate)
        return lhs.value == rhs.value
    }
}

@Test(arguments: [false, true])
private func derivedEqualityPreservesShortCircuitOrder(firstMatches: Bool) {
    let comparisons = Comparisons()
    let lhs = Compared.pair(
        RecordedEquality(coordinate: 0, value: firstMatches, comparisons: comparisons),
        RecordedEquality(coordinate: 1, value: false, comparisons: comparisons)
    )
    let rhs = Compared.pair(
        RecordedEquality(coordinate: 0, value: true, comparisons: comparisons),
        RecordedEquality(coordinate: 1, value: true, comparisons: comparisons)
    )
    #expect(lhs != rhs)
    #expect(comparisons.visited == (firstMatches ? [0, 1] : [0]))
}
