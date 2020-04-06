//
//  JSArrayBuffer.swift
//
//  The MIT License
//  Copyright (c) 2015 - 2020 Susan Cheng. All rights reserved.
//
//  Permission is hereby granted, free of charge, to any person obtaining a copy
//  of this software and associated documentation files (the "Software"), to deal
//  in the Software without restriction, including without limitation the rights
//  to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
//  copies of the Software, and to permit persons to whom the Software is
//  furnished to do so, subject to the following conditions:
//
//  The above copyright notice and this permission notice shall be included in
//  all copies or substantial portions of the Software.
//
//  THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
//  IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
//  FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT.  IN NO EVENT SHALL THE
//  AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
//  LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
//  OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
//  THE SOFTWARE.
//

#if canImport(JavaScriptCore)

import JavaScriptCore

#else

import CJSCore

#endif

extension JSObject {
    
    /// Creates a JavaScript `ArrayBuffer` object.
    ///
    /// - Parameters:
    ///   - length: Length of new `ArrayBuffer` object.
    ///   - context: The execution context to use.
    public convenience init(newArrayBufferWithLength length: Int, in context: JSContext) {
        let obj = context.global["ArrayBuffer"].construct(withArguments: [JSObject(double: Double(length), in: context)])
        self.init(context: context, object: obj.object)
    }
    
    /// Creates a JavaScript `ArrayBuffer` object.
    ///
    /// - Parameters:
    ///   - bytes: A buffer to be used as the backing store of the `ArrayBuffer` object.
    ///   - deallocator: The allocator to use to deallocate the external buffer when the `ArrayBuffer` object is deallocated.
    ///   - context: The execution context to use.
    @available(macOS 10.12, iOS 10.0, tvOS 10.0, *)
    public convenience init(
        newArrayBufferWithBytesNoCopy bytes: UnsafeMutableRawBufferPointer,
        deallocator: @escaping (UnsafeMutableRawBufferPointer) -> Void,
        in context: JSContext
    ) {
        
        typealias Deallocator = () -> Void
        
        let info: UnsafeMutablePointer<Deallocator> = .allocate(capacity: 1)
        info.initialize(to: { deallocator(bytes) })
        
        self.init(context: context, object: JSObjectMakeArrayBufferWithBytesNoCopy(context.context, bytes.baseAddress, bytes.count, { _, info in info?.assumingMemoryBound(to: Deallocator.self).deinitialize(count: 1).deallocate() }, info, &context._exception))
    }
    
    /// Creates a JavaScript `ArrayBuffer` object.
    ///
    /// - Parameters:
    ///   - bytes: A buffer to copy.
    ///   - context: The execution context to use.
    @available(macOS 10.12, iOS 10.0, tvOS 10.0, *)
    public convenience init<S: DataProtocol>(
        newArrayBufferWithBytes bytes: S,
        in context: JSContext
    ) {
        
        let buffer: UnsafeMutableRawPointer = .allocate(byteCount: bytes.count, alignment: MemoryLayout<UInt8>.alignment)
        bytes.copyBytes(to: UnsafeMutableRawBufferPointer(start: buffer, count: bytes.count))
        
        self.init(context: context, object: JSObjectMakeArrayBufferWithBytesNoCopy(context.context, buffer, bytes.count, { buffer, _ in buffer?.deallocate() }, nil, &context._exception))
    }
}

extension JSObject {
    
    /// Tests whether a JavaScript value’s type is the `ArrayBuffer` type.
    public var isArrayBuffer: Bool {
        return self.isInstance(of: context.global["ArrayBuffer"])
    }
    
    /// The length of the `ArrayBuffer`.
    @available(macOS 10.12, iOS 10.0, tvOS 10.0, *)
    public var byteLength: Int {
        guard self.isArrayBuffer else { return 0 }
        return JSObjectGetArrayBufferByteLength(context.context, object, &context._exception)
    }
    
    /// Copy the bytes of `ArrayBuffer`.
    @available(macOS 10.12, iOS 10.0, tvOS 10.0, *)
    public func copyBytes() -> Data? {
        guard self.isArrayBuffer else { return nil }
        let length = JSObjectGetArrayBufferByteLength(context.context, object, &context._exception)
        return Data(bytes: JSObjectGetArrayBufferBytesPtr(context.context, object, &context._exception), count: length)
    }
    
}
