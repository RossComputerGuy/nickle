//! WASM object format

const std = @import("std");
const Allocator = std.mem.Allocator;
const ir = @import("../ir.zig");
const ofmt = @import("../ofmt.zig");
const Self = @This();

pub fn emitModuleV1(alloc: Allocator, module: *const ir.v1.Module, writer: std.io.AnyWriter) anyerror!void {
    _ = alloc;
    _ = module;

    try writer.writeAll(&std.wasm.magic);
    try writer.writeAll(&std.wasm.version);
}

pub const vtable = ofmt.VTable{
    .emitModuleV1 = emitModuleV1,
};

test "WASM modules" {
    const wasmtime = @import("options").wasmtime;

    var tmpdir = std.testing.tmpDir(.{});
    defer tmpdir.cleanup();

    var wasmfile = try tmpdir.dir.createFile("test.wasm", .{});
    defer wasmfile.close();

    var module = try ir.v1.Module.create(std.testing.allocator);
    defer module.unref();

    try emitModuleV1(std.testing.allocator, module, wasmfile.writer().any());

    var proc = std.process.Child.init(&.{
        wasmtime,
        "test.wasm",
    }, std.testing.allocator);

    proc.cwd_dir = tmpdir.dir;
    proc.stdin_behavior = .Ignore;
    proc.stdout_behavior = .Pipe;
    proc.stderr_behavior = .Pipe;

    var stdout = std.ArrayList(u8).init(std.testing.allocator);
    var stderr = std.ArrayList(u8).init(std.testing.allocator);
    errdefer {
        stdout.deinit();
        stderr.deinit();
    }

    try proc.spawn();
    try proc.collectOutput(&stdout, &stderr, 50 * 1024);

    const result = try proc.wait();

    try std.testing.expectEqual(result, std.process.Child.Term{
        .Exited = 0,
    });

    try std.testing.expectEqual(stdout.items.len, 0);
    try std.testing.expectEqual(stderr.items.len, 0);
}
