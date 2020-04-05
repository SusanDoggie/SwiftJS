//
//  SwiftJSTest.swift
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
    
    func testClass() {
        
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
    
    func testGetter() {
        
        let context = JSContext()
        
        context.global["obj"] = JSObject(newObjectIn: context)
        
        let desc = JSPropertyDescriptor(
            getter: { this in JSObject(double: 3, in: this.context) }
        )
        
        context.global["obj"].defineProperty("three", desc)
        
        let result = context.evaluateScript("obj.three")
        XCTAssertNil(context.exception, "\(context.exception!)")
        
        XCTAssertEqual(result.doubleValue, 3)
    }
    
    func testSetter() {
        
        let context = JSContext()
        
        context.global["obj"] = JSObject(newObjectIn: context)
        
        let desc = JSPropertyDescriptor(
            getter: { this in this["number_container"] },
            setter: { this, newValue in this["number_container"] = newValue }
        )
        
        context.global["obj"].defineProperty("number", desc)
        
        context.evaluateScript("obj.number = 5")
        XCTAssertNil(context.exception, "\(context.exception!)")
        
        XCTAssertEqual(context.global["obj"]["number"].doubleValue, 5)
        XCTAssertEqual(context.global["obj"]["number_container"].doubleValue, 5)
        
        context.evaluateScript("obj.number = 3")
        XCTAssertNil(context.exception, "\(context.exception!)")
        
        XCTAssertEqual(context.global["obj"]["number"].doubleValue, 3)
        XCTAssertEqual(context.global["obj"]["number_container"].doubleValue, 3)
    }
    
}
