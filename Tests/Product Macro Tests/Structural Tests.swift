import Product_Macro
import Testing

@StructuralEquatable
@StructuralHashable
@StructuralSendable
private struct Pair<First, Second> {
    let first: First
    let second: Second

    init(first: First, second: Second) {
        self.first = first
        self.second = second
    }
}

@StructuralEquatable
@StructuralHashable
@StructuralSendable
private struct Unit {}

@StructuralEquatable
@StructuralHashable
@StructuralSendable
private enum Choice<Left, Right> {
    case left(Left)
    case right(Right)
    case neither
}

@StructuralEquatable
@StructuralHashable
@StructuralSendable
@Copyable
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

@StructuralEquatable
@StructuralHashable
private enum LabeledPayload {
    case pair(left: Int, right: String)
    case empty
}
@Test func structuralCapabilitiesHandleEveryAssociatedValue() {
    #expect(LabeledPayload.pair(left: 1, right: "a") == .pair(left: 1, right: "a"))
    #expect(LabeledPayload.pair(left: 1, right: "a") != .pair(left: 1, right: "b"))
    #expect(Set([LabeledPayload.pair(left: 1, right: "a"), .pair(left: 1, right: "a")]).count == 1)
}

@StructuralEquatable @StructuralHashable @StructuralSendable
private struct Phantom<Value: ~Copyable> { let tag: Int }
@Test func phantomParametersDoNotImposeCapabilities() {
    let value = Phantom<Linear>(tag: 1)
    requireHashable(value)
    requireSendable(value)
    requireCopyable(value)
    #expect(value == Phantom<Linear>(tag: 1))
    #expect(value.hashValue == Phantom<Linear>(tag: 1).hashValue)
}
