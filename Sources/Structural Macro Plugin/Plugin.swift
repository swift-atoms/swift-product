import SwiftCompilerPlugin
import SwiftSyntaxMacros
@main struct Plugin: CompilerPlugin {
    let providingMacros: [any SwiftSyntaxMacros.Macro.Type] = [StructuralEquatable.self, StructuralHashable.self, StructuralSendable.self, Copyable.self]
}
