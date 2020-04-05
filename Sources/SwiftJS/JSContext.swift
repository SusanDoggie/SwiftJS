//
//  JSContext.swift
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

open class JSContext {
    
    public let virtualMachine: JSVirtualMachine
    
    let context: JSGlobalContextRef
    
    open private(set) var exception: JSObject?
    
    open var exceptionHandler: ((JSContext, JSObject) -> Void)?
    
    public convenience init() {
        self.init(virtualMachine: JSVirtualMachine())
    }
    
    public init(virtualMachine: JSVirtualMachine) {
        self.virtualMachine = virtualMachine
        self.context = JSGlobalContextCreateInGroup(virtualMachine.group, nil)
    }
    
    deinit {
        JSGlobalContextRelease(context)
    }
    
}

extension JSContext {
    
    var _exception: JSObjectRef? {
        get {
            exception = nil
            return nil
        }
        set {
            
            guard let newValue = newValue else { return }
            
            if let callback = exceptionHandler {
                callback(self, JSObject(context: self, object: newValue))
            } else {
                exception = JSObject(context: self, object: newValue)
            }
        }
    }
}

extension JSContext {
    
    open var global: JSObject {
        return JSObject(context: self, object: JSContextGetGlobalObject(context))
    }
    
    open func garbageCollect() {
        JSGarbageCollect(context)
    }
}

extension JSContext {
    
    open var properties: [String] {
        return global.properties
    }
    
    open func hasProperty(_ property: String) -> Bool {
        return global.hasProperty(property)
    }
    
    @discardableResult
    open func removeProperty(_ property: String) -> Bool {
        return global.removeProperty(property)
    }
    
    open subscript(property: String) -> JSObject {
        get {
            return global[property]
        }
        set {
            global[property] = newValue
        }
    }
}

extension JSContext {
    
    open func checkScriptSyntax(_ script: String, sourceURL: URL? = nil, startingLineNumber: Int = 0) -> Bool {
        
        let script = script.withCString(JSStringCreateWithUTF8CString)
        defer { JSStringRelease(script) }
        
        let sourceURL = sourceURL?.absoluteString.withCString(JSStringCreateWithUTF8CString)
        defer { sourceURL.map(JSStringRelease) }
        
        return JSCheckScriptSyntax(context, script, sourceURL, Int32(startingLineNumber), &_exception)
    }
    
    @discardableResult
    open func evaluateScript(_ script: String, this: JSObjectRef? = nil, sourceURL: URL? = nil, startingLineNumber: Int = 0) -> JSObject {
        
        let script = script.withCString(JSStringCreateWithUTF8CString)
        defer { JSStringRelease(script) }
        
        let sourceURL = sourceURL?.absoluteString.withCString(JSStringCreateWithUTF8CString)
        defer { sourceURL.map(JSStringRelease) }
        
        let result = JSEvaluateScript(context, script, this, sourceURL, Int32(startingLineNumber), &_exception)
        
        return result.map { JSObject(context: self, object: $0) } ?? JSObject(undefinedIn: self)
    }
}
