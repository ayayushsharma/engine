const std = @import("std");
const rlz = @import("raylib_zig");

pub fn build(b: *std.Build) !void {
    const target = b.standardTargetOptions(.{});
    const optimize = b.standardOptimizeOption(.{});

    const raylib_dep = b.dependency("raylib_zig", .{
        .target = target,
        .optimize = optimize,
    });
    const emsdk_dep = raylib_dep.builder.dependency("emsdk", .{});
    const raylib = raylib_dep.module("raylib");
    const raylib_artifact = raylib_dep.artifact("raylib");

    const exe_mod = b.createModule(.{
        .root_source_file = b.path("src/main.zig"),
        .target = target,
        .optimize = optimize,
    });

    const log_mod = b.createModule(.{ .root_source_file = b.path("src/log.zig") });
    log_mod.addImport("raylib", raylib);

    const data_mod = b.createModule(.{ .root_source_file = b.path("src/data/root.zig") });
    data_mod.addImport("raylib", raylib);
    data_mod.addImport("log", log_mod);

    const engine_mod = b.createModule(.{ .root_source_file = b.path("src/engine/root.zig") });
    engine_mod.addImport("raylib", raylib);

    exe_mod.addImport("raylib", raylib);
    exe_mod.addImport("data", data_mod);
    exe_mod.addImport("log", log_mod);
    exe_mod.addImport("engine", engine_mod);

    const check = b.step("check", "Check if the project compiles");
    check.dependOn(&b.addTest(.{ .root_module = exe_mod }).step);

    const run_step = b.step("run", "Run the app");

    if (target.query.os_tag == .emscripten) {
        const emsdk = rlz.emsdk;
        const wasm = b.addLibrary(.{
            .name = "engine-zig",
            .root_module = exe_mod,
        });

        const install_dir: std.Build.InstallDir = .{ .custom = "web" };
        var emcc_flags = emsdk.emccDefaultFlags(b.allocator, .{ .optimize = optimize });
        try emcc_flags.put("-gsource-map", {});
        try emcc_flags.put("-g", {});

        var emcc_settings = emsdk.emccDefaultSettings(b.allocator, .{ .optimize = optimize });
        try emcc_settings.put("ASSERTIONS", "2");
        try emcc_settings.put("STACK_OVERFLOW_CHECK", "1");
        try emcc_settings.put("ALLOW_MEMORY_GROWTH", "1");
        try emcc_settings.put("EXIT_RUNTIME", "1");

        const emcc_step = emsdk.emccStep(b, raylib_artifact, wasm, .{
            .optimize = optimize,
            .flags = emcc_flags,
            .settings = emcc_settings,
            .shell_file_path = emsdk_dep.path("upstream/emscripten/src/shell.html"),
            .install_dir = install_dir,
            .embed_paths = &.{.{ .src_path = "resources/" }},
        });
        b.getInstallStep().dependOn(emcc_step);

        const html_filename = try std.fmt.allocPrint(b.allocator, "{s}.html", .{wasm.name});
        const emrun_step = emsdk.emrunStep(
            b,
            b.getInstallPath(install_dir, html_filename),
            &.{},
        );

        emrun_step.dependOn(emcc_step);
        run_step.dependOn(emrun_step);
        return;
    }

    const exe = b.addExecutable(.{
        .name = "engine-zig",
        .root_module = exe_mod,
        .use_llvm = true,
    });

    b.installArtifact(exe);

    const run_cmd = b.addRunArtifact(exe);
    run_cmd.step.dependOn(b.getInstallStep());

    run_step.dependOn(&run_cmd.step);
}
