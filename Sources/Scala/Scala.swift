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
        NavBar()
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

struct NavBar: DOMNode {
    static let tag = "nav"

    var tool = Mutable(Tool.tool1)

    enum Tool: String, Hashable {
        case tool1
        case tool2
        case tool3
    }

    @DOMBuilder
    static func button(
        _ source: Source,
        _ tool: Tool
    ) -> DOMModifiers {
        div {
            "TOOL \(tool.rawValue)"
            source.on(ClickEvent.self) { outputs, event in
                outputs.tool = tool
            }
        }
    }

    @DOMBuilder
    static func view(
        _ source: ViewSource<Self>
    ) -> DOMModifiers {
        h(1) { "Scala" }

        div {
            button(source, .tool1)
            button(source, .tool2)
            button(source, .tool3)
        }

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

enum Class: String, DOMClass {
    case app
}
