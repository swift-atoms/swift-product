/// Conditional capabilities follow stored component types. Phantom parameters are unconstrained.
/// Component witnesses and compiler checking establish eligibility; declarations alone do not prove laws.
@attached(extension, conformances: Swift.Equatable, names: named(==))
public macro StructuralEquatable() = #externalMacro(module: "Structural_Macro_Plugin", type: "StructuralEquatable")
@attached(extension, conformances: Swift.Hashable, names: named(hash(into:)))
public macro StructuralHashable() = #externalMacro(module: "Structural_Macro_Plugin", type: "StructuralHashable")
@attached(extension, conformances: Swift.Sendable)
public macro StructuralSendable() = #externalMacro(module: "Structural_Macro_Plugin", type: "StructuralSendable")
@attached(extension, conformances: Copyable)
public macro Copyable() = #externalMacro(module: "Structural_Macro_Plugin", type: "Copyable")
