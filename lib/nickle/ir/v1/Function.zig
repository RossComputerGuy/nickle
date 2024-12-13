const std = @import("std");
const assert = std.debug.assert;
const Allocator = std.mem.Allocator;
const BaseSymbol = @import("BaseSymbol.zig");
const Type = @import("../v1.zig").Type;
const Argument = @import("Argument.zig");
const Block = @import("Block.zig");
const Self = @This();

base: BaseSymbol,
return_type: ?Type,
noreturn: bool,
is_inline: bool,
code_model: ?std.builtin.CodeModel,
call_conv: ?std.builtin.CallingConvention,
arguments: std.ArrayListUnmanaged(*Argument),
block: ?*Block,

pub const Error = BaseSymbol.Error;

pub const Options = struct {
    args: ?[]*Argument = null,
    block: ?*Block = null,
    return_type: ?Type = null,
    noreturn: ?bool = null,
    is_inline: ?bool = null,
    code_model: ?std.builtin.CodeModel = null,
    call_conv: ?std.builtin.CallingConvention = null,
};

pub fn create(alloc: Allocator, name: []const u8, options: Options) Error!*Self {
    const self = try alloc.create(Self);
    errdefer alloc.destroy(self);

    self.base = try BaseSymbol.init(alloc, self, name, .{});
    errdefer {
        assert(self.base.unref());
        self.base.destroy();
    }

    self.arguments = .{};
    if (options.args) |args| {
        self.arguments = try std.ArrayListUnmanaged(*Argument).initCapacity(alloc, args.len);
        for (args) |arg| {
            arg.ref();
            self.arguments.appendAssumeCapacity(arg);
        }
    }

    self.block = null;
    self.return_type = null;
    self.noreturn = options.noreturn or false;
    self.is_inline = options.is_inline or false;
    self.code_model = options.code_model;
    self.call_conv = options.call_conv;
    self.target = options.target;

    if (options.return_type) |return_type| {
        return_type.ref();
        errdefer return_type.unref();
        self.return_type = return_type;
    }

    if (options.block) |block| {
        block.ref();
        errdefer block.unref();
        self.block = block;
    }
    return self;
}

pub inline fn ref(self: *Self) void {
    return self.base.ref();
}

pub fn unref(self: *Self) void {
    if (self.base.unref()) {
        self.base.destroy();
        if (self.block) |block| block.unref();
        if (self.return_type) |return_type| return_type.unref();
        for (self.arguments.items) |arg| arg.unref();
        self.arguments.deinit(self.base.type.allocator);
        self.base.type.allocator.destroy(self);
    }
}
