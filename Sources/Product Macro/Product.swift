// The product of a protocol: a struct named `Product` beside it, storing one arrow per operation and one value
// per getter, witnessing the protocol by forwarding. The name is fixed by the platform (a peer may only carry a
// statically declared name), so the protocol is meant to be nested and its domain supplies the name
// (`Greeting.Product`); at file scope the peer would be a file-scope `Product`. The nesting is not diagnosed:
// a macro attached inside another macro's output sees no lexical context.
@attached(peer, names: named(Product))
public macro Product() = #externalMacro(
    module: "Product_Macro_Plugin",
    type: "Macro"
)

// A generic structure has a capability exactly when every parameter has it. This is what the compiler would
// synthesize for a generic type if it synthesized conditional conformances, and what the library's
// `Product<each Element>` and `Coproduct<each Element>` spell by hand; it stands in for those until a generated
// type can be one of them (variadic enums). Sendable is derived for convenience only, never relied upon.
@attached(extension, conformances: Swift.Sendable, Swift.Equatable, Swift.Hashable, names: named(==), named(hash(into:)))
public macro Structural() = #externalMacro(
    module: "Product_Macro_Plugin",
    type: "Structural"
)

// The same law for Copyable on a generic structure that suppressed it: Copyable returns exactly when every
// parameter has it. Attach beside @Structural. Listing Copyable in a macro's conformances is what lets the
// compiler treat the attached declaration as suppressing it, which is why this is not a parameter of @Structural.
@attached(extension, conformances: Copyable)
public macro Copyable() = #externalMacro(
    module: "Product_Macro_Plugin",
    type: "Copyable"
)
