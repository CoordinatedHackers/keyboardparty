import Foundation

func delay(msec: UInt64, closure: () -> ()) -> (() -> ()) {
    var cancelled = false
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, Int64(msec * NSEC_PER_MSEC)), dispatch_get_main_queue()) {
        if cancelled { return }
        closure()
    }
    return { cancelled = true }
}