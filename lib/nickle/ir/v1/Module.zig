const std = @import("std");
const mem = std.mem;
const Allocator = mem.Allocator;
const Type = @import("../../Type.zig");
const Function = @import("Function.zig");
const Symbol = @import("Symbol.zig");
const Self = @This();

type: Type,
symbols: std.ArrayListUnmanaged(*Symbol),
functions: std.ArrayListUnmanaged(*Function),

pub const Error = Allocator.Error;

pub fn create(alloc: Allocator) Error!*Self {
    const self = try alloc.create(Self);
    errdefer alloc.destroy(self);

    self.* = .{
        .type = Type.init(alloc, self),
        .functions = .{},
        .symbols = .{},
    };
    return self;
}

pub inline fn ref(self: *Self) void {
    return self.type.ref();
}

pub fn unref(self: *Self) void {
    if (self.type.unref()) {
        for (self.symbols.items) |item| item.unref();
        for (self.functions.items) |item| item.unref();
        self.type.allocator.destroy(self);
    }
}
