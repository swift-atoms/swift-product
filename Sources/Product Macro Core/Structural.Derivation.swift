public import SwiftSyntax
import SwiftSyntaxBuilder

extension Structural {
    // The structural law: a structure has a capability exactly when every component has it. Each capability is
    // an extension conditional on the generic parameters; with no parameters the capability is asserted and the
    // compiler checks the components. Equality and hashing are spelled out: synthesis inside a conditional
    // extension of a noncopyable type is not emitted.
    public enum Derivation {
        // Copyable under the same law, for a generic structure that suppressed it (@Copyable).
        public static func copyable(of analysis: Analysis) -> [ExtensionDeclSyntax] {
            let requirements = analysis.parameters.map { "\($0): Copyable" }.joined(separator: ", ")
            return [DeclSyntax(stringLiteral: "extension \(analysis.type): Copyable where \(requirements) {}")]
                .compactMap { $0.as(ExtensionDeclSyntax.self) }
        }

        public static func extensions(of analysis: Analysis) -> [ExtensionDeclSyntax] {
            let isGeneric = !analysis.parameters.isEmpty
            func requirements(_ capability: String) -> String {
                isGeneric
                    ? " where " + analysis.parameters.map { "\($0): \(capability)" }.joined(separator: ", ")
                    : ""
            }
            var declarations: [String] = []
            declarations.append("extension \(analysis.type): Swift.Sendable\(requirements("Swift.Sendable")) {}")
            // A noncopyable structure compares and hashes only where @Copyable can restore Copyable: when generic.
            if !analysis.suppressesCopyable || isGeneric {
                declarations.append("""
                    extension \(analysis.type): Swift.Equatable\(requirements("Swift.Equatable")) {
                        \(analysis.access)static func == (lhs: Self, rhs: Self) -> Swift.Bool {
                            \(equality(of: analysis))
                        }
                    }
                    """)
                declarations.append("""
                    extension \(analysis.type): Swift.Hashable\(requirements("Swift.Hashable")) {
                        \(analysis.access)func hash(into hasher: inout Swift.Hasher) {
                            \(hashing(of: analysis))
                        }
                    }
                    """)
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
                enumCase.arity == 0
                    ? "case (.\(enumCase.name), .\(enumCase.name)): return true"
                    : "case let (.\(enumCase.name)(lhs), .\(enumCase.name)(rhs)): return lhs == rhs"
            } + (analysis.cases.count > 1 ? ["default: return false"] : [])
            return "switch (lhs, rhs) {\n\(arms.joined(separator: "\n"))\n}"
        }

        private static func hashing(of analysis: Analysis) -> String {
            guard analysis.isEnum else {
                return analysis.fields.map { "hasher.combine(\($0.name))" }.joined(separator: "\n")
            }
            guard !analysis.cases.isEmpty else { return "switch self {}" }
            let arms = analysis.cases.enumerated().map { offset, enumCase in
                enumCase.arity == 0
                    ? "case .\(enumCase.name): hasher.combine(\(offset))"
                    : "case let .\(enumCase.name)(value): hasher.combine(\(offset)); hasher.combine(value)"
            }
            return "switch self {\n\(arms.joined(separator: "\n"))\n}"
        }
    }
}
