import Foundation

enum Global {

    #if canImport(ObjectiveC)
    static func sync<T>(_ obj: AnyObject, _ body: () throws -> T) rethrows -> T {
        objc_sync_enter(obj); defer { objc_sync_exit(obj) }
        return try body()
    }
    #endif
}

