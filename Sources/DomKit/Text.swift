import JavaScriptKit

/// Text in a DOM

public struct Text: DOMElement {
    let interpolation: TextInterpolation

    private init(interpolation: TextInterpolation) {
        self.interpolation = interpolation
    }

    public func _appendDOMChildren(to children: inout DOMChildren) {
        children.nodes.append(
            TextNode(interpolation: self.interpolation)
        )
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
    private(set) var textElement: JSValue

    override var element: JSValue {
        self.textElement
    }

    fileprivate init(
        interpolation: TextInterpolation
    ) {
        self.interpolation = interpolation
        self.textElement = try! document.createTextNode("")
        super.init()

        /// Update once to create the interpolation and subscribe
        self.update()
    }

    override func update() {
        self.textElement = try! document.createTextNode(
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

    public mutating func appendInterpolation<State: DOMNode, Value: CustomStringConvertible>(
        _ interpolation: ValueSubscription<State, Value>
    ) {
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

extension ValueSubscription: TextInterpolationElement
where
    Value: CustomStringConvertible
{
    func interpolate(from node: AnyNode) -> String {
        self.subscribe(from: node).description
    }
}
