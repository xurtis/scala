import JavaScriptKit
import DomKit

@main
struct Scala {
    static func main() {
        run()
    }
}

@JS
func run() {
    setBody {
        H<1> {
            "Scala"
        }
        Div {
            "Body Text"
        }
        "Outer Text"
        App()
    }
}

struct App: DOMNode {
    @DOMState
    var count: Int = 0

    @DOMBuilder
    static func view(
        _ source: ViewSource<Self>
    ) -> DOMChildren {
        H<1> {
            "App"
        }
        Div {
            "Count: \(source.$count)"
        }
        Div {
            "Increment"
        }.on("click") { event in
            print("CLICKED")
            source.send(.increment)
        }
        Div {
            "Decrement"
        }.on("click") { event in
            print("CLICKED")
            source.send(.decrement)
        }
        "App Text"
    }

    struct Increment: DOMNodeEvent {
        let amount: Int
        typealias Target = App

        func deliver(toNode node: inout EventTarget<App>) { 
            print("Incrementing from: \(node.count)")
            node.$count += self.amount
            print("Incremented to: \(node.count)")
        }
    }
}

extension DOMNodeEvent where Self == App.Increment {
    static var increment: Self { Self(amount: 1) }
    static var decrement: Self { Self(amount: -1) }
}
