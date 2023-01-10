//
//  JSFunction.swift
//
//  The MIT License
//  Copyright (c) 2015 - 2023 Susan Cheng. All rights reserved.
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

public typealias JSObjectCallAsFunctionCallback = (JSContext, JSObject?, [JSObject]) throws -> JSObject

private struct JSObjectCallbackInfo {
    
    unowned let context: JSContext
    
    let callback: JSObjectCallAsFunctionCallback
}

private func function_finalize(_ object: JSObjectRef?) -> Void {
    
    let info = JSObjectGetPrivate(object).assumingMemoryBound(to: JSObjectCallbackInfo.self)
    
    info.deinitialize(count: 1)
    info.deallocate()
}
private func function_constructor(
    _ ctx: JSContextRef?,
    _ object: JSObjectRef?,
    _ argumentCount: Int,
    _ arguments: UnsafePointer<JSValueRef?>?,
    _ exception: UnsafeMutablePointer<JSValueRef?>?
) -> JSObjectRef? {
    
    let info = JSObjectGetPrivate(object).assumingMemoryBound(to: JSObjectCallbackInfo.self)
    let context = info.pointee.context
    
    do {
        
        let arguments = (0..<argumentCount).map { JSObject(context: context, object: arguments![$0]!) }
        let result = try info.pointee.callback(context, nil, arguments)
        
        let prototype = JSObjectGetPrototype(context.context, object)
        JSObjectSetPrototype(context.context, result.object, prototype)
        
        return result.object
        
    } catch let error {
        
        let error = error as? JSObject ?? JSObject(newErrorFromMessage: "\(error)", in: context)
        exception?.pointee = error.object
        
        return nil
    }
}
private func function_callback(
    _ ctx: JSContextRef?,
    _ object: JSObjectRef?,
    _ this: JSObjectRef?,
    _ argumentCount: Int,
    _ arguments: UnsafePointer<JSValueRef?>?,
    _ exception: UnsafeMutablePointer<JSValueRef?>?
) -> JSValueRef? {
    
    let info = JSObjectGetPrivate(object).assumingMemoryBound(to: JSObjectCallbackInfo.self)
    let context = info.pointee.context
    
    do {
        
        let this = this.map { JSObject(context: context, object: $0) }
        let arguments = (0..<argumentCount).map { JSObject(context: context, object: arguments![$0]!) }
        let result = try info.pointee.callback(context, this, arguments)
        
        return result.object
        
    } catch let error {
        
        let error = error as? JSObject ?? JSObject(newErrorFromMessage: "\(error)", in: context)
        exception?.pointee = error.object
        
        return nil
    }
}

private func function_instanceof(
    _ ctx: JSContextRef?,
    _ constructor: JSObjectRef?,
    _ possibleInstance: JSValueRef?,
    _ exception: UnsafeMutablePointer<JSValueRef?>?
) -> Bool {
    
    let info = JSObjectGetPrivate(constructor).assumingMemoryBound(to: JSObjectCallbackInfo.self)
    
    let context = info.pointee.context
    
    let prototype_0 = JSObjectGetPrototype(context.context, constructor)
    let prototype_1 = JSObjectGetPrototype(context.context, possibleInstance)
    
    return JSValueIsStrictEqual(context.context, prototype_0, prototype_1)
}

extension JSObject {
    
    /// Creates a JavaScript value of the function type.
    ///
    /// - Parameters:
    ///   - context: The execution context to use.
    ///   - callback: The callback function.
    public convenience init(newFunctionIn context: JSContext, callback: @escaping JSObjectCallAsFunctionCallback) {
        
        let info: UnsafeMutablePointer<JSObjectCallbackInfo> = .allocate(capacity: 1)
        info.initialize(to: JSObjectCallbackInfo(context: context, callback: callback))
        
        var def = JSClassDefinition()
        def.finalize = function_finalize
        def.callAsConstructor = function_constructor
        def.callAsFunction = function_callback
        def.hasInstance = function_instanceof
        
        let _class = JSClassCreate(&def)
        defer { JSClassRelease(_class) }
        
        self.init(context: context, object: JSObjectMake(context.context, _class, info))
    }
}
