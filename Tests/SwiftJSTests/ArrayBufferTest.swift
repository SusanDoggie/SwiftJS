//
//  ArrayBufferTest.swift
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
//  FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
//  AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
//  LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
//  OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
//  THE SOFTWARE.
//

import SwiftJS
import XCTest

@available(macOS 10.12, iOS 10.0, tvOS 10.0, *)
class ArrayBufferTest: XCTestCase {
    
    func testArrayBuffer() {
        
        let context = JSContext()
        
        let bytes: [UInt8] = [1, 2, 3, 4, 5, 6, 7, 8]
        context.global["buffer"] = JSObject(newArrayBufferWithBytes: bytes, in: context)
        
        XCTAssertTrue(context.global["buffer"].isArrayBuffer)
        XCTAssertEqual(context.global["buffer"].byteLength, 8)
        
    }
    
    func testArrayBufferWithBytesNoCopy() {
        
        var flag = 0
        
        do {
            
            let context = JSContext()
            
            var bytes: [UInt8] = [1, 2, 3, 4, 5, 6, 7, 8]
            
            bytes.withUnsafeMutableBytes { bytes in
                
                context.global["buffer"] = JSObject(
                    newArrayBufferWithBytesNoCopy: bytes,
                    deallocator: { _ in flag = 1 },
                    in: context)
                
                XCTAssertTrue(context.global["buffer"].isArrayBuffer)
                XCTAssertEqual(context.global["buffer"].byteLength, 8)
            }
            
        }
        
        XCTAssertEqual(flag, 1)
    }
    
    func testDataView() {
        
        let context = JSContext()
        
        let bytes: [UInt8] = [1, 2, 3, 4, 5, 6, 7, 8]
        context.global["buffer"] = JSObject(newArrayBufferWithBytes: bytes, in: context)
        
        context.evaluateScript("new DataView(buffer).setUint8(0, 5)")
        
        XCTAssertEqual(context["buffer"].copyBytes().map(Array.init), [5, 2, 3, 4, 5, 6, 7, 8])
        
    }
    
    func testSlice() {
        
        let context = JSContext()
        
        let bytes: [UInt8] = [1, 2, 3, 4, 5, 6, 7, 8]
        context.global["buffer"] = JSObject(newArrayBufferWithBytes: bytes, in: context)
        
        XCTAssertEqual(context.evaluateScript("buffer.slice(2, 4)").copyBytes().map(Array.init), [3, 4])
        
    }
    
}
