import JavaScriptKit

/// Set the body of the HTML document
public func setBody(
    @DOMBuilder
    _ rootModifiers: () -> DOMModifiers
) {
    let body = try! document.body

    /// Remove existing children
    while let last = try! body.asNode.lastChild {
        _ = try! body.asNode.removeChild(last)
    }

    /// Add new children
    let modifiers = rootModifiers()
    modifiers.apply(to: body)

}
