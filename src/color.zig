const std = @import("std");
const vectors = @import("vectors.zig");

const Vec3 = vectors.Vec3;

pub const Color = Vec3;

pub fn write_color(writer: *std.Io.Writer, pixel_color: Color) !void {
    const r = pixel_color.x();
    const g = pixel_color.y();
    const b = pixel_color.z();

    const r_byte: i32 = @intFromFloat(255.999 * r);
    const g_byte: i32 = @intFromFloat(255.999 * g);
    const b_byte: i32 = @intFromFloat(255.999 * b);

    try writer.print("{d} {d} {d}\n", .{ r_byte, g_byte, b_byte });
}
