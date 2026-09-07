import Equation
import Comparison
import Hash
import Product
import Testing

private func requireCopyable<Value: Copyable>(_: Value) {}
private func requireEscapable<Value: Escapable>(_: Value) {}

@Suite
struct `Product Tests` {
    @Suite struct Unit {}
    @Suite struct `Edge Case` {}
    @Suite struct Integration {}
    @Suite(.serialized) struct Performance {}
}

extension `Product Tests`.Unit {
    @Suite struct Construction {}
    @Suite struct Conformances {}
    @Suite struct Map {}
    @Suite struct Append {}
    @Suite struct Zip {}
    @Suite struct Fold {}
    @Suite struct Swap {}
    @Suite struct Codable {}
    @Suite struct Institute {}
    @Suite struct Bitwise {}
}

extension `Product Tests`.Unit.Construction {

    @Test
    func `nullary product has one empty coordinate family`() {
        let product = Product()

        #expect(MemoryLayout.size(ofValue: product) == 0)
    }

    @Test
    func `init holds component values`() {
        let pair = Product(1, "hello")
        #expect(pair.values.0 == 1)
        #expect(pair.values.1 == "hello")
    }

    @Test
    func `dynamic member lookup accesses tuple positions`() {
        let triple = Product(1, "hello", true)
        #expect(triple.0 == 1)
        #expect(triple.1 == "hello")
        #expect(triple.2 == true)
    }

    @Test
    func `dynamic positional projection reads and writes`() {
        var triple = Product(1, "hello", true)

        triple.0 = 2

        #expect(triple.0 == 2)
        #expect(triple.values.0 == 2)
    }

    @Test
    func `unary and binary products preserve their arity`() {
        let unary = Product(1)
        let binary = Product(1, "two")

        #expect(unary.values == 1)
        #expect(binary.values.0 == 1)
        #expect(binary.values.1 == "two")
    }

    @Test
    func `compiler-admitted element capabilities are preserved`() {
        let product = Product(1, "two", true)

        requireCopyable(product)
        requireEscapable(product)
    }
}

extension `Product Tests`.Unit.Conformances {

    @Test
    func `equatable compares all components`() {
        let a = Product(1, "x")
        let b = Product(1, "x")
        let c = Product(1, "y")
        #expect(a == b)
        #expect(a != c)
    }

    @Test
    func `hashable combines all components`() {
        let a = Product(1, "x", true)
        let b = Product(1, "x", true)
        #expect(a.hashValue == b.hashValue)
    }

    @Test
    func `comparable orders lexicographically by first differing position`() {
        let a = Product(1, "a", 0)
        let b = Product(1, "b", 0)
        let c = Product(1, "a", 1)
        #expect(a < b)
        #expect(a < c)
        #expect(!(a < a))
        #expect(b > a)
    }

    @Test
    func `comparable equal values yield neither lt nor gt`() {
        let a = Product(1, "x")
        let b = Product(1, "x")
        #expect(!(a < b))
        #expect(!(b < a))
    }

    @Test
    func `description renders parenthesized comma-separated components`() {
        let p = Product(1, "hi", true)
        #expect(p.description == "(1, hi, true)")
    }

    @Test
    func `error conformance available when components are errors`() {
        struct Failure: Swift.Error, Equatable {}
        struct Conflict: Swift.Error, Equatable {}
        let aggregated = Product(Failure(), Conflict())
        let asError: any Swift.Error = aggregated
        _ = asError
    }
}

extension `Product Tests`.Unit.Map {

    @Test
    func `map transforms every component preserving arity`() {
        let triple = Product(1, "hi", true)
        let mapped = triple.map(
            { $0 + 1 },
            { $0.uppercased() },
            { !$0 }
        )
        #expect(mapped.0 == 2)
        #expect(mapped.1 == "HI")
        #expect(mapped.2 == false)
    }

    @Test
    func `map preserves binary arity`() {
        let pair = Product(3, "x")
        let mapped = pair.map(
            { $0 * 2 },
            { "[\($0)]" }
        )
        #expect(mapped.0 == 6)
        #expect(mapped.1 == "[x]")
    }

    @Test
    func `map propagates typed throws`() {
        struct Boom: Swift.Error, Equatable {}
        let pair = Product(1, 2)
        do throws(Boom) {
            _ = try pair.map(
                { (_: Int) throws(Boom) -> Int in throw Boom() },
                { (x: Int) throws(Boom) -> Int in x }
            )
            Issue.record("expected throw")
        } catch {
            #expect(error == Boom())
        }
    }

    @Test
    func `map with identity preserves untouched positions`() {
        let triple = Product(1, "x", true)

        let firstOnly = triple.map({ $0 + 10 }, { $0 }, { $0 })
        #expect(firstOnly.0 == 11)
        #expect(firstOnly.1 == "x")
        #expect(firstOnly.2 == true)

        let secondOnly = triple.map({ $0 }, { $0.uppercased() }, { $0 })
        #expect(secondOnly.0 == 1)
        #expect(secondOnly.1 == "X")
        #expect(secondOnly.2 == true)

        let firstAndThird = triple.map({ $0 + 10 }, { $0 }, { !$0 })
        #expect(firstAndThird.0 == 11)
        #expect(firstAndThird.1 == "x")
        #expect(firstAndThird.2 == false)
    }
}

extension `Product Tests`.Unit.Append {

    @Test
    func `append extends the pack on the right`() {
        let pair = Product(1, "hi")
        let triple = pair.append(true)
        #expect(triple.0 == 1)
        #expect(triple.1 == "hi")
        #expect(triple.2 == true)
    }

    @Test
    func `prepend extends the pack on the left`() {
        let pair = Product(1, "hi")
        let triple = pair.prepend(0.5)
        #expect(triple.0 == 0.5)
        #expect(triple.1 == 1)
        #expect(triple.2 == "hi")
    }

    @Test
    func `append on singleton produces pair`() {
        let single = Product(42)
        let pair = single.append("y")
        #expect(pair.0 == 42)
        #expect(pair.1 == "y")
    }
}

extension `Product Tests`.Unit.Zip {

    @Test
    func `zip pairs corresponding components`() {
        let a = Product(1, "hi")
        let b = Product(true, 0.5)
        let z = a.zip(b)
        #expect(z.values.0.0 == 1)
        #expect(z.values.0.1 == true)
        #expect(z.values.1.0 == "hi")
        #expect(z.values.1.1 == 0.5)
    }

    @Test
    func `zip on ternary produces ternary of pairs`() {
        let a = Product(1, "x", true)
        let b = Product(0.5, 99, "y")
        let z = a.zip(b)
        #expect(z.values.0.0 == 1)
        #expect(z.values.0.1 == 0.5)
        #expect(z.values.1.0 == "x")
        #expect(z.values.1.1 == 99)
        #expect(z.values.2.0 == true)
        #expect(z.values.2.1 == "y")
    }
}

extension `Product Tests`.Unit.Fold {

    @Test
    func `fold collapses components via closure`() {
        let triple = Product(1, "hi", true)
        let s = triple.fold { a, b, c in "\(a) \(b) \(c)" }
        #expect(s == "1 hi true")
    }

    @Test
    func `fold on pair sums components`() {
        let pair = Product(2, 3)
        let total = pair.fold { $0 + $1 }
        #expect(total == 5)
    }

    @Test
    func `fold propagates typed throws`() {
        struct Boom: Swift.Error, Equatable {}
        let pair = Product(1, 2)

        do throws(Boom) {

            _ = try pair.fold { (_, _) throws(Boom) -> Int in throw Boom() }
            Issue.record("expected throw")
        } catch {
            #expect(error == Boom())
        }
    }
}

extension `Product Tests`.Unit.Swap {

    @Test
    func `swapped reverses a binary product`() {
        let pair = Product(1, "hi")
        let flipped = swapped(pair)
        #expect(flipped.0 == "hi")
        #expect(flipped.1 == 1)
    }

    @Test
    func `swapped is involutive`() {
        let pair = Product(1, "hi")
        let twice = swapped(swapped(pair))
        #expect(twice.0 == 1)
        #expect(twice.1 == "hi")
    }
}

extension `Product Tests`.Unit.Codable {

    @Test
    func `Product is Codable when each element is Codable`() {
        func _requireCodable<T: Codable>(_: T.Type) {}
        _requireCodable(Product<Int, String>.self)
        _requireCodable(Product<Int, String, Bool>.self)
        _requireCodable(Product<Double>.self)
    }
}

extension `Product Tests`.Unit.Institute {

    @Test
    func `conforms to Equation_Protocol when each element does`() {
        func eq<T: Equation::Equation.`Protocol`>(_ a: borrowing T, _ b: borrowing T) -> Bool {
            a == b
        }
        let a = Product(1, "x")
        let b = Product(1, "x")
        let c = Product(1, "y")
        #expect(eq(a, b))
        #expect(!eq(a, c))
    }

    @Test
    func `conforms to Hash_Protocol when each element does`() {
        func hashed<T: Hash::Hash.`Protocol`>(_ x: borrowing T) -> Int {
            var hasher = Hasher()
            x.hash(into: &hasher)
            return hasher.finalize()
        }
        let a = Product(1, "x", true)
        let b = Product(1, "x", true)
        #expect(hashed(a) == hashed(b))
    }

    @Test
    func `conforms to Comparison_Protocol when each element does`() {
        func less<T: Comparison::Comparison.`Protocol`>(
            _ a: borrowing T,
            _ b: borrowing T
        ) -> Bool { a < b }
        let a = Product(1, 2, 0)
        let b = Product(1, 3, 0)
        #expect(less(a, b))
        #expect(!less(b, a))
    }
}

extension `Product Tests`.Unit.Bitwise {

    @Test
    func `Product is BitwiseCopyable when each element is BitwiseCopyable`() {
        func requires<T: BitwiseCopyable>(_: T.Type) {}
        requires(Product<Int>.self)
        requires(Product<Int, Int>.self)
        requires(Product<Int, Int, Int>.self)
        requires(Product<Int, Double, Bool>.self)
    }

    @Test
    func `MemoryLayout matches the underlying tuple`() {
        #expect(MemoryLayout<Product<Int, Int, Int>>.size == MemoryLayout<(Int, Int, Int)>.size)
        #expect(MemoryLayout<Product<Int, Int, Int>>.stride == MemoryLayout<(Int, Int, Int)>.stride)
        #expect(
            MemoryLayout<Product<Int, Double, Bool>>.size == MemoryLayout<(Int, Double, Bool)>.size
        )
        #expect(MemoryLayout<Product<Int>>.size == MemoryLayout<Int>.size)
    }

    @Test
    func `InlineArray of Product is constructible`() {
        let triple = Product(1, 2, 3)
        let array: InlineArray<4, Product<Int, Int, Int>> = .init(repeating: triple)
        #expect(array[0].0 == 1)
        #expect(array[3].2 == 3)
    }
}
