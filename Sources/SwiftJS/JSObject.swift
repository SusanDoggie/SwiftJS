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

public typealias JSObjectCallAsFunctionCallback = (JSContext, JSObject?, [JSObject]) -> Result<JSObject, JSObject>

extension JSObject {
    
    private struct CallbackInfo {
        
        unowned let context: JSContext
        
        let callback: JSObjectCallAsFunctionCallback
    }
    
    public convenience init(newFunctionIn context: JSContext, callback: @escaping JSObjectCallAsFunctionCallback) {
        
        let info: UnsafeMutablePointer<CallbackInfo> = .allocate(capacity: 1)
        info.initialize(to: CallbackInfo(context: context, callback: callback))
        
        var def = JSClassDefinition()
        
        def.finalize = { object in
            
            let info = JSObjectGetPrivate(object).assumingMemoryBound(to: CallbackInfo.self)
            
            info.deinitialize(count: 1)
            info.deallocate()
        }
        
        def.callAsConstructor = { _, object, argumentCount, arguments, exception in
            
            let info = JSObjectGetPrivate(object).assumingMemoryBound(to: CallbackInfo.self)
            
            let context = info.pointee.context
            
            let arguments = (0..<argumentCount).map { JSObject(context: context, object: arguments![$0]!) }
            
            let result = info.pointee.callback(context, nil, arguments)
            
            switch result {
            case let .success(value):
                
                let prototype = JSObjectGetPrototype(context.context, object)
                JSObjectSetPrototype(context.context, value.object, prototype)
                
                return value.object
                
            case let .failure(error):
                
                exception?.pointee = error.object
                return nil
            }
        }
        
        def.callAsFunction = { _, object, thisObject, argumentCount, arguments, exception in
            
            let info = JSObjectGetPrivate(object).assumingMemoryBound(to: CallbackInfo.self)
            
            let context = info.pointee.context
            
            let thisObject = thisObject.map { JSObject(context: context, object: $0) }
            let arguments = (0..<argumentCount).map { JSObject(context: context, object: arguments![$0]!) }
            
            let result = info.pointee.callback(context, thisObject, arguments)
            
            switch result {
            case let .success(value):
                
                return value.object
                
            case let .failure(error):
                
                exception?.pointee = error.object
                return nil
            }
        }
        
        def.hasInstance = { _, constructor, possibleInstance, exception in
            
            let info = JSObjectGetPrivate(constructor).assumingMemoryBound(to: CallbackInfo.self)
            
            let context = info.pointee.context
            
            let prototype_0 = JSObjectGetPrototype(context.context, constructor)
            let prototype_1 = JSObjectGetPrototype(context.context, possibleInstance)
            
            return JSValueIsStrictEqual(context.context, prototype_0, prototype_1)
        }
        
        let _class = JSClassCreate(&def)
        defer { JSClassRelease(_class) }
        
        self.init(context: context, object: JSObjectMake(context.context, _class, info))
    }
}

extension JSObject: CustomStringConvertible {
    
    public var description: String {
        
        if self.isUndefined { return "undefined" }
        if self.isNull { return "null" }
        if self.isBoolean { return "\(self.boolValue)" }
        if self.isNumber { return "\(self.doubleValue!)" }
        if self.isString { return "\"\(self.stringValue!.unicodeScalars.reduce(into: "") { $0 += $1.escaped(asASCII: false) })\"" }
        
        let description = try? self.invokeMethod("toString", withArguments: [])
        return description?.stringValue ?? "unknown"
    }
}

extension JSObject: Error {
    
}

extension JSObject {
    
    public var prototype: JSObject {
        get {
            let prototype = JSObjectGetPrototype(context.context, object)
            return JSObject(context: context, object: prototype!)
        }
        set {
            JSObjectSetPrototype(context.context, object, newValue.object)
        }
    }
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
        let arrayClass = context.global["Array"]
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
        let str = JSValueToStringCopy(context.context, object, nil)
        defer { str.map(JSStringRelease) }
        return str.map(String.init)
    }
    
    public var array: [JSObject]? {
        guard self.isArray else { return nil }
        return (0..<self.count).map { self[$0] }
    }
    
    public var dictionary: [String: JSObject] {
        return self.properties.reduce(into: [:]) { $0[$1] = self[$1] }
    }
}

extension JSObject {
    
    public func call(withArguments arguments: [JSObject]) throws -> JSObject {
        
        var exception: JSObjectRef?
        
        let result = JSObjectCallAsFunction(context.context, object, nil, arguments.count, arguments.isEmpty ? nil : arguments.map { $0.object }, &exception)
        
        if let exception = exception { throw JSObject(context: context, object: exception) }
        
        return JSObject(context: context, object: result!)
    }
    
    public func construct(withArguments arguments: [JSObject]) throws -> JSObject {
        
        var exception: JSObjectRef?
        
        let result = JSObjectCallAsConstructor(context.context, object, arguments.count, arguments.isEmpty ? nil : arguments.map { $0.object }, &exception)
        
        if let exception = exception { throw JSObject(context: context, object: exception) }
        
        return JSObject(context: context, object: result!)
    }
    
    public func invokeMethod(_ name: String, withArguments arguments: [JSObject]) throws -> JSObject {
        
        let method = self[name]
        
        var exception: JSObjectRef?
        
        let result = JSObjectCallAsFunction(context.context, method.object, object, arguments.count, arguments.isEmpty ? nil : arguments.map { $0.object }, &exception)
        
        if let exception = exception { throw JSObject(context: context, object: exception) }
        
        return JSObject(context: context, object: result!)
    }
}

extension JSObject {
    
    /// Tests whether two JavaScript values are strict equal, as compared by the JS `===` operator.
    /// - Parameter other: The other value to be compare.
    /// - Returns: true if the two values are strict equal; otherwise false.
    public func isEquåal(to other: JSObject) -> Bool {
        return JSValueIsStrictEqual(context.context, object, other.object)
    }
    
    /// Tests whether two JavaScript values are equal, as compared by the JS `==` operator.
    /// - Parameter other: The other value to be compare.
    /// - Returns: true if the two values are equal; false if they are not equal or an exception is thrown.
    public func isEqualWithTypeCoercion(to other: JSObject) -> Bool {
        return JSValueIsEqual(context.context, object, other.object, nil)
    }
    
    /// Tests whether a JavaScript value is an object constructed by a given constructor, as compared by the `isInstance(of:)` operator.
    /// - Parameter other: The constructor to test against.
    /// - Returns: true if the value is an object constructed by constructor, as compared by the JS isInstance(of:) operator; otherwise false.
    public func isInstance(of other: JSObject) -> Bool {
        return JSValueIsInstanceOfConstructor(context.context, object, other.object, nil)
    }
}

extension JSObject {
    
    /// Get the names of an object’s enumerable properties.
    public var properties: [String] {
        
        let _list = JSObjectCopyPropertyNames(context.context, object)
        defer { JSPropertyNameArrayRelease(_list) }
        
        let count = JSPropertyNameArrayGetCount(_list)
        let list = (0..<count).map { JSPropertyNameArrayGetNameAtIndex(_list, $0)! }
        defer { list.forEach(JSStringRelease) }
        
        return list.map(String.init)
    }
    
    /// Tests whether an object has a given property.
    /// - Parameter property: A the property's name.
    /// - Returns: true if the object has `property`, otherwise false.
    public func hasProperty(_ property: String) -> Bool {
        let property = property.withCString(JSStringCreateWithUTF8CString)
        defer { JSStringRelease(property) }
        return JSObjectHasProperty(context.context, object, property)
    }
    
    /// Deletes a property from an object.
    /// - Parameter property: A the property's name.
    /// - Returns: true if the delete operation succeeds, otherwise false.
    @discardableResult public func removeProperty(_ property: String) -> Bool {
        let property = property.withCString(JSStringCreateWithUTF8CString)
        defer { JSStringRelease(property) }
        return JSObjectDeleteProperty(context.context, object, property, nil)
    }
    
    public subscript(property: String) -> JSObject {
        get {
            let property = JSStringCreateWithUTF8CString(property)
            defer { JSStringRelease(property) }
            let result = JSObjectGetProperty(context.context, object, property, nil)
            return JSObject(context: context, object: result!)
        }
        set {
            let property = JSStringCreateWithUTF8CString(property)
            defer { JSStringRelease(property) }
            JSObjectSetProperty(context.context, object, property, newValue.object, 0, nil)
        }
    }
}

extension JSObject {
    
    public var count: Int {
        guard self.isArray else { return 0 }
        return Int(self["length"].doubleValue ?? 0)
    }
    
    public subscript(index: Int) -> JSObject {
        get {
            let result = JSObjectGetPropertyAtIndex(context.context, object, UInt32(index), nil)
            return JSObject(context: context, object: result!)
        }
        set {
            JSObjectSetPropertyAtIndex(context.context, object, UInt32(index), newValue.object, nil)
        }
    }
}
