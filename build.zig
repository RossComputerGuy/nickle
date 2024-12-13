const std = @import("std");

fn makeSource(b: *std.Build, arches: []const []const u8) std.Build.LazyPath {
    const wf = b.addWriteFiles();

    _ = wf.addCopyDirectory(b.path("lib/nickle/ir"), "nickle/ir", .{});
    _ = wf.addCopyDirectory(b.path("lib/nickle/ofmt"), "nickle/ofmt", .{});

    _ = wf.addCopyFile(b.path("lib/nickle/codegen/Options.zig"), "nickle/codegen/Options.zig");
    _ = wf.addCopyFile(b.path("lib/nickle/codegen.zig"), "nickle/codegen.zig");
    _ = wf.addCopyFile(b.path("lib/nickle/ir.zig"), "nickle/ir.zig");
    _ = wf.addCopyFile(b.path("lib/nickle/ofmt.zig"), "nickle/ofmt.zig");
    _ = wf.addCopyFile(b.path("lib/nickle/Type.zig"), "nickle/Type.zig");

    var codegen_target_source = std.ArrayList(u8).init(b.allocator);
    defer codegen_target_source.deinit();

    for (arches) |arch| {
        const line = b.fmt("pub const {s} = @import(\"target/{s}.zig\");\n", .{
            arch,
            arch,
        });
        defer b.allocator.free(line);

        codegen_target_source.appendSlice(line) catch @panic("OOM");
        _ = wf.addCopyFile(b.path(b.fmt("lib/nickle/codegen/target/{s}.zig", .{arch})), b.fmt("nickle/codegen/target/{s}.zig", .{arch}));
    }

    codegen_target_source.appendSlice("\ntest {\n") catch @panic("OOM");

    for (arches) |arch| {
        const line = b.fmt("    _ = {s};\n", .{
            arch,
        });
        defer b.allocator.free(line);

        codegen_target_source.appendSlice(line) catch @panic("OOM");
    }

    codegen_target_source.appendSlice("}\n") catch @panic("OOM");

    _ = wf.add("nickle/codegen/target.zig", codegen_target_source.items);

    var arch_source = std.ArrayList(u8).init(b.allocator);
    defer arch_source.deinit();

    for (arches) |arch| {
        const line = b.fmt("pub const {s} = @import(\"arch/{s}.zig\");\n", .{
            arch,
            arch,
        });
        defer b.allocator.free(line);

        arch_source.appendSlice(line) catch @panic("OOM");
        _ = wf.addCopyFile(b.path(b.fmt("lib/nickle/arch/{s}.zig", .{arch})), b.fmt("nickle/arch/{s}.zig", .{arch}));
        _ = wf.addCopyDirectory(b.path(b.fmt("lib/nickle/arch/{s}", .{arch})), b.fmt("nickle/arch/{s}", .{arch}), .{});
    }

    arch_source.appendSlice("\ntest {\n") catch @panic("OOM");

    for (arches) |arch| {
        const line = b.fmt("    _ = {s};\n", .{
            arch,
        });
        defer b.allocator.free(line);

        arch_source.appendSlice(line) catch @panic("OOM");
    }

    arch_source.appendSlice("}\n") catch @panic("OOM");

    _ = wf.add("nickle/arch.zig", arch_source.items);
    return wf.addCopyFile(b.path("lib/nickle.zig"), "nickle.zig");
}

fn makeTest(
    b: *std.Build,
    options: *std.Build.Step.Options,
    target: std.Build.ResolvedTarget,
    optimize: std.builtin.OptimizeMode,
    linkage: std.builtin.LinkMode,
    arches: []const []const u8,
) *std.Build.Step.Compile {
    const module_test = b.addTest(.{
        .name = b.fmt("test-nickle-{s}", .{
            target.result.zigTriple(b.allocator) catch |e| std.debug.panic("Failed to generate zig triple: {s}", .{@errorName(e)}),
        }),
        .root_source_file = makeSource(b, arches),
        .target = target,
        .optimize = optimize,
    });

    module_test.linkage = linkage;
    module_test.root_module.addOptions("options", options);
    return module_test;
}

pub fn build(b: *std.Build) void {
    const optimize = b.standardOptimizeOption(.{});
    const target = b.standardTargetOptions(.{});
    const linkage = b.option(std.builtin.LinkMode, "linkage", "whether to statically or dynamically link the library") orelse @as(std.builtin.LinkMode, if (target.result.isGnuLibC()) .dynamic else .static);
    const arches = b.option([]const []const u8, "arches", "specific architectures to enable") orelse @as([]const []const u8, &.{
        "aarch64",
        "wasm32",
        "wasm64",
    });

    const step_test = b.step("test", "Run test suite");

    const options = b.addOptions();

    if (b.enable_wasmtime) {
        const wasmtime = b.findProgram(&.{"wasmtime"}, &.{}) catch |e| std.debug.panic("Could not find wasmtime: {s}", .{@errorName(e)});
        options.addOption([]const u8, "wasmtime", wasmtime);
    }

    options.addOption([]const []const u8, "arches", arches);

    const module = b.addModule("nickle", .{
        .root_source_file = makeSource(b, arches),
        .target = target,
        .optimize = optimize,
    });

    module.addOptions("options", options);

    for (arches) |arch| {
        const arch_tag = std.meta.stringToEnum(std.Target.Cpu.Arch, arch) orelse unreachable;

        // Zig doesn't support executing wasm64
        if (arch_tag == .wasm64) continue;

        // Skip wasm stuff if not enabled
        if (arch_tag.isWasm() and !b.enable_wasmtime) continue;

        const os_tag: std.Target.Os.Tag = if (std.mem.eql(u8, arch, "wasm32") or std.mem.eql(u8, arch, "wasm64")) .wasi else target.result.os.tag;
        const query = std.Target.Query.parse(.{
            .arch_os_abi = b.fmt("{s}-{s}-{s}", .{
                @tagName(arch_tag),
                @tagName(os_tag),
                @tagName(std.Target.Abi.default(arch_tag, .{
                    .tag = os_tag,
                    .version_range = std.Target.Os.VersionRange.default(os_tag, arch_tag),
                })),
            }),
        }) catch |e| std.debug.panic("Failed to parse query: {s}", .{@errorName(e)});

        step_test.dependOn(&b.addRunArtifact(makeTest(b, options, b.resolveTargetQuery(query), optimize, linkage, arches)).step);
    }

    const module_test_host = makeTest(b, options, b.graph.host, optimize, linkage, arches);
    b.installDirectory(.{
        .source_dir = module_test_host.getEmittedDocs(),
        .install_dir = .prefix,
        .install_subdir = "docs/nickle",
    });
}
