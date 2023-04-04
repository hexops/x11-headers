const std = @import("std");

pub fn build(b: *std.Build) void {
    const target = b.standardTargetOptions(.{});
    const optimize = b.standardOptimizeOption(.{});

    const lib = b.addStaticLibrary(.{
        .name = "x11-headers",
        .root_source_file = .{ .path = "stub.c" },
        .target = target,
        .optimize = optimize,
    });

    lib.linkLibC();

    // contains only GLX headers!
    lib.installHeadersDirectory("GL", "GL");
    lib.installHeadersDirectory("X11", "X11");
    lib.installHeadersDirectory("xkbcommon", "xkbcommon");

    lib.install();
}
