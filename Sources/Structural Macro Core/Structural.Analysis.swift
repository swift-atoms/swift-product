import Type_Algebra_Syntax
public import SwiftSyntax

extension Structural {
    // The components of a structure: a struct's stored fields or an enum's cases, and the generic parameters the
    // structure's capabilities are conditional on.
    public struct Analysis {
        public struct Field {
            public let name: String
            public let type: String
        }

        public struct Case {
            public let name: String
            public let arity: Int
            public let payloads: [TypeSyntax]
        }

        public let type: TypeSyntax
        public let access: String
        public let parameters: [String]
        public let noncopyableParameters: [String]
        public let fields: [Field]
        public let componentTypes: [TypeSyntax]
        public let cases: [Case]
        public let suppressesCopyable: Bool
        public let suppressesEscapable: Bool

        public let isEnum: Bool

        public static func coordinates(name: String, type: TypeSyntax) -> [Field] {
            guard let tuple = type.as(TupleTypeSyntax.self) else { return [Field(name: name, type: type.trimmedDescription)] }
            return tuple.elements.enumerated().flatMap { coordinates(name: "\(name).\($0.offset)", type: $0.element.type) }
        }

        /// Only stored component obligations; phantom parameters introduce no requirements.
        public func requirements(for capability: String) -> String {
            let dependent = componentTypes.flatMap { Self.coordinates(name: "", type: $0) }.map(\.type).filter { spelling in
                spelling.split(whereSeparator: { !$0.isLetter && !$0.isNumber && $0 != "_" }).contains { parameters.contains(String($0)) }
            }
            let unique = Array(Set(dependent)).sorted()
            var predicates = unique.map { "\($0): \(capability)" }
            for parameter in noncopyableParameters {
                let restoringCopyable = unique.contains(parameter) && ["Copyable", "Swift::Copyable", "Swift::Equatable", "Swift::Hashable"].contains(capability)
                if !restoringCopyable { predicates.append("\(parameter): ~Swift::Copyable") }
            }
            return predicates.isEmpty ? "" : " where " + predicates.joined(separator: ", ")
        }

        public init?(_ declaration: some DeclGroupSyntax, type: some TypeSyntaxProtocol) {
            let inheritance: InheritanceClauseSyntax?
            let modifiers: DeclModifierListSyntax
            let generics: GenericParameterClauseSyntax?
            if let structure = declaration.as(StructDeclSyntax.self) {
                inheritance = structure.inheritanceClause
                modifiers = structure.modifiers
                generics = structure.genericParameterClause
                isEnum = false
                let properties = Type.Syntax.Properties(structure)
                guard properties.diagnostics.isEmpty else { return nil }
                componentTypes = properties.fields.map(\.type)
                fields = properties.fields.flatMap { Self.coordinates(name: $0.name, type: $0.type) }
                cases = []
            } else if let enumeration = declaration.as(EnumDeclSyntax.self) {
                inheritance = enumeration.inheritanceClause
                modifiers = enumeration.modifiers
                generics = enumeration.genericParameterClause
                isEnum = true
                fields = []
                componentTypes = Type.Syntax.Recursion.elements(of: enumeration).flatMap { Type.Syntax.Recursion.parameters(of: $0).map(\.type) }
                cases = enumeration.memberBlock.members.flatMap { member in
                    member.decl.as(EnumCaseDeclSyntax.self)?.elements.map {
                        Case(name: $0.name.text, arity: $0.parameterClause?.parameters.count ?? 0, payloads: $0.parameterClause?.parameters.map(\.type) ?? [])
                    } ?? []
                }
            } else {
                return nil
            }
            self.type = TypeSyntax(type.trimmed)
            access = modifiers.first {
                $0.name.tokenKind == .keyword(.public) || $0.name.tokenKind == .keyword(.package)
            }.map { "\($0.name.text) " } ?? ""
            parameters = generics?.parameters.map(\.name.text) ?? []
            noncopyableParameters = generics?.parameters.filter { $0.inheritedType?.trimmedDescription.contains("~Copyable") == true }.map(\.name.text) ?? []
            let suppressed = inheritance?.inheritedTypes.compactMap {
                $0.type.as(SuppressedTypeSyntax.self)?.type.as(IdentifierTypeSyntax.self)?.name.text
            } ?? []
            suppressesCopyable = suppressed.contains("Copyable")
            suppressesEscapable = suppressed.contains("Escapable")
        }
    }
}
