package emem

import "core:mem"

Static_Allocator :: struct {
    data: rawptr,
    size: int,
    alignment: int,
}

static_allocator_init :: proc(s: ^Static_Allocator, data: ^[$N]$E) {
    s.data = raw_data(data[:])
    s.size = N * size_of(E)
    s.alignment = align_of(E)
}

static_allocator_proc :: proc(allocator_data: rawptr, mode: mem.Allocator_Mode,
                              size, alignment: int,
                              old_memory: rawptr, old_size: int, loc := #caller_location) -> ([]byte, mem.Allocator_Error) {
    s := cast(^Static_Allocator)allocator_data

    assert(size <= s.size)

    switch mode {
    case .Alloc, .Alloc_Non_Zeroed:
            return mem.byte_slice(s.data, size), nil
    case .Free:
        mem.set(s.data, 0, size)
    case .Free_All:
        mem.set(s.data, 0, s.size)
    case .Resize:
            return nil, .Mode_Not_Implemented
    case .Query_Features:
            set := (^mem.Allocator_Mode_Set)(old_memory)
            if set != nil {
                set^ = {.Alloc, .Alloc_Non_Zeroed, .Free, .Free_All, .Query_Features, .Query_Info}
            }
            return nil, nil

    case .Query_Info:
            info := (^mem.Allocator_Query_Info)(old_memory)
            if info != nil && info.pointer != nil {
                info.size = s.size
                info.alignment = s.alignment
                return mem.byte_slice(info, size_of(info^)), nil
            }
            return nil, nil
    }
    return nil, nil
}

static_allocator :: proc(allocator: ^Static_Allocator) -> mem.Allocator {
    return mem.Allocator{
        procedure = static_allocator_proc,
        data = allocator,
    }
}
