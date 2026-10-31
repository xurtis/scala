import JavaScriptKit

fileprivate final class BodyNode: AnyNode, @unchecked Sendable {
    static let root = BodyNode()

    private let body: JSElement
    private var modifiers: DOMModifiers = DOMModifiers()

    override var node: JSNode { self.body.asNode }

    override init() {
        self.body = try! document.body
        super.init()
    }

    override func update() {
        self.modifiers.reapply(to: self.body, forNode: self)
    }

    fileprivate func replace(
        with modifiers: DOMModifiers
    ) {
        let body = try! document.body

        /// Remove existing children
        while let last = try! body.asNode.lastChild {
            _ = try! body.asNode.removeChild(last)
        }

        /// Add new children
        self.modifiers = modifiers
        self.modifiers.apply(to: body, forNode: self)
    }
}

/// Set the body of the HTML document
public func setBody(
    @DOMBuilder
    _ rootModifiers: () -> DOMModifiers
) {
    BodyNode.root.replace(with: rootModifiers())

}
