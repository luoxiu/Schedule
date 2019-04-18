import Foundation

/// A unique key for removing an element from a bag.
struct BagKey: Equatable {

    private let i: UInt64

    /// A generator that can generate a sequence of unique `BagKey`.
    ///
    ///     let k1 = gen.next()
    ///     let k2 = gen.next()
    ///     ...
    struct Gen {
        private var key = BagKey(i: 0)
        init() { }
        mutating func next() -> BagKey {
            defer { key = BagKey(i: key.i + 1) }
            return key
        }
    }
}

/// An ordered sequence.
///
///     let k1 = bag.append(e1)
///     let k2 = bag.append(e2)
///
///     for e in bag {
///         // -> e1
///         // -> e2
///     }
///
///     bag.removeValue(for: k1)
struct Bag<Element> {

    private typealias Entry = (key: BagKey, val: Element)

    private var keyGen = BagKey.Gen()
    private var entries: [Entry] = []

    /// Appends a new element at the end of this bag.
    @discardableResult
    mutating func append(_ new: Element) -> BagKey {
        let key = keyGen.next()

        let entry = (key: key, val: new)
        entries.append(entry)

        return key
    }

    /// Returns the element associated with a given key.
    func value(for key: BagKey) -> Element? {
        return entries.first(where: { $0.key == key })?.val
    }

    /// Removes the given key and its associated element from this bag.
    @discardableResult
    mutating func removeValue(for key: BagKey) -> Element? {
        if let i = entries.firstIndex(where: { $0.key == key }) {
            return entries.remove(at: i).val
        }
        return nil
    }

    /// Removes all elements from this bag.
    mutating func removeAll() {
        entries.removeAll()
    }

    /// The number of elements in this bag.
    var count: Int {
        return entries.count
    }
}

extension Bag: Sequence {

    /// Returns an iterator over the elements of this bag.
    @inline(__always)
    func makeIterator() -> AnyIterator<Element> {
        var iterator = entries.makeIterator()
        return AnyIterator<Element> {
            return iterator.next()?.val
        }
    }
}
