const std = @import("std");
const utils = @import("utils.zig");
const math = std.math;

pub const Point3 = Vec3;
pub const Vec3 = struct {
    e: @Vector(3, f64),

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
        return .{ .e = -self.e };
    }

    pub fn add(self: Vec3, other: Vec3) Vec3 {
        return .{ .e = self.e + other.e };
    }

    pub fn sub(self: Vec3, other: Vec3) Vec3 {
        return .{ .e = self.e - other.e };
    }

    pub fn mul(self: Vec3, other: Vec3) Vec3 {
        return .{ .e = self.e * other.e };
    }

    pub fn scale(self: Vec3, t: f64) Vec3 {
        return .{ .e = self.e * @as(@Vector(3, f64), @splat(t)) };
    }

    pub fn div(self: Vec3, t: f64) Vec3 {
        return .{ .e = self.e / @as(@Vector(3, f64), @splat(t)) };
    }

    pub fn unit_vector(self: Vec3) Vec3 {
        return self.div(self.length());
    }

    pub fn random_in_unit_disk() Vec3 {
        while (true) {
            const p = Vec3.init(utils.random_float_range(-1, 1), utils.random_float_range(-1, 1), 0);
            if (p.length_squared() < 1)
                return p;
        }
    }

    pub fn random_unit_vector() Vec3 {
        while (true) {
            const p = Vec3.random_range(-1, 1);
            const len_sq = p.length_squared();
            if (1e-160 < len_sq and len_sq <= 1) {
                return p.div(math.sqrt(len_sq));
            }
        }
    }

    pub fn random_on_hemisphere(normal: Vec3) Vec3 {
        const on_unit_sphere = random_unit_vector();
        if (on_unit_sphere.dotProd(normal) > 0.0) { // In the same hemisphere as the normal
            return on_unit_sphere;
        } else {
            return on_unit_sphere.negate();
        }
    }

    pub fn reflect(v: Vec3, n: Vec3) Vec3 {
        return v.sub(n.scale(2 * v.dotProd(n)));
    }

    pub fn refract(uv: Vec3, n: Vec3, etai_over_etat: f64) Vec3 {
        const cos_theta: f64 = @min(uv.negate().dotProd(n), 1.0);
        const r_out_perp = uv.add(n.scale(cos_theta)).scale(etai_over_etat);
        const r_out_parallel = n.scale(-math.sqrt(@abs(1.0 - r_out_perp.length_squared())));
        return r_out_perp.add(r_out_parallel);
    }

    pub fn length(self: Vec3) f64 {
        return math.sqrt(self.length_squared());
    }

    pub fn length_squared(self: Vec3) f64 {
        return self.e[0] * self.e[0] + self.e[1] * self.e[1] + self.e[2] * self.e[2];
    }

    pub fn near_zero(self: Vec3) bool {
        // Return true if the vector is close to zero in all dimensions.
        const s = 1e-8;
        return (@abs(self.e[0]) < s) and (@abs(self.e[1]) < s) and (@abs(self.e[2]) < s);
    }

    pub fn random() Vec3 {
        return .init(
            utils.random_float(),
            utils.random_float(),
            utils.random_float(),
        );
    }

    pub fn random_range(min: f64, max: f64) Vec3 {
        return .init(
            utils.random_float_range(min, max),
            utils.random_float_range(min, max),
            utils.random_float_range(min, max),
        );
    }

    pub fn dotProd(self: Vec3, other: Vec3) f64 {
        return (self.e[0] * other.e[0]) + (self.e[1] * other.e[1]) + (self.e[2] * other.e[2]);
    }

    pub fn crossProd(self: Vec3, other: Vec3) Vec3 {
        return .init(
            self.e[1] * other.e[2] - self.e[2] * other.e[1],
            self.e[2] * other.e[0] - self.e[0] * other.e[2],
            self.e[0] * other.e[1] - self.e[1] * other.e[0],
        );
    }
};
