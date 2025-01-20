package server

import "core:fmt"
import "core:net"
import "core:thread"

import "../../forrest"
import "../request"
import "../response"

@(private="file")
Client :: struct {
    server: ^Server,
    socket: net.TCP_Socket,
}

@(private="package")
listen :: proc(s: ^Server, server_socket: net.TCP_Socket) {
    for {
        client_socket, source, err := net.accept_tcp(server_socket)
        if err != nil {
            fmt.println("Error while accepting tcp", err)
            continue
        }
        client := new(Client)
        client.server = s
        client.socket = client_socket
        thread.run_with_poly_data(client, handle_client)
    }
}

@(private="file")
handle_client := proc(client: ^Client) {
    defer free(client)
    socket := client.socket
    defer net.close(socket)
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

    req := req_parser.request
    res: ^response.Response
    defer {
        if res != nil {
            net.send_tcp(socket, response.response(res))
            // TODO: close the response
        }
    }

    http_method := forrest.HttpMethod.None

    switch req.method {
    case "GET":
        http_method = forrest.HttpMethod.GET
    case "POST":
        http_method = forrest.HttpMethod.POST
    }

    submap, has_http_method := client.server.handlers[http_method]
    if !has_http_method {
        fmt.println("has not http method")
        res = get_notfound_resp()
        return
    } else {
        fmt.println("has http method")
    }

    req_handler, has_req_handler := submap[req.target]
    if !has_req_handler {
        fmt.println("has not request handler")
        res = get_notfound_resp()
        return
    } else {
        fmt.println("has request handler")
    }

    res = req_handler(req)
}

@(private="file")
notfound_resp: ^response.Response

@(private="file")
get_notfound_resp :: proc() -> ^response.Response {
    if notfound_resp == nil {
        notfound_resp = response.text(404, "Not found")
    }
    return notfound_resp
}
