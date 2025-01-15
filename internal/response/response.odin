package response

import "core:bytes"
import "core:encoding/json"
import "core:fmt"
import "core:strconv"
import "core:strings"

Response :: struct {
    status: int,
    data: []byte,
    headers: map[string]string
}

@(private="file")
create :: proc(status: int, data: []byte, content_type: string) -> ^Response {
    r := new(Response)
    r.status = status
    r.data = data
    r.headers = make(map[string]string)
    r.headers["Server"] = "Odin http server"
    // TODO: Add Date header
    // r.headers["Date"] = ""
    r.headers["Content-Type"] = content_type
    return r
}

text_string :: proc(status: int, data: string) -> ^Response {
    data_bytes := make([dynamic]byte, len(data))
    copy_from_string(data_bytes[:], data)
    return text_bytes(status, data_bytes[:])
}

text_bytes :: proc(status: int, data: []byte) -> ^Response {
    r := create(status, data, "text/plain")
    return r
}

text :: proc{
    text_string,
    text_bytes,
}

json :: proc(status: int, data: []byte) -> ^Response {
    r := create(status, data, "application/json")
    return r
}

add_header :: proc(res: ^Response, name, value: string) {
    res.headers[name] = value
}

// TODO: current lazy loading, should we eager load?
response :: proc(res: ^Response) -> []byte {
    buf := new(bytes.Buffer)
    defer free(buf)

    // TODO: protocol (HTTP/1.1) should be taken from request?
    bytes.buffer_init_string(buf, fmt.aprintf("HTTP/1.1 %d %s\r\n", res.status, get_status_text(res.status)))

    for name, value in res.headers {
        bytes.buffer_write_string(buf, fmt.aprintf("%s: %s\r\n", name, value))
    }

    bytes.buffer_write_string(buf, fmt.aprintf("\r\n"))
    bytes.buffer_write(buf, res.data)

    res := make([]byte, bytes.buffer_length(buf))
    defer delete(res)
    bytes_read, err := bytes.buffer_read(buf, res)
    if err != nil {
        fmt.println("Error while response.response: bytes.buffer_read failed", err)
        return nil
    }
    return bytes.clone(res[:])
}
