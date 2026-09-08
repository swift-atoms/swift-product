import Foundation
import Product_Foundation_Integration
import Testing

extension `Products preserve component arity through operations and checked conformances`.`Product operations preserve positional values arity and capabilities`.`Product coding is available when every component supports coding` {
    @Test
    func `Nullary products round trip as empty coordinate arrays`() throws {
        let original = Product()
        let encoded = try JSONEncoder().encode(original)
        let decoded = try JSONDecoder().decode(type(of: original), from: encoded)

        #expect(String(decoding: encoded, as: UTF8.self) == "[]")
        #expect(decoded == original)
    }

    @Test
    func `Singleton products round trip their sole coordinate`() throws {
        let original = Product(42)
        let encoded = try JSONEncoder().encode(original)
        let decoded = try JSONDecoder().decode(Product<Int>.self, from: encoded)

        #expect(String(decoding: encoded, as: UTF8.self) == "[42]")
        #expect(decoded.values == 42)
        #expect(decoded == original)
    }

    @Test
    func `Heterogeneous products round trip every coordinate in order`() throws {
        let original = Product(7, "value", true)
        let encoded = try JSONEncoder().encode(original)
        let decoded = try JSONDecoder().decode(Product<Int, String, Bool>.self, from: encoded)

        #expect(String(decoding: encoded, as: UTF8.self) == "[7,\"value\",true]")
        #expect(decoded.values.0 == 7)
        #expect(decoded.values.1 == "value")
        #expect(decoded.values.2)
        #expect(decoded == original)
    }

    @Test
    func `Decoding a singleton product rejects its missing coordinate`() throws {
        do {
            _ = try JSONDecoder().decode(Product<Int>.self, from: Data("[]".utf8))
            Issue.record("Expected a missing coordinate error")
        } catch DecodingError.valueNotFound(_, let context) {
            #expect(context.codingPath.last?.intValue == 0)
        }
    }

    @Test(arguments: [
        ("[]", 0),
        ("[7]", 1),
        ("[7,\"value\"]", 2),
    ])
    func `Decoding heterogeneous products identifies missing coordinates`(_ fixture: (String, Int)) throws {
        do {
            _ = try JSONDecoder().decode(
                Product<Int, String, Bool>.self,
                from: Data(fixture.0.utf8)
            )
            Issue.record("Expected a missing coordinate error")
        } catch DecodingError.valueNotFound(_, let context) {
            #expect(context.codingPath.last?.intValue == fixture.1)
        }
    }

    @Test(arguments: [
        ("[\"seven\",\"value\",true]", 0),
        ("[7,42,true]", 1),
        ("[7,\"value\",\"true\"]", 2),
    ])
    func `Decoding heterogeneous products identifies wrongly typed coordinates`(_ fixture: (String, Int)) throws {
        do {
            _ = try JSONDecoder().decode(
                Product<Int, String, Bool>.self,
                from: Data(fixture.0.utf8)
            )
            Issue.record("Expected a coordinate type mismatch")
        } catch DecodingError.typeMismatch(_, let context) {
            #expect(context.codingPath.last?.intValue == fixture.1)
        }
    }

    @Test
    func `Product decoding continues to ignore trailing coordinates`() throws {
        let empty = Product()
        let nullary = try JSONDecoder().decode(type(of: empty), from: Data("[99]".utf8))
        let singleton = try JSONDecoder().decode(Product<Int>.self, from: Data("[7,99]".utf8))
        let heterogeneous = try JSONDecoder().decode(
            Product<Int, String, Bool>.self,
            from: Data("[7,\"value\",true,99]".utf8)
        )

        #expect(nullary == empty)
        #expect(singleton == Product(7))
        #expect(heterogeneous == Product(7, "value", true))
    }
}
