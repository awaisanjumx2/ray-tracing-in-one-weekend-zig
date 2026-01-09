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
const Material = material.Material;

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

    const ground_material = Lambertian.init(Color.init(0.5, 0.5, 0.5));
    try world.add(.{ .Sphere = .init(.init(0, -1000, 0), 1000, .{ .Lambertian = ground_material }) });

    var a: i32 = -11;
    while (a < 11) : (a += 1) {
        var b: i32 = -11;
        while (b < 11) : (b += 1) {
            const chose_mat = utils.random_float();
            const center = Point3.init(
                @as(f64, @floatFromInt(a)) + 0.9 * utils.random_float(),
                0.2,
                @as(f64, @floatFromInt(b)) + 0.9 * utils.random_float(),
            );

            if (center.sub(.init(4, 0.2, 0)).length() > 0.9) {
                var sphere_material: Material = undefined;

                if (chose_mat < 0.8) {
                    // diffuse
                    const albedo = Color.random().mul(Color.random());
                    sphere_material = .{ .Lambertian = .init(albedo) };
                    try world.add(.{ .Sphere = .init(center, 0.2, sphere_material) });
                } else if (chose_mat < 0.95) {
                    // metal
                    const albedo = Color.random_range(0.5, 1.0);
                    const fuzz = utils.random_float_range(0.0, 0.5);
                    sphere_material = .{ .Metal = .init(albedo, fuzz) };
                    try world.add(.{ .Sphere = .init(center, 0.2, sphere_material) });
                } else {
                    // glass
                    sphere_material = .{ .Dielectric = .init(1.5) };
                    try world.add(.{ .Sphere = .init(center, 0.2, sphere_material) });
                }
            }
        }
    }

    const material1 = Dielectric.init(1.5);
    try world.add(.{ .Sphere = .init(.init(0, 1, 0), 1.0, .{ .Dielectric = material1 }) });

    const material2 = Lambertian.init(.init(0.4, 0.2, 0.1));
    try world.add(.{ .Sphere = .init(.init(-4, 1, 0), 1.0, .{ .Lambertian = material2 }) });

    const material3 = Metal.init(.init(0.7, 0.6, 0.5), 0.0);
    try world.add(.{ .Sphere = .init(.init(4, 1, 0), 1.0, .{ .Metal = material3 }) });

    var camera = Camera.init(
        16.0 / 9.0,
        1200,
        500,
        50,
        20,
        .init(13, 2, 3),
        .init(0, 0, 0),
        .init(0, 1, 0),
        0.6,
        10.0,
    );
    try camera.render(&world, stdout, stderr);

    try stdout.flush();
    try utils.bufferedPrint(stderr, "\rDone.                 \n", .{});
}
