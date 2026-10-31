// Events

import JavaScriptKit

// MARK: - Event

public protocol EventProtocol {
    /// The string used to register the event handler
    static var type: String { get }

    /// The type of event object produced
    associatedtype Event: JSEventProtocol
}

internal protocol EventHandlerProtocol {
    /// The even type to register for
    var type: String { get }

    /// Produce the event handler closure
    var closure: JSClosure { get }
}

public struct EventHandler<Event: EventProtocol>: EventHandlerProtocol {
    public typealias Handler = (Event.Event) -> Void

    let handler: Handler

    public init(handler: @escaping Handler) {
        self.handler = handler
    }

    /// The event type to register for
    internal var type: String { Event.type }

    /// Handle the event
    internal var closure: JSClosure {
        JSClosure.typed(self.handler)
    }
}

public extension ComputationInputs {
    /// Construct an event handler
    func on<Event: EventProtocol>(
        _ eventType: Event.Type,
        handler: @escaping (inout EventOutputs<Object>, Event.Event) -> Void
    ) -> EventHandler<Event> {
        EventHandler(handler: self.eventHandler(handler))
    }
}

extension EventHandler: _DOMModifierProtocol {
    public func _addModifiers(to modifiers: inout DOMModifiers) {
        modifiers.handle(self)
    }
}

// MARK: - Events

// MARK: Click

public enum ClickEvent: EventProtocol {
    public static let type = "click"
    public typealias Event = JSPointerEvent
}

public extension EventProtocol {
    static var click: ClickEvent.Type { ClickEvent.self }
}
