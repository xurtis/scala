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
    public static func buildExpression<Element: _DOMModifierProtocol>(
        _ expression: Element
    ) -> Element {
        expression
    }

    @inline(always)
    public static func buildExpression<Class: DOMClass>(
        _ expression: Class
    ) -> ClassModifier<Class> {
        ClassModifier(expression)
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

    /// Dynamic conditions
    struct Condition {
        let condition: (AnyNode) -> Bool
    }

    /// Configured classes
    private(set) var classes: [String: Condition?] = [:]

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
        self.classes[insertedClass.rawValue] = .some(nil)
    }

    mutating func insert(
        _ insertedClass: some DOMClass,
        when condition: @escaping (AnyNode) -> Bool
    ) {
        self.classes[insertedClass.rawValue] = Condition(
            condition: condition
        )
    }

    mutating func handle(
        _ handler: some EventHandlerProtocol
    ) {
        self.eventHandlers.append(handler)
    }
}

extension DOMModifiers: _DOMModifierProtocol {
    public func _addModifiers(to modifiers: inout DOMModifiers) {
        modifiers.children.append(contentsOf: self.children)
        modifiers.classes.merge(self.classes) { left, right in
            guard case (nil, nil) = (left, right) else {
                fatalError("can't have overlapping condiionals")
            }

            return nil
        }
        modifiers.eventHandlers.append(contentsOf: self.eventHandlers)
    }
}

internal extension DOMModifiers {
    func apply(
        to element: some JSElementProtocol,
        forNode node: AnyNode
    ) {
        let element = element.asElement

        let elementNode = element.asNode
        for child in self.children {
            try! elementNode.appendChild(child.node)
        }

        let classList = try! element.classList
        for (className, condition) in self.classes {
            if let condition {
                if condition.condition(node) {
                    try! classList.add(className)
                }
            } else {
                try! classList.add(className)
            }
        }

        let eventTarget = element.asEventTarget
        for handler in self.eventHandlers {
            try! eventTarget.addEventListener(
                handler.type,
                handler.closure.jsValue
            )
        }
    }

    func reapply(
        to element: some JSElementProtocol,
        forNode node: AnyNode
    ) {
        let element = element.asElement

        let classList = try! element.classList
        for (className, condition) in self.classes {
            guard let condition else {
                continue
            }

            if condition.condition(node) {
                try! classList.add(className)
            } else {
                try! classList.remove(className)
            }
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

public extension DOMClass {
    func when<Subscribable: UpdateSubscribable>(
        _ subscribable: Subscribable,
        condition: @escaping (Subscribable.Value) -> Bool
    ) -> ConditionalClassModifier<Self> {
        ConditionalClassModifier(domClass: self) { node in
            condition(subscribable.readValue(forDependency: node))
        }
    }
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

public struct ConditionalClassModifier<Class: DOMClass>: _DOMModifierProtocol {
    private let domClass: Class
    private let condition: (AnyNode) -> Bool

    fileprivate init(
        domClass: Class,
        condition: @escaping (AnyNode) -> Bool
    ) {
        self.domClass = domClass
        self.condition = condition
    }

    public func _addModifiers(to modifiers: inout DOMModifiers) {
        modifiers.insert(self.domClass, when: self.condition)
    }
}
