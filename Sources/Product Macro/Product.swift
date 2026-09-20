@_exported import Structural_Macro

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

/// Construct a stored-value product, preserving declaration order and defaults.
@attached(member, names: named(init))
public macro Memberwise() = #externalMacro(module: "Product_Macro_Plugin", type: "Memberwise")

/// Select the writable product complementary to the named identity/metadata fields.
@attached(member, names: named(Draft), named(draft), named(init))
public macro Draft(excluding fields: String...) = #externalMacro(module: "Product_Macro_Plugin", type: "Draft")
