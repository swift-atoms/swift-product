import SwiftSyntax
import SwiftSyntaxMacros
import Product_Macro_Core

public struct Structural: ExtensionMacro {
    public static func expansion(
        of _: AttributeSyntax,
        attachedTo declaration: some DeclGroupSyntax,
        providingExtensionsOf type: some TypeSyntaxProtocol,
        conformingTo _: [TypeSyntax],
        in _: some MacroExpansionContext
    ) throws -> [ExtensionDeclSyntax] {
        guard let analysis = Product_Macro_Core.Structural.Analysis(declaration, type: type) else {
            throw MacroExpansionErrorMessage("@Structural applies to a struct or an enum.")
        }
        return Product_Macro_Core.Structural.Derivation.extensions(of: analysis)
    }
}

public struct Copyable: ExtensionMacro {
    public static func expansion(
        of _: AttributeSyntax,
        attachedTo declaration: some DeclGroupSyntax,
        providingExtensionsOf type: some TypeSyntaxProtocol,
        conformingTo _: [TypeSyntax],
        in _: some MacroExpansionContext
    ) throws -> [ExtensionDeclSyntax] {
        guard
            let analysis = Product_Macro_Core.Structural.Analysis(declaration, type: type),
            analysis.suppressesCopyable, !analysis.parameters.isEmpty
        else {
            throw MacroExpansionErrorMessage("@Copyable applies to a generic struct or enum declared ~Copyable.")
        }
        return Product_Macro_Core.Structural.Derivation.copyable(of: analysis)
    }
}
