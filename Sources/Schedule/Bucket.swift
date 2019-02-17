import Foundation

struct BucketKey {

    private let _underlying: UInt64
    
    init(underlying: UInt64) {
        self._underlying = underlying
    }

    func increased() -> BucketKey {
        let i = _underlying &+ 1
        return BucketKey(underlying: i)
    }
}

extension BucketKey: Equatable {

    static func == (lhs: BucketKey, rhs: BucketKey) -> Bool {
        return lhs._underlying == rhs._underlying
    }
}

struct Bucket<Element> {

    private typealias Entry = (key: BucketKey, element: Element)

    private var key = BucketKey(underlying: 0)

    private var entries: [Entry] = []

    @discardableResult
    mutating func append(_ new: Element) -> BucketKey {
        defer { key = key.increased() }

        let entry = (key: key, element: new)
        entries.append(entry)

        return key
    }

    func element(for key: BucketKey) -> Element? {
        if let entry = entries.first(where: { $0.key == key }) {
            return entry.element
        }

        return nil
    }

    @discardableResult
    mutating func removeElement(for key: BucketKey) -> Element? {
        if let index = entries.firstIndex(where: { $0.key == key }) {
            return entries.remove(at: index).element
        }

        return nil
    }

    mutating func removeAll() {
        entries.removeAll()
    }

    var count: Int {
        return entries.count
    }
}

extension Bucket: Sequence {

    func makeIterator() -> AnyIterator<Element> {
        var iterator = entries.makeIterator()
        return AnyIterator<Element> {
            return iterator.next()?.element
        }
    }
}
