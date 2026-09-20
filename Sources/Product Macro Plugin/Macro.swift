import SwiftSyntax
import SwiftSyntaxMacros
import Product_Macro_Core

public struct Macro: PeerMacro {
    public static func expansion(
        of node: AttributeSyntax,
        providingPeersOf declaration: some DeclSyntaxProtocol,
        in _: some MacroExpansionContext
    ) throws -> [DeclSyntax] {
        guard let declaration = declaration.as(ProtocolDeclSyntax.self) else {
            throw MacroExpansionErrorMessage("@Product applies to a protocol declaration only.")
        }
        let analysis = Product.Analysis(declaration)
        guard analysis.diagnostics.isEmpty else {
            throw MacroExpansionErrorMessage(
                "@Product cannot represent every requirement: \(analysis.diagnostics.joined(separator: "; "))."
            )
        }
        return Product.Derivation.peers(of: analysis)
    }
}
