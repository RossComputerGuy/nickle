const std = @import("std");
const Allocator = std.mem.Allocator;
const Type = @import("../../../Type.zig");
const AssignableExpression = @import("../expression.zig").Assignable;
const Self = @This();

type: Type,
is_const: bool,
name: []const u8,
value: AssignableExpression,

pub const Error = Allocator.Error;

pub const Options = struct {
    is_const: bool = false,
};

pub fn create(
    alloc: Allocator,
    name: []const u8,
    value: AssignableExpression,
    options: Options,
) Error!*Self {
    const self = try alloc.create(Self);
    errdefer alloc.destroy(self);

    value.ref();
    errdefer value.unref();

    self.* = .{
        .type = Type.init(alloc, self),
        .name = try alloc.dupe(u8, name),
        .value = value,
        .is_const = options.is_const,
    };

    return self;
}

pub inline fn ref(self: *Self) void {
    return self.type.ref();
}

pub fn unref(self: *Self) void {
    if (self.type.unref()) {
        self.value.unref();
        self.type.allocator.free(self.name);
        self.type.allocator.destroy(self);
    }
}
