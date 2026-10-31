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
        h(1) { "Scala" }
        div { "Body Text" }
        "Outer Text"
        App()
    }
}

struct App: DOMNode {
    var count = Mutable<Int>(0)

    @DOMBuilder
    static func view(
        _ source: ViewSource<Self>
    ) -> DOMModifiers {
        Class.app
        h(1) { "App" }
        div { "Count: \(source.count)" }
        div {
            "Increment"
            source.on(ClickEvent.self) { outputs, event in
                print("CLICKED")
                outputs.count += 1
            }
        }
        div {
            "Decrement"
            source.on(ClickEvent.self) { outputs, event in
                print("CLICKED")
                outputs.count -= 1
            }
        }
        "App Text"
    }
}

enum Class: String, DOMClass {
    case app
}
