package request

import "core:fmt"
import "core:strconv"
import "core:strings"

RequestParser :: struct {
    request: ^Request,
    done: bool,
    buff: [dynamic]byte,
    status: ParseStatus,
    headers: map[string]string,
    content_length: int,
}

ParseStatus :: enum {
    FIRST_LINE,
    HEADERS,
    BODY,
}

create_parser :: proc() -> ^RequestParser {
    rp := new(RequestParser)
    rp.request = nil
    rp.done = false
    rp.buff = [dynamic]byte{}
    rp.status = .FIRST_LINE
    rp.headers = make(map[string]string)
    rp.content_length = -1
    return rp
}

close_parser :: proc(rp: ^RequestParser) {
    free(rp)
}

add_bytes :: proc(rp: ^RequestParser, bytes: []byte) -> Error {
    for b in bytes {
        if b == '\n' && is_line(rp.buff) {
            pop(&rp.buff)
            #partial switch rp.status {
            case .FIRST_LINE:
                parse_first_line(rp) or_return
                rp.status = .HEADERS
            case .HEADERS:
                if len(rp.buff) == 0 {
                    rp.status = .BODY
                    if rp.content_length <= 0 {
                        rp.done = true
                        rp.content_length = 0
                    }
                } else {
                    parse_header(rp) or_return
                }
            }
            clear_dynamic_array(&rp.buff)
            continue
        }
        append(&rp.buff, b)
        if rp.status == .BODY && rp.content_length == len(rp.buff) {
            rp.done = true
            add_body(rp.request, rp.buff[:])
            clear_dynamic_array(&rp.buff)
            break
        }
    }
    return .NONE
}

@(private="file")
parse_line :: proc(rp: ^RequestParser) -> (string, Error) {
    line, err := strings.clone_from_bytes(rp.buff[:])
    if err != nil {
        fmt.println("parse_line: error: converting bytes to string ", err)
        return "", .PARSE_ERROR
    }
    return line, .NONE
}

@(private="file")
parse_first_line :: proc(rp: ^RequestParser) -> Error {
    line := parse_line(rp) or_return
    parts := strings.split(line, " ")
    if len(parts) != 3 {
        fmt.println("parse_first_line: error: not 3 parts, but ", len(parts))
        return .PARSE_ERROR
    }
    rp.request = create(parts[0], parts[1], parts[2])
    return .NONE
}

@(private="file")
parse_header :: proc(rp: ^RequestParser) -> Error {
    line := parse_line(rp) or_return
    line = strings.trim_space(line)
    idx := strings.index(line, ": ")
    // TODO: hanlde not ok cases
    name, _ := strings.substring_to(line, idx)
    value, _ := strings.substring_from(line, idx+2)
    add_header(rp.request, name, value)
    if rp.content_length < 0 && strings.equal_fold(name, "Content-Length") {
        rp.content_length = strconv.parse_int(value) or_else 0
    }
    return .NONE
}

@(private="file")
is_line :: proc(buff: [dynamic]byte) -> bool {
    if len(buff) == 0 {
        return false
    }
    return buff[len(buff) - 1] == '\r'
}
