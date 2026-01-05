const std = @import("std");
const utils = @import("utils.zig");
const vectors = @import("vectors.zig");
const shapes = @import("shapes.zig");
const camera_mod = @import("camera.zig");

const Point3 = vectors.Point3;
const Sphere = shapes.Sphere;
const HittableList = shapes.HittableList;
const Camera = camera_mod.Camera;

var stdout_buffer: [1024]u8 = undefined;
var stdout_writer = std.fs.File.stdout().writer(&stdout_buffer);
var stdout = &stdout_writer.interface;

var stderr_buffer: [1024]u8 = undefined;
var stderr_writer = std.fs.File.stderr().writer(&stderr_buffer);
var stderr = &stderr_writer.interface;

pub fn main() !void {
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    const allocator = gpa.allocator();
    defer _ = gpa.deinit();

    // World

    var world = try HittableList.init(allocator);
    defer world.deinit();

    try world.add(.{ .Sphere = Sphere.init(Point3.init(0, 0, -1), 0.5) });
    try world.add(.{ .Sphere = Sphere.init(Point3.init(0, -100.5, -1), 100) });

    var camera = Camera.init(16.0 / 9.0, 400, 10);
    try camera.render(&world, stdout, stderr);

    try stdout.flush();
    try utils.bufferedPrint(stderr, "\rDone.                 \n", .{});
}
