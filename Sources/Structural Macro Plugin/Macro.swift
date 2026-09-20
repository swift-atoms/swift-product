import SwiftSyntax
import SwiftSyntaxMacros
import Structural_Macro_Core

public struct Macro: ExtensionMacro {
    public static func expansion(of node: AttributeSyntax, attachedTo declaration: some DeclGroupSyntax,
        providingExtensionsOf type: some TypeSyntaxProtocol, conformingTo protocols: [TypeSyntax],
        in context: some MacroExpansionContext) throws -> [ExtensionDeclSyntax] {
        guard let analysis = Structural.Analysis(declaration, type: type),
            analysis.isEnum, analysis.suppressesCopyable, !analysis.parameters.isEmpty else {
            throw MacroExpansionErrorMessage("_Structural requires a generated generic noncopyable sum.")
        }
        return Structural.Derivation.copyable(of: analysis)
            + ["Swift.Equatable", "Swift.Hashable", "Swift.Sendable"].flatMap {
                Structural.Derivation.extensions(of: analysis, capability: $0)
            }
    }
}
