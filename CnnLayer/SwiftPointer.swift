// We are a way for the cosmos to know itself. -- C. Sagan

import Foundation

class SwiftPointer<T> {
    let raw: UnsafeMutableRawPointer
    let byteCount: Int

    var elementCount: Int { byteCount /  MemoryLayout<T>.size }

    init(_ dataType: T.Type, bytes: Int) {
        self.byteCount = bytes
        self.raw = UnsafeMutableRawPointer.allocate(byteCount: bytes, alignment: MemoryLayout<T>.alignment)
    }

    init(_ dataType: T.Type, elements: Int) {
        self.byteCount = elements * MemoryLayout<T>.size
        self.raw = UnsafeMutableRawPointer.allocate(byteCount: byteCount, alignment: MemoryLayout<T>.alignment)
    }

    deinit { raw.deallocate() }

    func getRawPointer() -> UnsafeRawPointer { UnsafeRawPointer(raw) }

    func getMutableBufferPointer() -> UnsafeMutableBufferPointer<T> {
        let tb0: UnsafeMutablePointer = raw.bindMemory(to: T.self, capacity: elementCount)
        return UnsafeMutableBufferPointer(start: tb0, count: elementCount)
    }

    func getBufferPointer() -> UnsafeBufferPointer<T> {
        let tb0: UnsafeMutablePointer = raw.bindMemory(to: T.self, capacity: elementCount)
        return UnsafeBufferPointer(start: tb0, count: elementCount)
    }

    func getMutableRawBufferPointer() -> UnsafeMutableRawBufferPointer {
        UnsafeMutableRawBufferPointer(start: raw, count: byteCount)
    }

    func getRawBufferPointer() -> UnsafeRawBufferPointer {
        UnsafeRawBufferPointer(start: raw, count: byteCount)
    }

    func getMutablePointer() -> UnsafeMutablePointer<T> {
        raw.bindMemory(to: T.self, capacity: elementCount)
    }

    func getPointer() -> UnsafePointer<T> {
        let t = raw.bindMemory(to: T.self, capacity: elementCount)
        return UnsafePointer(t)
    }

    func getArray() -> [T] {
        getBufferPointer().map { $0 }
    }
}
