@_exported import Structural_Macro

@attached(peer, names: named(Product))
public macro Product() = #externalMacro(
    module: "Product_Macro_Plugin",
    type: "Macro"
)

@attached(member, names: named(init))
public macro Memberwise() = #externalMacro(module: "Product_Macro_Plugin", type: "Memberwise")

@attached(member, names: named(Draft), named(draft), named(init))
public macro Draft(excluding fields: String...) = #externalMacro(module: "Product_Macro_Plugin", type: "Draft")
