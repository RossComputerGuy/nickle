const std = @import("std");
const Allocator = std.mem.Allocator;
const Type = @import("../../Type.zig");
const BlockExpression = @import("expression.zig").Block;
const Self = @This();

type: Type,
target: ?std.Target,
expressions: BlockExpression.ArrayList,

pub const Error = Allocator.Error;

pub const Options = struct {
    target: ?std.Target = null,
    expressions: ?[]BlockExpression = null,
};

pub fn create(alloc: Allocator, options: Options) Error!*Self {
    const self = try alloc.create(Self);
    errdefer alloc.destroy(self);

    self.* = .{
        .type = Type.init(alloc, self),
        .target = options.target,
        .expressions = .{},
    };

    if (options.expressions) |expressions| {
        self.expressions = try BlockExpression.ArrayList.initCapacity(alloc, expressions.len);

        for (expressions) |expr| {
            expr.ref();
            self.expressions.appendAssumeCapacity(expr);
        }
    }
    return self;
}

pub inline fn ref(self: *Self) void {
    return self.type.ref();
}

pub fn unref(self: *Self) void {
    if (self.type.unref()) {
        for (self.expressions.items) |expr| expr.unref();
        self.expressions.deinit(self.type.allocator);
        self.type.allocator.destroy(self);
    }
}
