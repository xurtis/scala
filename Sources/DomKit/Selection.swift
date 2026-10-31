// MARK: Combinators

fileprivate class SelectedNode<Selector: Hashable>: AnyNode {
    /// The source of the selection
    private let source: any UpdateSubscribable<Selector>

    /// The node to choose when empty
    private let empty: JSText

    /// Each selected choice
    private let choices: [Selector: Choice]

    /// The currently selected node
    private var selectedNode: JSNode

    private struct Choice {
        /// The node to present for the choice
        let element: JSElement

        /// The modifiers for the element
        let modifiers: DOMModifiers
    }

    fileprivate init(
        _ select: Select<Selector>
    ) {
        self.source = select.source
        self.empty = try! document.createTextNode("")
        self.choices = select.choices.mapValues { modifiers in
            let element = try! document.createElement("div")

            return Choice(
                element: element,
                modifiers: modifiers
            )
        }
        self.selectedNode = self.empty.asNode
        super.init()

        self.choices.values.forEach { choice in
            choice.modifiers.apply(to: choice.element, forNode: self)
        }

        self.update()
    }

    override var node: JSNode {
        self.selectedNode
    }

    override func update() {
        /// Update the selection
        let selection = self.source.readValue(forDependency: self)
        self.selectedNode =  self.choices[selection]?.element.asNode ?? self.empty.asNode

        self.choices.values.forEach { choice in
            choice.modifiers.apply(to: choice.element, forNode: self)
        }
    }
}

struct Select<Selector: Hashable>: _DOMModifierProtocol {
    let source: any UpdateSubscribable<Selector>
    let choices: [Selector: DOMModifiers]

    func _addModifiers(to modifiers: inout DOMModifiers) {
        modifiers.append(SelectedNode(self))
    }
}

public struct Selection<Selector: Hashable> {
    public func when(
        _ selector: Selector,
        @DOMBuilder modifiers: () -> DOMModifiers
    ) -> (selector: Selector, modifiers: DOMModifiers) {
        (selector, modifiers())
    }
}

public func select<Selector: Hashable>(
    _ selector: some UpdateSubscribable<Selector>,
    @SelectBuilder<Selector> choices: (
        Selection<Selector>
    ) -> [Selector: DOMModifiers]
) -> some _DOMModifierProtocol {
    Select(
        source: selector,
        choices: choices(Selection())
    )
}

@resultBuilder
public struct SelectBuilder<Selector: Hashable> {
    public static func buildBlock() -> [Selector: DOMModifiers] {
        [:]
    }

    public static func buildPartialBlock(
        first: (selector: Selector, modifiers: DOMModifiers)
    ) -> [Selector: DOMModifiers] {
        [first.selector: first.modifiers]
    }

    public static func buildPartialBlock(
        accumulated: [Selector: DOMModifiers],
        next: (selector: Selector, modifiers: DOMModifiers)
    ) -> [Selector: DOMModifiers] {
        var accumulated = accumulated
        accumulated[next.selector] = next.modifiers
        return accumulated
    }
}
