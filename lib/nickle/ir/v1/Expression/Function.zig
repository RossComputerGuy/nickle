const std = @import("std");
const Allocator = std.mem.Allocator;
const Type = @import("../../../Type.zig");
const AssignableExpression = @import("../expression.zig").Assignable;
const Self = @This();

type: Type,
name: []const u8,
params: AssignableExpression.ArrayList,

pub const Error = Allocator.Error;

pub fn create(
    alloc: Allocator,
    name: []const u8,
    params: []AssignableExpression,
) Error!*Self {
    const self = try alloc.create(Self);
    errdefer alloc.destroy(self);

    self.* = .{
        .type = Type.init(alloc, self),
        .name = try alloc.dupe(u8, name),
        .params = try AssignableExpression.ArrayList.initCapacity(alloc, params.len),
    };

    errdefer alloc.free(self.name);
    errdefer self.params.deinit(alloc);

    for (params.len) |param| {
        param.ref();
        self.params.appendAssumeCapacity(param);
    }
    return self;
}

pub inline fn ref(self: *Self) void {
    return self.type.ref();
}

pub fn unref(self: *Self) void {
    if (self.type.unref()) {
        for (self.params.items) |param| param.unref();
        self.params.deinit(self.type.allocator);

        self.type.allocator.free(self.name);
        self.type.allocator.destroy(self);
    }
}
