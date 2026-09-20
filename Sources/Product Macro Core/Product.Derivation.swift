import Type_Algebra_Syntax
import Foundation
import Operation_Syntax
public import SwiftSyntax
import SwiftSyntaxBuilder

extension Product {
    public enum Derivation {
        public static func peers(of analysis: Analysis) -> [DeclSyntax] {
            do { return try derive(analysis) }
            catch { return [DeclSyntax(stringLiteral: "#error(\(String(reflecting: String(describing: error))))")] }
        }

        private static func derive(_ analysis: Analysis) throws -> [DeclSyntax] {
            let protocolDeclaration = analysis.declaration
            let access = analysis.access.map { "\($0.name.text) " } ?? ""
            let semantic = protocolDeclaration.name.trimmedDescription
            let product = "Product"
            let functions = analysis.functionCoordinates
            let genericParameters = analysis.associatedTypeCoordinates.map { coordinate in
                coordinate.constraint.map { "\(coordinate.name.text): \($0.trimmedDescription)" }
                    ?? coordinate.name.text
            }
            let genericClause = genericParameters.isEmpty
                ? ""
                : "<\(genericParameters.joined(separator: ", "))>"

            let record = try analysis.storage(privateFunctions: true)
            let forwarding = functions.map { function in
                let invocation = function.invocation.trimmedDescription.replacingOccurrences(
                    of: "self._\(function.storage)", with: "self.\(Analysis.storageName(function.storage))"
                )
                let statement = function.returnsVoid ? invocation : "return \(invocation)"
                return """
                    \(access)func \(function.name.trimmedDescription)\(function.declaration.signature.trimmedDescription) {
                        \(statement)
                    }
                    """
            }

            let initializer = try record.initializer(access: access)
            let members = (record.declarations(access: access) + [initializer] + forwarding)
                .joined(separator: "\n\n")
            return [DeclSyntax(stringLiteral: """
                \(access)struct \(product)\(genericClause): \(semantic) {
                \(members)
                }
                """)]
        }
    }
}
