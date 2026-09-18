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
        }

        public let type: TypeSyntax
        public let access: String
        public let parameters: [String]
        public let fields: [Field]
        public let cases: [Case]
        public let suppressesCopyable: Bool
        public let suppressesEscapable: Bool

        public let isEnum: Bool

        public init?(_ declaration: some DeclGroupSyntax, type: some TypeSyntaxProtocol) {
            let inheritance: InheritanceClauseSyntax?
            let modifiers: DeclModifierListSyntax
            let generics: GenericParameterClauseSyntax?
            if let structure = declaration.as(StructDeclSyntax.self) {
                inheritance = structure.inheritanceClause
                modifiers = structure.modifiers
                generics = structure.genericParameterClause
                isEnum = false
                fields = structure.memberBlock.members.compactMap { member in
                    guard
                        let variable = member.decl.as(VariableDeclSyntax.self),
                        !variable.modifiers.contains(where: { $0.name.tokenKind == .keyword(.static) }),
                        variable.bindings.count == 1,
                        let binding = variable.bindings.first,
                        binding.accessorBlock == nil,
                        let name = binding.pattern.as(IdentifierPatternSyntax.self)?.identifier.text,
                        let type = binding.typeAnnotation?.type.trimmedDescription
                    else { return nil }
                    return Field(name: name, type: type)
                }
                cases = []
            } else if let enumeration = declaration.as(EnumDeclSyntax.self) {
                inheritance = enumeration.inheritanceClause
                modifiers = enumeration.modifiers
                generics = enumeration.genericParameterClause
                isEnum = true
                fields = []
                cases = enumeration.memberBlock.members.flatMap { member in
                    member.decl.as(EnumCaseDeclSyntax.self)?.elements.map {
                        Case(name: $0.name.text, arity: $0.parameterClause?.parameters.count ?? 0)
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
            let suppressed = inheritance?.inheritedTypes.compactMap {
                $0.type.as(SuppressedTypeSyntax.self)?.type.as(IdentifierTypeSyntax.self)?.name.text
            } ?? []
            suppressesCopyable = suppressed.contains("Copyable")
            suppressesEscapable = suppressed.contains("Escapable")
        }
    }
}
