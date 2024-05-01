const std = @import("std");

pub fn build(b: *std.Build) void {
    const target = b.standardTargetOptions(.{});
    const optimize = b.standardOptimizeOption(.{});

    const lib = b.addStaticLibrary(.{
        .name = "x11-headers",
        .root_source_file = b.addWriteFiles().add("empty.c", ""),
        .target = target,
        .optimize = optimize,
    });

    // contains only GLX headers!
    lib.installHeadersDirectory(.{ .path = "GL" }, "GL", .{});
    lib.installHeadersDirectory(.{ .path = "X11" }, "X11", .{});
    lib.installHeadersDirectory(.{ .path = "xcb" }, "xcb", .{});
    lib.installHeadersDirectory(.{ .path = "xkbcommon" }, "xkbcommon", .{});

    b.installArtifact(lib);
}
