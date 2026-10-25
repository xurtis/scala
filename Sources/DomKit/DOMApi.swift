// API for DOM

import JavaScriptKit

@JSClass
public struct Document {
    @JSGetter public var body: JSValue

    @JSFunction
    public func createElement(_ name: String) throws -> JSValue

    @JSFunction
    public func createTextNode(_ data: String) throws -> JSValue

    @JSFunction
    public func querySelector(_ name: String) throws -> Optional<JSValue>
}

@JSGetter(from: .global)
public var document: Document
