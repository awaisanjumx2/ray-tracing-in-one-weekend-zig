const std = @import("std");
const vectors = @import("vectors.zig");

const Vec3 = vectors.Vec3;
const Point3 = vectors.Point3;

pub const Ray = struct {
    origin: Point3,
    direction: Vec3,

    pub fn init(origin: Point3, direction: Vec3) Ray {
        return Ray{ .origin = origin, .direction = direction };
    }

    pub fn at(self: Ray, t: f64) Point3 {
        return vectors.add(self.origin, vectors.multiplyScalarWithVec3(t, self.direction));
    }
};
