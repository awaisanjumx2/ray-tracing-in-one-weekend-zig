const std = @import("std");
const vectors = @import("vectors.zig");
const colors = @import("color.zig");
const rays = @import("ray.zig");
const shapes = @import("shapes.zig");
const utils = @import("utils.zig");

const math = std.math;

const Vec3 = vectors.Vec3;
const Color = colors.Color;
const Ray = rays.Ray;
const HitRecord = shapes.HitRecord;

pub const Material = union(enum) {
    Lambertian: Lambertian,
    Metal: Metal,
    Dielectric: Dielectric,
};

pub const Lambertian = struct {
    albedo: Color,

    pub fn init(albedo: Color) Lambertian {
        return .{ .albedo = albedo };
    }

    pub fn scatter(self: Lambertian, r_in: Ray, hit_record: HitRecord, attenuation: *Color, scattered: *Ray) bool {
        _ = r_in;

        var scatter_direction = hit_record.normal.add(Vec3.random_unit_vector());

        // Catch degenerate scatter direction
        if (scatter_direction.near_zero())
            scatter_direction = hit_record.normal;

        scattered.* = Ray.init(hit_record.p, scatter_direction);
        attenuation.* = self.albedo;

        return true;
    }
};

pub const Metal = struct {
    albedo: Color,
    fuzz: f64,

    pub fn init(albedo: Color, fuzz: f64) Metal {
        return .{ .albedo = albedo, .fuzz = if (fuzz < 1) fuzz else 1 };
    }

    pub fn scatter(self: Metal, r_in: Ray, hit_record: HitRecord, attenuation: *Color, scattered: *Ray) bool {
        var reflected = Vec3.reflect(r_in.direction, hit_record.normal);
        reflected = reflected.unit_vector().add(Vec3.random_unit_vector().scale(self.fuzz));
        scattered.* = Ray.init(hit_record.p, reflected);
        attenuation.* = self.albedo;

        return scattered.direction.dotProd(hit_record.normal) > 0;
    }
};

pub const Dielectric = struct {
    // Refractive index in vacuum or air, or the ratio of the material's refractive index over
    // the refractive index of the enclosing media
    refraction_index: f64,

    pub fn init(refraction_index: f64) Dielectric {
        return .{ .refraction_index = refraction_index };
    }

    pub fn scatter(self: Dielectric, r_in: Ray, hit_record: HitRecord, attenuation: *Color, scattered: *Ray) bool {
        attenuation.* = Color.init(1.0, 1.0, 1.0);
        const ri = if (hit_record.front_face) (1.0 / self.refraction_index) else self.refraction_index;

        const unit_direction = r_in.direction.unit_vector();
        const cos_theta: f64 = @min(unit_direction.negate().dotProd(hit_record.normal), 1.0);
        const sin_theta = math.sqrt(1.0 - cos_theta * cos_theta);

        const cannot_refract = ri * sin_theta > 1.0;
        var direction: Vec3 = undefined;

        if (cannot_refract or reflectance(cos_theta, ri) > utils.random_float()) {
            direction = Vec3.reflect(unit_direction, hit_record.normal);
        } else {
            direction = Vec3.refract(unit_direction, hit_record.normal, ri);
        }

        scattered.* = Ray.init(hit_record.p, direction);

        return true;
    }

    pub fn reflectance(cosine: f64, refraction_index: f64) f64 {
        // Use Schlick's approximation for reflectance.
        var r0 = (1 - refraction_index) / (1 + refraction_index);
        r0 = r0 * r0;
        return r0 + (1 - r0) * math.pow(f64, (1 - cosine), 5);
    }
};
