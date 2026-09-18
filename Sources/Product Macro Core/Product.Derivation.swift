public import Operation_Macro_Core
public import SwiftSyntax
import SwiftSyntaxBuilder

extension Product {
    public enum Derivation {
        public static func peers(of analysis: Analysis) -> [DeclSyntax] {
            let protocolDeclaration = analysis.declaration
            let access = analysis.access.map { "\($0.name.text) " } ?? ""
            let semantic = protocolDeclaration.name.trimmedDescription
            let product = "Product"
            let functions = analysis.functionCoordinates
            let properties = analysis.propertyCoordinates
            let genericParameters = analysis.associatedTypeCoordinates.map { coordinate in
                coordinate.constraint.map { "\(coordinate.name.text): \($0.trimmedDescription)" }
                    ?? coordinate.name.text
            }
            let genericClause = genericParameters.isEmpty
                ? ""
                : "<\(genericParameters.joined(separator: ", "))>"

            let storedFunctions = functions.map { function in
                "    private let _\(function.storage): \(function.closureType.trimmedDescription)"
            }
            let storedProperties = properties.map { property in
                "    \(access)let \(property.name.text): \(property.type.trimmedDescription)"
            }
            let parameters = functions.map { function in
                "\(function.storage): @escaping \(function.closureType.trimmedDescription)"
            } + properties.map { property in
                "\(property.name.text): \(property.type.trimmedDescription)"
            }
            let assignments = functions.map { function in
                "        self._\(function.storage) = \(function.storage)"
            } + properties.map { property in
                "        self.\(property.name.text) = \(property.name.text)"
            }
            let forwarding = functions.map { function in
                let statement = function.returnsVoid
                    ? function.invocation.trimmedDescription
                    : "return \(function.invocation.trimmedDescription)"
                return """
                        \(access)func \(function.name.trimmedDescription)\(function.declaration.signature.trimmedDescription) {
                            \(statement)
                        }
                    """
            }

            let initializer = """
                    \(access)init(\(parameters.joined(separator: ", "))) {
                \(assignments.joined(separator: "\n"))
                }
                """
            let members = (storedFunctions + storedProperties + [initializer] + forwarding)
                .joined(separator: "\n\n")
            return [DeclSyntax(stringLiteral: """
                \(access)struct \(product)\(genericClause): \(semantic) {
                \(members)
                }
                """)]
        }
    }
}
