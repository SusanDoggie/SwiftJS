//
//  FunctionTest.swift
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

class FunctionTest: XCTestCase {
    
    func testConstructor() {
        
        let context = JSContext()
        
        let myClass = JSObject(newFunctionIn: context) { context, this, arguments in
            
            let result = arguments[0].doubleValue! + arguments[1].doubleValue!
            
            let object = JSObject(newObjectIn: context)
            object["result"] = JSObject(double: result, in: context)
            
            return object
        }
        
        XCTAssertTrue(myClass.isConstructor)
        
        context.global["myClass"] = myClass
        
        let result = context.evaluateScript("new myClass(1, 2)")
        XCTAssertNil(context.exception, "\(context.exception!)")
        
        XCTAssertTrue(result.isObject)
        XCTAssertEqual(result["result"].doubleValue, 3)
        
        XCTAssertTrue(result.isInstance(of: myClass))
    }
    
    func testFunction1() {
        
        let context = JSContext()
        
        let myFunction = JSObject(newFunctionIn: context) { context, this, arguments in
            
            let result = arguments[0].doubleValue! + arguments[1].doubleValue!
            
            return JSObject(double: result, in: context)
        }
        
        XCTAssertTrue(myFunction.isFunction)
        
        let result = myFunction.call(withArguments: [JSObject(double: 1, in: context), JSObject(double: 2, in: context)])
        XCTAssertNil(context.exception, "\(context.exception!)")
        
        XCTAssertTrue(result.isNumber)
        XCTAssertEqual(result.doubleValue, 3)
    }
    
    func testFunction2() {
        
        let context = JSContext()
        
        let myFunction = JSObject(newFunctionIn: context) { context, this, arguments in
            
            let result = arguments[0].doubleValue! + arguments[1].doubleValue!
            
            return JSObject(double: result, in: context)
        }
        
        XCTAssertTrue(myFunction.isFunction)
        
        context.global["myFunction"] = myFunction
        
        let result = context.evaluateScript("myFunction(1, 2)")
        XCTAssertNil(context.exception, "\(context.exception!)")
        
        XCTAssertTrue(result.isNumber)
        XCTAssertEqual(result.doubleValue, 3)
    }
    
}
