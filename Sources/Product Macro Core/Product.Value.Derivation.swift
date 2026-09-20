import Type_Algebra_Syntax
public import SwiftSyntax
import SwiftSyntaxBuilder

extension Product {
    public enum Value {
        public enum Derivation {
            private static func fields(of declaration: some DeclGroupSyntax) throws -> (StructDeclSyntax, [Type.Syntax.Properties.Field]) {
                guard let structure = declaration.as(StructDeclSyntax.self) else {
                    throw Type.Failure("Value-product derivations require a struct.")
                }
                let properties = Type.Syntax.Properties(structure)
                guard properties.diagnostics.isEmpty else {
                    throw Type.Failure(properties.diagnostics.joined(separator: "; "))
                }
                return (structure, properties.fields)
            }

            private static func access(_ structure: StructDeclSyntax) -> String {
                structure.modifiers.first { ["public", "package"].contains($0.name.text) }.map { "\($0.name.text) " } ?? ""
            }


            public static func memberwise(_ declaration: some DeclGroupSyntax) throws -> [DeclSyntax] {
                let (structure, stored) = try fields(of: declaration)
                let record = try Type.Syntax.Record(stored.map { field in
                    let escaping = field.type.is(FunctionTypeSyntax.self) ? "@escaping " : ""
                    return .init(field.name, type: field.type.trimmedDescription,
                        argument: escaping + field.type.trimmedDescription,
                        initial: field.defaultValue?.trimmedDescription, mutable: field.isMutable)
                })
                return [DeclSyntax(stringLiteral: try record.initializer(access: access(structure),
                    parameters: stored.filter { $0.isMutable || $0.defaultValue == nil }.map(\.name)))]
            }
            public static func draft(_ declaration: some DeclGroupSyntax, excluding excluded: [String]) throws -> [DeclSyntax] {
                let (structure, stored) = try fields(of: declaration)
                guard Set(excluded).count == excluded.count, Set(excluded).isSubset(of: Set(stored.map(\.name))) else {
                    throw Type.Failure("Draft exclusions must name distinct stored properties.")
                }
                guard !stored.contains(where: { ["Draft", "draft"].contains($0.name) }) else {
                    throw Type.Failure("Draft owns the draft projection and nested Draft type.")
                }
                let algebra = try Type.Record(stored.map { .init($0.name, .atom(.init($0.type.trimmedDescription, scope: ["Swift"]))) })
                let selection = try algebra.excluding(excluded)
                let selected = selection.indices.map { stored[$0] }
                guard !selected.isEmpty, selected.allSatisfy(\.isMutable) else {
                    throw Type.Failure("A writable draft must select at least one field, all mutable.")
                }
                let visibility = access(structure)
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
                    \(visibility)struct Draft {
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
    }
}
