import SwiftSyntax
import SwiftSyntaxMacros
import Structural_Macro_Core

public struct StructuralEquatable: ExtensionMacro {
    public static func expansion(of node: AttributeSyntax, attachedTo declaration: some DeclGroupSyntax,
        providingExtensionsOf type: some TypeSyntaxProtocol, conformingTo protocols: [TypeSyntax],
        in context: some MacroExpansionContext) throws -> [ExtensionDeclSyntax] {
        guard let analysis = Structural_Macro_Core.Structural.Analysis(declaration, type: type) else {
            throw MacroExpansionErrorMessage("Structural capability macros apply to structs and enums.")
        }
        guard !analysis.suppressesCopyable || !analysis.parameters.isEmpty else {
            throw MacroExpansionErrorMessage("@StructuralEquatable requires Copyable values; a noncopyable concrete type cannot have this capability")
        }
        return Structural_Macro_Core.Structural.Derivation.extensions(of: analysis, capability: "Swift.Equatable")
    }
}

public struct StructuralHashable: ExtensionMacro {
    public static func expansion(of node: AttributeSyntax, attachedTo declaration: some DeclGroupSyntax,
        providingExtensionsOf type: some TypeSyntaxProtocol, conformingTo protocols: [TypeSyntax],
        in context: some MacroExpansionContext) throws -> [ExtensionDeclSyntax] {
        guard let analysis = Structural_Macro_Core.Structural.Analysis(declaration, type: type) else {
            throw MacroExpansionErrorMessage("Structural capability macros apply to structs and enums.")
        }
        guard !analysis.suppressesCopyable || !analysis.parameters.isEmpty else {
            throw MacroExpansionErrorMessage("@StructuralHashable requires Copyable values; a noncopyable concrete type cannot have this capability")
        }
        return Structural_Macro_Core.Structural.Derivation.extensions(of: analysis, capability: "Swift.Hashable")
    }
}

public struct StructuralSendable: ExtensionMacro {
    public static func expansion(of node: AttributeSyntax, attachedTo declaration: some DeclGroupSyntax,
        providingExtensionsOf type: some TypeSyntaxProtocol, conformingTo protocols: [TypeSyntax],
        in context: some MacroExpansionContext) throws -> [ExtensionDeclSyntax] {
        guard let analysis = Structural_Macro_Core.Structural.Analysis(declaration, type: type) else {
            throw MacroExpansionErrorMessage("Structural capability macros apply to structs and enums.")
        }
        return Structural_Macro_Core.Structural.Derivation.extensions(of: analysis, capability: "Swift.Sendable")
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
            let analysis = Structural_Macro_Core.Structural.Analysis(declaration, type: type),
            analysis.suppressesCopyable, !analysis.parameters.isEmpty
        else {
            throw MacroExpansionErrorMessage("@Copyable applies to a generic struct or enum declared ~Copyable.")
        }
        guard analysis.componentTypes.contains(where: { type in
            let tokens = type.trimmedDescription.split(whereSeparator: { !$0.isLetter && !$0.isNumber && $0 != "_" })
            return analysis.parameters.contains(where: { tokens.contains(Substring($0)) })
        }) else {
            throw MacroExpansionErrorMessage("@Copyable cannot restore unconditional Copyable to an explicitly ~Copyable type; remove ~Copyable for a phantom-only product")
        }
        return Structural_Macro_Core.Structural.Derivation.copyable(of: analysis)
    }
}
