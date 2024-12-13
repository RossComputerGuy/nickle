const std = @import("std");
const assert = std.debug.assert;
const Allocator = std.mem.Allocator;
const Type = @import("../../Type.zig");
const Self = @This();

type: Type,
name: []const u8,
visibility: ?std.builtin.SymbolVisibility,

pub const Error = Allocator.Error;

pub const Options = struct {
    visibility: ?std.builtin.SymbolVisibility = null,
};

pub fn init(alloc: Allocator, ptr: *anyopaque, name: []const u8, options: Options) Error!Self {
    return .{
        .type = Type.init(alloc, ptr),
        .name = try alloc.dupe(u8, name),
        .visibility = options.visibility,
    };
}

pub inline fn ref(self: *Self) void {
    return self.type.ref();
}

pub inline fn unref(self: *Self) bool {
    return self.type.unref();
}

pub fn destroy(self: *Self) void {
    assert(self.type.ref_count == 0);

    self.type.allocator.free(self.name);
}
