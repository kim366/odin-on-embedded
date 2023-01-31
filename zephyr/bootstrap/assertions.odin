package bootstrap

import emem "zephyr:embedded_mem"
import "core:strings"
import "core:runtime"
import "core:c"

CONFIG_ASSERT_NO_FILE_INFO :: #config(CONFIG_ASSERT_NO_FILE_INFO, false)
CONFIG_ASSERT_VERBOSE      :: #config(CONFIG_ASSERT_VERBOSE, false)
CONFIG_ASSERT_NO_MSG_INFO  :: #config(CONFIG_ASSERT_NO_MSG_INFO, false)

when !ODIN_DISABLE_ASSERT {

    // __ASSERT_POST_ACTION
    when CONFIG_ASSERT_NO_FILE_INFO {
        foreign {
            assert_post_action :: proc() -> ! ---
        }
    } else {
        foreign {
            assert_post_action :: proc(file: cstring, line: c.uint) -> ! ---
        }
    }

    // __ASSERT_PRINT
    when CONFIG_ASSERT_VERBOSE {
        foreign {
            assert_print :: proc(fmt: cstring, #c_vararg args: ..any) ---
        }
    } else {
        assert_print :: proc "contextless" (fmt: cstring, args: ..any) {}
    }

    // __ASSERT_LOC
    assert_loc :: #force_inline proc "contextless" (file: cstring, line, column: c.int) {
        when CONFIG_ASSERT_NO_FILE_INFO {
            assert_print("ASSERTION FAIL\n")
        } else {
            assert_print("ASSERTION FAIL @ %s:%d:%d\n", file, line, column)
        }
    }

    // __ASSERT_MSG_INFO
    assert_msg_info :: #force_inline proc "contextless" (message: cstring) {
        when !CONFIG_ASSERT_NO_MSG_INFO {
            assert_print("\t%s\n", message)
        }
    }

    @(link_prefix="odin_")
    foreign {
        k_panic :: #force_inline proc() -> ! ---
    }

    zephyr_assertion_proc :: proc(prefix, message: string, loc: runtime.Source_Code_Location) -> ! {
        MAX_MESSAGE_LEN :: 191
        buffer: [MAX_MESSAGE_LEN + 1]u8
        static: emem.Static_Allocator
        emem.static_allocator_init(&static, &buffer)
        context.allocator = emem.static_allocator(&static)

        file := cstring(raw_data(loc.file_path))
        line := c.int(loc.line)
        column := c.int(loc.column)
        uline := c.uint(loc.line)

        assert_loc(file, line, column)    

        if len(message) <= MAX_MESSAGE_LEN {
            message := strings.clone_to_cstring(message)
            assert_msg_info(message)
        }

        when CONFIG_ASSERT_NO_FILE_INFO {
            assert_post_action()
        } else {
            assert_post_action(file, uline)
        }
    }
}
