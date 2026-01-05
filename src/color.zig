const std = @import("std");
const vectors = @import("vectors.zig");
const interval = @import("interval.zig");

const Vec3 = vectors.Vec3;
const Interval = interval.Interval;

pub const Color = Vec3;

pub fn write_color(writer: *std.Io.Writer, pixel_color: Color) !void {
    const r = pixel_color.x();
    const g = pixel_color.y();
    const b = pixel_color.z();

    // Translate the [0,1] component values to the byte range [0,255].
    const intensity = Interval.init(0.000, 0.999);
    const r_byte: i32 = @intFromFloat(256 * intensity.clamp(r));
    const g_byte: i32 = @intFromFloat(256 * intensity.clamp(g));
    const b_byte: i32 = @intFromFloat(256 * intensity.clamp(b));

    try writer.print("{d} {d} {d}\n", .{ r_byte, g_byte, b_byte });
}
