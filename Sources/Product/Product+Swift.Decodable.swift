#if !hasFeature(Embedded)
extension Product: Swift.Decodable where repeat each Element: Swift.Decodable {

        @inlinable
        public init(from decoder: any Decoder) throws(any Swift.Error) {
            var container = try decoder.unkeyedContainer()
            self.init(repeat try container.decode((each Element).self))
        }
    }
#endif
