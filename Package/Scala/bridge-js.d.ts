// NOTICE: This is auto-generated code by BridgeJS from JavaScriptKit,
// DO NOT EDIT.
//
// To update this file, just rebuild your project or run
// `swift package bridge-js`.

export interface Document {
    createElement(name: string): JSElement;
    createTextNode(data: string): JSText;
    querySelector(name: string): JSElement | null;
    readonly body: JSElement;
}
export interface JSEventTarget {
    addEventListener(type: string, listener: any): void;
}
export interface JSNode {
    appendChild(node: JSNode): void;
    removeChild(node: JSNode): void;
    replaceChild(oldChild: JSNode, newChild: JSNode): void;
    readonly firstChild: JSNode | null;
    readonly lastChild: JSNode | null;
    readonly parentElement: JSElement | null;
    readonly parentNode: JSNode | null;
}
export interface JSText {
}
export interface JSElement {
    readonly classList: JSDOMTokenList;
}
export interface JSEvent {
    preventDefault(): void;
    stopImmediatePropagation(): void;
    stopPropagation(): void;
    readonly bubbles: boolean;
    readonly cancelable: boolean;
    readonly composed: boolean;
    readonly type: string;
}
export interface JSPointerEvent {
}
export interface JSDOMTokenList {
    add(token: string): void;
    remove(token: string): void;
    contains(token: string): boolean;
    replace(oldToken: string, newToken: string): void;
    toggle(token: string): void;
    readonly length: number;
}
export type Exports = {
    run(): void;
}
export type Imports = {
}
export function createInstantiator(options: {
    imports: Imports;
}, swift: any): Promise<{
    addImports: (importObject: WebAssembly.Imports) => void;
    setInstance: (instance: WebAssembly.Instance) => void;
    createExports: (instance: WebAssembly.Instance) => Exports;
}>;