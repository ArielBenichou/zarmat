const std = @import("std");

pub fn build(b: *std.Build) void {
    const target = b.standardTargetOptions(.{});
    const optimize = b.standardOptimizeOption(.{});

    const lib_mod = b.createModule(.{
        .root_source_file = b.path("src/engine/root.zig"),
        .target = target,
        .optimize = optimize,
    });
    const lib = b.addLibrary(.{
        .linkage = .static,
        .name = "delme",
        .root_module = lib_mod,
    });
    configGameDevDeps(b, lib, target);
    b.installArtifact(lib);

    const exe_mod = b.createModule(.{
        .root_source_file = b.path("src/main.zig"),
        .target = target,
        .optimize = optimize,
    });
    exe_mod.addImport("engine", lib_mod);
    const exe = b.addExecutable(.{
        .name = "zarmat",
        .root_module = exe_mod,
    });
    b.installArtifact(exe);

    // RUN
    const run_cmd = b.addRunArtifact(exe);
    run_cmd.step.dependOn(b.getInstallStep());
    if (b.args) |args| {
        run_cmd.addArgs(args);
    }
    const run_step = b.step("run", "Run the app");
    run_step.dependOn(&run_cmd.step);

    // TEST
    const exe_unit_tests = b.addTest(.{
        .root_module = exe_mod,
    });
    const run_exe_unit_tests = b.addRunArtifact(exe_unit_tests);
    const lib_unit_tests = b.addTest(.{
        .root_module = lib_mod,
    });
    const run_lib_unit_tests = b.addRunArtifact(lib_unit_tests);
    const test_step = b.step("test", "Run unit tests");
    test_step.dependOn(&run_exe_unit_tests.step);
    test_step.dependOn(&run_lib_unit_tests.step);
}

// TODO: this should only be called for the engine i think, the game should use the abstraction
fn configGameDevDeps(b: *std.Build, artifact: *std.Build.Step.Compile, target: std.Build.ResolvedTarget) void {
    //---zglfw
    const zglfw = b.dependency("zglfw", .{
        .target = target,
    });
    artifact.root_module.addImport("zglfw", zglfw.module("root"));
    artifact.linkLibrary(zglfw.artifact("glfw"));

    //---zopengl
    const zopengl = b.dependency("zopengl", .{});
    artifact.root_module.addImport("zopengl", zopengl.module("root"));

    //---zstbi
    const zstbi = b.dependency("zstbi", .{});
    artifact.root_module.addImport("zstbi", zstbi.module("root"));

    //---zmath
    const zmath = b.dependency("zmath", .{});
    artifact.root_module.addImport("zmath", zmath.module("root"));

    //---zgui
    const zgui = b.dependency("zgui", .{
        .target = target,
        .backend = .glfw_opengl3,
        .shared = false,
        .with_implot = true,
    });
    artifact.root_module.addImport("zgui", zgui.module("root"));
    artifact.linkLibrary(zgui.artifact("imgui"));

    //---system_sdk
    if (target.result.os.tag == .macos) {
        if (b.lazyDependency("system_sdk", .{})) |system_sdk| {
            artifact.addLibraryPath(system_sdk.path("macos12/usr/lib"));
            artifact.addSystemFrameworkPath(system_sdk.path("macos12/System/Library/Frameworks"));
        }
    }
}
