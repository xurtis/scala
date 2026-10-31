// Dependency tracking and recomputation

import JavaScriptKit

// MARK: - Protocols

// MARK: Constant

/// A value that will never be updated
public protocol Constant<ConstantValue> {
    associatedtype ConstantValue = Self

    var constantValue: ConstantValue { get }
}

public extension Constant where ConstantValue == Self {
    var constantValue: ConstantValue { self }
}

extension Bool: Constant {}
extension String: Constant {}
extension UInt: Constant {}
extension UInt8: Constant {}
extension UInt16: Constant {}
extension UInt32: Constant {}
extension UInt64: Constant {}
extension Int: Constant {}
extension Int8: Constant {}
extension Int16: Constant {}
extension Int32: Constant {}
extension Int64: Constant {}

extension Array: Constant
where
    Element: Constant
{}
extension Dictionary: Constant
where
    Key: Constant,
    Value: Constant
{}

// MARK: UpdateTrackable

/// A value that subscribes readers for update notifications
public protocol UpdateSubscribable<Value> {
    associatedtype Value

    func readValue(
        forDependency dependency: some Recomputable
    ) -> Value
}

// MARK: Updatable

/// A value that will need to notify dependencies when it changes
public protocol Updatable<Value> {
    associatedtype Value

    /// The current value
    var currentValue: Value { get }

    /// The list of dependencies
    var dependencies: UpdateDependencies { get set }
}

internal extension Updatable {
    /// Trigger all dependencies to update
    mutating func recomputeDependencies() {
        self.dependencies.recompute()
    }

    /// Read the value for a dependency
    mutating func readValue(
        forDependency dependency: some Recomputable
    ) -> Value {
        self.dependencies.register(dependency: dependency)
        return self.currentValue
    }
}

// MARK: Declaration

/// A type that represents a declaration of some computed value
public protocol Declaration {
}

public extension Declaration {
    /// Declare a constant
    static func const<Value>(
        ofType type: Value.Type = Value.self,
        _ definition: () -> Value
    ) -> Const<Value> {
        Const(definition())
    }
}

// MARK: Computation

/// An object that can be recomputed when its state is changed
public protocol Computation<State>: Recomputable {
    associatedtype State: Declaration

    var state: State { get set }
}

// MARK: - Wrappers

// MARK: Constant

/// A wrapper to mark a value as explicitly constant
@propertyWrapper
public struct Const<ConstantValue>: Constant {
    public let constantValue: ConstantValue

    public init(_ constantValue: ConstantValue) {
        self.constantValue = constantValue
    }

    public init(wrappedValue: ConstantValue) {
        self.init(wrappedValue)
    }

    public var wrappedValue: ConstantValue { self.constantValue }
    public var projectedValue: Self { self }
}

// MARK: Mutable

/// A value that may be directly mutated
public struct Mutable<Value>: Updatable {
    public var dependencies = UpdateDependencies()
    private var value: Value

    public init(
        _ value: Value
    ) {
        self.value = value
    }

    public var currentValue: Value {
        _read {
            yield self.value
        }
        _modify {
            yield &self.value
            self.recomputeDependencies()
        }
    }
}

// MARK: ComputationInputs

/// Read-only access to the state for a computation
@dynamicMemberLookup
public struct ComputationInputs<Object>
where
    Object: Computation
{
    private let object: Object

    internal init(_ object: Object) {
        self.object = object
    }

    /// Provide read-only access to constant members
    public subscript<Member: Constant>(
        dynamicMember path: KeyPath<Object.State, Member>
    ) -> Member.ConstantValue {
        self.object.state[keyPath: path].constantValue
    }

    /// Track reads of updatable members
    public subscript<Member: Updatable>(
        dynamicMember keyPath: any (WritableKeyPath<Object.State, Member> & Sendable)
    ) -> MutableInput<Object, Member> {
        MutableInput(
            object: self.object,
            keyPath: keyPath
        )
    }

    /// Construct an event handler
    public func eventHandler<Event>(
        eventType: Event.Type = Event.self,
        _ handler: @escaping (inout EventOutputs<Object>, Event) -> Void
    ) -> (Event) -> Void {
        let outputs = EventOutputs(object)
        return { event in
            var outputs = outputs
            handler(&outputs, event)
        }
    }
}

/// Access to a mutable input to computation
@dynamicMemberLookup
public struct MutableInput<Object, Member>: UpdateSubscribable
where
    Object: Computation,
    Member: Updatable
{
    private let object: Object
    private let keyPath: any (WritableKeyPath<Object.State, Member> & Sendable)

    fileprivate init(
        object: Object,
        keyPath: any (WritableKeyPath<Object.State, Member> & Sendable)
    ) {
        self.object = object
        self.keyPath = keyPath
    }

    public func readValue(
        forDependency dependency: some Recomputable
    ) -> Member.Value {
        self.object.state[keyPath: self.keyPath].readValue(forDependency: dependency)
    }

    /// Track reads of an element
    public subscript<Element>(
        dynamicMember keyPath: any (KeyPath<Member.Value, Element> & Sendable)
    ) -> MutableInputElement<Object, Member, Element> {
        MutableInputElement(
            input: self,
            keyPath: keyPath
        )
    }
}

/// Access to an element of a mutable input to computation
public struct MutableInputElement<Object, Member, Element>: UpdateSubscribable
where
    Object: Computation,
    Member: Updatable
{
    private let input: MutableInput<Object, Member>
    private let keyPath: any (KeyPath<Member.Value, Element> & Sendable)

    fileprivate init(
        input: MutableInput<Object, Member>,
        keyPath: any (KeyPath<Member.Value, Element> & Sendable)
    ) {
        self.input = input
        self.keyPath = keyPath
    }

    public func readValue(
        forDependency dependency: some Recomputable
    ) -> Element {
        self.input.readValue(forDependency: dependency)[keyPath: self.keyPath]
    }
}

// MARK: EventOutputs

/// Read/Write access to the state for an event handler
@dynamicMemberLookup
public struct EventOutputs<Object>
where
    Object: Computation
{
    private let object: Object

    fileprivate init(_ object: Object) {
        self.object = object
    }

    /// Provide read-only access to constant members
    public subscript<Member: Constant>(
        dynamicMember path: KeyPath<Object.State, Member>
    ) -> Member.ConstantValue {
        self.object.state[keyPath: path].constantValue
    }

    /// Track reads of updatable members
    public subscript<Member: Updatable>(
        dynamicMember path: any (KeyPath<Object.State, Member> & Sendable)
    ) -> Member.Value {
        self.object.state[keyPath: path].currentValue
    }

    /// Track reads and publish writes of mutable members
    public subscript<Value>(
        dynamicMember path: any (WritableKeyPath<Object.State, Mutable<Value>> & Sendable)
    ) -> Value {
        _read {
            yield self.object.state[keyPath: path].currentValue
        }
        _modify {
            yield &self.object.state[keyPath: path].currentValue
        }
    }
}

// MARK: - Recomputable

/// A value that is computed from dependencies
public class Recomputable {
    /// Whether the value has been scheduled to be recomputed because
    /// dependencies have updated
    private var recomputePending: Bool = false

    /// Trigger the recomputation
    fileprivate func triggerRecompute() {
        guard !self.recomputePending else {
            /// Recompute already triggered
            return
        }

        /// Enqueue the update
        let _ = JSObject.global.window.setTimeout(
            JSClosure.typed {
                self.runRecomputation()
            }
        )

        self.recomputePending = true
    }

    /// Run the recomputation
    private func runRecomputation() {
        guard self.recomputePending else {
            /// Recompute is not pending
            return
        }

        /// Clear the recompute pending flag
        self.recomputePending = false

        /// Run update implementation
        self.recompute()

        /// The recompute should not become pending until after the
        /// recomuptation completes
        assert(self.recomputePending == false)
    }

    /// Recompute the value
    internal func recompute() {
        fatalError("\(Self.self) did not implement Recomputable.recompute")
    }
}

/// MARK: Computation

/// MARK: UpdateDependencies

/// The dependencies of an updatable value
public struct UpdateDependencies {
    /// The registered dependencies
    private var dependencies: [Dependency] = []

    /// A registered dependency
    private struct Dependency {
        /// The ``Recomputable`` that needs to be recomputed on update
        weak let computation: Recomputable?
    }

    internal init() {}
}

internal extension UpdateDependencies {
    /// Trigger all dependencies to recompute
    mutating func recompute() {
        /// Trigger all dependencies that still exist
        for dependency in self.dependencies {
            if let computation = dependency.computation {
                computation.triggerRecompute()
            }
        }

        /// Drop all dependencies but keep capacity as most will
        /// resubscribe
        self.dependencies.removeAll(keepingCapacity: true)
    }
}

public extension UpdateDependencies {
    /// Register a dependency to be recomputed on update
    mutating func register(
        dependency computation: some Recomputable
    ) {
        self.dependencies.append(Dependency(computation: computation))
    }
}

