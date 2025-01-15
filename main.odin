package main

import "core:fmt"
import "core:net"
import "core:strings"
import "core:thread"

import "forrest/request"
import "forrest/response"

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

// TODO: function for debugging, remove it
_handle_client := proc(socket: net.TCP_Socket) {
    for {
        buff: [8]byte

        bytes_read, err := net.recv_tcp(socket, buff[:])

        if err != nil {
            fmt.println("Error while receiving tcp", err)
            continue
        }

        if bytes_read == 0 {
            fmt.println("bytes read is 0, hence terminating")
            return
        }

        s := string(buff[:])

        for r in s {
            switch r {
            case '\t':
                fmt.print("<TAB>")
            case ' ':
                fmt.print("<WS>")
            case '\r':
                fmt.print("<RET>")
            case '\n':
                fmt.print("<NL>\n")
            case:
                fmt.printf("%c", r)
            }
        }
    }
}

handle_client := proc(socket: net.TCP_Socket) {
    req_parser := request.create_parser()
    defer request.close(req_parser)

    for {
        buff := [8]byte{}
        bytes_read, err := net.recv_tcp(socket, buff[:])

        if err != nil {
            fmt.println("Error while receiving tcp", err)
            continue
        }

        if bytes_read == 0 {
            fmt.println("bytes read is 0, hence terminating")
            return
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



    // resp := response.text(200, "hello there")
    resp := response.json(201, req_parser.request.body)

    net.send_tcp(socket, response.response(resp))

    net.close(socket)
}
