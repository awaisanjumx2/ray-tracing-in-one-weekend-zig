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

var prng = std.Random.DefaultPrng.init(5489);
var rand = prng.random();

pub fn random_float() f64 {
    return rand.float(f64);
}

pub fn random_float_range(min: f64, max: f64) f64 {
    return min + (max - min) * random_float();
}
