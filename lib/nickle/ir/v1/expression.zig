const std = @import("std");
const Expression = @import("Expression.zig");

pub const Assignable = union(enum) {
    function: *Expression.Function,

    pub inline fn ref(self: Assignable) void {
        return switch (self) {
            .function => |function| function.ref(),
        };
    }

    pub inline fn unref(self: Assignable) void {
        return switch (self) {
            .function => |function| function.unref(),
        };
    }

    pub const ArrayList = std.ArrayListUnmanaged(Assignable);
};

pub const Block = union(enum) {
    function: *Expression.Function,
    vardecl: *Expression.VarDecl,

    pub inline fn ref(self: Block) void {
        return switch (self) {
            .function => |function| function.ref(),
            .vardecl => |vardecl| vardecl.ref(),
        };
    }

    pub inline fn unref(self: Block) void {
        return switch (self) {
            .function => |function| function.unref(),
            .vardecl => |vardecl| vardecl.unref(),
        };
    }

    pub const ArrayList = std.ArrayListUnmanaged(Block);
};

pub const Const = union(enum) {
    pub inline fn ref(_: Const) void {}
    pub inline fn unref(_: Const) void {}

    pub const ArrayList = std.ArrayListUnmanaged(Const);
};
