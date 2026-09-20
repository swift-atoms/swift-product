import Product_Macro
import Testing

private enum Native {
    @Product
    protocol Ports: Sendable { func ready() -> Bool }
}

@Test private func protocolNativeSendableControlsProductStorage() async {
    let value = Native.Product(ready: { true })
    #expect(await Task.detached { value.ready() }.value)
}
