package server

import "core:fmt"

import "../../forrest"

get :: proc(s: ^Server, url: string, handler: forrest.request_handler) {
    add_handler(s, forrest.HttpMethod.GET, url, handler)
}

put :: proc(s: ^Server, url: string, handler: forrest.request_handler) {
    add_handler(s, forrest.HttpMethod.PUT, url, handler)
}

post :: proc(s: ^Server, url: string, handler: forrest.request_handler) {
    add_handler(s, forrest.HttpMethod.POST, url, handler)
}

add_handler :: proc(s: ^Server, method: forrest.HttpMethod, url: string, handler: forrest.request_handler) {
    submap := s.handlers[method] or_else make(map[string]forrest.request_handler)
    submap[url] = submap[url] or_else handler
    s.handlers[method] = submap
}

// TODO: for debugging purpose, remove it
print_all_handlers :: proc(s: ^Server) {
    fmt.println("print_all_handlers")
    for k, submap in s.handlers {
        fmt.printf("%s:\n", k)
        for url, _ in submap {
            fmt.printf("\t%s\n", url)
        }
    }
}
