const std = @import("std");
const utils = @import("utils.zig");
const colors = @import("color.zig");
const rays = @import("ray.zig");
const vectors = @import("vectors.zig");
const shapes = @import("shapes.zig");

const math = std.math;

const Color = colors.Color;
const Ray = rays.Ray;
const Point3 = vectors.Point3;
const Vec3 = vectors.Vec3;
const Sphere = shapes.Sphere;
const HitRecord = shapes.HitRecord;
const HittableList = shapes.HittableList;

var stdout_buffer: [1024]u8 = undefined;
var stdout_writer = std.fs.File.stdout().writer(&stdout_buffer);
var stdout = &stdout_writer.interface;

var stderr_buffer: [1024]u8 = undefined;
var stderr_writer = std.fs.File.stderr().writer(&stderr_buffer);
var stderr = &stderr_writer.interface;

fn ray_color(ray: Ray, world: *HittableList) Color {
    var hit_record: HitRecord = undefined;
    if (world.hit(ray, 0, utils.infinity, &hit_record)) {
        return hit_record.normal.add(Color.init(1, 1, 1).scale(0.5));
    }

    const unit_direction = ray.direction.unit_vector();
    const a = 0.5 * (unit_direction.y() + 1.0);
    return Color.init(1.0, 1.0, 1.0).scale(1.0 - a).add(
        Color.init(0.5, 0.7, 1.0).scale(a),
    );
}

pub fn main() !void {
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    const allocator = gpa.allocator();
    defer _ = gpa.deinit();

    // Image

    const aspect_ratio: f64 = 16.0 / 9.0;
    const image_width: u32 = 400;

    // Calculate the image height, and ensure that it's at least 1.
    var image_height: u32 = @intFromFloat(image_width / aspect_ratio);
    image_height = if (image_height < 1) 1 else image_height;

    // World

    var world = try HittableList.init(allocator);
    defer world.deinit();

    try world.add(.{ .Sphere = Sphere.init(Point3.init(0, 0, -1), 0.5) });
    try world.add(.{ .Sphere = Sphere.init(Point3.init(0, -100.5, -1), 100) });

    // Camera

    const focal_length: f64 = 1.0;
    const viewport_height: f64 = 2.0;
    const viewport_width = viewport_height * @as(f64, @floatFromInt(image_width)) / @as(f64, @floatFromInt(image_height));
    const camera_center = Point3.init(0, 0, 0);

    // Calculate the vectors across the horizontal and down the vertical viewport edges.
    const viewport_u = Vec3.init(viewport_width, 0, 0);
    const viewport_v = Vec3.init(0, -viewport_height, 0);

    // Calculate the horizontal and vertical delta vectors from pixel to pixel.
    const pixel_delta_u = viewport_u.div(@floatFromInt(image_width));
    const pixel_delta_v = viewport_v.div(@floatFromInt(image_height));

    // Calculate the location of the upper left pixel.
    const viewport_upper_left = camera_center
        .sub(Vec3.init(0, 0, focal_length))
        .sub(viewport_u.div(2))
        .sub(viewport_v.div(2));
    const pixel00_loc = viewport_upper_left
        .add(pixel_delta_u.add(pixel_delta_v).scale(0.5));

    // Render

    try stdout.print("P3\n{d} {d}\n255\n", .{ image_width, image_height });

    for (0..image_height) |j| {
        try utils.bufferedPrint(stderr, "\rScanlines remaining: {d} \n", .{image_height - j});
        for (0..image_width) |i| {
            const pixel_center = pixel00_loc
                .add(pixel_delta_u.scale(@floatFromInt(i)))
                .add(pixel_delta_v.scale(@floatFromInt(j)));
            const ray_direction = pixel_center.sub(camera_center);
            const ray = Ray.init(camera_center, ray_direction);

            const pixel_color = ray_color(ray, &world);

            try colors.write_color(stdout, pixel_color);
        }
    }

    try stdout.flush();
    try utils.bufferedPrint(stderr, "\rDone.                 \n", .{});
}
