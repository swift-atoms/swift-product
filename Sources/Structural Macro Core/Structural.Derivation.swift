public import SwiftSyntax
import SwiftSyntaxBuilder

extension Structural {
    // The structural law: a structure has a capability exactly when every component has it. Each capability is
    // an extension conditional on the stored component types; with no parameters the capability is asserted and the
    // compiler checks the components. Equality and hashing are spelled out: synthesis inside a conditional
    // extension of a noncopyable type is not emitted.
    public enum Derivation {
        // Copyable under the same law, for a generic structure that suppressed it (@Copyable).
        public static func copyable(of analysis: Analysis) -> [ExtensionDeclSyntax] {
            return [DeclSyntax(stringLiteral: "extension \(analysis.type): Copyable\(analysis.requirements(for: "Copyable")) {}")]
                .compactMap { $0.as(ExtensionDeclSyntax.self) }
        }

        public static func extensions(of analysis: Analysis, capability: String) -> [ExtensionDeclSyntax] {
            let isGeneric = !analysis.parameters.isEmpty
            func requirements(_ capability: String) -> String { analysis.requirements(for: capability) }
            var declarations: [String] = []
            if capability == "Swift.Sendable" { declarations.append("extension \(analysis.type): Swift.Sendable\(requirements("Swift.Sendable")) {}") }
            // A noncopyable structure compares and hashes only where @Copyable can restore Copyable: when generic.
            if !analysis.suppressesCopyable || isGeneric {
                if capability == "Swift.Equatable" {
                declarations.append("""
                    extension \(analysis.type): Swift.Equatable\(requirements("Swift.Equatable")) {
                        \(analysis.access)static func == (lhs: Self, rhs: Self) -> Swift.Bool {
                            \(equality(of: analysis))
                        }
                    }
                    """)
                }
                if capability == "Swift.Hashable" {
                declarations.append("""
                    extension \(analysis.type): Swift.Hashable\(requirements("Swift.Hashable")) {
                        \(analysis.access)func hash(into hasher: inout Swift.Hasher) {
                            \(hashing(of: analysis))
                        }
                    }
                    """)
            }
            }
            return declarations.compactMap { DeclSyntax(stringLiteral: $0).as(ExtensionDeclSyntax.self) }
        }

        private static func equality(of analysis: Analysis) -> String {
            guard analysis.isEnum else {
                return analysis.fields.isEmpty
                    ? "return true"
                    : "return " + analysis.fields.map { "lhs.\($0.name) == rhs.\($0.name)" }.joined(separator: " && ")
            }
            guard !analysis.cases.isEmpty else { return "switch (lhs, rhs) {}" }
            let arms = analysis.cases.map { enumCase in
                guard enumCase.arity > 0 else { return "case (.\(enumCase.name), .\(enumCase.name)): return true" }
                let lhs = (0..<enumCase.arity).map { "lhs\($0)" }.joined(separator: ", ")
                let rhs = (0..<enumCase.arity).map { "rhs\($0)" }.joined(separator: ", ")
                let comparisons = enumCase.payloads.enumerated().flatMap { index, type in
                    Analysis.coordinates(name: "lhs\(index)", type: type).map { field in
                        let suffix = field.name.dropFirst(3)
                        return "\(field.name) == rhs\(suffix)"
                    }
                }.joined(separator: " && ")
                return "case let (.\(enumCase.name)(\(lhs)), .\(enumCase.name)(\(rhs))): return \(comparisons.isEmpty ? "true" : comparisons)"
            } + (analysis.cases.count > 1 ? ["default: return false"] : [])
            return "switch (lhs, rhs) {\n\(arms.joined(separator: "\n"))\n}"
        }

        private static func hashing(of analysis: Analysis) -> String {
            guard analysis.isEnum else {
                return analysis.fields.map { "hasher.combine(\($0.name))" }.joined(separator: "\n")
            }
            guard !analysis.cases.isEmpty else { return "switch self {}" }
            let arms = analysis.cases.enumerated().map { offset, enumCase in
                guard enumCase.arity > 0 else { return "case .\(enumCase.name): hasher.combine(\(offset))" }
                let values = (0..<enumCase.arity).map { "value\($0)" }
                return "case let .\(enumCase.name)(\(values.joined(separator: ", "))): hasher.combine(\(offset)); " + enumCase.payloads.enumerated().flatMap { Analysis.coordinates(name: "value\($0.offset)", type: $0.element).map { "hasher.combine(\($0.name))" } }.joined(separator: "; ")
            }
            return "switch self {\n\(arms.joined(separator: "\n"))\n}"
        }
    }
}
