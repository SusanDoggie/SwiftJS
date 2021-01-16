//
//  SwiftJSTest.swift
//
//  The MIT License
//  Copyright (c) 2015 - 2021 Susan Cheng. All rights reserved.
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

class SwiftJSTest: XCTestCase {
    
    func testCalculation() {
        
        let context = JSContext()
        
        let result = context.evaluateScript("1 + 1")
        XCTAssertNil(context.exception, "\(context.exception!)")
        
        XCTAssertTrue(result.isNumber)
        XCTAssertEqual(result.doubleValue, 2)
    }
    
    func testArray() {
        
        let context = JSContext()
        
        let result = context.evaluateScript("[1 + 2, \"BMW\", \"Volvo\"]")
        XCTAssertNil(context.exception, "\(context.exception!)")
        
        XCTAssertTrue(result.isArray)
        
        let length = result["length"]
        XCTAssertEqual(length.doubleValue, 3)
        
        XCTAssertEqual(result[0].doubleValue, 3)
        XCTAssertEqual(result[1].stringValue, "BMW")
        XCTAssertEqual(result[2].stringValue, "Volvo")
    }
    
}
