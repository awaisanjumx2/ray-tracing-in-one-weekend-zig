const std = @import("std");
const utils = @import("utils.zig");

var stdout_buffer: [1024]u8 = undefined;
var stdout_writer = std.fs.File.stdout().writer(&stdout_buffer);
var stdout = &stdout_writer.interface;

var stderr_buffer: [1024]u8 = undefined;
var stderr_writer = std.fs.File.stderr().writer(&stderr_buffer);
var stderr = &stderr_writer.interface;

pub fn main() !void {
    // Image

    const image_width = 256;
    const image_height = 256;

    // Render

    try stdout.print("P3\n{d} {d}\n255\n", .{ image_width, image_height });

    for (0..image_height) |j| {
        try utils.bufferedPrint(stderr, "\rScanlines remaining: {d} \n", .{image_height - j});
        for (0..image_width) |i| {
            const r = @as(f64, @floatFromInt(i)) / @as(f64, image_width - 1);
            const g = @as(f64, @floatFromInt(j)) / @as(f64, image_height - 1);
            const b = 0.0;

            const ir: i32 = @intFromFloat(255.999 * r);
            const ig: i32 = @intFromFloat(255.999 * g);
            const ib: i32 = @intFromFloat(255.999 * b);

            try stdout.print("{d} {d} {d}\n", .{ ir, ig, ib });
        }
    }

    try stdout.flush();
    try utils.bufferedPrint(stderr, "\rDone.                 \n", .{});
}
