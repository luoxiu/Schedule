//
//  DeinitObserver.swift
//  Schedule
//
//  Created by Quentin Jin on 2018/8/26.
//

import Foundation

#if os(macOS) || os(iOS) || os(tvOS) || os(watchOS)

class DeinitObserver<T: AnyObject> {

    private weak var observed: T?

    private var block: () -> Void

    private init(_ block: @escaping () -> Void) {
        self.block = block
    }

    static func observe(_ observed: T, whenDeinit: @escaping () -> Void) {
        let observer = DeinitObserver(whenDeinit)
        var key: Void = ()
        objc_setAssociatedObject(observed, &key, observer, .OBJC_ASSOCIATION_RETAIN)
    }

    deinit {
        block()
    }
}

#endif
