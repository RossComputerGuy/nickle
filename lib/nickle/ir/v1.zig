//! Version 1 IR

const std = @import("std");

pub const Argument = @import("v1/Argument.zig");
pub const BaseSymbol = @import("v1/BaseSymbol.zig");
pub const Block = @import("v1/Block.zig");
pub const Expression = @import("v1/Expression.zig");
pub const Function = @import("v1/Function.zig");
pub const Module = @import("v1/Module.zig");
pub const Symbol = @import("v1/Symbol.zig");

pub const expression = @import("v1/expression.zig");

pub const Type = union(enum) {
    integer: *Integer,

    pub const Integer = @import("v1/Type/Integer.zig");

    pub inline fn ref(self: Type) void {
        return switch (self) {
            .integer => |int| int.ref(),
        };
    }

    pub inline fn unref(self: Type) void {
        return switch (self) {
            .integer => |int| int.unref(),
        };
    }

    pub inline fn typeName(self: Type) std.fmt.AllocPrintError![]const u8 {
        return switch (self) {
            .integer => |int| int.typeName(),
        };
    }
};

test {
    _ = Argument;
    _ = BaseSymbol;
    _ = Block;
    _ = Expression;
    _ = Function;
    _ = Module;
    _ = Symbol;

    _ = expression;
}
