// Standard DOM nodes

import JavaScriptKit

/// A standard DOM node type
final class StandardNode: AnyNode {
    private(set) var standardElement: JSElement

    /// Need to hold onto modifiers to keep them in the tree
    private let modifiers: DOMModifiers

    override var node: JSNode {
        self.standardElement.asNode
    }

    fileprivate init(
        _ element: StandardElement
    ) {
        self.standardElement = try! document.createElement(element.tag)
        self.modifiers = element.modifiers
        super.init()

        self.modifiers.apply(to: self.standardElement, forNode: self)
    }

    override func update() {
        self.modifiers.reapply(to: self.standardElement, forNode: self)
    }
}

public struct StandardElement: _DOMModifierProtocol {
    /// The tag of the element
    let tag: String

    /// The node modifiers
    let modifiers: DOMModifiers

    fileprivate init(
        tag: String,
        modifiers: DOMModifiers
    ) {
        self.tag = tag
        self.modifiers = modifiers
    }

    public func _addModifiers(to modifiers: inout DOMModifiers) {
        modifiers.append(StandardNode(self))
    }
}

public func h(
    _ depth: UInt = 1,
    @DOMBuilder
    modifiers: () -> DOMModifiers = { DOMModifiers() }
) -> StandardElement {
    StandardElement(
        tag: "h\(depth)",
        modifiers: modifiers()
    )
}

public func div(
    @DOMBuilder
    modifiers: () -> DOMModifiers = { DOMModifiers() }
) -> StandardElement {
    StandardElement(
        tag: "div",
        modifiers: modifiers()
    )
}

public func ul(
    @DOMBuilder
    modifiers: () -> DOMModifiers = { DOMModifiers() }
) -> StandardElement {
    StandardElement(
        tag: "ul",
        modifiers: modifiers()
    )
}

public func ol(
    @DOMBuilder
    modifiers: () -> DOMModifiers = { DOMModifiers() }
) -> StandardElement {
    StandardElement(
        tag: "ol",
        modifiers: modifiers()
    )
}

public func li(
    @DOMBuilder
    modifiers: () -> DOMModifiers = { DOMModifiers() }
) -> StandardElement {
    StandardElement(
        tag: "li",
        modifiers: modifiers()
    )
}
