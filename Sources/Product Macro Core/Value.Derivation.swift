public import SwiftSyntax
import SwiftSyntaxBuilder

extension Value {
    public enum Derivation {
        public static func extensions(
            of structure: StructDeclSyntax,
            type: some TypeSyntaxProtocol
        ) -> [ExtensionDeclSyntax] {
            let parameters = structure.genericParameterClause?.parameters.map(\.name.text) ?? []
            let stored = structure.memberBlock.members.compactMap { member -> (name: String, type: String)? in
                guard
                    let variable = member.decl.as(VariableDeclSyntax.self),
                    variable.bindings.count == 1,
                    let binding = variable.bindings.first,
                    binding.accessorBlock == nil,
                    let name = binding.pattern.as(IdentifierPatternSyntax.self)?.identifier.text,
                    let type = binding.typeAnnotation?.type.trimmedDescription
                else { return nil }
                return (name, type)
            }
            let fields = stored.map(\.name)
            let access = structure.modifiers.first {
                $0.name.tokenKind == .keyword(.public) || $0.name.tokenKind == .keyword(.package)
            }.map { "\($0.name.text) " } ?? ""
            func clause(_ conformance: String) -> String {
                parameters.isEmpty
                    ? ""
                    : " where \(parameters.map { "\($0): \(conformance)" }.joined(separator: ", "))"
            }
            let comparisons = fields.map { field in
                """
                    if lhs.\(field) != rhs.\(field) {
                        return lhs.\(field) < rhs.\(field)
                    }
                """
            }.joined(separator: "\n")
            let keys = fields.isEmpty
                ? "\(access)enum CodingKeys: Swift.CodingKey {}"
                : "\(access)enum CodingKeys: Swift.String, Swift.CodingKey { case \(fields.joined(separator: ", ")) }"
            let encodes = stored.isEmpty
                ? "_ = encoder.container(keyedBy: CodingKeys.self)"
                : "var container = encoder.container(keyedBy: CodingKeys.self)\n"
                    + stored.map { "try container.encode(self.\($0.name), forKey: .\($0.name))" }.joined(separator: "\n")
            let decodes = stored.isEmpty
                ? "_ = try decoder.container(keyedBy: CodingKeys.self)"
                : "let container = try decoder.container(keyedBy: CodingKeys.self)\n"
                    + stored.map { "self.\($0.name) = try container.decode(\($0.type).self, forKey: .\($0.name))" }.joined(separator: "\n")
            let extensions: [String] = [
                "extension \(type.trimmed): Swift.Equatable\(clause("Swift.Equatable")) {}",
                "extension \(type.trimmed): Swift.Hashable\(clause("Swift.Hashable")) {}",
                "extension \(type.trimmed): Swift.Sendable\(clause("Swift.Sendable")) {}",
                """
                extension \(type.trimmed) {
                    \(keys)
                }
                """,
                """
                extension \(type.trimmed): Swift.Encodable\(clause("Swift.Encodable")) {
                    \(access)func encode(to encoder: any Swift.Encoder) throws {
                        \(encodes)
                    }
                }
                """,
                """
                extension \(type.trimmed): Swift.Decodable\(clause("Swift.Decodable")) {
                    \(access)init(from decoder: any Swift.Decoder) throws {
                        \(decodes)
                    }
                }
                """,
                """
                extension \(type.trimmed): Swift.Comparable\(clause("Swift.Comparable")) {
                    \(access)static func < (lhs: Self, rhs: Self) -> Swift.Bool {
                \(comparisons)
                        return false
                    }
                }
                """,
            ]
            return extensions.compactMap { DeclSyntax(stringLiteral: $0).as(ExtensionDeclSyntax.self) }
        }
    }
}
