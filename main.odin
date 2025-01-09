package main

import "core:fmt"
import "core:net"
import "core:strings"
import "core:thread"

import "internal/request"

main :: proc() {
    server_socket, err := net.listen_tcp(net.Endpoint{
        port = 7711,
        address = net.IP4_Loopback,
    })
    if err != nil {
        fmt.println("Error while listen tcp", err)
        return
    }

    for {
        client, source, err := net.accept_tcp(server_socket)
        if err != nil {
            fmt.println("Error while accepting tcp", err)
            continue
        }
        thread.run_with_poly_data(client, handle_client)
    }
}

handle_client := proc(socket: net.TCP_Socket) {
    req_parser := request.create_parser()
    defer request.close(req_parser)

    for {
        buff: [dynamic]byte
        if req_parser.status == .BODY {
            buff = make([dynamic]byte, req_parser.content_length - len(req_parser.buff))
        } else {
            buff = make([dynamic]byte, 8)
        }
        bytes_read, err := net.recv_tcp(socket, buff[:])

        if err != nil {
            fmt.println("Error while receiving tcp", err)
            continue
        }

        if bytes_read == 0 {
            continue
        }

        parser_err := request.add_bytes(req_parser, buff[:])
        if parser_err != nil {
            fmt.println("parser error: %s\n", err)
            return
        }

        if req_parser.done {
            break
        }
    }

    request.print(req_parser.request)

    net.close(socket)
}
