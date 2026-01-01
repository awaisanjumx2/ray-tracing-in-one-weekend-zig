const std = @import("std");
const math = std.math;

pub const Point3 = Vec3;
pub const Vec3 = struct {
    e: [3]f64,

    pub fn zero() Vec3 {
        return .{ .e = [3]f64{ 0, 0, 0 } };
    }

    pub fn init(e0: f64, e1: f64, e2: f64) Vec3 {
        return .{ .e = [3]f64{ e0, e1, e2 } };
    }

    pub fn x(self: Vec3) f64 {
        return self.e[0];
    }
    pub fn y(self: Vec3) f64 {
        return self.e[1];
    }
    pub fn z(self: Vec3) f64 {
        return self.e[2];
    }

    pub fn negate(self: Vec3) Vec3 {
        return .{ .e = [3]f64{ self.e[0], self.e[1], self.e[2] } };
    }

    pub fn add(self: Vec3, other: Vec3) Vec3 {
        return .init(
            self.e[0] + other.e[0],
            self.e[1] + other.e[1],
            self.e[2] + other.e[2],
        );
    }

    pub fn sub(self: Vec3, other: Vec3) Vec3 {
        return .init(
            self.e[0] - other.e[0],
            self.e[1] - other.e[1],
            self.e[2] - other.e[2],
        );
    }

    pub fn mul(self: Vec3, other: Vec3) Vec3 {
        return .init(
            self.e[0] * other.e[0],
            self.e[1] * other.e[1],
            self.e[2] * other.e[2],
        );
    }

    pub fn scale(self: Vec3, t: f64) Vec3 {
        return .init(
            t * self.e[0],
            t * self.e[1],
            t * self.e[2],
        );
    }

    pub fn div(self: Vec3, t: f64) Vec3 {
        return self.scale(1.0 / t);
    }

    pub fn unit_vector(self: Vec3) Vec3 {
        return self.div(self.length());
    }

    pub fn length(self: Vec3) f64 {
        return math.sqrt(self.length_squared());
    }

    pub fn length_squared(self: Vec3) f64 {
        return self.e[0] * self.e[0] + self.e[1] * self.e[1] + self.e[2] * self.e[2];
    }
};
