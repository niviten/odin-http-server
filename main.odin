package main

import "core:fmt"

import "forrest/request"
import "forrest/response"
import "forrest/server"

main :: proc() {
    s := server.create()

    server.get(s, "/", hello_world)
    server.get(s, "/hello", hello)

    server.print_all_handlers(s)

    err := server.start(s, 7711, proc() {
        fmt.println("server started @", 7711)
    })

    if err != nil {
        fmt.println("error while starting server", err)
    }
}

hello_world :: proc(req: ^request.Request) -> ^response.Response {
    return response.text(200, "hello world")
}

hello :: proc(req: ^request.Request) -> ^response.Response {
    return response.text(200, "hello there")
}
