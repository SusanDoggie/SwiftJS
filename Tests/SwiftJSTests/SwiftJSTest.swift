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
        
        do {
            
            let result = try context.evaluateScript("1 + 1")
            
            XCTAssertTrue(result.isNumber)
            XCTAssertEqual(result.doubleValue, 2)
            
        } catch let error {
            
            XCTFail("\((error as? JSObject)?["message"] ?? error)")
        }
    }
    
    func testArray() {
        
        let context = JSContext()
        
        do {
            
            let result = try context.evaluateScript("[1 + 2, \"BMW\", \"Volvo\"]")
            
            XCTAssertTrue(result.isArray)
            
            let length = result["length"]
            XCTAssertEqual(length.doubleValue, 3)
            
            XCTAssertEqual(result[0].doubleValue, 3)
            XCTAssertEqual(result[1].stringValue, "BMW")
            XCTAssertEqual(result[2].stringValue, "Volvo")
            
        } catch let error {
            
            XCTFail("\((error as? JSObject)?["message"] ?? error)")
        }
    }
    
    func testFunction1() {
        
        let context = JSContext()
        
        do {
            
            let myFunction = JSObject(newFunctionIn: context) { context, this, arguments in
                
                let result = arguments[0].doubleValue! + arguments[1].doubleValue!
                
                return JSObject(double: result, in: context)
            }
            
            XCTAssertTrue(myFunction.isFunction)
            
            let result = try myFunction.call(withArguments: [JSObject(double: 1, in: context), JSObject(double: 2, in: context)])
            
            XCTAssertTrue(result.isNumber)
            XCTAssertEqual(result.doubleValue, 3)
            
        } catch let error {
            
            XCTFail("\((error as? JSObject)?["message"] ?? error)")
        }
    }
    
    func testFunction2() {
        
        let context = JSContext()
        
        do {
            
            let myFunction = JSObject(newFunctionIn: context) { context, this, arguments in
                
                let result = arguments[0].doubleValue! + arguments[1].doubleValue!
                
                return JSObject(double: result, in: context)
            }
            
            XCTAssertTrue(myFunction.isFunction)
            
            context.global["myFunction"] = myFunction
            
            let result = try context.evaluateScript("myFunction(1, 2)")
            
            XCTAssertTrue(result.isNumber)
            XCTAssertEqual(result.doubleValue, 3)
            
        } catch let error {
            
            XCTFail("\((error as? JSObject)?["message"] ?? error)")
        }
    }
    
    func testClass() {
        
        let context = JSContext()
        
        do {
            
            let myClass = JSObject(newFunctionIn: context) { context, this, arguments in
                
                let result = arguments[0].doubleValue! + arguments[1].doubleValue!
                
                let object = JSObject(newObjectIn: context)
                object["result"] = JSObject(double: result, in: context)
                
                return object
            }
            
            XCTAssertTrue(myClass.isConstructor)
            
            context.global["myClass"] = myClass
            
            let result = try context.evaluateScript("new myClass(1, 2)")
            
            XCTAssertTrue(result.isObject)
            XCTAssertEqual(result["result"].doubleValue, 3)
            
            XCTAssertTrue(result.isInstance(of: myClass))
            
        } catch let error {
            
            XCTFail("\((error as? JSObject)?["message"] ?? error)")
        }
    }
    
    func testGetter() {
        
        let context = JSContext()
        
        do {
            
            context.global["obj"] = JSObject(newObjectIn: context)
            
            let desc = JSPropertyDescriptor(getter: JSObject(newFunctionIn: context) { context, _, _ in
                return JSObject(double: 3, in: context)
            })
            
            context.global["obj"].defineProperty("three", desc)
            
            let result = try context.evaluateScript("obj.three")
            
            XCTAssertEqual(result.doubleValue, 3)
            
        } catch let error {
            
            XCTFail("\((error as? JSObject)?["message"] ?? error)")
        }
    }
    
    func testSetter() {
        
        let context = JSContext()
        
        do {
            
            context.global["obj"] = JSObject(newObjectIn: context)
            
            let desc = JSPropertyDescriptor(getter: JSObject(newFunctionIn: context) { context, this, _ in
                
                return this?["number_container"] ?? JSObject(undefinedIn: context)
                
                }, setter: JSObject(newFunctionIn: context) { context, this, arguments in
                    
                    this?["number_container"] = arguments[0]
                    
                    return JSObject(undefinedIn: context)
            })
            
            context.global["obj"].defineProperty("number", desc)
            
            try context.evaluateScript("obj.number = 5")
            
            XCTAssertEqual(context.global["obj"]["number"].doubleValue, 5)
            XCTAssertEqual(context.global["obj"]["number_container"].doubleValue, 5)
            
            try context.evaluateScript("obj.number = 3")
            
            XCTAssertEqual(context.global["obj"]["number"].doubleValue, 3)
            XCTAssertEqual(context.global["obj"]["number_container"].doubleValue, 3)
            
        } catch let error {
            
            XCTFail("\((error as? JSObject)?["message"] ?? error)")
        }
    }
    
}
