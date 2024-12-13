const std = @import("std");
const assert = std.debug.assert;
const Allocator = std.mem.Allocator;
const Type = @import("../../../Type.zig");
const Self = @This();

type: Type,
signedness: std.builtin.Signedness,
bits: u16,
endian: ?std.builtin.Endian,

pub const Error = Allocator.Error;

pub const Options = struct {
    endian: ?std.builtin.Endian = null,
};

pub fn create(
    alloc: Allocator,
    signedness: std.builtin.Signedness,
    bits: u16,
    options: Options,
) Error!*Self {
    const self = try alloc.create(Self);
    errdefer alloc.destroy(self);

    self.* = .{
        .type = Type.init(alloc, self),
        .signedness = signedness,
        .bits = bits,
        .endian = options.endian,
    };

    return self;
}

pub inline fn ref(self: *Self) void {
    return self.type.ref();
}

pub fn unref(self: *Self) void {
    if (self.type.unref()) {
        self.type.allocator.destroy(self);
    }
}

pub fn typeName(self: *const Self) std.fmt.AllocPrintError![]const u8 {
    if (self.endian) |endian| {
        return std.fmt.allocPrint(self.type.allocator, "{c}{d}{c}e", .{
            @tagName(self.signedness)[0],
            self.bits,
            @tagName(endian)[0],
        });
    }

    return std.fmt.allocPrint(self.type.allocator, "{c}{d}", .{
        @tagName(self.signedness)[0],
        self.bits,
    });
}

pub fn min(self: *const Self) isize {
    if (self.signedness == .unsigned or self.bits == 0) return 0;
    return -(1 << (self.bits - 1));
}

pub fn max(self: *const Self) usize {
    if (self.bits == 0) return 0;
    return (1 << (self.bits - @intFromBool(self.signedness == .signed))) - 1;
}
