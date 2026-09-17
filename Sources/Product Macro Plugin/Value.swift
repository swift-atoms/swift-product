import SwiftSyntax
import SwiftSyntaxMacros
import Product_Macro_Core

public struct Value: ExtensionMacro {
    public static func expansion(
        of _: AttributeSyntax,
        attachedTo declaration: some DeclGroupSyntax,
        providingExtensionsOf type: some TypeSyntaxProtocol,
        conformingTo _: [TypeSyntax],
        in _: some MacroExpansionContext
    ) throws -> [ExtensionDeclSyntax] {
        guard let structure = declaration.as(StructDeclSyntax.self) else {
            throw MacroExpansionErrorMessage(
                "@Value applies to a struct whose fields are its generic parameters."
            )
        }
        return Product_Macro_Core.Value.Derivation.extensions(of: structure, type: type)
    }
}
