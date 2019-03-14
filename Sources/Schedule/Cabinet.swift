import Foundation

struct CabinetKey: Equatable {

    private let i: UInt64

    init(underlying: UInt64) {
        self.i = underlying
    }

    func increased() -> CabinetKey {
        return CabinetKey(underlying: i &+ 1)
    }

    static func == (lhs: CabinetKey, rhs: CabinetKey) -> Bool {
        return lhs.i == rhs.i
    }
}

struct Cabinet<Element> {

    private typealias Entry = (key: CabinetKey, element: Element)

    private var key = CabinetKey(underlying: 0)
    private var entries: [Entry] = []

    @discardableResult
    mutating func append(_ new: Element) -> CabinetKey {
        defer { key = key.increased() }

        let entry = (key: key, element: new)
        entries.append(entry)

        return key
    }

    func get(_ key: CabinetKey) -> Element? {
        if let entry = entries.first(where: { $0.key == key }) {
            return entry.element
        }
        return nil
    }

    @discardableResult
    mutating func delete(_ key: CabinetKey) -> Element? {
        if let i = entries.firstIndex(where: { $0.key == key }) {
            return entries.remove(at: i).element
        }

        return nil
    }

    mutating func clear() {
        entries.removeAll()
    }

    var count: Int {
        return entries.count
    }
}

extension Cabinet: Sequence {

    func makeIterator() -> AnyIterator<Element> {
        var iterator = entries.makeIterator()
        return AnyIterator<Element> {
            return iterator.next()?.element
        }
    }
}
