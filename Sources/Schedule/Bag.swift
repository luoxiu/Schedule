import Foundation

/// A unique key used to operate the corresponding element from a bag.
struct BagKey: Equatable {

    fileprivate let i: UInt64

    fileprivate init(underlying: UInt64) {
        self.i = underlying
    }

    /// Returns a Boolean value indicating whether two BagKeys are equal.
    static func == (lhs: BagKey, rhs: BagKey) -> Bool {
        return lhs.i == rhs.i
    }
}

/// A generator used to generate a sequence of unique `BagKey`.
///
///     let k1 = gen.next()
///     let k2 = gen.next()
///     ...
struct BagKeyGenerator: Sequence, IteratorProtocol {

    typealias Element = BagKey

    private var k = BagKey(underlying: 0)

    /// Advances to the next element and returns it, or nil if no next element exists.
    mutating func next() -> Element? {
        if k.i == UInt64.max {
            return nil
        }
        defer { k = BagKey(underlying: k.i + 1) }
        return k
    }
}

/// A data structure used to store a sequence of elements.
///
///     let k1 = bag.append(e1)
///     let k2 = bag.append(e2)
///
///     for e in bag {
///         // -> e1
///         // -> e2
///     }
///
///     bag.delete(k1)
struct Bag<Element> {

    private typealias Entry = (key: BagKey, element: Element)

    private var keys = BagKeyGenerator()
    private var entries: [Entry] = []

    /// Pushes the given element on to the end of this container.
    @discardableResult
    mutating func append(_ new: Element) -> BagKey {
        let key = keys.next()!

        let entry = (key: key, element: new)
        entries.append(entry)

        return key
    }

    /// Returns the element for key if key is in this container.
    func get(_ key: BagKey) -> Element? {
        if let entry = entries.first(where: { $0.key == key }) {
            return entry.element
        }
        return nil
    }

    /// Deletes the element with the given key and returns this element.
    @discardableResult
    mutating func delete(_ key: BagKey) -> Element? {
        if let i = entries.firstIndex(where: { $0.key == key }) {
            return entries.remove(at: i).element
        }
        return nil
    }

    /// Removes all elements from this containers.
    mutating func clear() {
        entries.removeAll()
    }

    /// The number of elements in this containers.
    var count: Int {
        return entries.count
    }
}

extension Bag: Sequence {

    /// Returns an iterator over the elements of this containers.
    func makeIterator() -> AnyIterator<Element> {
        var iterator = entries.makeIterator()
        return AnyIterator<Element> {
            return iterator.next()?.element
        }
    }
}
