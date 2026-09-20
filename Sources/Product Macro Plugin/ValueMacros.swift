import Product_Macro_Core
import SwiftSyntax
import SwiftSyntaxMacros

public struct Memberwise: MemberMacro {
    public static func expansion(of node: AttributeSyntax, providingMembersOf declaration: some DeclGroupSyntax,
        conformingTo protocols: [TypeSyntax], in context: some MacroExpansionContext) throws -> [DeclSyntax] {
        try Product.Value.Derivation.memberwise(declaration)
    }
}

public struct Draft: MemberMacro {
    public static func expansion(of node: AttributeSyntax, providingMembersOf declaration: some DeclGroupSyntax,
        conformingTo protocols: [TypeSyntax], in context: some MacroExpansionContext) throws -> [DeclSyntax] {
        let arguments = node.arguments?.as(LabeledExprListSyntax.self) ?? []
        let excluded = try arguments.map { argument -> String in
            guard let literal = argument.expression.as(StringLiteralExprSyntax.self), literal.segments.count == 1,
                let text = literal.segments.first?.as(StringSegmentSyntax.self) else {
                throw MacroExpansionErrorMessage("Draft exclusions must be literal stored-property names.")
            }
            return text.content.text
        }

        return try Product.Value.Derivation.draft(declaration, excluding: excluded)
    }
}
