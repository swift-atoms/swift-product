import Foundation
import Testing

@Suite
private struct `Variadic parameter capabilities remain constrained by the compiler` {
    @Test
    func `variadic parameters cannot suppress element capabilities`() throws {
        let diagnostic = try typecheckFailure(
            named: "Suppressed Variadic Elements.swift"
        )

        #expect(diagnostic.contains("cannot suppress '~Copyable'"))
        #expect(diagnostic.contains("cannot suppress '~Escapable'"))
        #expect(diagnostic.contains("each Element"))
    }

    private func typecheckFailure(named name: String) throws -> String {
        let fixture = Bundle.module.resourceURL!
            .appendingPathComponent("Fixtures")
            .appendingPathComponent(name)
        let process = Process()
        let standardError = Pipe()
        process.executableURL = URL(fileURLWithPath: "/usr/bin/xcrun")
        process.arguments = [
            "swiftc",
            "-typecheck",
            "-swift-version", "6",
            "-enable-experimental-feature", "Lifetimes",
            "-enable-experimental-feature", "MoveOnlyTuples",
            "-module-name", "Proof",
            fixture.path,
        ]
        process.standardError = standardError
        try process.run()
        process.waitUntilExit()
        let diagnostic = String(
            decoding: standardError.fileHandleForReading.readDataToEndOfFile(),
            as: UTF8.self
        )

        #expect(process.terminationStatus != 0, "Fixture unexpectedly typechecked")
        return diagnostic
    }
}
