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

public class JSContext {
    
    public let virtualMachine: JSVirtualMachine
    
    let context: JSContextRef
    
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
    
    public var globalObject: JSObject {
        return JSObject(context: self, object: JSContextGetGlobalObject(context))
    }
}

extension JSContext {
    
    public func checkScriptSyntax(_ script: String, sourceURL: URL? = nil, startingLineNumber: Int = 0) throws -> Bool {
        
        let script = script.withCString(JSStringCreateWithUTF8CString)
        defer { JSStringRelease(script) }
        
        let sourceURL = sourceURL?.path.withCString(JSStringCreateWithUTF8CString)
        defer { sourceURL.map(JSStringRelease) }
        
        var exception: JSObjectRef?
        
        let result = JSCheckScriptSyntax(context, script, sourceURL, Int32(startingLineNumber), &exception)
        
        if let exception = exception { throw JSObject(context: self, object: exception) }
        
        return result
    }
    
    public func evaluateScript(_ script: String, thisObject: JSObjectRef? = nil, sourceURL: URL? = nil, startingLineNumber: Int = 0) throws -> JSObject {
        
        let script = script.withCString(JSStringCreateWithUTF8CString)
        defer { JSStringRelease(script) }
        
        let sourceURL = sourceURL?.path.withCString(JSStringCreateWithUTF8CString)
        defer { sourceURL.map(JSStringRelease) }
        
        var exception: JSObjectRef?
        
        let result = JSEvaluateScript(context, script, thisObject, sourceURL, Int32(startingLineNumber), &exception)
        
        if let exception = exception { throw JSObject(context: self, object: exception) }
        
        return JSObject(context: self, object: result!)
    }
    
    public func garbageCollect() {
        JSGarbageCollect(context)
    }
    
}
