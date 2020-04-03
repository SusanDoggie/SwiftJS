//
//  JSValue.swift
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

public class JSObject {
    
    public let context: JSContext
    
    let object: JSObjectRef
    
    init(context: JSContext, object: JSObjectRef) {
        JSValueProtect(context.context, object)
        self.context = context
        self.object = object
    }
    
    deinit {
        JSValueUnprotect(context.context, object)
    }
}

extension JSObject {
    
    public convenience init(undefinedIn context: JSContext) {
        self.init(context: context, object: JSValueMakeUndefined(context.context))
    }
    
    public convenience init(nullIn context: JSContext) {
        self.init(context: context, object: JSValueMakeNull(context.context))
    }
    
    public convenience init(bool value: Bool, in context: JSContext) {
        self.init(context: context, object: JSValueMakeBoolean(context.context, value))
    }
    
    public convenience init(double value: Double, in context: JSContext) {
        self.init(context: context, object: JSValueMakeNumber(context.context, value))
    }
    
    public convenience init(string value: String, in context: JSContext) {
        let value = value.withCString(JSStringCreateWithUTF8CString)
        defer { JSStringRelease(value) }
        self.init(context: context, object: JSValueMakeString(context.context, value))
    }
    
    public convenience init(newRegularExpressionFromPattern pattern: String, flags: String, in context: JSContext) throws {
        
        let arguments = [JSObject(string: pattern, in: context), JSObject(string: flags, in: context)]
        
        var exception: JSObjectRef?
        
        let object = JSObjectMakeRegExp(context.context, 2, arguments.map { $0.object }, &exception)
        
        if let exception = exception { throw JSObject(context: context, object: exception) }
        
        self.init(context: context, object: object!)
    }
    
    public convenience init(newErrorFromMessage message: String, in context: JSContext) {
        let arguments = [JSObject(string: message, in: context)]
        self.init(context: context, object: JSObjectMakeError(context.context, 1, arguments.map { $0.object }, nil))
    }
    
    public convenience init(newObjectIn context: JSContext) {
        self.init(context: context, object: JSObjectMake(context.context, nil, nil))
    }
    
    public convenience init(newArrayIn context: JSContext) {
        self.init(context: context, object: JSObjectMakeArray(context.context, 0, nil, nil))
    }
}

extension JSObject {
    
    public convenience init(function name: String?,
                            parameters: [String],
                            body: String,
                            sourceURL: URL? = nil,
                            startingLineNumber: Int = 0,
                            in context: JSContext) throws {
        
        let name = name?.withCString(JSStringCreateWithUTF8CString)
        defer { name.map(JSStringRelease) }
        
        let parameters = parameters.map { $0.withCString(JSStringCreateWithUTF8CString) }
        defer { parameters.forEach(JSStringRelease) }
        
        let body = body.withCString(JSStringCreateWithUTF8CString)
        defer { JSStringRelease(body) }
        
        let sourceURL = sourceURL?.path.withCString(JSStringCreateWithUTF8CString)
        defer { sourceURL.map(JSStringRelease) }
        
        var exception: JSObjectRef?
        
        let object = JSObjectMakeFunction(
            context.context,
            name,
            UInt32(parameters.count),
            parameters.isEmpty ? nil : parameters,
            body,
            sourceURL,
            Int32(startingLineNumber),
            &exception
        )
        
        if let exception = exception { throw JSObject(context: context, object: exception) }
        
        self.init(context: context, object: object!)
    }
    
}

extension JSObject: CustomStringConvertible {
    
    public var description: String {
        
        if self.isUndefined { return "undefined" }
        if self.isNull { return "null" }
        if self.isBoolean { return "\(self.boolValue)" }
        if self.isNumber { return "\(self.doubleValue!)" }
        if self.isString { return "\(self.stringValue!)" }
        
        if self.isArray {
            let count = Int(self.value(forProperty: "length").doubleValue ?? 0)
            return "\((0..<count).map(self.value))"
        }
        
        if self.isObject {
            
            var object: [String: JSObject] = [:]
            
            for property in self.propertyNames {
                object[property] = self.value(forProperty: property)
            }
            
            return "\(object)"
        }
        
        return "unknown"
    }
}

extension JSObject: Error {
    
}

extension JSObject {
    
    public var isUndefined: Bool {
        return JSValueIsUndefined(context.context, object)
    }
    
    public var isNull: Bool {
        return JSValueIsNull(context.context, object)
    }
    
    public var isBoolean: Bool {
        return JSValueIsBoolean(context.context, object)
    }
    
    public var isNumber: Bool {
        return JSValueIsNumber(context.context, object)
    }
    
    public var isString: Bool {
        return JSValueIsString(context.context, object)
    }
    
    public var isObject: Bool {
        return JSValueIsObject(context.context, object)
    }
    
    public var isArray: Bool {
        guard self.isObject else { return false }
        let arrayClass = context.globalObject.value(forProperty: "Array")
        guard let result = try? arrayClass.invokeMethod("isArray", withArguments: [self]) else { return false }
        return JSValueToBoolean(context.context, result.object)
    }
    
    public var isConstructor: Bool {
        return JSObjectIsConstructor(context.context, object)
    }
    
    public var isFunction: Bool {
        return JSObjectIsFunction(context.context, object)
    }
    
}

extension JSObject {
    
    public var boolValue: Bool {
        return JSValueToBoolean(context.context, object)
    }
    
    public var doubleValue: Double? {
        var exception: JSObjectRef?
        let result = JSValueToNumber(context.context, object, &exception)
        return exception == nil ? result : nil
    }
    
    public var stringValue: String? {
        
        var exception: JSObjectRef?
        
        let str = JSValueToStringCopy(context.context, object, &exception)
        defer { JSStringRelease(str) }
        
        guard exception == nil else { return nil }
        
        return String(str!)
    }
    
}

extension JSObject {
    
    public func call(withArguments arguments: [JSObject]) throws -> JSObject {
        
        var exception: JSObjectRef?
        
        let result = JSObjectCallAsFunction(context.context, object, nil, arguments.count, arguments.map { $0.object }, &exception)
        
        if let exception = exception { throw JSObject(context: context, object: exception) }
        
        return JSObject(context: context, object: result!)
    }
    
    public func construct(withArguments arguments: [JSObject]) throws -> JSObject {
        
        var exception: JSObjectRef?
        
        let result = JSObjectCallAsConstructor(context.context, object, arguments.count, arguments.map { $0.object }, &exception)
        
        if let exception = exception { throw JSObject(context: context, object: exception) }
        
        return JSObject(context: context, object: result!)
    }
    
    public func invokeMethod(_ name: String, withArguments arguments: [JSObject]) throws -> JSObject {
        
        let method = self.value(forProperty: name)
        
        var exception: JSObjectRef?
        
        let result = JSObjectCallAsFunction(context.context, method.object, object, arguments.count, arguments.map { $0.object }, &exception)
        
        if let exception = exception { throw JSObject(context: context, object: exception) }
        
        return JSObject(context: context, object: result!)
    }
}

extension JSObject {
    
    public func isEqual(to other: JSObject) -> Bool {
        return JSValueIsStrictEqual(context.context, object, other.object)
    }
    
    public func isEqualWithTypeCoercion(to other: JSObject) -> Bool {
        return JSValueIsEqual(context.context, object, other.object, nil)
    }
    
    public func isInstance(of other: JSObject) -> Bool {
        return JSValueIsInstanceOfConstructor(context.context, object, other.object, nil)
    }
}

extension JSObject {
    
    public var propertyNames: [String] {
        
        let _list = JSObjectCopyPropertyNames(context.context, object)
        defer { JSPropertyNameArrayRelease(_list) }
        
        let count = JSPropertyNameArrayGetCount(_list)
        let list = (0..<count).map { JSPropertyNameArrayGetNameAtIndex(_list, $0)! }
        defer { list.forEach(JSStringRelease) }
        
        return list.map(String.init)
    }
    
    public func hasProperty(_ property: String) -> Bool {
        let property = property.withCString(JSStringCreateWithUTF8CString)
        defer { JSStringRelease(property) }
        return JSObjectHasProperty(context.context, object, property)
    }
    
    public func deleteProperty(_ property: String) -> Bool {
        let property = property.withCString(JSStringCreateWithUTF8CString)
        defer { JSStringRelease(property) }
        return JSObjectDeleteProperty(context.context, object, property, nil)
    }
    
    public func value(forProperty property: String) -> JSObject {
        let property = JSStringCreateWithUTF8CString(property)
        defer { JSStringRelease(property) }
        let result = JSObjectGetProperty(context.context, object, property, nil)
        return JSObject(context: context, object: result!)
    }
    
    public func setValue(_ value: JSObject, forProperty property: String) {
        let property = JSStringCreateWithUTF8CString(property)
        defer { JSStringRelease(property) }
        JSObjectSetProperty(context.context, object, property, value.object, 0, nil)
    }
    
    public func value(at index: Int) -> JSObject {
        let result = JSObjectGetPropertyAtIndex(context.context, object, UInt32(index), nil)
        return JSObject(context: context, object: result!)
    }
    
    public func setValue(_ value: JSObject, at index: Int) {
        JSObjectSetPropertyAtIndex(context.context, object, UInt32(index), value.object, nil)
    }
}
