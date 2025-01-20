package forrest

import "request"
import "response"

request_handler :: proc(req: ^request.Request) -> ^response.Response
