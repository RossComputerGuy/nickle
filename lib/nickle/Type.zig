//! Basic type structure to handle references and allocation.

const std = @import("std");
const assert = std.debug.assert;
const Allocator = std.mem.Allocator;
const Self = @This();

/// Zig allocator
allocator: Allocator,
/// Current number of references made
ref_count: usize,
/// Pointer to the structure
ptr: *anyopaque,
/// Name of the type
type_name: []const u8,

/// Initializes the type structure with the allocator,
/// reference count, pointer, and type name.
pub fn init(alloc: Allocator, ptr: anytype) Self {
    comptime assert(@typeInfo(@TypeOf(ptr)) == .pointer);
    return .{
        .allocator = alloc,
        .ref_count = 1,
        .ptr = ptr,
        .type_name = @typeName(@TypeOf(ptr)),
    };
}

/// Increase reference count
pub fn ref(self: *Self) void {
    self.ref_count += 1;
}

/// Decreases the reference count and returns
/// true when there are no more references left.
/// This indicates that the type should be destroyed.
pub fn unref(self: *Self) bool {
    assert(self.ref_count > 0);
    self.ref_count -= 1;
    return self.ref_count == 0;
}
