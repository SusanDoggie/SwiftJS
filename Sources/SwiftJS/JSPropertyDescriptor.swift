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
    
    let _getter: JSObject?
    
    let _setter: JSObject?
    
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
        self._getter = nil
        self._setter = nil
        self.getter = getter
        self.setter = setter
        self.configurable = configurable
        self.enumerable = enumerable
    }
    
    public init(
        getter: JSObject? = nil,
        setter: JSObject? = nil,
        configurable: Bool? = nil,
        enumerable: Bool? = nil
    ) {
        precondition(getter?.isFunction != false, "Invalid getter type")
        precondition(setter?.isFunction != false, "Invalid setter type")
        self.value = nil
        self.writable = nil
        self._getter = getter
        self._setter = setter
        self.getter = getter.map { getter in { this in
            let context = this.context
            let result = JSObjectCallAsFunction(context.context, getter.object, this.object, 0, nil, &context._exception)
            return result.map { JSObject(context: context, object: $0) } ?? JSObject(undefinedIn: context)
            } }
        self.setter = setter.map { setter in { this, newValue in
            let context = this.context
            JSObjectCallAsFunction(context.context, setter.object, this.object, 1, [newValue.object], &context._exception)
            } }
        self.configurable = configurable
        self.enumerable = enumerable
    }
}

extension JSObject {
    
    /// Defines a property on the JavaScript object value or modifies a property’s definition.
    ///
    /// The descriptor determines the behavior of the JavaScript property, and must fit one of three cases:
    ///
    /// - Data Descriptor: Contains one or both of the keys value and writable, and optionally also contains the keys enumerable or configurable.
    ///   Cannot contain the keys get or set. Use a data descriptor to create or modify the attributes of a data property on an object (replacing any
    ///   existing accessor property).
    ///
    /// - Accessor Descriptor: Contains one or both of the keys get or set, and optionally also contains the keys enumerable or configurable.
    ///   Cannot contain the keys value and writable. Use an accessor descriptor to create or modify the attributes of an accessor property on
    ///   an object (replacing any existing data property).
    ///
    ///   For example:
    ///
    ///       let desc = JSPropertyDescriptor(
    ///           getter: { this in this["private_val"] },
    ///           setter: { this, newValue in this["private_val"] = newValue }
    ///       )
    ///
    /// - Generic Descriptor: Contains one or both of the keys enumerable or configurable, and cannot contain any other keys. Use a genetic
    ///   descriptor to modify the attributes of an existing data or accessor property, or to create a new data property.
    ///
    /// - Parameters:
    ///   - property: The property's name.
    ///   - descriptor: The descriptor object.
    /// - Returns: true if the operation succeeds, otherwise false.
    @discardableResult
    public func defineProperty(_ property: String, _ descriptor: JSPropertyDescriptor) -> Bool {
        
        let desc = JSObject(newObjectIn: context)
        
        if let value = descriptor.value { desc["value"] = value }
        if let writable = descriptor.writable { desc["writable"] = JSObject(bool: writable, in: context) }
        if let getter = descriptor._getter {
            desc["get"] = getter
        } else if let getter = descriptor.getter {
            desc["get"] = JSObject(newFunctionIn: context) { _, this, _ in getter(this!) }
        }
        if let setter = descriptor._setter {
            desc["set"] = setter
        } else if let setter = descriptor.setter {
            desc["set"] = JSObject(newFunctionIn: context) { context, this, arguments in
                setter(this!, arguments[0])
                return JSObject(undefinedIn: context)
            }
        }
        if let configurable = descriptor.configurable { desc["configurable"] = JSObject(bool: configurable, in: context) }
        if let enumerable = descriptor.enumerable { desc["enumerable"] = JSObject(bool: enumerable, in: context) }
        
        context.global["Object"].invokeMethod("defineProperty", withArguments: [self, JSObject(string: property, in: context), desc])
        
        return context.exception == nil
    }
    
    public func propertyDescriptor(_ property: String) -> JSObject {
        return context.global["Object"].invokeMethod("getOwnPropertyDescriptor", withArguments: [self, JSObject(string: property, in: context)])
    }
}
