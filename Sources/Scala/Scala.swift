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
        App()
    }
}

struct App: DOMNode {
    var count = Mutable<Int>(0)

    var tool = Mutable(Tool.tool1)

    enum Tool: String, Hashable {
        case tool1
        case tool2
        case tool3
    }

    @DOMBuilder
    static func view(
        _ source: ViewSource<Self>
    ) -> DOMModifiers {
        Class.app
        NavBar(toolChoice: source.tool)
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

        select(source.tool) {
            $0.when(.tool1) {
                h(2) { "Tool 1" }
                "This is the first tool"
            }
            $0.when(.tool2) {
                h(2) { "Tool 2" }
                "This is the second tool"
            }
            $0.when(.tool3) {
                h(2) { "Tool 3" }
                "This is the third tool"
            }
        }
    }
}

struct NavBar: DOMNode {
    static let tag = "nav"

    let toolChoice: BoundMutable<App.Tool>

    @DOMBuilder
    static func button(
        _ source: Source,
        _ tool: App.Tool
    ) -> DOMModifiers {
        li {
            Class.button
            Class.current.when(source.toolChoice) { $0 == tool }
            "TOOL \(tool.rawValue)"
            source.on(ClickEvent.self) { outputs, event in
                outputs.toolChoice = tool
            }
        }
    }

    @DOMBuilder
    static func view(
        _ source: ViewSource<Self>
    ) -> DOMModifiers {
        h(1) { "Scala" }

        ul {
            button(source, .tool1)
            button(source, .tool2)
            button(source, .tool3)
        }
    }
}

enum Class: String, DOMClass {
    case app
    case button
    case current
}
