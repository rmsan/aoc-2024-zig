const std = @import("std");

pub fn setup_day(
    b: *std.Build,
    target: std.Build.ResolvedTarget,
    mode: std.builtin.OptimizeMode,
    day: u32,
) void {
    const path = b.fmt("day{:0>2}", .{day});
    const root_src = b.fmt("{s}/main.zig", .{path});
    const exe = b.addExecutable(.{ .name = path, .root_module = b.createModule(.{ .root_source_file = b.path(root_src), .target = target, .optimize = mode }) });

    const install_cmd = b.addInstallArtifact(exe, .{});
    const install_step = b.step(path, "Build specified day");
    install_step.dependOn(&install_cmd.step);

    const run_cmd = b.addRunArtifact(exe);
    run_cmd.step.dependOn(&install_cmd.step);
    if (b.args) |args| {
        run_cmd.addArgs(args);
    }

    const run_step = b.step(b.fmt("run_{s}", .{path}), "Run specified day");
    run_step.dependOn(&run_cmd.step);

    const exe_test = b.addTest(.{ .root_module = exe.root_module });

    const run_test = b.addRunArtifact(exe_test);
    const test_step = b.step(b.fmt("test_{s}", .{path}), "Run tests for given day.");
    test_step.dependOn(&run_test.step);
}

pub fn build(b: *std.Build) void {
    const target = b.standardTargetOptions(.{});
    const optimize = b.standardOptimizeOption(.{});

    comptime var counter: usize = 1;
    inline while (counter <= 25) {
        setup_day(b, target, optimize, counter);
        counter += 1;
    }
}
