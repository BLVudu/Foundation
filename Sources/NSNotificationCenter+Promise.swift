import Foundation.NSNotification
#if !COCOAPODS
import PromiseKit
#endif

/**
 To import the `NSNotificationCenter` category:

    use_frameworks!
    pod "PromiseKit/Foundation"

 Or `NSNotificationCenter` is one of the categories imported by the umbrella pod:

    use_frameworks!
    pod "PromiseKit"

 And then in your sources:

    import PromiseKit
*/
extension NotificationCenter {
    /// Observe the named notification once
    public func observe(once name: String) -> NotificationPromise {
        let (promise, fulfill, _) = NotificationPromise.go()
        let id = addObserver(forName: NSNotification.Name(rawValue: name), object: nil, queue: nil, using: fulfill)
        _ = promise.then(on: zalgo) { _ in self.removeObserver(id) }
        return promise
    }
    
    public class func once(_ name: String) -> NotificationPromise {
        return NotificationCenter.default.observe(once: name)
    }
    
    public class func once(_ name: String, timeout: TimeInterval) -> NotificationPromise {
        return NotificationCenter.default.observe(once: name)
    }
    
    public func observe(once name: String, timeout: TimeInterval) -> NotificationPromise {
        let (promise, fulfill, reject) = NotificationPromise.go()
        let id = addObserver(forName: NSNotification.Name(rawValue: name), object: nil, queue: nil, using: fulfill)
        after(interval: timeout).then { reject(NSError(code: 0)) }
        _ = promise.always(on: zalgo) { _ in self.removeObserver(id) }
        return promise
    }
}

/// The promise returned by `NotificationCenter.observe(once:)`
open class NotificationPromise: Promise<[AnyHashable: Any]> {
    fileprivate let pending = Promise<Notification>.pending()

    open func asNotification() -> Promise<Notification> {
        return pending.promise
    }

    fileprivate class func go() -> (NotificationPromise, (Notification) -> (), (Error) -> () ) {
        let (p, fulfill, reject) = NotificationPromise.pending()
        let promise = p as! NotificationPromise
        _ = promise.pending.promise.then { fulfill($0.userInfo ?? [:]) }
        _ = promise.pending.promise.catch { reject($0) }
        return (promise, promise.pending.fulfill, promise.pending.reject)
    }
}
