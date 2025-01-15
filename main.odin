package main

import "core:fmt"

import "forrest/server"

main :: proc() {
    s := server.create()

    err := server.start(s, 7711, proc() {
        fmt.println("server started @", 7711)
    })

    if err != nil {
        fmt.println("error while starting server", err)
    }
}
