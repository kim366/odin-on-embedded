package bootstrap

import "core:runtime"
import main "../../src"

@export
odin_main :: proc "c" () {
    context = runtime.default_context()

    when !ODIN_DISABLE_ASSERT {
        context.assertion_failure_proc = bootstrap.zephyr_assertion_proc
    }

    runtime._startup_runtime()
    defer runtime._cleanup_runtime()

    main.main()
}
