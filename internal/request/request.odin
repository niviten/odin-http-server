package request

import "core:fmt"
import "core:strings"

Request :: struct {
    method: string,
    target: string,
    protocol: string,
    headers: map[string]string,
    body: []byte,
}

create :: proc(method, target, protocol: string) -> ^Request {
    req := new(Request)
    req.method = method
    req.target = target
    req.protocol = protocol
    req.headers = make(map[string]string)
    req.body = nil
    return req
}

close_request :: proc(req: ^Request) {
    free(req)
}

@(private)
add_header :: proc(req: ^Request, name, value: string) {
    req.headers[name] = value
}

@(private)
add_body :: proc(req: ^Request, body: []byte) {
    req.body = body
}

// TODO: function for debugging, remove it
print :: proc(req: ^Request) {
    fmt.println()
    fmt.println(strings.repeat("-", 33))
    fmt.printf("method: %s\n", req.method)
    fmt.printf("target: %s\n", req.target)
    fmt.println("headers:")
    for name, value in req.headers {
        fmt.printf("\t%s -> %s\n", name, value)
    }
    fmt.printf("body (%d):\n%s\n", len(req.body), strings.trim_space(string(req.body)))
    fmt.println(strings.repeat("-", 33))
    fmt.println()
}
