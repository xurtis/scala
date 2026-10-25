// Standard DOM nodes

import JavaScriptKit

/// A `div` DOM element
public struct Div: DOMNode {
    public static let tag = "div"
    public let initialChildren: DOMChildren

    public private(set) var handlers: [String: (JSValue) -> Void] = [:]

    public init(
        @DOMBuilder
        children: () -> DOMChildren = { DOMChildren() }
    ) {
        self.initialChildren = children()
    }

    static public func view(
        _ source: ViewSource<Self>
    ) -> DOMChildren {
        source.initialChildren
    }

    public consuming func on(
        _ event: String,
        _ handler: @escaping (JSValue) -> Void
    ) -> Self {
        self.handlers[event] = handler
        return self
    }
}

public struct H<let depth: Int>: DOMNode {
    public static var tag: String { "h\(depth)" }
    public let initialChildren: DOMChildren

    public init(
        @DOMBuilder
        children: () -> DOMChildren = { DOMChildren() }
    ) {
        self.initialChildren = children()
    }

    static public func view(
        _ source: ViewSource<Self>
    ) -> DOMChildren {
        source.initialChildren
    }
}
