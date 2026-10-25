import JavaScriptKit

/// Set the body of the HTML document
public func setBody(
    @DOMBuilder
    _ rootChildren: () -> DOMChildren
) {
    let body = try! document.body

    /// Remove existing children
    while true {
        let last: JSValue = body.lastChild
        guard !last.isNull else { break }
        _ = body.removeChild(last)
    }

    /// Add new children
    for child in rootChildren().nodes {
        _ = body.appendChild(child.element)
    }

}

/// An element in a sequence of DOM children
public protocol DOMElement {
    func _appendDOMChildren(to children: inout DOMChildren)
}

/// The children of a DOM element
public struct DOMChildren: DOMElement {
    internal var nodes: [AnyNode]

    private init(
        nodes: [AnyNode]
    ) {
        self.nodes = nodes
    }

    public func _appendDOMChildren(to children: inout DOMChildren) {
        children.nodes.append(contentsOf: self.nodes)
    }
}

internal extension DOMChildren {
    @usableFromInline
    init() {
        self.init(nodes: [])
    }
}

/// A result builder for DOM elements
@resultBuilder
public enum DOMBuilder {
    public static func buildExpression(
        _ expression: Text
    ) -> Text {
        expression
    }

    public static func buildExpression<Node: DOMNode>(
        _ expression: Node
    ) -> Node {
        expression
    }

    public static func buildExpression(
        _ expression: DOMChildren
    ) -> DOMChildren {
        expression
    }

    public static func buildBlock() -> DOMChildren {
        DOMChildren()
    }

    public static func buildPartialBlock(
        first: some DOMElement
    ) -> DOMChildren {
        var children = DOMChildren()
        first._appendDOMChildren(to: &children)
        return children
    }

    public static func buildPartialBlock(
        accumulated: DOMChildren,
        next: some DOMElement
    ) -> DOMChildren {
        var children = accumulated
        next._appendDOMChildren(to: &children)
        return children
    }
}
