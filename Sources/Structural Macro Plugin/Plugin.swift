#if ProductMacro || StructuralMacro
    import SwiftCompilerPlugin
    import SwiftSyntaxMacros

    @main struct Plugin: CompilerPlugin {
        let providingMacros: [any SwiftSyntaxMacros.Macro.Type] = [Macro.self]
    }
#else
    @main enum Plugin { static func main() {} }
#endif
