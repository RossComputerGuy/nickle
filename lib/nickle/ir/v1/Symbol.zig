const std = @import("std");
const assert = std.debug.assert;
const Allocator = std.mem.Allocator;
const BaseSymbol = @import("BaseSymbol.zig");
const Type = @import("../v1.zig").Type;
const ConstExpression = @import("expression.zig").Const;
const Self = @This();

base: BaseSymbol,
type: Type,
value: *ConstExpression,

pub const Error = BaseSymbol.Error;

pub fn create(alloc: Allocator, name: []const u8, typeval: Type, value: *ConstExpression) Error!*Self {
    const self = try alloc.create(Self);
    errdefer alloc.destroy(self);

    self.base = try BaseSymbol.init(alloc, self, name, .{});
    errdefer {
        assert(self.base.unref());
        self.base.destroy();
    }

    typeval.ref();
    errdefer typeval.unref();

    self.type = typeval;

    value.ref();
    errdefer value.unref();

    self.value = value;
    return self;
}

pub inline fn ref(self: *Self) void {
    return self.base.ref();
}

pub fn unref(self: *Self) void {
    if (self.base.unref()) {
        self.base.destroy();
        self.type.unref();
        self.value.unref();
        self.base.type.allocator.destroy(self);
    }
}
