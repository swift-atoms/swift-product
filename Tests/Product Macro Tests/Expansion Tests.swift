import SwiftSyntaxMacroExpansion
import SwiftSyntaxMacrosGenericTestSupport
import Testing

@testable import Product_Macro_Plugin

private let productMacros: [String: MacroSpec] = [
    "Product": MacroSpec(type: Product_Macro_Plugin.Macro.self)
]

private func expectProductExpansion(
    _ originalSource: String,
    expandedSource: String,
    diagnostics: [DiagnosticSpec] = [],
    fileID: StaticString = #fileID,
    filePath: StaticString = #filePath,
    line: UInt = #line,
    column: UInt = #column
) {
    assertMacroExpansion(
        originalSource,
        expandedSource: expandedSource,
        diagnostics: diagnostics,
        macroSpecs: productMacros,
        failureHandler: { failure in
            Issue.record(
                Comment(rawValue: failure.message),
                sourceLocation: SourceLocation(
                    fileID: failure.location.fileID.description,
                    filePath: failure.location.filePath.description,
                    line: Int(failure.location.line),
                    column: Int(failure.location.column)
                )
            )
        },
        fileID: fileID,
        filePath: filePath,
        line: line,
        column: column
    )
}

extension `Product Derivation Tests` {
    @Suite
    struct Expansion {
        @Test
        func `protocol expands to its operation product`() {
            expectProductExpansion(
                """
                enum Greeting {
                    @Product
                    protocol `Protocol` {
                        func greet(name: String) -> String
                    }
                }
                """,
                expandedSource: """
                enum Greeting {
                    protocol `Protocol` {
                        func greet(name: String) -> String
                    }

                    struct Product: `Protocol` {
                        private let `_greet`: (String) -> String

                        init(greet: @escaping (String) -> String) {
                            self.`_greet` = greet
                        }

                        func greet(name: String) -> String {
                            return (self.`_greet`)(name)
                        }
                    }
                }
                """
            )
        }

        @Test
        func `parameter ownership is preserved by the operation field`() {
            expectProductExpansion(
                """
                enum Transform {
                    @Product
                    protocol `Protocol` {
                        associatedtype Input: ~Copyable
                        associatedtype Output: ~Copyable
                        func transform(_ input: borrowing Input, into output: consuming Output)
                    }
                }
                """,
                expandedSource: """
                enum Transform {
                    protocol `Protocol` {
                        associatedtype Input: ~Copyable
                        associatedtype Output: ~Copyable
                        func transform(_ input: borrowing Input, into output: consuming Output)
                    }

                    struct Product<Input: ~Copyable, Output: ~Copyable>: `Protocol` {
                        private let `_transform`: (borrowing Input, consuming Output) -> Void

                        init(transform: @escaping (borrowing Input, consuming Output) -> Void) {
                            self.`_transform` = transform
                        }

                        func transform(_ input: borrowing Input, into output: consuming Output) {
                            (self.`_transform`)(input, output)
                        }
                    }
                }
                """
            )
        }

        @Test
        func `inout parameters are forwarded with an inout argument`() {
            expectProductExpansion(
                """
                enum Mutation {
                    @Product
                    protocol `Protocol` {
                        associatedtype Value
                        func mutate(_ value: inout Value)
                    }
                }
                """,
                expandedSource: """
                enum Mutation {
                    protocol `Protocol` {
                        associatedtype Value
                        func mutate(_ value: inout Value)
                    }

                    struct Product<Value>: `Protocol` {
                        private let `_mutate`: (inout Value) -> Void

                        init(mutate: @escaping (inout Value) -> Void) {
                            self.`_mutate` = mutate
                        }

                        func mutate(_ value: inout Value) {
                            (self.`_mutate`)(&value)
                        }
                    }
                }
                """
            )
        }

        @Test
        func `unsupported requirements are diagnosed instead of discarded`() {
            expectProductExpansion(
                """
                enum Greeting {
                    @Product
                    protocol `Protocol` {
                        var salutation: String { get }
                        func greet<Value>(name: Value) -> String
                    }
                }
                """,
                expandedSource: """
                enum Greeting {
                    protocol `Protocol` {
                        var salutation: String { get }
                        func greet<Value>(name: Value) -> String
                    }
                }
                """,
                diagnostics: [
                    DiagnosticSpec(
                        message: "@Product cannot represent every requirement: `greet` is generic; stored operation fields cannot be generic.",
                        line: 2,
                        column: 5
                    )
                ]
            )
        }

        @Test
        func `mutable property requirements are rejected`() {
            expectProductExpansion(
                """
                enum Counter {
                    @Product
                    protocol `Protocol` {
                        var value: Int { get set }
                    }
                }
                """,
                expandedSource: """
                enum Counter {
                    protocol `Protocol` {
                        var value: Int { get set }
                    }
                }
                """,
                diagnostics: [
                    DiagnosticSpec(
                        message: "@Product cannot represent every requirement: `var value: Int { get set }` is not a getter-only property requirement.",
                        line: 2,
                        column: 5
                    )
                ]
            )
        }

        @Test
        func `non protocol attachment is diagnosed`() {
            expectProductExpansion(
                """
                enum Greeting {
                    @Product
                    struct Model {}
                }
                """,
                expandedSource: """
                enum Greeting {
                    struct Model {}
                }
                """,
                diagnostics: [
                    DiagnosticSpec(
                        message: "@Product applies to a protocol declaration only.",
                        line: 2,
                        column: 5
                    )
                ]
            )
        }
    }
}
