//
//  JSPropertyDescriptor.swift
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

public struct JSPropertyDescriptor {
    
    public let value: JSObject?
    
    public let writable: Bool?
    
    public let getter: ((JSObject) -> JSObject)?
    
    public let setter: ((JSObject, JSObject) -> Void)?
    
    public let configurable: Bool?
    
    public let enumerable: Bool?
    
    public init(
        value: JSObject? = nil,
        writable: Bool? = nil,
        getter: ((JSObject) -> JSObject)? = nil,
        setter: ((JSObject, JSObject) -> Void)? = nil,
        configurable: Bool? = nil,
        enumerable: Bool? = nil
    ) {
        precondition((value == nil && writable == nil) || (getter == nil && setter == nil), "Invalid descriptor type")
        self.value = value
        self.writable = writable
        self.getter = getter
        self.setter = setter
        self.configurable = configurable
        self.enumerable = enumerable
    }
}

extension JSObject {
    
    public func defineProperty(_ property: String, _ descriptor: JSPropertyDescriptor) {
        
        let desc = JSObject(newObjectIn: context)
        
        if let value = descriptor.value { desc["value"] = value }
        if let writable = descriptor.writable { desc["writable"] = JSObject(bool: writable, in: context) }
        if let getter = descriptor.getter {
            desc["get"] = JSObject(newFunctionIn: context) { _, this, _ in getter(this!) }
        }
        if let setter = descriptor.setter {
            desc["set"] = JSObject(newFunctionIn: context) { context, this, arguments in
                setter(this!, arguments[0])
                return JSObject(undefinedIn: context)
            }
        }
        if let configurable = descriptor.configurable { desc["configurable"] = JSObject(bool: configurable, in: context) }
        if let enumerable = descriptor.enumerable { desc["enumerable"] = JSObject(bool: enumerable, in: context) }
        
        _ = try? context.global["Object"].invokeMethod("defineProperty", withArguments: [self, JSObject(string: property, in: context), desc])
    }
}
