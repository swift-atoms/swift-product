#if !hasFeature(Embedded)
extension Product: Swift.Encodable where repeat each Element: Swift.Encodable {

        @inlinable
        public func encode(to encoder: any Encoder) throws(any Swift.Error) {
            var container = encoder.unkeyedContainer()
            for value in repeat each values {
                try container.encode(value)
            }
        }
    }
#endif
