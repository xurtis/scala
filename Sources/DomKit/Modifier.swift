// Modifiers of DOM nodes

import JavaScriptKit

/// A result builder for DOM elements
@resultBuilder
public enum DOMBuilder {
    @inline(always)
    public static func buildExpression(
        _ expression: Text
    ) -> Text {
        expression
    }

    @inline(always)
    public static func buildExpression(
        _ expression: StandardElement
    ) -> StandardElement {
        expression
    }

    @inline(always)
    public static func buildExpression<Node: DOMNode>(
        _ expression: Node
    ) -> Node {
        expression
    }

    @inline(always)
    public static func buildExpression<Class: DOMClass>(
        _ expression: Class
    ) -> ClassModifier<Class> {
        ClassModifier(expression)
    }

    @inline(always)
    public static func buildExpression<Event: EventProtocol>(
        _ expression: EventHandler<Event>
    ) -> EventHandler<Event> {
        expression
    }

    @inline(always)
    public static func buildBlock() -> DOMModifiers {
        DOMModifiers()
    }

    @inline(always)
    public static func buildPartialBlock(
        first: some _DOMModifierProtocol
    ) -> DOMModifiers {
        var modifiers = DOMModifiers()
        first._addModifiers(to: &modifiers)
        return modifiers
    }

    @inline(always)
    public static func buildPartialBlock(
        accumulated: DOMModifiers,
        next: some _DOMModifierProtocol
    ) -> DOMModifiers {
        var modifiers = accumulated
        next._addModifiers(to: &modifiers)
        return modifiers
    }
}

// MARK: - Modifiers

/// The modifiers that configure a DOM node
public struct DOMModifiers {
    /// Appended child nodes
    private(set) var children: [AnyNode] = []

    /// Configured classes
    private(set) var classes: Set<String> = []

    /// Configured event handlers
    private(set) var eventHandlers: [any EventHandlerProtocol] = []

    @usableFromInline
    init() {}
}

internal extension DOMModifiers {
    mutating func append(_ child: AnyNode) {
        self.children.append(child)
    }

    mutating func insert(_ insertedClass: some DOMClass) {
        self.classes.insert(insertedClass.rawValue)
    }

    mutating func handle(
        _ handler: some EventHandlerProtocol
    ) {
        self.eventHandlers.append(handler)
    }
}

internal extension DOMModifiers {
    consuming func apply(to element: some JSElementProtocol) {
        let element = element.asElement

        let node = element.asNode
        for child in self.children {
            try! node.appendChild(child.node)
        }

        let classList = try! element.classList
        for className in self.classes {
            try! classList.add(className)
        }

        let eventTarget = element.asEventTarget
        for handler in self.eventHandlers {
            try! eventTarget.addEventListener(
                handler.type,
                handler.closure.jsValue
            )
        }
    }
}

// MARK: DOMModifierProtocol

public protocol _DOMModifierProtocol {
    func _addModifiers(to modifiers: inout DOMModifiers)
}

// MARK: - Class

public protocol DOMClass: RawRepresentable<String> {
}

public struct ClassModifier<Class: DOMClass>: _DOMModifierProtocol {
    let domClass: Class

    public init(_ domClass: Class) {
        self.domClass = domClass
    }

    public func _addModifiers(to modifiers: inout DOMModifiers) {
        modifiers.insert(self.domClass)
    }
}
