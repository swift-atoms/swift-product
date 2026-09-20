import Product_Macro
import Testing

@Memberwise
@Draft(excluding: "id", "created")
private struct ValueRecord: Equatable, Sendable {
    var id: Int
    var title: String = ""
    var completed: Bool = false
    var created: Int
}

@Memberwise
@Draft(excluding: "id")
private struct GenericRecord<Element>: Equatable, Sendable {
    var id: Int
    var title: String = ""
}

@Test private func draftIsTheComplementaryProduct() {
    var record = ValueRecord(id: 1, created: 123)
    #expect(record.draft == ValueRecord.Draft())
    let original = record
    record.draft = original.draft
    #expect(record == original)
    let first = ValueRecord.Draft(title: "First", completed: true)
    record.draft = first
    #expect(record.draft == first)
    #expect(record.id == 1 && record.created == 123)
    let second = ValueRecord.Draft(title: "Second")
    record.draft = second
    #expect(record == ValueRecord(id: 1, second, created: 123))
    #expect(GenericRecord<Int>(id: 2, .init(title: "Generic")).draft.title == "Generic")
}
