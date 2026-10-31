import JavaScriptKit

/// Text in a DOM

public struct Text: _DOMModifierProtocol {
    let interpolation: TextInterpolation

    private init(interpolation: TextInterpolation) {
        self.interpolation = interpolation
    }

    public func _addModifiers(to modifiers: inout DOMModifiers) {
        modifiers.append(TextNode(interpolation: self.interpolation))
    }
}

extension Text: ExpressibleByStringInterpolation {
    public init(stringLiteral value: String) {
        self.init(interpolation: TextInterpolation(literal: value))
    }

    public init(stringInterpolation interpolation: TextInterpolation) {
        self.init(interpolation: interpolation)
    }
}

final class TextNode: AnyNode {
    private let interpolation: TextInterpolation
    private(set) var textNode: JSText

    override var node: JSNode {
        self.textNode.asNode
    }

    fileprivate init(
        interpolation: TextInterpolation
    ) {
        self.interpolation = interpolation
        self.textNode = try! document.createTextNode("")
        super.init()

        /// Update once to create the interpolation and subscribe
        self.update()
    }

    override func update() {
        self.textNode = try! document.createTextNode(
            self.interpolation.interpolate(
                from: self
            )
        )
    }
}

// MARK: - Interpolation

public struct TextInterpolation: StringInterpolationProtocol {
    fileprivate private(set) var interpolations: [any TextInterpolationElement] = []

    fileprivate func interpolate(from node: AnyNode) -> String {
        self.interpolations.map { $0.interpolate(from: node) }.joined()
    }

    fileprivate init(literal: String) {
        self.interpolations = [literal]
    }

    public init(literalCapacity: Int, interpolationCount: Int) {
        self.interpolations.reserveCapacity(
            literalCapacity + interpolationCount
        )
    }

    public mutating func appendLiteral(_ literal: String) {
        self.interpolations.append(literal)
    }

    public mutating func appendInterpolation<Value: CustomStringConvertible>(
        _ value: Value
    ) {
        self.interpolations.append(value.description)
    }

    public mutating func appendInterpolation<Object, Member>(
        _ interpolation: MutableInput<Object, Member>
    )
    where
        Member.Value: CustomStringConvertible
    {
        self.interpolations.append(interpolation)
    }

    public mutating func appendInterpolation<Object, Member, Element>(
        _ interpolation: MutableInputElement<Object, Member, Element>
    )
    where
        Element: CustomStringConvertible
    {
        self.interpolations.append(interpolation)
    }
}

fileprivate protocol TextInterpolationElement {
    func interpolate(from node: AnyNode) -> String
}

extension String: TextInterpolationElement {
    func interpolate(from node: AnyNode) -> String {
        self
    }
}

extension UpdateSubscribable
where
    Self: TextInterpolationElement,
    Value: CustomStringConvertible
{
    func interpolate(from node: AnyNode) -> String {
        self.readValue(forDependency: node).description
    }
}

extension MutableInput: TextInterpolationElement
where
    Member.Value: CustomStringConvertible
{}

extension MutableInputElement: TextInterpolationElement
where
    Element: CustomStringConvertible
{}
