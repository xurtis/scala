// API for DOM

import JavaScriptKit

public extension JSClosure {
    static func typed<each Argument, Return>(
        _ body: @escaping (repeat each Argument) -> Return
    ) -> JSClosure
    where
        repeat each Argument: ConstructibleFromJSValue,
        Return: ConvertibleToJSValue
    {
        JSClosure { rawArguments in
            var rawArguments = rawArguments
            rawArguments.reverse()

            return body(
                repeat (each Argument).construct(from: rawArguments.removeLast())!
            ).jsValue
        }
    }

    static func typed<each Argument: ConstructibleFromJSValue>(
        _ body: @escaping (repeat each Argument) -> Void
    ) -> JSClosure {
        return self.typed { (argument: repeat each Argument) in
            body(repeat each argument)
            return JSValue.undefined
        }
    }
}

@JSClass(jsName: "Document")
public struct Document {
    @JSGetter
    public var body: JSElement

    @JSFunction
    public func createElement(_ name: String) throws -> JSElement

    @JSFunction
    public func createTextNode(_ data: String) throws -> JSText

    @JSFunction
    public func querySelector(_ name: String) throws -> Optional<JSElement>
}

@JSGetter(from: .global)
public var document: Document

// MARK: - Event Targets

public protocol JSEventTargetProtocol: _JSBridgedClass {
}

public extension JSEventTargetProtocol {
    var asEventTarget: JSEventTarget {
        JSEventTarget(unsafelyWrapping: self.jsObject)
    }
}

@JSClass(jsName: "EventTarget")
public struct JSEventTarget: JSEventTargetProtocol {
    @JSFunction
    func addEventListener(_ type: String, _ listener: JSValue) throws
}

// MARK: - Nodes

public protocol JSNodeProtocol: JSEventTargetProtocol, _JSBridgedClass {
}

public extension JSNodeProtocol {
    var asNode: JSNode {
        JSNode(unsafelyWrapping: self.jsObject)
    }
}

@JSClass(jsName: "Node")
public struct JSNode: JSNodeProtocol {
    @JSGetter
    var firstChild: JSNode?

    @JSGetter
    var lastChild: JSNode?

    @JSGetter
    var parentElement: JSElement?

    @JSGetter
    var parentNode: JSNode?

    @JSFunction
    func appendChild(_ node: JSNode) throws

    @JSFunction
    func removeChild(_ node: JSNode) throws

    @JSFunction
    func replaceChild(_ oldChild: JSNode, _ newChild: JSNode) throws
}

@JSClass(jsName: "Text")
public struct JSText: JSNodeProtocol {
}

// MARK: - Elements

public protocol JSElementProtocol: JSNodeProtocol, _JSBridgedClass {
}

public extension JSNodeProtocol {
    var asElement: JSElement {
        JSElement(unsafelyWrapping: self.jsObject)
    }
}

@JSClass
public struct JSElement: JSElementProtocol {
    @JSGetter
    var classList: JSDOMTokenList
}

// MARK: - Events

public protocol JSEventProtocol: ConstructibleFromJSValue, _JSBridgedClass {
}

public extension JSEventProtocol {
    static func construct(from value: JSValue) -> Self? {
        guard let object = value.object else {
            return nil
        }

        return Self(unsafelyWrapping: object)
    }
}

public extension JSEventProtocol {
    var asEvent: JSEvent {
        JSEvent(unsafelyWrapping: self.jsObject)
    }
}

@JSClass(jsName: "Event")
public struct JSEvent: JSEventProtocol {
    @JSGetter
    var bubbles: Bool

    @JSGetter
    var cancelable: Bool

    @JSGetter
    var composed: Bool

    @JSGetter
    var type: String

    @JSFunction
    func preventDefault() throws

    @JSFunction
    func stopImmediatePropagation() throws

    @JSFunction
    func stopPropagation() throws
}

@JSClass(jsName: "PointerEvent")
public struct JSPointerEvent: JSEventProtocol {}

// MARK: - TokenList

@JSClass(jsName: "DOMTokenList")
public struct JSDOMTokenList {
    @JSGetter
    var length: Int

    @JSFunction
    func add(_ token: String) throws

    @JSFunction
    func remove(_ token: String) throws

    @JSFunction
    func contains(_ token: String) throws -> Bool

    @JSFunction
    func replace(_ oldToken: String, _ newToken: String) throws

    @JSFunction
    func toggle(_ token: String) throws
}
