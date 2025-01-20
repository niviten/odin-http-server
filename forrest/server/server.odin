package server

import "core:net"

import "../../forrest"

Server :: struct {
    handlers: map[forrest.HttpMethod]map[string]forrest.request_handler,
}

Error :: union #shared_nil {
    ServerError,
    net.Network_Error,
}

ServerError :: enum {
    None
}

create :: proc() -> ^Server {
    s := new(Server)
    s.handlers = make(map[forrest.HttpMethod]map[string]forrest.request_handler)
    return s
}

destroy :: proc(s: ^Server) {
    for k, submap in s.handlers {
        delete(submap)
    }
    delete(s.handlers)
}

start :: proc(s: ^Server, port: int, cb: proc()) -> Error {
    server_socket, err := net.listen_tcp(net.Endpoint{
        port = port,
        address = net.IP4_Loopback,
    })

    if err != nil {
        return err
    }

    cb()

    listen(s, server_socket)

    return .None
}
