//
//  JSValue.swift
//
//  The MIT License
//  Copyright (c) 2015 - 2022 Susan Cheng. All rights reserved.
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

#if canImport(JavaScriptCore)

import JavaScriptCore

#else

import CJSCore

#endif

/// A JavaScript object.
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
    
    private static let rfc3339: DateFormatter = {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "en_US_POSIX")
        formatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ss.SSS'Z'"
        formatter.timeZone = TimeZone(abbreviation: "UTC")
        return formatter
    }()
}

extension JSObject {
    
    public convenience init(json: Json, in context: JSContext) {
        if let json = json.json() {
            let json = json.withCString(JSStringCreateWithUTF8CString)
            defer { JSStringRelease(json) }
            self.init(context: context, object: JSValueMakeFromJSONString(context.context, json))
        } else {
            self.init(context: context, object: JSValueMakeNull(context.context))
        }
    }
}

extension JSObject {
    
    /// Creates a JavaScript value of the `undefined` type.
    /// 
    /// - Parameters:
    ///   - context: The execution context to use.
    public convenience init(undefinedIn context: JSContext) {
        self.init(context: context, object: JSValueMakeUndefined(context.context))
    }
    
    /// Creates a JavaScript value of the `null` type.
    ///
    /// - Parameters:
    ///   - context: The execution context to use.
    public convenience init(nullIn context: JSContext) {
        self.init(context: context, object: JSValueMakeNull(context.context))
    }
    
    /// Creates a JavaScript `Boolean` value.
    ///
    /// - Parameters:
    ///   - value: The value to assign to the object.
    ///   - context: The execution context to use.
    public convenience init(bool value: Bool, in context: JSContext) {
        self.init(context: context, object: JSValueMakeBoolean(context.context, value))
    }
    
    /// Creates a JavaScript value of the `Number` type.
    ///
    /// - Parameters:
    ///   - value: The value to assign to the object.
    ///   - context: The execution context to use.
    public convenience init(double value: Double, in context: JSContext) {
        self.init(context: context, object: JSValueMakeNumber(context.context, value))
    }
    
    /// Creates a JavaScript value of the `String` type.
    ///
    /// - Parameters:
    ///   - value: The value to assign to the object.
    ///   - context: The execution context to use.
    public convenience init(string value: String, in context: JSContext) {
        let value = value.withCString(JSStringCreateWithUTF8CString)
        defer { JSStringRelease(value) }
        self.init(context: context, object: JSValueMakeString(context.context, value))
    }
    
    /// Creates a JavaScript `Date` object, as if by invoking the built-in `RegExp` constructor.
    ///
    /// - Parameters:
    ///   - value: The value to assign to the object.
    ///   - context: The execution context to use.
    public convenience init(date value: Date, in context: JSContext) {
        let arguments = [JSObject(string: JSObject.rfc3339.string(from: value), in: context)]
        let object = JSObjectMakeDate(context.context, 1, arguments.map { $0.object }, &context._exception)
        self.init(context: context, object: object!)
    }
    
    /// Creates a JavaScript `RegExp` object, as if by invoking the built-in `RegExp` constructor.
    ///
    /// - Parameters:
    ///   - pattern: The pattern of regular expression.
    ///   - flags: The flags pass to the constructor.
    ///   - context: The execution context to use.
    public convenience init(newRegularExpressionFromPattern pattern: String, flags: String, in context: JSContext) {
        let arguments = [JSObject(string: pattern, in: context), JSObject(string: flags, in: context)]
        let object = JSObjectMakeRegExp(context.context, 2, arguments.map { $0.object }, &context._exception)
        self.init(context: context, object: object!)
    }
    
    /// Creates a JavaScript `Error` object, as if by invoking the built-in `Error` constructor.
    ///
    /// - Parameters:
    ///   - message: The error message.
    ///   - context: The execution context to use.
    public convenience init(newErrorFromMessage message: String, in context: JSContext) {
        let arguments = [JSObject(string: message, in: context)]
        self.init(context: context, object: JSObjectMakeError(context.context, 1, arguments.map { $0.object }, &context._exception))
    }
    
    /// Creates a JavaScript `Object`.
    ///
    /// - Parameters:
    ///   - context: The execution context to use.
    public convenience init(newObjectIn context: JSContext) {
        self.init(context: context, object: JSObjectMake(context.context, nil, nil))
    }
    
    /// Creates a JavaScript `Object` with prototype.
    ///
    /// - Parameters:
    ///   - context: The execution context to use.
    ///   - prototype: The prototype to be used.
    public convenience init(newObjectIn context: JSContext, prototype: JSObject) {
        let obj = context.global["Object"].invokeMethod("create", withArguments: [prototype])
        self.init(context: context, object: obj.object)
    }
    
    /// Creates a JavaScript `Array` object.
    ///
    /// - Parameters:
    ///   - context: The execution context to use.
    public convenience init(newArrayIn context: JSContext) {
        self.init(context: context, object: JSObjectMakeArray(context.context, 0, nil, &context._exception))
    }
}

extension JSObject: CustomStringConvertible {
    
    public var description: String {
        if self.isUndefined { return "undefined" }
        if self.isNull { return "null" }
        if self.isBoolean { return "\(self.boolValue!)" }
        if self.isNumber { return "\(self.doubleValue!)" }
        if self.isString { return "\"\(self.stringValue!.unicodeScalars.reduce(into: "") { $0 += $1.escaped(asASCII: false) })\"" }
        return self.invokeMethod("toString", withArguments: []).stringValue!
    }
}

extension JSObject: Error {
    
}

extension JSObject {
    
    /// Object’s prototype.
    public var prototype: JSObject {
        get {
            let prototype = JSObjectGetPrototype(context.context, object)
            return prototype.map { JSObject(context: context, object: $0) } ?? JSObject(undefinedIn: context)
        }
        set {
            JSObjectSetPrototype(context.context, object, newValue.object)
        }
    }
}

extension JSObject {
    
    /// Tests whether a JavaScript value’s type is the undefined type.
    public var isUndefined: Bool {
        return JSValueIsUndefined(context.context, object)
    }
    
    /// Tests whether a JavaScript value’s type is the null type.
    public var isNull: Bool {
        return JSValueIsNull(context.context, object)
    }
    
    /// Tests whether a JavaScript value is Boolean.
    public var isBoolean: Bool {
        return JSValueIsBoolean(context.context, object)
    }
    
    /// Tests whether a JavaScript value’s type is the number type.
    public var isNumber: Bool {
        return JSValueIsNumber(context.context, object)
    }
    
    /// Tests whether a JavaScript value’s type is the string type.
    public var isString: Bool {
        return JSValueIsString(context.context, object)
    }
    
    /// Tests whether a JavaScript value’s type is the object type.
    public var isObject: Bool {
        return JSValueIsObject(context.context, object)
    }
    
    /// Tests whether a JavaScript value’s type is the date type.
    public var isDate: Bool {
        return self.isInstance(of: context.global["Date"])
    }
    
    /// Tests whether a JavaScript value’s type is the array type.
    public var isArray: Bool {
        let result = context.global["Array"].invokeMethod("isArray", withArguments: [self])
        return JSValueToBoolean(context.context, result.object)
    }
    
    /// Tests whether an object can be called as a constructor.
    public var isConstructor: Bool {
        return JSObjectIsConstructor(context.context, object)
    }
    
    /// Tests whether an object can be called as a function.
    public var isFunction: Bool {
        return JSObjectIsFunction(context.context, object)
    }
    
    /// Tests whether a JavaScript value’s type is the error type.
    public var isError: Bool {
        return self.isInstance(of: context.global["Error"])
    }
}

extension JSObject {
    
    public var isFrozen: Bool {
        return context.global["Object"].invokeMethod("isFrozen", withArguments: [self]).boolValue ?? false
    }
    
    public var isExtensible: Bool {
        return context.global["Object"].invokeMethod("isExtensible", withArguments: [self]).boolValue ?? false
    }
    
    public var isSealed: Bool {
        return context.global["Object"].invokeMethod("isSealed", withArguments: [self]).boolValue ?? false
    }
    
    public func freeze() {
        context.global["Object"].invokeMethod("freeze", withArguments: [self])
    }
    
    public func preventExtensions() {
        context.global["Object"].invokeMethod("preventExtensions", withArguments: [self])
    }
    
    public func seal() {
        context.global["Object"].invokeMethod("seal", withArguments: [self])
    }
}

extension JSObject {
    
    /// Returns the JavaScript boolean value.
    public var boolValue: Bool? {
        guard self.isBoolean else { return nil }
        return JSValueToBoolean(context.context, object)
    }
    
    /// Returns the JavaScript number value.
    public var doubleValue: Double? {
        guard self.isNumber else { return nil }
        var exception: JSObjectRef?
        let result = JSValueToNumber(context.context, object, &exception)
        return exception == nil ? result : nil
    }
    
    /// Returns the JavaScript string value.
    public var stringValue: String? {
        guard self.isString else { return nil }
        let str = JSValueToStringCopy(context.context, object, nil)
        defer { str.map(JSStringRelease) }
        return str.map(String.init)
    }
    
    /// Returns the JavaScript date value.
    public var dateValue: Date? {
        guard self.isDate else { return nil }
        let result = self.invokeMethod("toISOString", withArguments: [])
        return result.stringValue.flatMap { JSObject.rfc3339.date(from: $0) }
    }
    
    /// Returns the JavaScript array.
    public var array: [JSObject]? {
        guard self.isArray else { return nil }
        return (0..<self.count).map { self[$0] }
    }
    
    /// Returns the JavaScript object as dictionary.
    public var dictionary: [String: JSObject]? {
        guard self.isObject else { return nil }
        return self.properties.reduce(into: [:]) { $0[$1] = self[$1] }
    }
}

extension JSObject {
    
    public func toJson() -> Json? {
        let str = JSValueCreateJSONString(context.context, object, 0, nil)
        defer { str.map(JSStringRelease) }
        return str.map(String.init).flatMap { try? Json(decode: $0) }
    }
}

extension JSObject {
    
    /// Calls an object as a function.
    ///
    /// - Parameters:
    ///   - arguments: The arguments pass to the function.
    ///   - this: The object to use as `this`, or `nil` to use the global object as `this`.
    ///
    /// - Returns: The object that results from calling object as a function
    @discardableResult
    public func call(withArguments arguments: [JSObject], this: JSObject? = nil) -> JSObject {
        let result = JSObjectCallAsFunction(context.context, object, this?.object, arguments.count, arguments.isEmpty ? nil : arguments.map { $0.object }, &context._exception)
        return result.map { JSObject(context: context, object: $0) } ?? JSObject(undefinedIn: context)
    }
    
    /// Calls an object as a constructor.
    ///
    /// - Parameters:
    ///   - arguments: The arguments pass to the function.
    ///   
    /// - Returns: The object that results from calling object as a constructor.
    public func construct(withArguments arguments: [JSObject]) -> JSObject {
        let result = JSObjectCallAsConstructor(context.context, object, arguments.count, arguments.isEmpty ? nil : arguments.map { $0.object }, &context._exception)
        return result.map { JSObject(context: context, object: $0) } ?? JSObject(undefinedIn: context)
    }
    
    /// Invoke an object's method.
    ///
    /// - Parameters:
    ///   - name: The name of method.
    ///   - arguments: The arguments pass to the function.
    ///
    /// - Returns: The object that results from calling the method.
    @discardableResult
    public func invokeMethod(_ name: String, withArguments arguments: [JSObject]) -> JSObject {
        return self[name].call(withArguments: arguments, this: self)
    }
}

extension JSObject {
    
    /// Tests whether two JavaScript values are strict equal, as compared by the JS `===` operator.
    ///
    /// - Parameters:
    ///   - other: The other value to be compare.
    ///   
    /// - Returns: true if the two values are strict equal; otherwise false.
    public func isEqual(to other: JSObject) -> Bool {
        return JSValueIsStrictEqual(context.context, object, other.object)
    }
    
    /// Tests whether two JavaScript values are equal, as compared by the JS `==` operator.
    ///
    /// - Parameters:
    ///   - other: The other value to be compare.
    ///   
    /// - Returns: true if the two values are equal; false if they are not equal or an exception is thrown.
    public func isEqualWithTypeCoercion(to other: JSObject) -> Bool {
        return JSValueIsEqual(context.context, object, other.object, &context._exception)
    }
    
    /// Tests whether a JavaScript value is an object constructed by a given constructor, as compared by the `isInstance(of:)` operator.
    ///
    /// - Parameters:
    ///   - other: The constructor to test against.
    ///   
    /// - Returns: true if the value is an object constructed by constructor, as compared by the JS isInstance(of:) operator; otherwise false.
    public func isInstance(of other: JSObject) -> Bool {
        return JSValueIsInstanceOfConstructor(context.context, object, other.object, &context._exception)
    }
}

extension JSObject {
    
    /// Get the names of an object’s enumerable properties.
    public var properties: [String] {
        
        let _list = JSObjectCopyPropertyNames(context.context, object)
        defer { JSPropertyNameArrayRelease(_list) }
        
        let count = JSPropertyNameArrayGetCount(_list)
        let list = (0..<count).map { JSPropertyNameArrayGetNameAtIndex(_list, $0)! }
        
        return list.map(String.init)
    }
    
    /// Tests whether an object has a given property.
    ///
    /// - Parameters:
    ///   - property: The property's name.
    ///   
    /// - Returns: true if the object has `property`, otherwise false.
    public func hasProperty(_ property: String) -> Bool {
        let property = property.withCString(JSStringCreateWithUTF8CString)
        defer { JSStringRelease(property) }
        return JSObjectHasProperty(context.context, object, property)
    }
    
    /// Deletes a property from an object.
    ///
    /// - Parameters:
    ///   - property: The property's name.
    ///   
    /// - Returns: true if the delete operation succeeds, otherwise false.
    @discardableResult
    public func removeProperty(_ property: String) -> Bool {
        let property = property.withCString(JSStringCreateWithUTF8CString)
        defer { JSStringRelease(property) }
        return JSObjectDeleteProperty(context.context, object, property, &context._exception)
    }
    
    /// The value of the property.
    public subscript(property: String) -> JSObject {
        get {
            let property = JSStringCreateWithUTF8CString(property)
            defer { JSStringRelease(property) }
            let result = JSObjectGetProperty(context.context, object, property, &context._exception)
            return result.map { JSObject(context: context, object: $0) } ?? JSObject(undefinedIn: context)
        }
        set {
            let property = JSStringCreateWithUTF8CString(property)
            defer { JSStringRelease(property) }
            JSObjectSetProperty(context.context, object, property, newValue.object, 0, &context._exception)
        }
    }
}

extension JSObject {
    
    /// The length of the object.
    public var count: Int {
        return Int(self["length"].doubleValue ?? 0)
    }
    
    /// The value in object at index.
    public subscript(index: Int) -> JSObject {
        get {
            let result = JSObjectGetPropertyAtIndex(context.context, object, UInt32(index), &context._exception)
            return result.map { JSObject(context: context, object: $0) } ?? JSObject(undefinedIn: context)
        }
        set {
            JSObjectSetPropertyAtIndex(context.context, object, UInt32(index), newValue.object, &context._exception)
        }
    }
}
