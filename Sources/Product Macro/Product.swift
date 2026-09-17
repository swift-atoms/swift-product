@attached(peer, names: named(Product), prefixed(__))
@attached(extension, names: named(Product))
public macro Product() = #externalMacro(
    module: "Product_Macro_Plugin",
    type: "Macro"
)

@attached(extension, conformances: Equatable, Hashable, Comparable, Encodable, Decodable, Sendable, names: named(<), named(CodingKeys), named(encode(to:)), named(init(from:)))
public macro Value() = #externalMacro(
    module: "Product_Macro_Plugin",
    type: "Value"
)
