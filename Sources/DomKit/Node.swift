import JavaScriptKit

// MARK: - Node

/// An opaque node
public class AnyNode: Recomputable {
    /// The current DOM element to be placed into a parent
    var node: JSNode {
        fatalError("Not overridden")
    }

    /// Perform the update
    internal override func recompute() {
        /// Get the current node
        let currentNode = self.node

        /// Run update implementation
        self.update()

        /// Get the update node
        let newNode = self.node

        if newNode != currentNode {
            /// Replace the node in the parent
            guard
                let parent = try! currentNode.parentNode
            else {
                fatalError("Node has no parent node")
            }

            _ = try! parent.replaceChild(newNode, currentNode)
        }
    }

    /// Update the node
    func update() {
        fatalError("Attempted to update but not overridden")
    }
}

/// A node with typed state
public final class Node<State: DOMNode>: AnyNode & Computation {
    public var state: State
    private var nodeElement: JSElement
    private var modifiers: DOMModifiers = DOMModifiers()

    override var node: JSNode { self.nodeElement.asNode }

    init(_ state: State) {
        self.state = state
        self.nodeElement = try! document.createElement(State.tag)
        super.init()

        // Add all current children
        self.modifiers = State.view(ViewSource(self))
        self.modifiers.apply(to: self.nodeElement, forNode: self)

        self.update()
    }

    override func update() {
        self.modifiers.reapply(to: self.nodeElement, forNode: self)
    }
}

// MARK: - DOMNode

/// An element that is associated with a node in the DOM
public protocol DOMNode: Declaration, _DOMModifierProtocol {
    /// The tag used to create the node
    static var tag: String { get }

    /// The initial children of the node
    @DOMBuilder
    static func view(
        _ instance: ViewSource<Self>
    ) -> DOMModifiers
}

public extension DOMNode {
    typealias Source = ComputationInputs<Node<Self>>
    typealias Sync = EventOutputs<Node<Self>>

    /// By default make all nodes 'div'
    static var tag: String { "div" }

    /// By default produce no initial children
    @DOMBuilder
    static func view(
        _ source: ViewSource<Self>
    ) -> DOMModifiers {
    }

    /// Add modifiers from node
    func _addModifiers(to modifiers: inout DOMModifiers) {
        modifiers.append(Node(self))
    }
}

public typealias ViewSource<State: DOMNode> = ComputationInputs<Node<State>>
