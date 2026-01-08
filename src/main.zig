const std = @import("std");
const utils = @import("utils.zig");
const vectors = @import("vectors.zig");
const shapes = @import("shapes.zig");
const camera_mod = @import("camera.zig");
const colors = @import("color.zig");
const material = @import("material.zig");

const Point3 = vectors.Point3;
const Sphere = shapes.Sphere;
const HittableList = shapes.HittableList;
const Camera = camera_mod.Camera;
const Lambertian = material.Lambertian;
const Metal = material.Metal;
const Dielectric = material.Dielectric;
const Color = colors.Color;
const Vec3 = vectors.Vec3;

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

    const material_ground = Lambertian.init(Color.init(0.8, 0.8, 0.0));
    const material_center = Lambertian.init(Color.init(0.1, 0.2, 0.5));
    const material_left = Dielectric.init(1.50);
    const material_bubble = Dielectric.init(1.00 / 1.50);
    const material_right = Metal.init(Color.init(0.8, 0.6, 0.2), 1.0);

    try world.add(.{ .Sphere = Sphere.init(Point3.init(0.0, -100.5, -1.0), 100.0, .{ .Lambertian = material_ground }) });
    try world.add(.{ .Sphere = Sphere.init(Point3.init(0.0, 0.0, -1.2), 0.5, .{ .Lambertian = material_center }) });
    try world.add(.{ .Sphere = Sphere.init(Point3.init(-1.0, 0.0, -1.0), 0.5, .{ .Dielectric = material_left }) });
    try world.add(.{ .Sphere = Sphere.init(Point3.init(-1.0, 0.0, -1.0), 0.4, .{ .Dielectric = material_bubble }) });
    try world.add(.{ .Sphere = Sphere.init(Point3.init(1.0, 0.0, -1.0), 0.5, .{ .Metal = material_right }) });

    var camera = Camera.init(
        16.0 / 9.0,
        400,
        10,
        50,
        20,
        Point3.init(-2, 2, 1),
        Point3.init(0, 0, -1),
        Vec3.init(0, 1, 0),
        10.0,
        3.4,
    );
    try camera.render(&world, stdout, stderr);

    try stdout.flush();
    try utils.bufferedPrint(stderr, "\rDone.                 \n", .{});
}
