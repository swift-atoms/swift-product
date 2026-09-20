/// Compiler hook for generated generic sums; use native conformances on source declarations.
@attached(extension, conformances: Swift.Equatable, Swift.Hashable, Swift.Sendable, Swift.Copyable, names: named(==), named(hash(into:)))
public macro _Structural() = #externalMacro(module: "Structural_Macro_Plugin", type: "Macro")
