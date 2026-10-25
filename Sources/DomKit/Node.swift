import JavaScriptKit

// MARK: - Node

/// An opaque node
class AnyNode {
    /// Whether the node has been queued for an update
    private var updatePending: Bool = false

    /// The current DOM element to be placed into a parent
    var element: JSValue {
        fatalError("Not overridden")
    }

    /// Trigger an update to the node
    internal func triggerUpdate() {
        guard !self.updatePending else {
            /// Update already triggered
            return
        }

        /// Enqueue the update
        JSObject.global.window.setTimeout(JSClosure { arguments in
            self.performUpdate()
            return .undefined
        })

        self.updatePending = true
    }

    /// Perform the update
    private func performUpdate() {
        guard self.updatePending else {
            /// Update is not pending
            return
        }

        /// Clear the update pending flag
        self.updatePending = false

        /// Get the current element
        let currentElement = self.element

        /// Run update implementation
        self.update()

        /// Get the update element
        let newElement = self.element

        if newElement != currentElement {
            /// Replace the element in the parent
            let parent: JSValue = currentElement.parentNode
            if !parent.isNull {
                _ = parent.replaceChild(newElement, currentElement)
            }
        }
    }

    /// Update the node
    func update() {
        fatalError("Attempted to update but not overridden")
    }
}

/// A node with typed state
final class Node<State: DOMNode>: AnyNode {
    var state: State
    private var nodeElement: JSValue
    private var children = DOMChildren()

    override var element: JSValue { self.nodeElement }

    init(_ state: State) {
        self.state = state
        self.nodeElement = try! document.createElement(State.tag)
        super.init()

        /// Register all event handlers
        for (event, handler) in self.state.handlers {
            self.nodeElement.addEventListener(
                event,
                JSClosure { arguments in
                    handler(arguments[0])
                    return .undefined
                }
            )
        }

        // Add all current children
        self.children = State.view(ViewSource(self))
        for child in self.children.nodes {
            _ = self.nodeElement.appendChild(child.element)
        }

        self.update()
    }

    override func update() {
        /// Do nothing
    }
}

// MARK: - DOMNode

/// An element that is associated with a node in the DOM
public protocol DOMNode: DOMElement {
    /// The tag used to create the node
    static var tag: String { get }

    /// The initial children of the node
    @DOMBuilder
    static func view(
        _ instance: ViewSource<Self>
    ) -> DOMChildren

    /// The event handlers to register for the node
    var handlers: [String: (JSValue) -> Void] { get }
}

public extension DOMNode {
    func _appendDOMChildren(to children: inout DOMChildren) {
        children.nodes.append(Node(self))
    }

    /// By default make all nodes 'div'
    static var tag: String { "div" }

    /// By default produce no initial children
    @DOMBuilder
    static func view(
        _ source: ViewSource<Self>
    ) -> DOMChildren {
    }

    /// By default register no handlers
    var handlers: [String: (JSValue) -> Void] { [:] }
}

// MARK: - State

@propertyWrapper
public struct DOMState<Value> {
    private var stored: Value
    private var subscriptions: [Subscription] = []

    public var wrappedValue: Value {
        _read {
            yield self.stored
        }
    }

    public var projectedValue: Self {
        _read {
            yield self
        }
        _modify {
            yield &self
        }
    }

    public init(wrappedValue: Value) {
        self.stored = wrappedValue
    }

    /// Subscribe from a view constructor
    internal mutating func subscribe(
        from node: AnyNode
    ) -> Value {
        /// Track the subscription to the value
        self.subscriptions.append(Subscription(node: node))

        /// Return the current value
        return self.stored
    }

    /// Read from an event handler
    internal func read() -> Value {
        self.stored
    }

    /// Publish from an event handler
    internal mutating func publish(_ value: Value) {
        /// Update the value
        self.stored = value

        /// Notify all subscribers
        for subscription in self.subscriptions {
            if let node = subscription.node {
                node.triggerUpdate()
            }
        }

        /// Remove all subscriptions
        self.subscriptions.removeAll(keepingCapacity: true)
    }

    private struct Subscription {
        weak let node: AnyNode?
    }
}

// MARK: - View

/// A wrapper around a DOM node permitting construction of the output
/// tree
@dynamicMemberLookup
public struct ViewSource<State: DOMNode> {
    /// The wrapped handle to the node object
    private let node: Node<State>

    fileprivate init(_ node: Node<State>) {
        self.node = node
    }

    // Access a read-only property
    public subscript<Value>(
        dynamicMember path: KeyPath<State, Value>
    ) -> Value {
        self.node.state[keyPath: path]
    }

    /// Access a mutable property
    public subscript<Value>(
        dynamicMember path: WritableKeyPath<State, DOMState<Value>>
    ) -> ValueSubscription<State, Value> {
        ValueSubscription(
            node: node,
            path: path
        )
    }

    /// Send an event to the source
    public func send<Event: DOMNodeEvent<State>>(
        _ event: Event
    ) {
        /// Deliver the event to the node
        var target = EventTarget(self.node)
        event.deliver(toNode: &target)
    }
}

/// A subscription to a mutable value from a node
public struct ValueSubscription<State: DOMNode, Value> {
    let node: Node<State>
    let path: WritableKeyPath<State, DOMState<Value>>

    internal func subscribe(
        from node: AnyNode
    ) -> Value {
        self.node.state[keyPath: path].subscribe(from: node)
    }
}

// MARK: - Event

/// An event that can be triggered on a DOM node
public protocol DOMNodeEvent<Target> {
    /// The type of node to which the event is delivered
    associatedtype Target: DOMNode

    /// Deliver the event to the node
    func deliver(toNode node: inout EventTarget<Target>)
}

/// A wrapper around a DOM node permitting modification of
@dynamicMemberLookup
public struct EventTarget<State: DOMNode> {
    /// The wrapped handle to the node object
    private let node: Node<State>

    fileprivate init(_ node: Node<State>) {
        self.node = node
    }

    /// Access a read-only property
    public subscript<Value>(
        dynamicMember path: KeyPath<State, Value>
    ) -> Value {
        self.node.state[keyPath: path]
    }

    /// Access a mutable property
    public subscript<Value>(
        dynamicMember path: WritableKeyPath<State, DOMState<Value>>
    ) -> Value {
        get {
            /// Read the current value
            self.node.state[keyPath: path].read()
        }
        set(newValue) {
            /// Update the value and notify subscribers
            self.node.state[keyPath: path].publish(newValue)
        }
    }
}
