const std = @import("std");
const math = std.math;

pub const Point3 = Vec3;
pub const Vec3 = struct {
    e: [3]f64,

    pub fn init() Vec3 {
        return .{ .e = [3]f64{ 0, 0, 0 } };
    }

    pub fn initWith(e0: f64, e1: f64, e2: f64) Vec3 {
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

    pub fn addScalar(self: *Vec3, other: *Vec3) void {
        self.*.e[0] += other.*.e[0];
        self.*.e[1] += other.*.e[1];
        self.*.e[2] += other.*.e[2];
    }

    pub fn multiplyScalar(self: *Vec3, t: f64) void {
        self.*.e[0] *= t;
        self.*.e[1] *= t;
        self.*.e[2] *= t;
    }

    pub fn divideScaler(self: *Vec3, t: f64) void {
        self.multiplyScalar(1.0 / t);
    }

    pub fn length(self: Vec3) f64 {
        return math.sqrt(self.length_squared());
    }

    pub fn length_squared(self: Vec3) f64 {
        return self.e[0] * self.e[0] + self.e[1] * self.e[1] + self.e[2] * self.e[2];
    }
};

pub fn add(x: Vec3, y: Vec3) Vec3 {
    return .initWith(
        x.e[0] + y.e[0],
        x.e[1] + y.e[1],
        x.e[2] + y.e[2],
    );
}

pub fn subtract(x: Vec3, y: Vec3) Vec3 {
    return .initWith(
        x.e[0] - y.e[0],
        x.e[1] - y.e[1],
        x.e[2] - y.e[2],
    );
}

pub fn multiply(x: Vec3, y: Vec3) Vec3 {
    return .initWith(
        x.e[0] * y.e[0],
        x.e[1] * y.e[1],
        x.e[2] * y.e[2],
    );
}

pub fn multiplyScalarWithVec3(t: f64, v: Vec3) Vec3 {
    return .initWith(
        t * v.e[0],
        t * v.e[1],
        t * v.e[2],
    );
}

pub fn divideByScalar(v: Vec3, t: f64) Vec3 {
    return multiplyScalarWithVec3(1 / t, v);
}

pub fn unit_vector(v: Vec3) Vec3 {
    return divideByScalar(v, v.length());
}
