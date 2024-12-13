const std = @import("std");
const Allocator = std.mem.Allocator;
const Type = @import("../../Type.zig");
const SymbolType = @import("../v1.zig").Type;
const Self = @This();

type: Type,
name: []const u8,
type_of: SymbolType,

pub const Error = Allocator.Error;

pub fn create(alloc: Allocator, name: []const u8, type_of: SymbolType) Error!*Self {
    const self = try alloc.create(Self);
    errdefer alloc.destroy(self);

    type_of.ref();
    errdefer type_of.unref();

    self.* = .{
        .type = Type.init(alloc, self),
        .name = try alloc.dupe(u8, name),
        .type_of = type_of,
    };

    return self;
}

pub inline fn ref(self: *Self) void {
    return self.type.ref();
}

pub fn unref(self: *Self) void {
    if (self.type.unref()) {
        self.type_of.unref();
        self.type.allocator.free(self.name);
        self.type.allocator.destroy(self);
    }
}
