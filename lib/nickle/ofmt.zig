const std = @import("std");
const Allocator = std.mem.Allocator;
const ir = @import("ir.zig");
const Self = @This();

pub const formats = struct {
    pub const wasm = @import("ofmt/wasm.zig").vtable;
};
pub const Type = std.meta.DeclEnum(formats);

pub const VTable = struct {
    emitModuleV1: *const fn (alloc: Allocator, module: *const ir.v1.Module, writer: std.io.AnyWriter) anyerror!void,
};

pub fn vtable(t: Type) *const VTable {
    inline for (std.meta.declarations(formats)) |decl| {
        if (std.mem.eql(u8, decl.name, @tagName(t))) {
            return &@field(formats, decl.name);
        }
    }

    unreachable;
}

pub inline fn emitModuleV1(t: Type, alloc: Allocator, module: *const ir.v1.Module, writer: std.io.AnyWriter) anyerror!void {
    return vtable(t).emitModuleV1(alloc, module, writer);
}

test {
    if (@hasDecl(@import("options"), "wasmtime") and std.process.can_spawn) {
        _ = formats.wasm;
    }
}
