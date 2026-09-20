import SwiftSyntax
import SwiftSyntaxBuilder
import SwiftSyntaxMacros
import Type_Algebra_Syntax

private func fields(of declaration: some DeclGroupSyntax) throws -> (StructDeclSyntax, [StoredProperties.Field]) {
    guard let structure = declaration.as(StructDeclSyntax.self) else {
        throw MacroExpansionErrorMessage("Value-product derivations require a struct.")
    }
    let properties = StoredProperties(structure)
    guard properties.diagnostics.isEmpty else {
        throw MacroExpansionErrorMessage(properties.diagnostics.joined(separator: "; "))
    }
    return (structure, properties.fields)
}

private func access(_ structure: StructDeclSyntax) -> String {
    structure.modifiers.first { ["public", "package"].contains($0.name.text) }.map { "\($0.name.text) " } ?? ""
}

public struct Memberwise: MemberMacro {
    public static func expansion(of node: AttributeSyntax, providingMembersOf declaration: some DeclGroupSyntax,
        conformingTo protocols: [TypeSyntax], in context: some MacroExpansionContext) throws -> [DeclSyntax] {
        let (structure, stored) = try fields(of: declaration)
        let parameters = stored.filter { $0.isMutable || $0.defaultValue == nil }
        let arguments = parameters.map { field in
            let escaping = field.type.is(FunctionTypeSyntax.self) ? "@escaping " : ""
            return "\(field.name): \(escaping)\(field.type.trimmedDescription)" + (field.defaultValue.map { " = \($0.trimmedDescription)" } ?? "")
        }
        return [DeclSyntax(stringLiteral: """
            \(access(structure))init(\(arguments.joined(separator: ", "))) {
                \(parameters.map { "self.\($0.name) = \($0.name)" }.joined(separator: "\n"))
            }
            """)]
    }
}

public struct Draft: MemberMacro {
    public static func expansion(of node: AttributeSyntax, providingMembersOf declaration: some DeclGroupSyntax,
        conformingTo protocols: [TypeSyntax], in context: some MacroExpansionContext) throws -> [DeclSyntax] {
        let (structure, stored) = try fields(of: declaration)
        let arguments = node.arguments?.as(LabeledExprListSyntax.self) ?? []
        let excluded = try arguments.map { argument -> String in
            guard let literal = argument.expression.as(StringLiteralExprSyntax.self), literal.segments.count == 1,
                let text = literal.segments.first?.as(StringSegmentSyntax.self) else {
                throw MacroExpansionErrorMessage("Draft exclusions must be literal stored-property names.")
            }
            return text.content.text
        }
        guard Set(excluded).count == excluded.count, Set(excluded).isSubset(of: Set(stored.map(\.name))) else {
            throw MacroExpansionErrorMessage("Draft exclusions must name distinct stored properties.")
        }
        guard !stored.contains(where: { ["Draft", "draft"].contains($0.name) }) else {
            throw MacroExpansionErrorMessage("Draft owns the draft projection and nested Draft type.")
        }
        let selected = stored.filter { !excluded.contains($0.name) }
        guard !selected.isEmpty, selected.allSatisfy(\.isMutable) else {
            throw MacroExpansionErrorMessage("A writable draft must select at least one field, all mutable.")
        }
        let visibility = access(structure)
        let conformances = structure.inheritanceClause?.inheritedTypes.compactMap { inherited -> String? in
            let name = inherited.type.trimmedDescription.split(separator: ".").last.map(String.init) ?? ""
            return ["Hashable", "Equatable", "Sendable"].contains(name) ? inherited.type.trimmedDescription : nil
        } ?? []
        let inherits = conformances.isEmpty ? "" : ": " + conformances.joined(separator: ", ")
        let properties = selected.map { field in
            "\(visibility)var \(field.name): \(field.type.trimmedDescription)" + (field.defaultValue.map { " = \($0.trimmedDescription)" } ?? "")
        }
        let first = stored.firstIndex { !excluded.contains($0.name) }!
        var parameters: [String] = []
        for (index, field) in stored.enumerated() {
            if index == first { parameters.append("_ draft: Draft") }
            if excluded.contains(field.name), field.isMutable || field.defaultValue == nil {
                parameters.append("\(field.name): \(field.type.trimmedDescription)" + (field.defaultValue.map { " = \($0.trimmedDescription)" } ?? ""))
            }
        }
        let assignments = stored.filter { $0.isMutable || $0.defaultValue == nil }.map { field in
            "self.\(field.name) = \(excluded.contains(field.name) ? field.name : "draft.\(field.name)")"
        }
        return [DeclSyntax(stringLiteral: """
            @Memberwise
            \(visibility)struct Draft\(inherits) {
                \(properties.joined(separator: "\n"))
            }
            """), DeclSyntax(stringLiteral: """
            \(visibility)var draft: Draft {
                get { Draft(\(selected.map { "\($0.name): \($0.name)" }.joined(separator: ", "))) }
                set { \(selected.map { "\($0.name) = newValue.\($0.name)" }.joined(separator: "\n")) }
            }
            """), DeclSyntax(stringLiteral: """
            \(visibility)init(\(parameters.joined(separator: ", "))) {
                \(assignments.joined(separator: "\n"))
            }
            """)]
    }
}
