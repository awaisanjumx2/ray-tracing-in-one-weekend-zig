const std = @import("std");
const vectors = @import("vectors.zig");
const interval = @import("interval.zig");

const math = std.math;

const Vec3 = vectors.Vec3;
const Interval = interval.Interval;

pub const Color = Vec3;

pub fn linear_to_gamma(linear_component: f64) f64 {
    if (linear_component > 0) {
        return math.sqrt(linear_component);
    }

    return 0;
}

pub fn write_color(writer: *std.Io.Writer, pixel_color: Color) !void {
    var r = pixel_color.x();
    var g = pixel_color.y();
    var b = pixel_color.z();

    // Apply a linear to gamma transform for gamma 2
    r = linear_to_gamma(r);
    g = linear_to_gamma(g);
    b = linear_to_gamma(b);

    // Translate the [0,1] component values to the byte range [0,255].
    const intensity = Interval.init(0.000, 0.999);
    const r_byte: i32 = @intFromFloat(256 * intensity.clamp(r));
    const g_byte: i32 = @intFromFloat(256 * intensity.clamp(g));
    const b_byte: i32 = @intFromFloat(256 * intensity.clamp(b));

    try writer.print("{d} {d} {d}\n", .{ r_byte, g_byte, b_byte });
}
