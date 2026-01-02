const std = @import("std");

pub const pi = 3.1415926535897932385;
pub const infinity = std.math.inf(f64);

pub fn bufferedPrint(writer: *std.Io.Writer, comptime fmt: []const u8, args: anytype) !void {
    try writer.print(fmt, args);
    try writer.flush();
}

pub fn degrees_to_radians(degrees: f64) f64 {
    return degrees * pi / 180.0;
}
