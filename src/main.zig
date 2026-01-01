const std = @import("std");
const utils = @import("utils.zig");
const colors = @import("color.zig");
const rays = @import("ray.zig");
const vectors = @import("vectors.zig");

const Color = colors.Color;
const Ray = rays.Ray;
const Point3 = vectors.Point3;
const Vec3 = vectors.Vec3;

var stdout_buffer: [1024]u8 = undefined;
var stdout_writer = std.fs.File.stdout().writer(&stdout_buffer);
var stdout = &stdout_writer.interface;

var stderr_buffer: [1024]u8 = undefined;
var stderr_writer = std.fs.File.stderr().writer(&stderr_buffer);
var stderr = &stderr_writer.interface;

fn ray_color(ray: Ray) Color {
    const unit_direction = vectors.unit_vector(ray.direction);
    const a = 0.5 * (unit_direction.y() + 1.0);
    return vectors.add(
        vectors.multiplyScalarWithVec3(1.0 - a, Color.initWith(1.0, 1.0, 1.0)),
        vectors.multiplyScalarWithVec3(a, Color.initWith(0.5, 0.7, 1.0)),
    );
}

pub fn main() !void {
    // Image

    const aspect_ratio: f64 = 16.0 / 9.0;
    const image_width: u32 = 400;

    // Calculate the image height, and ensure that it's at least 1.
    var image_height: u32 = @intFromFloat(image_width / aspect_ratio);
    image_height = if (image_height < 1) 1 else image_height;

    // Camera

    const focal_length: f64 = 1.0;
    const viewport_height: f64 = 2.0;
    const viewport_width = viewport_height * @as(f64, @floatFromInt(image_width)) / @as(f64, @floatFromInt(image_height));
    const camera_center = Point3.initWith(0, 0, 0);

    // Calculate the vectors across the horizontal and down the vertical viewport edges.
    const viewport_u = Vec3.initWith(viewport_width, 0, 0);
    const viewport_v = Vec3.initWith(0, -viewport_height, 0);

    // Calculate the horizontal and vertical delta vectors from pixel to pixel.
    const pixel_delta_u = vectors.divideByScalar(viewport_u, @floatFromInt(image_width));
    const pixel_delta_v = vectors.divideByScalar(viewport_v, @floatFromInt(image_height));

    // Calculate the location of the upper left pixel.
    const viewport_upper_left = vectors.subtract(
        vectors.subtract(
            vectors.subtract(camera_center, Vec3.initWith(0, 0, focal_length)),
            vectors.divideByScalar(viewport_u, 2),
        ),
        vectors.divideByScalar(viewport_v, 2),
    );
    const pixel00_loc = vectors.add(
        viewport_upper_left,
        vectors.multiplyScalarWithVec3(
            0.5,
            vectors.add(pixel_delta_u, pixel_delta_v),
        ),
    );

    // Render

    try stdout.print("P3\n{d} {d}\n255\n", .{ image_width, image_height });

    for (0..image_height) |j| {
        try utils.bufferedPrint(stderr, "\rScanlines remaining: {d} \n", .{image_height - j});
        for (0..image_width) |i| {
            const pixel_center = vectors.add(
                pixel00_loc,
                vectors.add(
                    vectors.multiplyScalarWithVec3(@floatFromInt(i), pixel_delta_u),
                    vectors.multiplyScalarWithVec3(@floatFromInt(j), pixel_delta_v),
                ),
            );
            const ray_direction = vectors.subtract(pixel_center, camera_center);
            const ray = Ray.init(camera_center, ray_direction);

            const pixel_color = ray_color(ray);

            try colors.write_color(stdout, pixel_color);
        }
    }

    try stdout.flush();
    try utils.bufferedPrint(stderr, "\rDone.                 \n", .{});
}
