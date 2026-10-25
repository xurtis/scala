import JavaScriptKit

@main
struct Scala {
    static func main() {
        run()
    }
}

@JS
func run() {
    let document = JSObject.global.document
    let placeholder = document.querySelector("#load-placeholder")
    let div = document.createElement("div")
    div.innerText = "Hello, World!"
    _ = document.body.removeChild(placeholder)
    _ = document.body.appendChild(div)
}
